"""
Drone detection algorithm
"""
from collections import deque
import time

# Detection parameters
NOISE_FLOOR = -100  # dBm
DETECTION_THRESHOLD = -70  # dBm
MIN_SIGNAL_WIDTH = 10
BURST_DETECTION_WINDOW = 10

# Store recent power measurements to detect burst patterns
signal_history = {}

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
    """Detect burst patterns characteristic of drone signals"""
    if freq_key not in signal_history:
        signal_history[freq_key] = deque(maxlen=history_window)
    
    signal_history[freq_key].append(current_power)
    
    if len(signal_history[freq_key]) < 5:
        return False, 0
    
    powers = list(signal_history[freq_key])
    avg_power = sum(powers) / len(powers)
    max_power = max(powers)
    min_power = min(powers)
    power_variation = max_power - min_power
    
    has_variation = power_variation > 15
    is_burst_active = current_power > (avg_power + 10)
    not_continuous = power_variation > 5
    
    confidence = 0
    if has_variation:
        confidence += 40
    if is_burst_active:
        confidence += 30
    if not_continuous:
        confidence += 30
    
    is_burst = has_variation and not_continuous
    return is_burst, confidence

def analyze_for_drones(spectrum_data):
    """Advanced drone detection using signal characteristics"""
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
