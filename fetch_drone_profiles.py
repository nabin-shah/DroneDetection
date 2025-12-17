"""
Fetch real drone profiles from Aaronia RTSA Suite PRO
"""

import requests
import json

RTSA_HOST = 'http://localhost:54664'

def fetch_server_info():
    """Check if RTSA server is running"""
    try:
        response = requests.get(f'{RTSA_HOST}/info', timeout=2)
        if response.status_code == 200:
            print("✅ RTSA Server Connected!")
            print(json.dumps(response.json(), indent=2))
            return True
        return False
    except Exception as e:
        print(f"❌ Cannot connect to RTSA server: {e}")
        print("\n⚠️ Make sure:")
        print("   1. Aaronia RTSA Suite PRO is running")
        print("   2. HTTP Server block is active (port 54664)")
        return False


def fetch_remote_config():
    """Fetch all configuration including profiles"""
    try:
        response = requests.get(f'{RTSA_HOST}/remoteconfig', timeout=5)
        if response.status_code == 200:
            config = response.json()
            
            # Save full config for inspection
            with open('rtsa_full_config.json', 'w') as f:
                json.dump(config, f, indent=2)
            
            print("✅ Full config saved to: rtsa_full_config.json")
            return config
        else:
            print(f"❌ Error fetching config: {response.status_code}")
            return None
    except Exception as e:
        print(f"❌ Error: {e}")
        return None


def find_profile_data(config):
    """Search for frequency profile data in config"""
    print("\n🔍 Searching for profile configurations...\n")
    
    def search_recursive(obj, path=""):
        """Recursively search for profile-related settings"""
        if isinstance(obj, dict):
            # Look for profile-related keys
            for key, value in obj.items():
                current_path = f"{path}.{key}" if path else key
                
                # Check if this looks like profile data
                if any(keyword in key.lower() for keyword in ['profile', 'frequency', 'preset', 'drone']):
                    print(f"📍 Found: {current_path}")
                    print(f"   Value: {value if not isinstance(value, dict) else '...'}")
                    print()
                
                # Recurse into nested structures
                if isinstance(value, (dict, list)):
                    search_recursive(value, current_path)
        
        elif isinstance(obj, list):
            for idx, item in enumerate(obj):
                search_recursive(item, f"{path}[{idx}]")
    
    search_recursive(config)


def get_current_frequency_settings():
    """Get current frequency range settings"""
    try:
        response = requests.get(f'{RTSA_HOST}/sample', timeout=2)
        if response.status_code == 200:
            data = response.json()
            
            print("\n📡 Current Frequency Settings:")
            print(f"   Start: {data.get('startFrequency', 0) / 1e9:.3f} GHz")
            print(f"   End:   {data.get('endFrequency', 0) / 1e9:.3f} GHz")
            print(f"   Span:  {(data.get('endFrequency', 0) - data.get('startFrequency', 0)) / 1e6:.1f} MHz")
            
            return data
    except Exception as e:
        print(f"❌ Error getting frequency settings: {e}")
        return None


def test_profile_switching():
    """Test if we can switch between profiles via API"""
    print("\n🧪 Testing profile switching capability...\n")
    
    # Try to set a known drone frequency range
    test_configs = [
        {
            'name': 'DJI 2.4GHz Test',
            'frequencyStart': 2.400e9,
            'frequencyEnd': 2.483e9,
            'type': 'capture'
        },
        {
            'name': 'DJI 5.8GHz Test', 
            'frequencyStart': 5.720e9,
            'frequencyEnd': 5.880e9,
            'type': 'capture'
        }
    ]
    
    for config in test_configs:
        try:
            print(f"Testing: {config['name']}")
            
            response = requests.put(
                f'{RTSA_HOST}/control',
                json=config,
                timeout=2
            )
            
            if response.status_code == 200:
                print(f"   ✅ Successfully set {config['name']}")
            else:
                print(f"   ⚠️ Response: {response.status_code}")
        except Exception as e:
            print(f"   ❌ Error: {e}")


def main():
    print("=" * 60)
    print("AARONIA RTSA DRONE PROFILE EXTRACTOR")
    print("=" * 60)
    
    # Step 1: Check connection
    if not fetch_server_info():
        return
    
    print("\n" + "=" * 60)
    
    # Step 2: Get current settings
    get_current_frequency_settings()
    
    print("\n" + "=" * 60)
    
    # Step 3: Fetch full config
    config = fetch_remote_config()
    
    if config:
        print("\n" + "=" * 60)
        find_profile_data(config)
    
    print("\n" + "=" * 60)
    
    # Step 4: Test profile switching
    test_profile_switching()
    
    print("\n" + "=" * 60)
    print("\n✅ Profile extraction complete!")
    print("\n📁 Check these files:")
    print("   - rtsa_full_config.json (full configuration)")
    print("\n💡 Next steps:")
    print("   1. Review rtsa_full_config.json for profile data")
    print("   2. Look for 'profile' or 'preset' entries")
    print("   3. Extract exact frequency ranges")


if __name__ == '__main__':
    main()
