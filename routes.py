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

from radar_sync import radar_sync # Imports the global instance from our new file

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
    #########################################################

    #########################################################
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
    



    # ==========================================
    # MANUAL CAMERA CAPTURE ROUTES (NEW)
    # ==========================================
    
    @app.route('/api/camera/manual_capture', methods=['POST'])
    def manual_capture():
        """Save manual camera capture from browser"""
        import base64
        
        try:
            data = request.get_json()
            image_data = data.get('image')
            
            if not image_data:
                return jsonify({'error': 'No image data'}), 400
            
            # Remove data:image/jpeg;base64, prefix
            if 'base64,' in image_data:
                image_data = image_data.split('base64,')[1]
            
            # Decode base64
            image_bytes = base64.b64decode(image_data)
            
            # Generate filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"manual_{timestamp}.jpg"
            
            # Use same folder as detection captures
            if not os.path.exists(CAPTURE_FOLDER):
                os.makedirs(CAPTURE_FOLDER)
            
            filepath = os.path.join(CAPTURE_FOLDER, filename)
            
            # Save image
            with open(filepath, 'wb') as f:
                f.write(image_bytes)
            
            print(f"✅ [Manual Capture] Saved: {filename}")
            
            return jsonify({
                'success': True,
                'filename': filename,
                'timestamp': timestamp
            })
            
        except Exception as e:
            print(f"❌ [Manual Capture] Error: {e}")
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/captures_list')
    def captures_list():
        """List all captured images (manual + detections)"""
        
        if not os.path.exists(CAPTURE_FOLDER):
            return jsonify({'captures': []})
        
        captures = []
        
        try:
            for filename in os.listdir(CAPTURE_FOLDER):
                if filename.endswith('.jpg'):
                    filepath = os.path.join(CAPTURE_FOLDER, filename)
                    timestamp = os.path.getmtime(filepath)
                    time_str = datetime.fromtimestamp(timestamp).strftime("%H:%M:%S")
                    
                    # Determine type based on filename
                    if filename.startswith("manual_"):
                        capture_type = "📸 Manual"
                    else:
                        capture_type = "🚁 Detection"
                    
                    captures.append({
                        'filename': filename,
                        'time': time_str,
                        'type': capture_type,
                        'timestamp': timestamp
                    })
            
            # Sort by timestamp (newest first)
            captures.sort(key=lambda x: x['timestamp'], reverse=True)
            
            return jsonify({'captures': captures[:20]})  # Last 20
            
        except Exception as e:
            print(f"Error listing captures: {e}")
            return jsonify({'captures': []})







    @app.route('/camera_test')
    def camera_test_page():
            """Serve the proven working camera test page"""
            return '''
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Camera Test</title>
            <style>
                body {font-family: Arial; background: #1a1a2e; color: white; padding: 30px; text-align: center;}
                h1 { color: #00ff00; margin-bottom: 30px; }
                #videoBox {width: 640px; height: 480px; margin: 20px auto; border: 4px solid #00ff00; background: #000; position: relative;}
                video { width: 100%; height: 100%; object-fit: contain; }
                #status {font-size: 24px; font-weight: bold; margin: 20px; padding: 15px; background: rgba(255,255,255,0.1); border-radius: 10px; display: inline-block;}
                button {padding: 15px 30px; font-size: 18px; margin: 10px; border: none; border-radius: 10px; cursor: pointer; font-weight: bold;}
                .btn-green { background: #00ff00; color: #000; }
                .btn-red { background: #ff4444; color: white; }
                .btn-blue { background: #00aaff; color: white; }
            </style>
        </head>
        <body>
            <h1>🎥 Camera Test on Port 5000</h1>
            <div id="status">Status: Not Started</div>
            <div id="videoBox"><video id="myVideo" autoplay playsinline muted></video></div>
            <button class="btn-green" onclick="startCam()">▶ Start</button>
            <button class="btn-red" onclick="stopCam()">⏹ Stop</button>
            <button class="btn-blue" onclick="takePhoto()">📸 Photo</button>
            <br><br>
            <a href="/" style="color: #00ff00; text-decoration: none; font-size: 18px;">← Back to Dashboard</a>
            
            <script>
                let myStream = null;
                
                function startCam() {
                    console.log('Starting camera...');
                    document.getElementById('status').textContent = 'Requesting access...';
                    
                    navigator.mediaDevices.getUserMedia({ video: true })
                        .then(function(stream) {
                            myStream = stream;
                            document.getElementById('myVideo').srcObject = stream;
                            document.getElementById('status').textContent = '✅ CAMERA ACTIVE';
                            document.getElementById('status').style.color = '#00ff00';
                            console.log('Camera started!');
                        })
                        .catch(function(error) {
                            document.getElementById('status').textContent = '❌ ACCESS DENIED';
                            document.getElementById('status').style.color = '#ff4444';
                            console.error('Camera error:', error);
                            alert('Camera denied! Error: ' + error.message);
                        });
                }
                
                function stopCam() {
                    if (myStream) {
                        myStream.getTracks().forEach(function(track) { track.stop(); });
                        myStream = null;
                    }
                    document.getElementById('myVideo').srcObject = null;
                    document.getElementById('status').textContent = 'Camera Stopped';
                    document.getElementById('status').style.color = '#888';
                }
                
                function takePhoto() {
                    if (!myStream) { alert('Start camera first!'); return; }
                    var video = document.getElementById('myVideo');
                    var canvas = document.createElement('canvas');
                    canvas.width = video.videoWidth;
                    canvas.height = video.videoHeight;
                    canvas.getContext('2d').drawImage(video, 0, 0);
                    var link = document.createElement('a');
                    link.download = 'capture.jpg';
                    link.href = canvas.toDataURL('image/jpeg');
                    link.click();
                }
            </script>
        </body>
        </html>
                '''






    @app.route('/api/captures/<filename>')
    def get_capture(filename):
        """Serve captured images"""
        return send_from_directory(CAPTURE_FOLDER, filename)


    # ==========================================
    # FREQUENCY SCANNER ROUTES
    # ==========================================
    
    @app.route('/api/scanner/start', methods=['POST'])
    def scanner_start():
        """Start automatic frequency scanning"""
        from frequency_scanner import scanner
        
        success = scanner.start()
        return jsonify({
            'success': success,
            'message': 'Scanner started' if success else 'Scanner already running'
        })
    
    @app.route('/api/scanner/stop', methods=['POST'])
    def scanner_stop():
        """Stop automatic frequency scanning"""
        from frequency_scanner import scanner
        
        success = scanner.stop()
        return jsonify({
            'success': success,
            'message': 'Scanner stopped' if success else 'Scanner not running'
        })
    
    @app.route('/api/scanner/status')
    def scanner_status():
        """Get scanner status"""
        from frequency_scanner import scanner
        
        status = scanner.get_status()
        return jsonify(status)
    
    @app.route('/api/scanner/bands')
    def scanner_bands():
        """Get list of frequency bands"""
        from frequency_scanner import scanner
        
        bands = scanner.get_bands()
        return jsonify({'bands': bands})
    
    @app.route('/api/scanner/set_band/<int:band_index>', methods=['POST'])
    def scanner_set_band(band_index):
        """Manually set to specific band"""
        from frequency_scanner import scanner
        
        success = scanner.set_band(band_index)
        return jsonify({
            'success': success,
            'band_index': band_index
        })
    
    @app.route('/api/scanner/set_dwell/<int:seconds>', methods=['POST'])
    def scanner_set_dwell(seconds):
        """Set dwell time per band"""
        from frequency_scanner import scanner
        
        success = scanner.set_dwell_time(seconds)
        return jsonify({
            'success': success,
            'dwell_time': seconds
        })
    
    # ==========================================
    # SYNCHRONIZED RADAR CONTROLS
    # ==========================================
    
    @app.route('/api/radar/start', methods=['POST'])
    def radar_start():
        """Start the synchronized Antenna + RTSA sweep"""
        if not radar_sync.arduino:
            return jsonify({'success': False, 'message': 'Arduino not connected!'}), 503
            
        radar_sync.start()
        return jsonify({'success': True, 'message': 'Synchronized radar started'})

    @app.route('/api/radar/stop', methods=['POST'])
    def radar_stop():
        """Stop the synchronized sweep"""
        radar_sync.stop()
        return jsonify({'success': True, 'message': 'Synchronized radar stopped'})

    @app.route('/api/radar/status')
    def radar_status():
        """Get the current status of the synchronized sweep"""
        return jsonify({
            'is_scanning': radar_sync.is_scanning,
            'arduino_connected': radar_sync.arduino is not None,
            'current_angle': radar_sync.current_angle
        })