# --- Stage 1: Build Stage ---
FROM python:3.10-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# --- Stage 2: Final Runtime Stage ---
FROM python:3.10-slim
WORKDIR /app

# [NEW] Install system libraries required by OpenCV
# These are the "missing pieces" in the slim image
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m monash_user
USER monash_user

# Copy packages and code
COPY --from=builder /install /usr/local
COPY main.py .
COPY yolov8l.pt .

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]