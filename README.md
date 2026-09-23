# SpeakMate DZ — Flutter Android App

## Requirements
- Flutter 3.x
- Android Studio
- Android SDK

## Setup
This archive contains the Flutter application source. The easiest way to create the platform scaffolding is:

1. Install Flutter.
2. Create a temporary Flutter app:
   `flutter create speakmate_dz`
3. Replace its `pubspec.yaml` with the one in this archive.
4. Replace `lib/main.dart` with this archive's `lib/main.dart`.
5. Replace the Android manifest with `android/app/src/main/AndroidManifest.xml`.
6. Run:
   `flutter pub get`
   `flutter run`

## Backend
The app expects the FastAPI server at:
`http://10.0.2.2:8000` for an Android emulator.

For a physical Android phone, change `apiBase` in `lib/main.dart` to the computer's local network address, for example:
`http://192.168.1.20:8000`

Start the backend from the previous SpeakMate DZ v2 project:
`uvicorn main:app --reload --host 0.0.0.0 --port 8000`

## Included
- Mobile home screen
- Practice selection
- A2/B1/B2/C1
- Voice input with speech_to_text
- Text input
- AI/backend conversation
- Speaking report
- Progress screen
- Research screen
- Android microphone + internet permissions

## Important
The current backend still uses demo conversational/scoring logic. For the thesis production version, connect a real server-side LLM, speech-to-text and validated pronunciation/fluency analysis, then add authentication, PostgreSQL, consent and research data controls.
