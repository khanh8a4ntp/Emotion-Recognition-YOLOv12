# How to Run EvisionApp

This section provides a detailed guide to running **EvisionApp**, a Flutter-based mobile application for emotion recognition using the YOLOv12 model. The instructions focus on setting up the environment, installing dependencies, and launching the app on Android devices or emulators.

## Prerequisites

Ensure the following tools are installed before proceeding:

- **Flutter SDK**: Version 3.29.2 (stable channel). [Installation Guide](https://flutter.dev/docs/get-started/install)
- **Dart**: Version 3.7.2 (included with Flutter)
- **Android Studio**: For running emulators or Android devices. Requires Android SDK 35.0.0
- **JDK**: Version 21.0.5
- **NDK**: Version 27.0.12077973
- **Device/Emulator**: Android device (API 21+) with USB Debugging enabled or an Android emulator
- **IDE**: VS Code or Android Studio with Flutter and Dart plugins

Verify your setup by running:
```bash
flutter doctor
```

## Setup Instructions
Win + R -> cmd
1. Move to location of folder
```bash
cd your/path/of/EvisionApp
```
2. Install libs
    ```bash
   pip install -r requirement.txt
   ```
3. Install Dependencies
Install the required packages listed in pubspec.yaml:
```bash
flutter pub get
```
4. Open USB debugging in setting and turn on
5. Run the Application
Connect an Android device or start an emulator:
```bash
flutter devices
```
6. Launch the app in debug mode:
```bash
flutter run
```
