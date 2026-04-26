import os
import base64
import random
from io import BytesIO
from PIL import Image
from locust import HttpUser, task, constant_pacing

# --- Configuration ---
IMAGE_FOLDER = "/Users/apple/Github/Monash_Project/5225_Project/Ass_1/CloudEco_Project/wildlife-yolo-detector/WILD-ANIMALS-DETECTION-1/test/images"

# Global list to store pre-encoded, highly optimized images
ENCODED_IMAGES = []

def preload_and_optimize_images():
    """Scans the directory, resizes images to YOLO's native size (640x640), and encodes them."""
    print(f"Scanning and optimizing images in: {IMAGE_FOLDER} ...")
    
    if not os.path.exists(IMAGE_FOLDER):
        print(f"ERROR: Directory not found at {IMAGE_FOLDER}")
        return

    # Filter for .jpg files as requested
    files = [f for f in os.listdir(IMAGE_FOLDER) if f.lower().endswith('.jpg')]
    
    if not files:
        print("ERROR: No .jpg images found in the specified directory.")
        return

    for filename in files:
        file_path = os.path.join(IMAGE_FOLDER, filename)
        try:
            # 1. Open the image
            with Image.open(file_path) as img:
                # 2. Convert to RGB (to ensure consistency and remove alpha channels if any)
                img = img.convert("RGB")
                
                # 3. Resize to 640x640 (maintains aspect ratio, shrinks the longest side to 640)
                # This drastically reduces network payload and backend decoding time.
                img.thumbnail((640, 640))
                
                # 4. Save to a temporary memory buffer with 80% JPEG quality
                buffered = BytesIO()
                img.save(buffered, format="JPEG", quality=80)
                
                # 5. Encode the compressed bytes to Base64
                img_b64 = base64.b64encode(buffered.getvalue()).decode('utf-8')
                ENCODED_IMAGES.append(img_b64)
                
        except Exception as e:
            print(f"Failed to process {filename}: {e}")
    
    print(f"Successfully loaded and compressed {len(ENCODED_IMAGES)} images into memory.")

# Execute the optimization pipeline once when Locust starts
preload_and_optimize_images()

class WildlifeApiUser(HttpUser):
    # Maximum pressure: zero wait time between requests
    wait_time = constant_pacing(0)

    @task(3)
    def test_predict(self):
        """High frequency task: object detection."""
        if not ENCODED_IMAGES:
            return
            
        payload = {
            "uuid": f"locust-{random.randint(1000, 9999)}",
            "image": random.choice(ENCODED_IMAGES)
        }
        self.client.post("/api/predict", json=payload)

    @task(1)
    def test_annotate(self):
        """Low frequency task: bounding box annotation."""
        if not ENCODED_IMAGES:
            return
            
        payload = {
            "uuid": f"locust-{random.randint(1000, 9999)}",
            "image": random.choice(ENCODED_IMAGES)
        }
        self.client.post("/api/annotate", json=payload)