# Emotion Detection Web Application

## Overview

Welcome to the **Emotion Detection Web Application**, a powerful tool designed for both real-time and static emotion detection using the advanced YOLOv12 model. This web-based application allows users to analyze emotions through various methods, including:

- Uploading images or videos
- Capturing photos via webcam
- Recording videos
- Streaming live webcam feeds for real-time detection

Integrated with a friendly chatbot powered by the Gemini API, the application provides interactive responses based on detected emotions, supporting both Vietnamese and English languages. The app features a responsive and intuitive interface, complete with customizable settings, downloadable results, and seamless real-time interaction capabilities.

## Features

- **Image and Video Upload**: Upload images (JPEG/PNG) or videos (WebM/MP4) to detect emotions with annotated bounding boxes.
- **Photo Capture**: Use your webcam to capture a photo and instantly analyze the emotions present.
- **Video Recording**: Record videos via your webcam and process them for emotion detection, with annotations added every 30 frames.
- **Real-time Detection**: Stream your webcam feed for continuous emotion detection, complete with live bounding box overlays and chatbot interaction.
- **Emotion-based Chatbot**: A friendly chatbot that responds to detected emotions in Vietnamese or English, adapting to the user's language through automatic detection.
- **Adjustable Confidence Threshold**: Customize the detection sensitivity using a slider (default: 5%) to fine-tune results.
- **Downloadable Results**: Save processed images, videos, or detection results as text files for further use.
- **Responsive Interface**: Enjoy a user-friendly UI with loading animations, notifications, and clear result displays.

## Tech Stack

- **Backend**: Flask (Python) with Flask-SocketIO for real-time communication
- **Frontend**: HTML, CSS, and JavaScript, leveraging Socket.IO for seamless real-time streaming
- **Machine Learning**: YOLOv12 model (`yolov12s.pt`) via the Ultralytics library for emotion detection
- **Libraries**:
  - OpenCV for image and video processing
  - NumPy for numerical operations
  - `langdetect` for automatic language detection of user messages
- **Chatbot**: Powered by the Gemini API for generating emotion-based responses
- **Dependencies**: All required packages are listed in `requirements.txt`

## Supported Emotions

The application detects a range of emotions, each accompanied by a confidence score, an emoji, and a color-coded bounding box:

- **Anger** 😡
- **Contempt** 😏
- **Disgust** 🤢
- **Fear** 😱
- **Happy** 😂
- **Neutral** 😐
- **Sad** 😢
- **Surprised** 😲
- **Unknown** ❓ (for unrecognized emotions)

## Usage Scenarios

- **Static Analysis**: Upload an image or video to analyze emotions in a single moment or across a sequence of frames.
- **Instant Capture**: Take a quick photo with your webcam to see what emotions are present.
- **Video Processing**: Record a video and let the app annotate emotions frame-by-frame.
- **Live Interaction**: Use the real-time feature to stream your webcam feed, watch emotions being detected live, and chat with the bot based on your mood.

## Chatbot Interaction

The integrated chatbot enhances the user experience by responding to detected emotions in a conversational manner. Key features include:

- **Initiation**: In real-time mode, the chatbot starts a conversation after 5 seconds based on the dominant detected emotion.
- **Language Support**:
  - **Vietnamese Responses**: Uses a friendly tone with informal pronouns like "cậu-tớ" or "bạn-tôi", and lively emojis.
  - **English Responses**: Uses a casual, playful tone with teencode (e.g., "u", "bro", "lol") and emojis for a fun vibe.
- **Automatic Language Detection**: Detects the user's language to respond appropriately.

## Configuration Details

### File Structure

- **`app.py`**: Main Flask application handling routes and SocketIO events for real-time functionality
- **`src/model_loader.py`**: Loads the YOLO model for emotion detection
- **`src/emotion_detector.py`**: Processes images/videos and draws bounding boxes using OpenCV
- **`config.py`**: Stores configuration settings like model paths and API keys
- **`static/js/`**: Contains JavaScript files for frontend features
  - `upload.js`: Manages image/video uploads
  - `capture.js`: Handles webcam photo capture
  - `record.js`: Controls video recording
  - `realtime.js`: Enables real-time streaming and chatbot interaction
- **`templates/`**: HTML templates for the user interface (e.g., `index.html`, `upload.html`)
- **`uploads/`**: Directory for storing uploaded and processed files
- **`models/`**: Stores the YOLO model (`yolov12s.pt`)

### Key Configurations

- **Model**: Uses `yolov12s.pt` for emotion detection, expected to be placed in the `models/` directory
- **Uploads**: Processed files are saved in the `uploads/` directory
- **Gemini API**: Requires a valid API key for the chatbot to function
- **Confidence Threshold**: Adjustable via the UI (default: 5%) to control detection sensitivity

## Notes

- The YOLO model must be trained or fine-tuned for emotion detection to recognize the supported emotions accurately.
- Real-time detection can be resource-intensive; ensure your system has sufficient CPU/GPU resources.
- The chatbot requires an active internet connection and a valid Gemini API key to operate.

## Contributing

We welcome contributions! To contribute:

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "Add your feature"`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Contact

For questions or support, reach out to the project maintainer at [your-email@example.com].

---

### Đặc điểm chính
- Định dạng theo phong cách GitHub với các tiêu đề sử dụng `#` và `##`, danh sách gạch đầu dòng (`-`), và đoạn mã được bọc trong dấu `` ```
- Loại bỏ hoàn toàn phần **How to Run** theo yêu cầu.
- Tập trung vào giới thiệu tổng quan, tính năng, công nghệ, và các thông tin liên quan đến ứng dụng.
- Nội dung được trình bày ngắn gọn, rõ ràng, và chuyên nghiệp, phù hợp với chuẩn README trên GitHub.

Nếu bạn cần chỉnh sửa thêm, hãy cho tôi biết!
