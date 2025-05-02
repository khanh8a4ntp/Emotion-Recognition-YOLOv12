import google.generativeai as genai
import os

# Thiết lập API key
genai.configure(api_key="AIzaSyAEGNoQjDSQQOCd8tCf2JrDJQNt6_6QFwE")

# Lấy danh sách mô hình
for model in genai.list_models():
    if 'generateContent' in model.supported_generation_methods:
        print(f"Name: {model.name}")
        print(f"Description: {model.description}")
        print(f"Supported Methods: {model.supported_generation_methods}")
        print("-" * 50)

if __name__ == "__main__":
    pass