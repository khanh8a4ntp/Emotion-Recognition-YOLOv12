# HOW TO RUN
Follow these steps to launch the application:

1. Open a Terminal:
On Windows: Press Win + R, type cmd, and press Enter.
On macOS/Linux: Open your terminal application.


2. Navigate to the Project Directory:
```bash
cd /path/to/EvisionWeb
```
Replace /path/to/EvisionWeb with the actual path to the project folder.


3. Activate the Virtual Environment:
- On Mac:
```bash
source venv/bin/activate
```
- On Windows:
```bash
venv\Scripts\activate
```

5. Install Dependencies (if not done):
```bash
pip install -r requirements.txt
```

6. Start the Flask Server:
```bash
python app.py
```

The server will run on localhost in debug mode.
Look for logs confirming the YOLO model loading and server startup.
