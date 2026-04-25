# --- Section 7: Locust Load Generation Script ---
import base64
from locust import HttpUser, task, between

class WildlifeApiUser(HttpUser):
    # Simulate a user waiting between 1 to 2 seconds between requests
    wait_time = between(1, 2)

    def on_start(self):
        # Pre-load and encode the image to save local CPU during testing
        self.image_path = "zebra.jpg"
        with open(self.image_path, "rb") as f:
            self.img_b64 = base64.b64encode(f.read()).decode('utf-8')
        
        self.payload = {
            "uuid": "test-uuid-locust",
            "image": self.img_b64
        }

    @task(3)
    def test_predict(self):
        # High-weight task for object detection endpoint
        self.client.post("/api/predict", json=self.payload)

    @task(1)
    def test_annotate(self):
        # Lower-weight task for annotated image endpoint
        self.client.post("/api/annotate", json=self.payload)