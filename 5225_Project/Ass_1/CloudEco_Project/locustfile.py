import os
import base64
import random
import uuid
from locust import HttpUser, task, constant_pacing


IMAGE_FOLDER = os.getenv("IMAGE_FOLDER", "./test_images")
MAX_IMAGES = int(os.getenv("MAX_IMAGES", 10))
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png"}

ENCODED_IMAGES = []


def preload_images():
    print(f"Scanning directory: {IMAGE_FOLDER} ...")

    if not os.path.exists(IMAGE_FOLDER):
        print(f"ERROR: Directory not found at {IMAGE_FOLDER}")
        return

    files = [
        f for f in os.listdir(IMAGE_FOLDER)
        if os.path.splitext(f)[1].lower() in ALLOWED_EXTENSIONS
    ]

    files = files[:MAX_IMAGES]

    if not files:
        print("ERROR: No valid images found in the specified directory.")
        return

    for filename in files:
        file_path = os.path.join(IMAGE_FOLDER, filename)
        try:
            with open(file_path, "rb") as f:
                img_b64 = base64.b64encode(f.read()).decode("utf-8")
                ENCODED_IMAGES.append(img_b64)
        except Exception as e:
            print(f"Failed to encode {filename}: {e}")

    print(f"Successfully pre-loaded {len(ENCODED_IMAGES)} images into memory.")


preload_images()


class WildlifeApiUser(HttpUser):
    wait_time = constant_pacing(0)

    def make_payload(self):
        return {
            "uuid": str(uuid.uuid4()),
            "image": random.choice(ENCODED_IMAGES)
        }

    @task(3)
    def test_predict(self):
        if not ENCODED_IMAGES:
            return

        payload = self.make_payload()

        with self.client.post("/api/predict", json=payload, catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"HTTP {response.status_code}")
                return

            try:
                data = response.json()
            except Exception:
                response.failure("Invalid JSON")
                return

            required_fields = [
                "uuid",
                "count",
                "detections",
                "boxes",
                "speed_preprocess_ms",
                "speed_inference_ms",
                "speed_postprocess_ms"
            ]

            for field in required_fields:
                if field not in data:
                    response.failure(f"Missing required field: {field}")
                    return

            if data["uuid"] != payload["uuid"]:
                response.failure("UUID mismatch")
                return

            if data["count"] != len(data["boxes"]):
                response.failure("Count does not match number of boxes")
                return

            response.success()

    @task(1)
    def test_annotate(self):
        if not ENCODED_IMAGES:
            return

        payload = self.make_payload()

        with self.client.post("/api/annotate", json=payload, catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"HTTP {response.status_code}")
                return

            try:
                data = response.json()
            except Exception:
                response.failure("Invalid JSON")
                return

            if "uuid" not in data or "image" not in data:
                response.failure("Missing uuid or image field")
                return

            if data["uuid"] != payload["uuid"]:
                response.failure("UUID mismatch")
                return

            if not data["image"]:
                response.failure("Empty annotated image")
                return

            response.success()