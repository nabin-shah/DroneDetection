import cv2

print("Testing camera access...")

# Try different camera indices
for i in range(3):
    print(f"\nTrying camera index {i}...")
    cap = cv2.VideoCapture(i)
    
    if cap.isOpened():
        print(f"✓ Camera {i} opened successfully!")
        ret, frame = cap.read()
        if ret:
            print(f"✓ Camera {i} can capture frames!")
            print(f"  Resolution: {frame.shape[1]}x{frame.shape[0]}")
        else:
            print(f"✗ Camera {i} opened but can't read frames")
        cap.release()
    else:
        print(f"✗ Camera {i} not available")

print("\n" + "="*50)
print("Test complete!")
