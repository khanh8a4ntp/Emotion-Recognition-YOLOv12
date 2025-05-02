# File: config.py
import os

# Đường dẫn đến thư mục gốc của dự án
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Đường dẫn đến mô hình YOLO
MODEL_PATH = os.path.join(BASE_DIR, "models", "yolov12s.pt")

# Đường dẫn đến thư mục lưu trữ uploads (ảnh, video)
UPLOADS_DIR = os.path.join(BASE_DIR, "uploads")
os.makedirs(UPLOADS_DIR, exist_ok=True)

# Đường dẫn đến file video tạm thời
TEMP_VIDEO_PATH = os.path.join(UPLOADS_DIR, "temp_video.mp4")

# Đường dẫn đến file video quay từ webcam
RECORDED_VIDEO_PATH = os.path.join(UPLOADS_DIR, "recorded_video.mp4")

# Đường dẫn đến ảnh chụp từ webcam
CAPTURED_IMAGE_PATH = os.path.join(UPLOADS_DIR, "captured_image.jpg")

# API key cho Gemini (thay bằng API key thực tế của bạn)
GEMINI_API_KEY = "AIzaSyAEGNoQjDSQQOCd8tCf2JrDJQNt6_6QFwE"  # Thay bằng API key thực tế