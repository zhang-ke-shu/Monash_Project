import base64
import numpy as np
import cv2
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
from ultralytics import YOLO
from starlette.concurrency import run_in_threadpool
import logging

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


# Initialize FastAPI application
app = FastAPI()

# Load the YOLO model. 
try:
    model = YOLO("yolov8l.pt")
except Exception as e:
    logger.error(f"Failed to load YOLO model: {e}")
    raise RuntimeError("Model failed to load")

if model is None:
    raise RuntimeError("Model failed to load")

# --- Pydantic Models for Data Validation ---

class ImageRequest(BaseModel):
    uuid: str 
    image: str 

class BoxInfo(BaseModel):
    x: float
    y: float
    width: float
    height: float
    probability: float 

class PredictResponse(BaseModel):
    uuid: str 
    count: int 
    detections: List[str] 
    boxes: List[BoxInfo] 
    speed_preprocess_ms: float 
    speed_inference_ms: float 
    speed_postprocess_ms: float 

class AnnotateResponse(BaseModel):
    uuid: str
    image: str

# --- CPU-Bound Pipeline Functions (The "Kitchen") ---
# EVERYTHING inside these functions will run in a background thread,
# completely freeing up the FastAPI event loop.

def decode_base64_to_cv2(base64_str: str):
    """CPU-bound task: Decodes base64 to image matrix."""
    try:
        img_data = base64.b64decode(base64_str, validate=True)
        nparr = np.frombuffer(img_data, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError("Decoded image is empty.")
        return img
    except Exception as e:
        raise ValueError(f"Image decoding failed: {e}")

def execute_predict_pipeline(base64_image: str):
    """Full CPU-bound pipeline for the /predict endpoint."""
    img = decode_base64_to_cv2(base64_image)
    results = model.predict(img, conf=0.5, imgsz=320, verbose=False)
    result = results[0]
    
    latency = result.speed 
    boxes_data = []
    labels_data = []
    
    for box in result.boxes:
        labels_data.append(model.names[int(box.cls)])
        x, y, w, h = box.xywh[0].tolist()
        boxes_data.append({
            "x": round(x, 4), 
            "y": round(y, 4), 
            "width": round(w, 4), 
            "height": round(h, 4),
            "probability": round(float(box.conf), 4)
        })
        
    return len(labels_data), labels_data, boxes_data, latency

def execute_annotate_pipeline(base64_image: str):
    """Full CPU-bound pipeline for the /annotate endpoint."""
    img = decode_base64_to_cv2(base64_image)
    results = model.predict(img, conf=0.5, imgsz=320, verbose=False)
    
    # Ultralytics plotting is also CPU-bound
    annotated_img = results[0].plot() 
    
    # Encoding back to base64 is CPU-bound
    _, buffer = cv2.imencode('.jpg', annotated_img)
    return base64.b64encode(buffer).decode('utf-8')


# --- Async API Endpoints (The "Waiter") ---

@app.post("/api/predict", response_model=PredictResponse)
async def predict_api(request: ImageRequest):
    logger.info(f"Received prediction request: {request.uuid}")
    try:
        # The waiter instantly hands the ENTIRE job to the threadpool.
        # The event loop is now free to accept hundreds of other requests.
        count, labels, boxes, speed = await run_in_threadpool(
            execute_predict_pipeline, request.image
        )
        
        return {
            "uuid": request.uuid,
            "count": count,
            "detections": labels,
            "boxes": boxes,
            "speed_preprocess_ms": round(speed.get('preprocess', 0.0), 2),
            "speed_inference_ms": round(speed.get('inference', 0.0), 2),
            "speed_postprocess_ms": round(speed.get('postprocess', 0.0), 2)
        }
    except ValueError as ve:
        logger.error(f"Prediction validation failed: {ve}")
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"Prediction failed: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error during prediction.")


@app.post("/api/annotate", response_model=AnnotateResponse)
async def annotate_api(request: ImageRequest):
    try:
        # Offload decoding, inference, plotting, and encoding to the background.
        annotated_base64 = await run_in_threadpool(
            execute_annotate_pipeline, request.image
        )
        
        return {
            "uuid": request.uuid,
            "image": annotated_base64
        }
    except ValueError as ve:
        logger.info(f"Annotation validation request:{ve}")
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.info(f"Annotation failed:{e}")
        raise HTTPException(status_code=500, detail="Internal Server Error during annotation.")