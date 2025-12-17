"""
Automatic Frequency Scanner
Cycles through key drone frequency bands
"""

import requests
import threading
import time
from datetime import datetime

class FrequencyScanner:
    def __init__(self, rtsa_host='http://localhost:54664'):
        self.rtsa_host = rtsa_host
        self.is_scanning = False
        self.current_band_index = 0
        self.scan_thread = None
        self.dwell_time = 5  # seconds per band
        
        # Key drone frequency bands to scan
        self.frequency_bands = [
            {
                'name': '2.4 GHz Control',
                'center': 2.441e9,
                'span': 83e6,
                'description': 'DJI Phantom/Mavic RC Control',
                'profile': 'dji_rc_channels_2400',
                'icon': '🎮'
            },
            {
                'name': '5.8 GHz Video',
                'center': 5.800e9,
                'span': 160e6,
                'description': 'DJI Lightbridge HD Video',
                'profile': 'dji_lightbridge_5800',
                'icon': '📹'
            },
            {
                'name': '915 MHz ISM',
                'center': 915e6,
                'span': 26e6,
                'description': 'Long Range RC Control (US)',
                'profile': '915mhz_ism_band',
                'icon': '📡'
            },
            {
                'name': '868 MHz EU',
                'center': 866e6,
                'span': 5.3e6,
                'description': 'JETI RC Control (EU)',
                'profile': 'jeti_dc_900',
                'icon': '🇪🇺'
            },
            {
                'name': '1.2 GHz Video',
                'center': 1.145e9,
                'span': 310e6,
                'description': 'Analog FPV Video',
                'profile': '1200mhz_videotransmitter',
                'icon': '📺'
            }
        ]
    
    def set_frequency(self, center_freq, span=None):
        """Set RTSA frequency via HTTP API"""
        try:
            # Calculate start and end frequencies
            if span:
                start_freq = center_freq - (span / 2)
                end_freq = center_freq + (span / 2)
            else:
                # Use span from current band
                band = self.frequency_bands[self.current_band_index]
                start_freq = center_freq - (band['span'] / 2)
                end_freq = center_freq + (band['span'] / 2)
            
            payload = {
                'frequencyStart': start_freq,
                'frequencyEnd': end_freq,
                'type': 'capture'
            }
            
            response = requests.put(
                f'{self.rtsa_host}/control',
                json=payload,
                timeout=2
            )
            
            if response.status_code == 200:
                return True
            else:
                print(f"⚠️ Failed to set frequency: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Error setting frequency: {e}")
            return False
    
    def scan_loop(self):
        """Main scanning loop that cycles through bands"""
        print("🔄 Auto-scan started!")
        
        while self.is_scanning:
            band = self.frequency_bands[self.current_band_index]
            
            print(f"\n{band['icon']} Scanning: {band['name']}")
            print(f"   Center: {band['center']/1e9:.3f} GHz")
            print(f"   Span: {band['span']/1e6:.1f} MHz")
            print(f"   Profile: {band['profile']}")
            
            # Set frequency
            self.set_frequency(band['center'], band['span'])
            
            # Dwell on this frequency
            start_time = time.time()
            while time.time() - start_time < self.dwell_time:
                if not self.is_scanning:
                    break
                time.sleep(0.5)
            
            # Move to next band
            self.current_band_index = (self.current_band_index + 1) % len(self.frequency_bands)
        
        print("⏸️ Auto-scan stopped")
    
    def start(self):
        """Start automatic scanning"""
        if not self.is_scanning:
            self.is_scanning = True
            self.scan_thread = threading.Thread(target=self.scan_loop, daemon=True)
            self.scan_thread.start()
            return True
        return False
    
    def stop(self):
        """Stop automatic scanning"""
        if self.is_scanning:
            self.is_scanning = False
            if self.scan_thread:
                self.scan_thread.join(timeout=2)
            return True
        return False
    
    def get_status(self):
        """Get current scanner status"""
        if self.is_scanning and self.current_band_index < len(self.frequency_bands):
            band = self.frequency_bands[self.current_band_index]
            return {
                'scanning': True,
                'current_band': band['name'],
                'current_band_index': self.current_band_index,
                'total_bands': len(self.frequency_bands),
                'center_frequency': band['center'],
                'span': band['span'],
                'description': band['description'],
                'icon': band['icon'],
                'dwell_time': self.dwell_time
            }
        else:
            return {
                'scanning': False,
                'current_band': 'None',
                'current_band_index': 0,
                'total_bands': len(self.frequency_bands)
            }
    
    def set_band(self, band_index):
        """Manually set to specific band"""
        if 0 <= band_index < len(self.frequency_bands):
            self.current_band_index = band_index
            band = self.frequency_bands[band_index]
            self.set_frequency(band['center'], band['span'])
            return True
        return False
    
    def set_dwell_time(self, seconds):
        """Set how long to dwell on each frequency"""
        if 1 <= seconds <= 60:
            self.dwell_time = seconds
            return True
        return False
    
    def get_bands(self):
        """Get list of all frequency bands"""
        return self.frequency_bands


# Global scanner instance
scanner = FrequencyScanner()
