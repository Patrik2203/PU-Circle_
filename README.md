# pu_circle

A# PU Circle - Social Networking App

## 📌 Project Overview
PU Circle is a social networking app built using **Flutter**. It provides features such as user authentication, post creation, messaging, match-making, and an admin dashboard for content moderation.

## 📂 Project Structure

```
lib/
├── main.dart
├── firebase/
│   ├── auth_service.dart
│   ├── storage_service.dart
│   ├── firestore_service.dart
│   └── notification_service.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── admin_login_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   ├── post_detail_screen.dart
│   │   └── create_post_screen.dart
│   ├── match/
│   │   ├── match_screen.dart
│   │   └── match_detail_screen.dart
│   ├── profile/
│   │   ├── profile_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   └── followers_screen.dart
│   ├── messaging/
│   │   ├── chat_list_screen.dart
│   │   └── chat_screen.dart
│   ├── notifications/
│   │   └── notification_screen.dart
│   └── admin/
│       ├── admin_dashboard.dart
│       ├── user_management.dart
│       └── content_moderation.dart
├── utils/
│   ├── colors.dart
│   ├── constants.dart
│   ├── theme.dart
│   └── helpers.dart
├── models/
│   ├── user_model.dart
│   ├── post_model.dart
│   ├── match_model.dart
│   ├── chat_model.dart
│   └── notification_model.dart
└── widgets/
    ├── common_widgets.dart
    ├── post_widget.dart
    ├── profile_card_widget.dart
    └── chat_bubble_widget.dart
```

## 🔥 Features
- **User Authentication** (Login, Signup, Admin Login)
- **Post Creation & Details**
- **Match-Making System**
- **Profile Management**
- **Messaging System (Chat)**
- **Notifications**
- **Admin Dashboard (User Management & Content Moderation)**

## 🚀 Installation
1. Clone the repository:
   ```sh
   git clone https://github.com/your-repo/pu_circle.git
   cd pu_circle
   ```
2. Install dependencies:
   ```sh
   flutter pub get
   ```
3. Set up Firebase:
    - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) inside the `android/app/` and `ios/` folders respectively.
    - Run:
      ```sh
      cd ios
      pod install
      ```
4. Run the app:
   ```sh
   flutter run
   ```

## 📜 Dependencies
- **Firebase Authentication** - User login/signup
- **Cloud Firestore** - Database for storing posts, messages, and user data
- **Firebase Storage** - Storing media files
- **Firebase Messaging** - Push notifications
- **Provider/Riverpod** - State management (if applicable)

## 🛠 Contribution
1. Fork the repository.
2. Create a new branch:
   ```sh
   git checkout -b feature-name
   ```
3. Make changes and commit:
   ```sh
   git commit -m "Added new feature"
   ```
4. Push and create a pull request.

## 📄 License
This project is licensed under the MIT License.
