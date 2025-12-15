"""
Camera capture functionality
"""
import cv2
import os
import base64
from datetime import datetime

# Camera configuration
camera = None
camera_enabled = False
CAPTURE_FOLDER = 'drone_captures'

# Create captures folder
if not os.path.exists(CAPTURE_FOLDER):
    os.makedirs(CAPTURE_FOLDER)

def init_camera(camera_index=0):
    """Initialize webcam"""
    global camera, camera_enabled
    try:
        # Use DirectShow backend for Windows (better compatibility)
        camera = cv2.VideoCapture(camera_index, cv2.CAP_DSHOW)
        
        # Set resolution
        camera.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        
        if camera.isOpened():
            # Test frame capture
            ret, test_frame = camera.read()
            if ret:
                camera_enabled = True
                print(f"[Camera] Initialized camera {camera_index} - {test_frame.shape[1]}x{test_frame.shape[0]}")
                return True
            else:
                print(f"[Camera] Camera opened but can't read frames")
                camera.release()
                camera_enabled = False
                return False
        else:
            print(f"[Camera] Failed to open camera {camera_index}")
            camera_enabled = False
            return False
            
    except Exception as e:
        print(f"[Camera] Error: {e}")
        camera_enabled = False
        return False

def get_camera_frame():
    """Get current camera frame as base64 for live preview"""
    global camera, camera_enabled
    
    if not camera_enabled:
        print("[Camera] Camera not enabled")
        return None
    
    if camera is None:
        print("[Camera] Camera object is None")
        return None
    
    if not camera.isOpened():
        print("[Camera] Camera not opened, attempting to reinitialize...")
        init_camera(0)
        if not camera_enabled:
            return None
    
    try:
        ret, frame = camera.read()
        
        if not ret:
            print("[Camera] Failed to read frame")
            return None
        
        # Resize for web display (smaller = faster)
        frame = cv2.resize(frame, (640, 480))
        
        # Convert to JPEG
        ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
        
        if not ret:
            print("[Camera] Failed to encode frame")
            return None
        
        # Convert to base64
        jpg_as_text = base64.b64encode(buffer).decode('utf-8')
        return f"data:image/jpeg;base64,{jpg_as_text}"
        
    except Exception as e:
        print(f"[Camera] Frame capture error: {e}")
        return None

def capture_image(detection_data):
    """Capture image from webcam when drone is detected"""
    global camera, camera_enabled
    
    if not camera_enabled or camera is None:
        print("[Camera] Camera not available for capture")
        return None
    
    try:
        ret, frame = camera.read()
        
        if not ret:
            print("[Camera] Failed to capture frame for detection")
            return None
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"drone_{timestamp}.jpg"
        filepath = os.path.join(CAPTURE_FOLDER, filename)
        
        strongest = detection_data.get('strongest', {})
        
        # Add detection info overlay
        cv2.putText(frame, "DRONE DETECTED", (10, 30), 
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
        cv2.putText(frame, f"Freq: {strongest.get('frequency', 0)/1e9:.3f} GHz", (10, 70),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        cv2.putText(frame, f"Power: {strongest.get('power', 0):.1f} dBm", (10, 110),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        cv2.putText(frame, f"Score: {strongest.get('drone_score', 0)}", (10, 150),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        cv2.putText(frame, timestamp, (10, 190),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)
        
        # Save image
        cv2.imwrite(filepath, frame)
        print(f"[Camera] Captured detection image: {filepath}")
        
        return filename
        
    except Exception as e:
        print(f"[Camera] Detection capture error: {e}")
        return None

def get_camera_status():
    """Get current camera status"""
    status = {
        'enabled': camera_enabled,
        'available': camera is not None
    }
    
    if camera is not None:
        status['is_opened'] = camera.isOpened()
    else:
        status['is_opened'] = False
    
    return status

def release_camera():
    """Release camera resources"""
    global camera, camera_enabled
    
    if camera is not None:
        camera.release()
        print("[Camera] Camera released")
    
    camera = None
    camera_enabled = False
