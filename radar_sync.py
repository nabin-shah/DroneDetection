import serial
import time
import requests
import threading

class RadarSynchronizer:
    def __init__(self, com_port='COM3', baud_rate=115200, rtsa_host='http://localhost:54664'):
        self.rtsa_host = rtsa_host
        self.is_scanning = False
        self.scan_thread = None
        
        self.current_angle = 0  # NEW: Stores the real-time physical angle
        self.sweep_complete_event = threading.Event() # NEW: Used to signal the main loop
        
        self.profiles = [
            {'name': '2.4 GHz Control', 'center': 2.441e9, 'span': 83e6},
            {'name': '5.8 GHz Video', 'center': 5.800e9, 'span': 160e6},
            {'name': '915 MHz ISM', 'center': 915e6, 'span': 26e6},
            {'name': '868 MHz EU', 'center': 866e6, 'span': 5.3e6},
            {'name': '1.2 GHz Video', 'center': 1.145e9, 'span': 310e6}
        ]
        
        try:
            print(f"📡 Connecting to Antenna Arduino on {com_port}...")
            self.arduino = serial.Serial(com_port, baud_rate, timeout=0.1)
            time.sleep(2)
            self.arduino.reset_input_buffer()
            print("✅ Arduino Connected!")
            
            # Start the continuous serial reader thread
            self.serial_thread = threading.Thread(target=self._serial_reader_loop, daemon=True)
            self.serial_thread.start()
            
        except Exception as e:
            print(f"❌ Arduino connection failed: {e}")
            self.arduino = None

    def _serial_reader_loop(self):
        """Continuously reads incoming data from Arduino in the background"""
        while True:
            if self.arduino and self.arduino.in_waiting > 0:
                try:
                    line = self.arduino.readline().decode('utf-8').strip()
                    if line.startswith("ANGLE:"):
                        # Extract the angle number (e.g., "ANGLE:45" -> 45)
                        self.current_angle = int(line.split(":")[1])
                    elif line in ["DONE_F", "DONE_B"]:
                        # Signal the main loop that the physical sweep is done
                        self.sweep_complete_event.set()
                except Exception:
                    pass
            time.sleep(0.01) # Tiny sleep to prevent CPU maxing

    def set_rtsa_profile(self, profile):
        try:
            start_freq = profile['center'] - (profile['span'] / 2)
            end_freq = profile['center'] + (profile['span'] / 2)
            payload = {
                'frequencyStart': start_freq,
                'frequencyEnd': end_freq,
                'type': 'capture'
            }
            requests.put(f'{self.rtsa_host}/control', json=payload, timeout=2)
            print(f"🎛️ RTSA set to: {profile['name']}")
            time.sleep(0.5) 
        except Exception as e:
            print(f"❌ RTSA Error: {e}")

    def sync_loop(self):
        profile_idx = 0
        moving_forward = True

        while self.is_scanning:
            current_profile = self.profiles[profile_idx]
            self.set_rtsa_profile(current_profile)
            
            self.sweep_complete_event.clear() # Reset the completion flag
            
            if moving_forward:
                print(f"➡️ Sweeping 0° to 180° for {current_profile['name']}")
                if self.arduino: self.arduino.write(b'F')
            else:
                print(f"⬅️ Sweeping 180° to 0° for {current_profile['name']}")
                if self.arduino: self.arduino.write(b'B')
            
            # Wait until the serial reader thread sees "DONE_F" or "DONE_B"
            if self.arduino:
                self.sweep_complete_event.wait(timeout=15.0) # Failsafe timeout
            else:
                time.sleep(3) # Simulation mode if no arduino
            
            moving_forward = not moving_forward
            profile_idx = (profile_idx + 1) % len(self.profiles)

    def start(self):
        if not self.is_scanning:
            self.is_scanning = True
            self.scan_thread = threading.Thread(target=self.sync_loop, daemon=True)
            self.scan_thread.start()

    def stop(self):
        self.is_scanning = False
        if self.scan_thread:
            self.scan_thread.join()

radar_sync = RadarSynchronizer()