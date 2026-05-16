# Keep It Clean 🌿

A **full-stack Flutter mobile application** connecting volunteers with people recovering from addiction — helping them rebuild their lives through community support, courses, and structured tasks.

## Features

### 👤 Authentication
- User registration & login via **Firebase Authentication**
- Role-based access (Volunteer / Admin)

### 🏠 Core Screens
| Screen | Description |
|--------|-------------|
| **Home** | Dashboard with overview, announcements, and quick actions |
| **Tasks** | Browse and claim volunteer tasks |
| **Courses** | Educational rehabilitation courses with detail pages |
| **Map** | Find nearby volunteers and locations via **Google Maps** |
| **Chat** | Real-time messaging between volunteers and coordinators |
| **Leaderboard** | Top volunteers ranked by contribution points |
| **Attendance** | Track volunteer attendance and participation |
| **Contact** | Emergency contacts and support resources |
| **Profile** | Edit profile, view stats, upload profile picture |
| **Settings** | App preferences, language, notifications |

### 🛡️ Admin Panel
Full admin dashboard to manage:
- Volunteers & users
- Tasks assignment
- Courses management
- Attendance records
- Announcements

### 🔔 Notifications
- Push notifications via **Firebase Cloud Messaging (FCM)**

## Tech Stack

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)
![Firestore](https://img.shields.io/badge/Firestore-FF6F00?style=flat-square&logo=google&logoColor=white)
![Google Maps](https://img.shields.io/badge/Google_Maps-4285F4?style=flat-square&logo=google-maps&logoColor=white)

## Dependencies
```yaml
firebase_core, firebase_auth, cloud_firestore,
firebase_storage, firebase_messaging,
google_maps_flutter, google_fonts,
image_picker, video_player,
geolocator, url_launcher,
shared_preferences, intl
```

## Project Structure
```
lib/
├── main.dart
├── core/
│   ├── app_theme.dart
│   └── app_settings.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── main_screen.dart
│   ├── home_screen.dart
│   ├── tasks_screen.dart
│   ├── courses_screen.dart
│   ├── course_detail_screen.dart
│   ├── map_screen.dart
│   ├── chat_screen.dart
│   ├── attendance_screen.dart
│   ├── leaderboard_screen.dart
│   ├── profile_screen.dart
│   ├── edit_profile_screen.dart
│   ├── contact_screen.dart
│   ├── settings_screen.dart
│   └── admin_screen.dart
└── services/
    └── notification_service.dart
```

## Setup

1. Clone the repo
2. Run `flutter pub get`
3. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
4. Enable: Authentication, Firestore, Storage, Cloud Messaging
5. Download `google-services.json` → place in `android/app/`
6. Add your `firebase_options.dart` (use `flutterfire configure`)
7. Run: `flutter run`

## Author
**Malek Hisham Moselhy** — [LinkedIn](https://www.linkedin.com/in/malek-hisham-8005882a0) · [GitHub](https://github.com/Malek-Hisham)
