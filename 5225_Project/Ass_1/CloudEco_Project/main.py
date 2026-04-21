import base64
import io
import numpy as np
import cv2
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict
from ultralytics import YOLO
from starlette.concurrency import run_in_threadpool # 用于处理非阻塞推理

# 初始化 FastAPI
app = FastAPI()

# 加载你的 Model 4 (野生动物检测) [cite: 50]
# 确保项目目录下有此权重文件
model = YOLO("yolov8l.pt")

class ImageRequest(BaseModel):
    uuid: str # 客户端发送的唯一标识符 [cite: 56, 63]
    image: str # Base64 编码的图像字符串 [cite: 56, 64]

class BoxInfo(BaseModel):
    x: float
    y: float
    width: float
    height: float
    probability: float # 置信度 [cite: 72, 82]

class PredictResponse(BaseModel):
    uuid: str # 必须返回与请求一致的 uuid [cite: 68, 78]
    count: int # 检测到的物体总数 [cite: 69, 80]
    detections: List[str] # 类别名称列表 [cite: 70]
    boxes: List[BoxInfo] # 坐标详情列表 [cite: 71, 72]
    speed_preprocess_ms: float # 预处理延迟 [cite: 73, 84]
    speed_inference_ms: float # 推理延迟 [cite: 74, 84]
    speed_postprocess_ms: float # 后处理延迟 [cite: 75, 84]


def process_base64_image(base64_str: str):
    # 将 Base64 解码为二进制字节流 [cite: 58]
    img_data = base64.b64decode(base64_str)
    # 转换为 NumPy 数组
    nparr = np.frombuffer(img_data, np.uint8)
    # 使用 OpenCV 读取为图像矩阵
    return cv2.imdecode(nparr, cv2.IMREAD_COLOR)

def convert_to_base64(image_np):
    # 将图像矩阵转回 Base64，用于标注接口 [cite: 88]
    _, buffer = cv2.imencode('.jpg', image_np)
    return base64.b64encode(buffer).decode('utf-8')


def run_model_inference(img):
    # 执行 YOLO 推理 [cite: 48, 54]
    results = model.predict(img)
    result = results[0]
    
    # 获取 Ultralytics 自动生成的延迟指标 
    latency = result.speed 
    
    boxes_data = []
    labels_data = []
    
    for box in result.boxes:
        # 提取类别名称 [cite: 58]
        labels_data.append(model.names[int(box.cls)])
        # 提取坐标 (x,y,w,h) [cite: 72, 81]
        x, y, w, h = box.xywh[0].tolist()
        boxes_data.append({
            "x": x, "y": y, "width": w, "height": h,
            "probability": float(box.conf)
        })
        
    return result, len(labels_data), labels_data, boxes_data, latency


@app.post("/api/predict", response_model=PredictResponse)
async def predict_api(request: ImageRequest):
    # 解码图像
    img = process_base64_image(request.image)
    
    # HD 重点：在线程池执行推理，避免阻塞主循环 
    _, count, labels, boxes, speed = await run_in_threadpool(run_model_inference, img)
    
    return {
        "uuid": request.uuid,
        "count": count,
        "detections": labels,
        "boxes": boxes,
        "speed_preprocess_ms": speed['preprocess'],
        "speed_inference_ms": speed['inference'],
        "speed_postprocess_ms": speed['postprocess']
    }

@app.post("/api/annotate")
async def annotate_api(request: ImageRequest):
    img = process_base64_image(request.image)
    
    # 获取推理结果及画好框的图片
    result, _, _, _, _ = await run_in_threadpool(run_model_inference, img)
    
    # 使用 YOLO 自带工具生成标注图 [cite: 87]
    annotated_img = result.plot()
    
    return {
        "uuid": request.uuid,
        "image": convert_to_base64(annotated_img) # 转回 Base64 [cite: 88]
    }