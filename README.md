# FaceTrust VKYC - Liveness Detection Flutter App

A cross-platform Flutter application that performs Video KYC (VKYC) with face liveness detection using `google_mlkit_face_detection`. The app captures a single photo of the user's face, verifies liveness (blink and head orientation), enforces environmental and facial validation rules, and presents the KYC result in a clean multi-screen flow.

## 📱 Features

- ✅ Real-time **liveness detection** using google_mlkit_face_detection (blink + head orientation).
- 📷 Capture a **single photo** of user's face.
- ⚠️ Validation for:
  - Insufficient lighting
  - Face masks or sunglasses
  - Multiple faces
  - Screen/photo spoofing (edge check)
- 🖼 Multi-screen flow:
  - Splash Screen
  - Home Screen (saved VKYC selfies)
  - VKYC Instructions
  - Camera Preview with real-time feedback
  - VKYC Success Screen
- 💡 Modern, intuitive UI with user-friendly instructions
- 🎯 Fully offline — **No Firebase required**
- 🔐 Permission handling for Android and iOS

## 🛠 Tech Stack

- **Flutter SDK**: `^3.5.4`
- **Liveness Detection**: [`google_mlkit_face_detection`](https://pub.dev/packages/google_mlkit_face_detection)
- **Camera Access**: [`camera`](https://pub.dev/packages/camera)
- **Storage & Files**: [`path_provider`](https://pub.dev/packages/path_provider), [`path`](https://pub.dev/packages/path)
- **State Management**: `GetX`
- **Permission Handling**: `permission_handler`
- **UI/UX Helpers**: `delightful_toast`, `intl`, custom splash with `flutter_native_splash`

## 📂 Project Structure

```
lib/
├── main.dart
├── pages/
│ ├── home_screen.dart
│ ├── camera_page.dart
│ ├── image_viewer.dart
│ └── success_page.dart
├── controller/
│ └── ImageController.dart
└── widgets/
  └── snackbar.dart
```


## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.5.4+
- Android Studio or Xcode
- Device or emulator with camera support

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/Ashahad07/liveness_detection_task.git
   cd liveness_detection_task

2. **Install dependencies**
   ```bash
   flutter pub get

3. **Run the app**
   ```bash
   flutter run 
   ```

## Android Notes
  - **Minimum SDK version: 21**
  - Make sure android/app/src/main/AndroidManifest.xml includes camera permissions:

  ```
  <uses-permission android:name="android.permission.CAMERA" />
  ```

 ## 🧪 Testing
  To test the VKYC flow:

  1. Launch the app

2. Grant camera permissions

3. Follow on-screen instructions:

    - Ensure bright lighting

    - Remove sunglasses/mask

    - Look straight at the camera

    - Blink once

4. Capture selfie → App will perform liveness validation

5. View success screen if validation passes

Saved selfies are stored locally and displayed on the Home screen.


## 📸 Demo Video

🔗[`Demo Video (Google Drive)`](https://pub.dev/packages/google_mlkit_face_detection)



## Contributing

Contributions are welcome! Feel free to fork the repository and create a pull request.

## Contact

For any questions or feedback, feel free to reach out to [ashahadshaikh0007@gmail.com](mailto:ashahadshaikh0007@gmail.com).


### Made with ❤️ by Ashahad Shaikh