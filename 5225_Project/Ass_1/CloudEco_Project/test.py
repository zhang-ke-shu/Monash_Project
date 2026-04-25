import requests
import base64
import json

# 1. Local setup
URL = "http://34.151.179.167/api/predict"
IMAGE_PATH = "zebra.jpg"  # Make sure you have a zebra or elephant image here
OUTPUT_FILE = "response_check.json"

def test_real_inference():
    # Load and encode a real animal image
    with open(IMAGE_PATH, "rb") as f:
        img_b64 = base64.b64encode(f.read()).decode('utf-8')

    payload = {
        "uuid": "real-test-uuid-001",
        "image": img_b64
    }

    print(f"Sending real image to API...")
    response = requests.post(URL, json=payload)
    
    if response.status_code == 200:
        data = response.json()
        # Save for manual inspection
        with open(OUTPUT_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        print(f"✅ Success! Detected {data['count']} animals.")
        print(f"Detections: {data['detections']}")
        print(f"Inference Speed: {data['speed_inference_ms']} ms")
    else:
        print(f"❌ Failed with status {response.status_code}")
        print(response.text)

if __name__ == "__main__":
    test_real_inference()