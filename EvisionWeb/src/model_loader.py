# File: src/model_loader.py
from ultralytics import YOLO

def load_model(model_path):
    """
    Tải mô hình YOLO từ đường dẫn được cung cấp.
    
    Args:
        model_path (str): Đường dẫn đến file mô hình .pt
    
    Returns:
        model: Mô hình YOLO đã được tải
    """
    try:
        model = YOLO(model_path)
        return model
    except Exception as e:
        raise Exception(f"Không thể tải mô hình từ {model_path}: {str(e)}")