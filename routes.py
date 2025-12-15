"""
API Routes for drone detection system
"""
from flask import jsonify, request, send_file, send_from_directory
import requests
import json
import os
import time
from datetime import datetime
from threading import Thread

# Import detection and camera modules
from detection import analyze_for_drones
from camera import init_camera, capture_image, get_camera_status, CAPTURE_FOLDER,get_camera_frame

# RTSA HTTP Server configuration
RTSA_HOST = 'http://localhost:54664'

# Detection history storage
detection_history = []
MAX_HISTORY = 100

# Scanning configuration
scanning_active = False
current_scan_band = 0
scan_interval = 5  # seconds per band

def log_detection(detection_data, spectrum_data):
    """Log a drone detection event with timestamp and capture image"""
    if not detection_data.get('detected'):
        return
    
    # Capture image if camera is enabled
    image_filename = capture_image(detection_data)
    
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'unix_time': time.time(),
        'image': image_filename,
        'frequency_band': {
            'start': spectrum_data['startFrequency'],
            'end': spectrum_data['endFrequency'],
            'center': (spectrum_data['startFrequency'] + spectrum_data['endFrequency']) / 2
        },
        'strongest_signal': detection_data['strongest'],
        'total_signals': detection_data['count'],
        'confidence': detection_data.get('confidence', 0),
        'all_detections': detection_data.get('all_detections', [])
    }
    
    detection_history.append(log_entry)
    
    if len(detection_history) > MAX_HISTORY:
        detection_history.pop(0)
    
    log_file = 'drone_detections.json'
    try:
        if os.path.exists(log_file):
            with open(log_file, 'r') as f:
                all_logs = json.load(f)
        else:
            all_logs = []
        
        all_logs.append(log_entry)
        
        with open(log_file, 'w') as f:
            json.dump(all_logs, f, indent=2)
            
    except Exception as e:
        print(f"Error saving detection log: {e}")

def auto_scan_bands():
    """Automatically rotate through drone frequency bands"""
    global scanning_active, current_scan_band
    
    bands = ['2.4ghz', '5.8ghz']
    
    while scanning_active:
        band = bands[current_scan_band]
        
        try:
            control_cmd = {
                'frequencyStart': 2.400e9 if band == '2.4ghz' else 5.725e9,
                'frequencyEnd': 2.483e9 if band == '2.4ghz' else 5.875e9,
                'type': 'capture'
            }
            
            requests.put(f'{RTSA_HOST}/control', json=control_cmd, timeout=2)
            print(f"[Auto-Scan] Switched to {band}")
            
            current_scan_band = (current_scan_band + 1) % len(bands)
            
        except Exception as e:
            print(f"[Auto-Scan] Error: {e}")
        
        time.sleep(scan_interval)

def register_routes(app):
    """Register all routes with the Flask app"""
    
    @app.route('/api/spectrum')
    def get_spectrum():
        """Fetch spectrum data from RTSA and return as JSON"""
        try:
            response = requests.get(f'{RTSA_HOST}/sample', timeout=1)
            response.raise_for_status()
            data = response.json()
            
            if 'samples' not in data:
                return jsonify({'error': 'Invalid data received'}), 500
            
            detection_result = analyze_for_drones(data)
            data['detection'] = detection_result
            
            # Log detections
            log_detection(detection_result, data)
                
            return jsonify(data)
        except requests.exceptions.Timeout:
            return jsonify({'error': 'Connection timeout'}), 503
        except requests.exceptions.ConnectionError:
            return jsonify({'error': 'Cannot connect to RTSA'}), 503
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @app.route('/api/status')
    def get_status():
        """Check RTSA connection status"""
        try:
            response = requests.get(f'{RTSA_HOST}/info', timeout=1)
            response.raise_for_status()
            if response.status_code == 200:
                return jsonify({'status': 'connected', 'info': response.json()})
            else:
                return jsonify({'status': 'error'}), 500
        except:
            return jsonify({'status': 'disconnected'}), 503

    @app.route('/api/set_frequency', methods=['POST'])
    def set_frequency():
        """Change SPECTRAN V6 frequency settings via API"""
        try:
            data = request.get_json()
            
            control_cmd = {"type": "capture"}
            
            if 'start' in data and 'end' in data:
                control_cmd['frequencyStart'] = float(data['start'])
                control_cmd['frequencyEnd'] = float(data['end'])
            elif 'center' in data and 'span' in data:
                control_cmd['frequencyCenter'] = float(data['center'])
                control_cmd['frequencySpan'] = float(data['span'])
            else:
                return jsonify({'error': 'Need either start/end or center/span'}), 400
            
            response = requests.put(f'{RTSA_HOST}/control', json=control_cmd, timeout=2)
            
            if response.status_code == 200:
                return jsonify({
                    'success': True,
                    'message': 'Frequency changed',
                    'command': control_cmd
                })
            else:
                return jsonify({'error': 'RTSA rejected command'}), 500
                
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @app.route('/api/scan_band/<band_name>')
    def scan_band(band_name):
        """Quick switch to predefined drone frequency bands"""
        bands = {
            '2.4ghz': {'start': 2.400e9, 'end': 2.483e9, 'name': '2.4 GHz Control'},
            '5.8ghz': {'start': 5.725e9, 'end': 5.875e9, 'name': '5.8 GHz Video'},
            '900mhz': {'start': 902e6, 'end': 928e6, 'name': '900 MHz Control'},
            '433mhz': {'start': 433e6, 'end': 434e6, 'name': '433 MHz Control'}
        }
        
        if band_name not in bands:
            return jsonify({'error': 'Unknown band. Use: 2.4ghz, 5.8ghz, 900mhz, 433mhz'}), 400
        
        try:
            band = bands[band_name]
            control_cmd = {
                'frequencyStart': band['start'],
                'frequencyEnd': band['end'],
                'type': 'capture'
            }
            
            response = requests.put(f'{RTSA_HOST}/control', json=control_cmd, timeout=2)
            
            if response.status_code == 200:
                return jsonify({
                    'success': True,
                    'band': band['name'],
                    'start': band['start'],
                    'end': band['end']
                })
            else:
                return jsonify({'error': 'RTSA rejected command'}), 500
                
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @app.route('/api/auto_scan/start')
    def start_auto_scan():
        """Start automatic band scanning"""
        global scanning_active
        
        if scanning_active:
            return jsonify({'message': 'Already scanning'})
        
        scanning_active = True
        scan_thread = Thread(target=auto_scan_bands, daemon=True)
        scan_thread.start()
        
        return jsonify({
            'success': True,
            'message': 'Auto-scan started',
            'interval': scan_interval,
            'bands': ['2.4 GHz', '5.8 GHz']
        })

    @app.route('/api/auto_scan/stop')
    def stop_auto_scan():
        """Stop automatic band scanning"""
        global scanning_active
        scanning_active = False
        
        return jsonify({
            'success': True,
            'message': 'Auto-scan stopped'
        })

    @app.route('/api/auto_scan/status')
    def auto_scan_status():
        """Get auto-scan status"""
        return jsonify({
            'active': scanning_active,
            'current_band': ['2.4 GHz', '5.8 GHz'][current_scan_band],
            'interval': scan_interval
        })

    @app.route('/api/detection_log')
    def detection_log():
        """Return detailed detection information for debugging"""
        try:
            response = requests.get(f'{RTSA_HOST}/sample', timeout=1)
            response.raise_for_status()
            data = response.json()
            
            if 'samples' not in data:
                return jsonify({'error': 'No data'}), 500
            
            detection = analyze_for_drones(data)
            
            result = {
                'frequency_range': {
                    'start': data['startFrequency'],
                    'end': data['endFrequency'],
                    'center': (data['startFrequency'] + data['endFrequency']) / 2
                },
                'detection': detection
            }
            
            if detection.get('detected'):
                result['all_signals'] = detection.get('all_detections', [])
            
            return jsonify(result)
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @app.route('/api/detection_history')
    def get_detection_history():
        """Get recent detection history"""
        return jsonify({
            'total': len(detection_history),
            'detections': detection_history[-20:]
        })

    @app.route('/api/detection_history/clear')
    def clear_detection_history():
        """Clear detection history"""
        global detection_history
        detection_history = []
        return jsonify({'success': True, 'message': 'History cleared'})

    @app.route('/api/detection_history/export')
    def export_detection_history():
        """Export all detection history as downloadable JSON"""
        if not os.path.exists('drone_detections.json'):
            return jsonify({'error': 'No detections recorded yet'}), 404
        
        return send_file('drone_detections.json', 
                         mimetype='application/json',
                         as_attachment=True,
                         download_name=f'drone_detections_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json')
    


    @app.route('/api/camera/init')
    def camera_init():
        """Initialize camera"""
        success = init_camera(0)
        return jsonify({
            'success': success,
            'enabled': get_camera_status()['enabled']
        })

    @app.route('/api/camera/status')
    def camera_status():
        """Get camera status"""
        return jsonify(get_camera_status())

    # ADD THIS ROUTE (it was missing!)
    @app.route('/api/camera/preview')
    def camera_preview():
        """Get current camera frame"""
        from camera import get_camera_frame
        
        frame = get_camera_frame()
        if frame:
            return jsonify({'image': frame})
        else:
            return jsonify({'error': 'No frame available'}), 503

    @app.route('/api/captures/<filename>')
    def get_capture(filename):
        """Serve captured images"""
        return send_from_directory(CAPTURE_FOLDER, filename)
