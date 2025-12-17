"""
Simplified Camera Module - Tested & Working
"""
import cv2
import base64
import os
from datetime import datetime

# Camera globals
camera = None
camera_enabled = False
CAPTURE_FOLDER = 'drone_captures'

if not os.path.exists(CAPTURE_FOLDER):
    os.makedirs(CAPTURE_FOLDER)

def init_camera(camera_index=0):
    """Initialize webcam"""
    global camera, camera_enabled
    
    try:
        camera = cv2.VideoCapture(camera_index, cv2.CAP_DSHOW)
        camera.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        
        if camera.isOpened():
            # Test one frame
            ret, test_frame = camera.read()
            if ret and test_frame is not None:
                camera_enabled = True
                print(f"✅ [Camera] Initialized 640x480")
                return True
        print("❌ [Camera] Failed to capture test frame")
        return False
        
    except Exception as e:
        print(f"❌ [Camera] Init error: {e}")
        return False

def get_camera_frame():
    """Get current camera frame - EXACTLY like standalone test"""
    global camera, camera_enabled
    
    if not camera_enabled or camera is None or not camera.isOpened():
        return None
    
    try:
        # EXACT SAME LOGIC AS WORKING STANDALONE TEST
        ret, frame = camera.read()
        
        if not ret or frame is None:
            return None
        
        # Resize to 640x480 for web (exactly like standalone)
        frame = cv2.resize(frame, (640, 480))
        
        # Encode JPEG directly (no fancy params that might break)
        _, buffer = cv2.imencode('.jpg', frame)
        
        # Base64 encode
        jpg_as_text = base64.b64encode(buffer).decode('utf-8')
        return f"data:image/jpeg;base64,{jpg_as_text}"
        
    except Exception as e:
        print(f"❌ [Camera] Frame error: {e}")
        return None

def capture_image(detection_data):
    """Save detection image"""
    if not camera_enabled:
        return None
    
    try:
        ret, frame = camera.read()
        if not ret:
            return None
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"drone_{timestamp}.jpg"
        filepath = os.path.join(CAPTURE_FOLDER, filename)
        
        # Overlay detection info
        cv2.putText(frame, "DRONE DETECTED!", (10, 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
        
        cv2.imwrite(filepath, frame)
        print(f"💾 [Camera] Saved: {filename}")
        return filename
        
    except Exception as e:
        print(f"❌ [Camera] Capture error: {e}")
        return None

def get_camera_status():
    """Camera status"""
    return {
        'enabled': camera_enabled,
        'available': camera is not None,
        'opened': camera.isOpened() if camera else False
    }
