"""
Extract exact frequency ranges for each drone profile from RTSA API
"""

import requests
import json
import time

RTSA_HOST = 'http://localhost:54664'

# Profile names from config
DRONE_PROFILES = [
    "dji_lightbridge_5800",
    "dji_phantom_1_2_rc_channels_2400",
    "dji_phantom4_pro_rc_channels_2400",
    "jeti_dc_900",
    "jeti_dc_2400",
    "dji_rc_channels_2400",
    "ad223_900mhz",
    "dji_lightbridge_2400",
    "Drones",
    "915mhz_ism_band",
    "1200mhz_videotransmitter",
    "dji_phantom_3_4_rc_channels_2400"
]


def set_profile(profile_name):
    """Set a specific frequency profile"""
    try:
        payload = {
            "request": 1,
            "config": {
                "type": "group",
                "name": "Block_Spectran_V6B_0",
                "items": [{
                    "type": "group",
                    "name": "main",
                    "items": [{
                        "type": "frequencyprofiles",
                        "name": "frequencyprofile",
                        "value": profile_name
                    }]
                }]
            }
        }
        
        response = requests.put(
            f'{RTSA_HOST}/remoteconfig',
            json=payload,
            timeout=3
        )
        
        if response.status_code == 200:
            print(f"  ✅ Set profile: {profile_name}")
            return True
        else:
            print(f"  ❌ Failed to set profile: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False


def get_frequency_range():
    """Get current frequency range after profile is set"""
    try:
        # Wait for profile to apply
        time.sleep(0.5)
        
        response = requests.get(f'{RTSA_HOST}/sample', timeout=2)
        if response.status_code == 200:
            data = response.json()
            return {
                'startFrequency': data.get('startFrequency', 0),
                'endFrequency': data.get('endFrequency', 0),
                'bandwidth': data.get('endFrequency', 0) - data.get('startFrequency', 0)
            }
    except Exception as e:
        print(f"  ⚠️ Error getting frequency: {e}")
        return None


def extract_all_profiles():
    """Extract frequency ranges for all drone profiles"""
    
    print("=" * 70)
    print("DRONE PROFILE FREQUENCY EXTRACTOR")
    print("=" * 70)
    print()
    
    profiles_data = {}
    
    for profile_name in DRONE_PROFILES:
        print(f"📡 Processing: {profile_name}")
        
        if set_profile(profile_name):
            freq_data = get_frequency_range()
            
            if freq_data:
                start_ghz = freq_data['startFrequency'] / 1e9
                end_ghz = freq_data['endFrequency'] / 1e9
                bw_mhz = freq_data['bandwidth'] / 1e6
                
                print(f"  📊 Start: {start_ghz:.3f} GHz")
                print(f"  📊 End:   {end_ghz:.3f} GHz")
                print(f"  📊 BW:    {bw_mhz:.1f} MHz")
                
                profiles_data[profile_name] = {
                    'start_frequency': freq_data['startFrequency'],
                    'end_frequency': freq_data['endFrequency'],
                    'bandwidth': freq_data['bandwidth'],
                    'start_ghz': round(start_ghz, 3),
                    'end_ghz': round(end_ghz, 3),
                    'bandwidth_mhz': round(bw_mhz, 1)
                }
        
        print()
        time.sleep(0.3)  # Small delay between profiles
    
    # Save to JSON
    with open('drone_profiles_ranges.json', 'w') as f:
        json.dump(profiles_data, f, indent=2)
    
    print("=" * 70)
    print("✅ Profile extraction complete!")
    print(f"📁 Saved to: drone_profiles_ranges.json")
    print()
    
    # Generate Python code
    generate_python_profiles(profiles_data)
    
    return profiles_data


def generate_python_profiles(profiles_data):
    """Generate Python dictionary code for detection.py"""
    
    print("=" * 70)
    print("PYTHON CODE FOR detection.py")
    print("=" * 70)
    print()
    print("DRONE_PROFILES = {")
    
    for profile_name, data in profiles_data.items():
        # Create readable name
        readable_name = profile_name.replace('_', ' ').title()
        
        # Determine type
        if 'lightbridge' in profile_name.lower() or 'video' in profile_name.lower():
            signal_type = 'video'
        elif 'rc' in profile_name.lower() or 'channel' in profile_name.lower():
            signal_type = 'control'
        elif 'ism' in profile_name.lower() or 'jeti' in profile_name.lower() or 'ad223' in profile_name.lower():
            signal_type = 'control'
        else:
            signal_type = 'mixed'
        
        # Extract manufacturer
        if 'dji' in profile_name.lower():
            manufacturer = 'DJI'
        elif 'jeti' in profile_name.lower():
            manufacturer = 'JETI'
        else:
            manufacturer = 'Generic'
        
        print(f"    '{profile_name}': {{")
        print(f"        'start': {data['start_frequency']},")
        print(f"        'end': {data['end_frequency']},")
        print(f"        'type': '{signal_type}',")
        print(f"        'bandwidth_range': ({int(data['bandwidth']*0.8)}, {int(data['bandwidth']*1.2)}),  # ±20%")
        print(f"        'manufacturer': '{manufacturer}',")
        print(f"        'description': '{readable_name}',")
        print(f"        'confidence_boost': 30,")
        print(f"        'power_range': (-80, -25)")
        print(f"    }},")
        print()
    
    print("}")
    print()
    print("=" * 70)


if __name__ == '__main__':
    extract_all_profiles()
