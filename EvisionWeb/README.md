How to Run
Follow these steps to launch the application:

Open a Terminal:
On Windows: Press Win + R, type cmd, and press Enter.
On macOS/Linux: Open your terminal application.
Navigate to the Project Directory:



cd /path/to/EvisionWeb
Replace /path/to/EvisionWeb with the actual path to the project folder.
Activate the Virtual Environment:



source venv/bin/activate  # On Windows: venv\Scripts\activate
Install Dependencies (if not done):



pip install -r requirements.txt
Start the Flask Server:



python app.py
The server will run on http://127.0.0.1:5000 in debug mode.
Look for logs confirming the YOLO model loading and server startup.
Access the Application:
Open a browser and go to http://127.0.0.1:5000.
Explore features via the homepage (upload, capture, record, real-time).
