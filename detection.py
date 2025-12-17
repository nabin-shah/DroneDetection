"""
Enhanced Drone Detection Algorithm
Based on Aaronia RTSA Suite PRO Drone Profiles + Industry Standards
"""

from collections import deque
import time

# Detection parameters
NOISE_FLOOR = -100  # dBm
DETECTION_THRESHOLD = -70  # dBm (adjust based on testing)
MIN_SIGNAL_WIDTH = 10
BURST_DETECTION_WINDOW = 10

# Store recent power measurements to detect burst patterns
signal_history = {}

# PROFESSIONAL DRONE FREQUENCY PROFILES
# Based on Aaronia RTSA Suite PRO profiles + industry standards
DRONE_PROFILES = {
    # ===== VIDEO TRANSMISSION SYSTEMS =====
    'dji_lightbridge_5800': {
        'start': 5.720e9,
        'end': 5.880e9,
        'type': 'video',
        'bandwidth_range': (20e6, 80e6),  # DJI Lightbridge uses 20-40 MHz channels
        'manufacturer': 'DJI',
        'description': 'DJI Lightbridge 5.8GHz HD Video',
        'confidence_boost': 35,
        'power_range': (-75, -30)
    },
    
    'dji_lightbridge_2400': {
        'start': 2.280e9,
        'end': 2.600e9,
        'type': 'video',
        'bandwidth_range': (20e6, 80e6),
        'manufacturer': 'DJI',
        'description': 'DJI Lightbridge 2.4GHz Video',
        'confidence_boost': 30,
        'power_range': (-75, -30)
    },
    
    '1200mhz_videotransmitter': {
        'start': 990e6,
        'end': 1.300e9,
        'type': 'video',
        'bandwidth_range': (5e6, 30e6),  # Analog FPV typically 5-20 MHz
        'manufacturer': 'Generic',
        'description': '1.2GHz Analog FPV Video',
        'confidence_boost': 25,
        'power_range': (-80, -35)
    },
    
    # ===== DJI CONTROL SYSTEMS (2.4 GHz) =====
    'dji_phantom_1_2_rc_channels_2400': {
        'start': 2.400e9,
        'end': 2.483e9,
        'type': 'control',
        'bandwidth_range': (15e6, 80e6),  # WiFi-based, wider bandwidth
        'manufacturer': 'DJI',
        'description': 'DJI Phantom 1 & 2 RC Control',
        'confidence_boost': 35,
        'power_range': (-70, -25)
    },
    
    'dji_phantom_3_4_rc_channels_2400': {
        'start': 2.400e9,
        'end': 2.483e9,
        'type': 'control',
        'bandwidth_range': (20e6, 80e6),
        'manufacturer': 'DJI',
        'description': 'DJI Phantom 3 & 4 RC Control',
        'confidence_boost': 35,
        'power_range': (-70, -25)
    },
    
    'dji_phantom4_pro_rc_channels_2400': {
        'start': 2.400e9,
        'end': 2.483e9,
        'type': 'control',
        'bandwidth_range': (20e6, 80e6),
        'manufacturer': 'DJI',
        'description': 'DJI Phantom 4 PRO RC Control',
        'confidence_boost': 35,
        'power_range': (-70, -25)
    },
    
    'dji_rc_channels_2400': {
        'start': 2.400e9,
        'end': 2.483e9,
        'type': 'control',
        'bandwidth_range': (20e6, 80e6),
        'manufacturer': 'DJI',
        'description': 'DJI Generic RC Channels (2.4GHz)',
        'confidence_boost': 30,
        'power_range': (-70, -25)
    },
    
    # ===== JETI CONTROL SYSTEMS =====
    'jeti_dc_2400': {
        'start': 2.400e9,
        'end': 2.483e9,
        'type': 'control',
        'bandwidth_range': (1e6, 20e6),  # Narrow band RC
        'manufacturer': 'JETI',
        'description': 'JETI DC-24 Dual Band (2.4GHz)',
        'confidence_boost': 30,
        'power_range': (-75, -30)
    },
    
    'jeti_dc_900': {
        'start': 863.7e6,
        'end': 869.0e6,
        'type': 'control',
        'bandwidth_range': (200e3, 5e6),  # Very narrow band
        'manufacturer': 'JETI',
        'description': 'JETI DC-24 Dual Band (868MHz EU)',
        'confidence_boost': 35,
        'power_range': (-80, -35)
    },
    
    # ===== ISM BANDS =====
    '915mhz_ism_band': {
        'start': 902e6,
        'end': 928e6,
        'type': 'control',
        'bandwidth_range': (500e3, 15e6),
        'manufacturer': 'Generic',
        'description': '915MHz ISM Band RC Control (US)',
        'confidence_boost': 30,
        'power_range': (-80, -30)
    },
    
    'ad223_900mhz': {
        'start': 893e6,
        'end': 1.020e9,
        'type': 'control',
        'bandwidth_range': (1e6, 20e6),
        'manufacturer': 'Generic',
        'description': 'AD223 900MHz Long Range RC',
        'confidence_boost': 25,
        'power_range': (-85, -35)
    },
    
    # ===== COMBINED PROFILE =====
    'Drones': {
        'start': 2.400e9,
        'end': 5.880e9,
        'type': 'mixed',
        'bandwidth_range': (1e6, 80e6),
        'manufacturer': 'Generic',
        'description': 'All Drone Frequencies (Wide Scan)',
        'confidence_boost': 20,
        'power_range': (-85, -25)
    }
}


def match_drone_profile(frequency, bandwidth, power):
    """
    Match signal characteristics against known drone profiles
    Returns: (matched, profile_name, profile_data, confidence)
    """
    best_match = None
    best_confidence = 0
    
    for profile_name, profile in DRONE_PROFILES.items():
        # Check if frequency is in range
        if not (profile['start'] <= frequency <= profile['end']):
            continue
        
        confidence = 0
        
        # Frequency match (base score)
        confidence += 30
        
        # Bandwidth match
        bw_min, bw_max = profile['bandwidth_range']
        if bw_min <= bandwidth <= bw_max:
            confidence += 30
        elif bw_min * 0.5 <= bandwidth <= bw_max * 2:
            # Close but not perfect
            confidence += 15
        
        # Power level match
        pwr_min, pwr_max = profile['power_range']
        if pwr_min <= power <= pwr_max:
            confidence += 20
        elif power > pwr_max:  # Too strong (nearby drone)
            confidence += 25
        
        # Apply profile-specific confidence boost
        confidence += profile['confidence_boost']
        
        if confidence > best_confidence:
            best_confidence = confidence
            best_match = (True, profile_name, profile, confidence)
    
    if best_match:
        return best_match
    
    return (False, None, None, 0)


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
    
    # Detect characteristics
    has_variation = power_variation > 15  # Power changes (moving drone)
    is_burst_active = current_power > (avg_power + 10)
    not_continuous = power_variation > 5  # Not constant signal
    
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
    """
    Enhanced drone detection using professional profiles from Aaronia RTSA Suite PRO
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
    
    # Scan through spectrum
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
                # Signal detected - analyze it
                center_freq = start_freq + ((start_idx + idx) / 2 * freq_step)
                signal_bandwidth = consecutive_count * freq_step
                
                # Match against professional drone profiles
                matched, profile_name, profile_data, profile_confidence = match_drone_profile(
                    center_freq, signal_bandwidth, peak_power
                )
                
                # Burst pattern detection
                freq_key = f"{int(center_freq/1e6)}"
                is_burst, burst_confidence = detect_burst_pattern(freq_key, peak_power)
                
                # Build detection characteristics
                characteristics = {
                    'frequency': center_freq,
                    'power': peak_power,
                    'bandwidth': signal_bandwidth,
                    'matched_profile': matched,
                    'profile_name': profile_name if matched else 'Unknown',
                    'profile_description': profile_data['description'] if matched else 'Unknown signal',
                    'manufacturer': profile_data['manufacturer'] if matched else 'Unknown',
                    'signal_type': profile_data['type'] if matched else 'unknown',
                    'is_burst': is_burst,
                    'burst_confidence': burst_confidence
                }
                
                # Calculate confidence score
                drone_score = 0
                reasons = []
                
                if matched:
                    drone_score += profile_confidence
                    reasons.append(f"Matches {profile_name}")
                    reasons.append(f"Manufacturer: {profile_data['manufacturer']}")
                    reasons.append(f"Type: {profile_data['type'].upper()}")
                
                if is_burst:
                    drone_score += 20
                    reasons.append(f"Burst pattern detected")
                
                # Bandwidth validation
                bw_mhz = signal_bandwidth / 1e6
                if matched and profile_data:
                    bw_min, bw_max = profile_data['bandwidth_range']
                    if bw_min/1e6 <= bw_mhz <= bw_max/1e6:
                        drone_score += 20
                        reasons.append(f"Bandwidth: {bw_mhz:.1f} MHz")
                
                characteristics['drone_score'] = min(drone_score, 100)  # Cap at 100%
                characteristics['detection_reasons'] = reasons
                
                # Threshold: 50% confidence
                if drone_score >= 50:
                    detections.append(characteristics)
            
            consecutive_count = 0
            peak_power = NOISE_FLOOR
    
    # Check last signal
    if consecutive_count >= MIN_SIGNAL_WIDTH:
        center_freq = start_freq + ((start_idx + len(samples)) / 2 * freq_step)
        signal_bandwidth = consecutive_count * freq_step
        
        matched, profile_name, profile_data, profile_confidence = match_drone_profile(
            center_freq, signal_bandwidth, peak_power
        )
        
        freq_key = f"{int(center_freq/1e6)}"
        is_burst, burst_confidence = detect_burst_pattern(freq_key, peak_power)
        
        characteristics = {
            'frequency': center_freq,
            'power': peak_power,
            'bandwidth': signal_bandwidth,
            'matched_profile': matched,
            'profile_name': profile_name if matched else 'Unknown',
            'profile_description': profile_data['description'] if matched else 'Unknown signal',
            'manufacturer': profile_data['manufacturer'] if matched else 'Unknown',
            'signal_type': profile_data['type'] if matched else 'unknown',
            'is_burst': is_burst,
            'burst_confidence': burst_confidence
        }
        
        drone_score = 0
        reasons = []
        
        if matched:
            drone_score += profile_confidence
            reasons.append(f"Matches {profile_name}")
            reasons.append(f"Manufacturer: {profile_data['manufacturer']}")
        
        if is_burst:
            drone_score += 20
            reasons.append(f"Burst pattern")
        
        characteristics['drone_score'] = min(drone_score, 100)
        characteristics['detection_reasons'] = reasons
        
        if drone_score >= 50:
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
