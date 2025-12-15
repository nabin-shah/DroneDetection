# from flask import Flask, render_template, jsonify
from flask import Flask, render_template, jsonify, request  # Add request here

import requests
from datetime import datetime
from collections import deque
# Add this after your existing imports
import time
# Add at the top with other imports
from threading import Thread

#imports for camera function 
import cv2
import base64
from io import BytesIO
from PIL import Image



from datetime import datetime
import json
import os

# Detection history storage
detection_history = []
MAX_HISTORY = 100  # Keep last 100 detections

def log_detection(detection_data, spectrum_data):
    """
    Log a drone detection event with timestamp
    """
    if not detection_data.get('detected'):
        return
    
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'unix_time': time.time(),
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
    
    # Keep only recent detections
    if len(detection_history) > MAX_HISTORY:
        detection_history.pop(0)
    
    # Also save to file for permanent record
    log_file = 'drone_detections.json'
    try:
        # Read existing logs
        if os.path.exists(log_file):
            with open(log_file, 'r') as f:
                all_logs = json.load(f)
        else:
            all_logs = []
        
        all_logs.append(log_entry)
        
        # Write back
        with open(log_file, 'w') as f:
            json.dump(all_logs, f, indent=2)
            
    except Exception as e:
        print(f"Error saving detection log: {e}")





app = Flask(__name__)

# RTSA HTTP Server configuration
RTSA_HOST = 'http://localhost:54664'

# Detection parameters
NOISE_FLOOR = -100  # dBm
DETECTION_THRESHOLD = -75  # dBm - signal above noise
MIN_SIGNAL_WIDTH = 5  # Minimum bins
BURST_DETECTION_WINDOW = 10  # Store last 10 measurements

# Store recent power measurements to detect burst patterns
signal_history = {}  # frequency -> deque of power measurements

# Drone frequency bands (in Hz)
DRONE_BANDS = {
    '2.4GHz_control': {'start': 2.400e9, 'end': 2.483e9, 'type': 'control'},
    '5.8GHz_video': {'start': 5.725e9, 'end': 5.875e9, 'type': 'video'},
    '900MHz': {'start': 902e6, 'end': 928e6, 'type': 'control'},
    '433MHz': {'start': 433e6, 'end': 434e6, 'type': 'control'}
}

def is_in_drone_band(frequency):
    """Check if frequency is in known drone bands"""
    for band_name, band_info in DRONE_BANDS.items():
        if band_info['start'] <= frequency <= band_info['end']:
            return True, band_name, band_info['type']
    return False, None, None

def detect_burst_pattern(freq_key, current_power, history_window=10):
    """
    Detect burst patterns characteristic of drone signals
    Drones show intermittent bursts, not continuous signals
    """
    if freq_key not in signal_history:
        signal_history[freq_key] = deque(maxlen=history_window)
    
    signal_history[freq_key].append(current_power)
    
    if len(signal_history[freq_key]) < 5:
        return False, 0
    
    powers = list(signal_history[freq_key])
    
    # Calculate statistics
    avg_power = sum(powers) / len(powers)
    max_power = max(powers)
    min_power = min(powers)
    power_variation = max_power - min_power
    
    # Detect burst characteristics:
    # 1. High variation (bursts vs silence)
    # 2. Current power significantly above average (active burst)
    # 3. Variation above threshold (not continuous carrier)
    
    has_variation = power_variation > 15  # dB variation indicates bursting
    is_burst_active = current_power > (avg_power + 10)  # Currently in burst
    not_continuous = power_variation > 5  # Not a continuous carrier
    
    # Calculate burst confidence (0-100)
    confidence = 0
    if has_variation:
        confidence += 40
    if is_burst_active:
        confidence += 30
    if not_continuous:
        confidence += 30
    
    is_burst = has_variation and not_continuous
    
    return is_burst, confidence

def calculate_bandwidth(samples, start_freq, end_freq, threshold):
    """
    Calculate actual occupied bandwidth of signal
    Drone control signals are typically 20-80 MHz wide
    """
    freq_step = (end_freq - start_freq) / len(samples)
    
    # Find continuous regions above threshold
    bandwidths = []
    current_bw = 0
    
    for power in samples:
        if power > threshold:
            current_bw += freq_step
        else:
            if current_bw > 0:
                bandwidths.append(current_bw)
            current_bw = 0
    
    if current_bw > 0:
        bandwidths.append(current_bw)
    
    return bandwidths

def analyze_for_drones(spectrum_data):
    """
    Advanced drone detection using signal characteristics
    """
    if 'samples' not in spectrum_data or not spectrum_data['samples']:
        return {'detected': False, 'reason': 'No data'}
    
    samples = spectrum_data['samples'][0]
    start_freq = spectrum_data['startFrequency']
    end_freq = spectrum_data['endFrequency']
    sample_size = spectrum_data['sampleSize']
    
    freq_step = (end_freq - start_freq) / sample_size
    
    detections = []
    consecutive_count = 0
    peak_power = NOISE_FLOOR
    peak_frequency = 0
    start_idx = 0
    
    # Scan through samples
    for idx, power in enumerate(samples):
        current_freq = start_freq + (idx * freq_step)
        
        if power > DETECTION_THRESHOLD:
            if consecutive_count == 0:
                start_idx = idx
            consecutive_count += 1
            
            if power > peak_power:
                peak_power = power
                peak_frequency = current_freq
        else:
            if consecutive_count >= MIN_SIGNAL_WIDTH:
                center_freq = start_freq + ((start_idx + idx) / 2 * freq_step)
                signal_bandwidth = consecutive_count * freq_step
                
                # Check if in drone band
                in_drone_band, band_name, band_type = is_in_drone_band(center_freq)
                
                # Detect burst pattern
                freq_key = f"{int(center_freq/1e6)}"
                is_burst, burst_confidence = detect_burst_pattern(freq_key, peak_power)
                
                # Calculate signal characteristics
                characteristics = {
                    'frequency': center_freq,
                    'power': peak_power,
                    'bandwidth': signal_bandwidth,
                    'in_drone_band': in_drone_band,
                    'band_name': band_name if in_drone_band else 'Unknown',
                    'band_type': band_type if in_drone_band else 'Unknown',
                    'is_burst': is_burst,
                    'burst_confidence': burst_confidence
                }
                
                # Scoring system for drone likelihood
                drone_score = 0
                reasons = []
                
                # 1. In known drone band (50 points)
                if in_drone_band:
                    drone_score += 50
                    reasons.append(f"In {band_name} drone band")
                
                # 2. Burst pattern detected (30 points)
                if is_burst:
                    drone_score += 30
                    reasons.append(f"Burst pattern detected ({burst_confidence}% confidence)")
                
                # 3. Appropriate bandwidth (20 points)
                bw_mhz = signal_bandwidth / 1e6
                if band_type == 'video' and 5 <= bw_mhz <= 30:
                    drone_score += 20
                    reasons.append(f"Video signal bandwidth ({bw_mhz:.1f} MHz)")
                elif band_type == 'control' and 20 <= bw_mhz <= 90:
                    drone_score += 20
                    reasons.append(f"Control signal bandwidth ({bw_mhz:.1f} MHz)")
                
                characteristics['drone_score'] = drone_score
                characteristics['detection_reasons'] = reasons
                
                # Only add if score is high enough (threshold: 50+)
                if drone_score >= 70:
                    detections.append(characteristics)
            
            consecutive_count = 0
            peak_power = NOISE_FLOOR
    
    # Check last signal
    if consecutive_count >= MIN_SIGNAL_WIDTH:
        center_freq = start_freq + ((start_idx + len(samples)) / 2 * freq_step)
        signal_bandwidth = consecutive_count * freq_step
        
        in_drone_band, band_name, band_type = is_in_drone_band(center_freq)
        freq_key = f"{int(center_freq/1e6)}"
        is_burst, burst_confidence = detect_burst_pattern(freq_key, peak_power)
        
        characteristics = {
            'frequency': center_freq,
            'power': peak_power,
            'bandwidth': signal_bandwidth,
            'in_drone_band': in_drone_band,
            'band_name': band_name if in_drone_band else 'Unknown',
            'band_type': band_type if in_drone_band else 'Unknown',
            'is_burst': is_burst,
            'burst_confidence': burst_confidence
        }
        
        drone_score = 0
        reasons = []
        
        if in_drone_band:
            drone_score += 50
            reasons.append(f"In {band_name} drone band")
        
        if is_burst:
            drone_score += 30
            reasons.append(f"Burst pattern detected ({burst_confidence}% confidence)")
        
        bw_mhz = signal_bandwidth / 1e6
        if band_type == 'video' and 5 <= bw_mhz <= 30:
            drone_score += 20
            reasons.append(f"Video signal bandwidth ({bw_mhz:.1f} MHz)")
        elif band_type == 'control' and 20 <= bw_mhz <= 90:
            drone_score += 20
            reasons.append(f"Control signal bandwidth ({bw_mhz:.1f} MHz)")
        
        characteristics['drone_score'] = drone_score
        characteristics['detection_reasons'] = reasons
        
        if drone_score >= 70:
            detections.append(characteristics)
    
    if detections:
        strongest = max(detections, key=lambda x: x['drone_score'])
        return {
            'detected': True,
            'count': len(detections),
            'strongest': strongest,
            'all_detections': detections,
            'confidence': strongest['drone_score']
        }
    
    return {'detected': False, 'reason': 'No drone-like signals found'}

@app.route('/')
def dashboard():
    return render_template('dashboard.html')

@app.route('/api/spectrum')
def get_spectrum():
    try:
        response = requests.get(f'{RTSA_HOST}/sample', timeout=1)
        response.raise_for_status()
        data = response.json()
        
        if 'samples' not in data:
            return jsonify({'error': 'Invalid data received'}), 500
        
        detection_result = analyze_for_drones(data)
        data['detection'] = detection_result

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
    try:
        response = requests.get(f'{RTSA_HOST}/info', timeout=1)
        response.raise_for_status()
        if response.status_code == 200:
            return jsonify({'status': 'connected', 'info': response.json()})
        else:
            return jsonify({'status': 'error'}), 500
    except:
        return jsonify({'status': 'disconnected'}), 503




# Add these new routes BEFORE the if __name__ == '__main__':

@app.route('/api/set_frequency', methods=['POST'])
def set_frequency():
    """
    Change SPECTRAN V6 frequency settings via API
    Expects JSON: {"start": freq_hz, "end": freq_hz} or {"center": freq_hz, "span": span_hz}
    """
    try:
        data = request.get_json()
        
        # Build control command
        control_cmd = {"type": "capture"}
        
        if 'start' in data and 'end' in data:
            control_cmd['frequencyStart'] = float(data['start'])
            control_cmd['frequencyEnd'] = float(data['end'])
        elif 'center' in data and 'span' in data:
            control_cmd['frequencyCenter'] = float(data['center'])
            control_cmd['frequencySpan'] = float(data['span'])
        else:
            return jsonify({'error': 'Need either start/end or center/span'}), 400
        
        # Send command to RTSA
        response = requests.put(
            f'{RTSA_HOST}/control',
            json=control_cmd,
            timeout=2
        )
        
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
    """
    Quick switch to predefined drone frequency bands
    """
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
        
        response = requests.put(
            f'{RTSA_HOST}/control',
            json=control_cmd,
            timeout=2
        )
        
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





@app.route('/api/detection_history')
def get_detection_history():
    """
    Get recent detection history
    """
    return jsonify({
        'total': len(detection_history),
        'detections': detection_history[-20:]  # Last 20 detections
    })

@app.route('/api/detection_history/clear')
def clear_detection_history():
    """
    Clear detection history
    """
    global detection_history
    detection_history = []
    return jsonify({'success': True, 'message': 'History cleared'})

@app.route('/api/detection_history/export')
def export_detection_history():
    """
    Export all detection history as downloadable JSON
    """
    from flask import send_file
    
    if not os.path.exists('drone_detections.json'):
        return jsonify({'error': 'No detections recorded yet'}), 404
    
    return send_file('drone_detections.json', 
                     mimetype='application/json',
                     as_attachment=True,
                     download_name=f'drone_detections_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json')




# Scanning configuration
scanning_active = False
current_scan_band = 0
scan_interval = 5  # seconds per band

def auto_scan_bands():
    """
    Automatically rotate through drone frequency bands
    """
    global scanning_active, current_scan_band
    
    bands = ['2.4ghz', '5.8ghz']  # Primary drone bands
    
    while scanning_active:
        band = bands[current_scan_band]
        
        try:
            # Switch to next band
            control_cmd = {
                'frequencyStart': 2.400e9 if band == '2.4ghz' else 5.725e9,
                'frequencyEnd': 2.483e9 if band == '2.4ghz' else 5.875e9,
                'type': 'capture'
            }
            
            requests.put(f'{RTSA_HOST}/control', json=control_cmd, timeout=2)
            print(f"[Auto-Scan] Switched to {band}")
            
            # Move to next band
            current_scan_band = (current_scan_band + 1) % len(bands)
            
        except Exception as e:
            print(f"[Auto-Scan] Error: {e}")
        
        # Wait before next switch
        time.sleep(scan_interval)

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
    """
    Return detailed detection information for debugging
    """
    try:
        response = requests.get(f'{RTSA_HOST}/sample', timeout=1)
        response.raise_for_status()
        data = response.json()
        
        if 'samples' not in data:
            return jsonify({'error': 'No data'}), 500
        
        detection = analyze_for_drones(data)
        
        # Add raw spectrum info
        result = {
            'frequency_range': {
                'start': data['startFrequency'],
                'end': data['endFrequency'],
                'center': (data['startFrequency'] + data['endFrequency']) / 2
            },
            'detection': detection
        }
        
        # If detected, show all signals found
        if detection.get('detected'):
            result['all_signals'] = detection.get('all_detections', [])
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500











if __name__ == '__main__':
    app.run(debug=True, port=5000)


