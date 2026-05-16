# Setup Guide

## Required API Keys

### 1. Firebase
Run `flutterfire configure` to generate `firebase_options.dart` with your own Firebase project.

Enable in Firebase Console:
- Authentication (Email/Password)
- Cloud Firestore
- Firebase Storage
- Cloud Messaging (FCM)

### 2. Groq AI (Chatbot feature)
1. Get a free API key from [console.groq.com](https://console.groq.com)
2. In `lib/screens/home_screen.dart`, replace:
```dart
static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE';
```
with your actual key.

### 3. Google Maps
Add your Maps API key in:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/AppDelegate.swift`
