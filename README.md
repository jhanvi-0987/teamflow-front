# TeamFlow Mobile Application (Flutter)

A modern, responsive team collaboration and project management client built with **Flutter**, **Riverpod**, and **Material 3**.

---

## Features
- **Team Chat Hub**: Real-time messaging, channels, direct messages, and typing indicators via Socket.IO.
- **Push Notifications**: Firebase Cloud Messaging (FCM) v1 with native heads-up system drawer notifications, sounds, vibration, and tap-to-open routing.
- **Live Cards & Unread Badges**: Real-time channel preview message updates and instant unread count badge incrementing.
- **Projects & Kanban**: Workspace boards, task management, status updates, and priorities.
- **Role-Based Access Control (RBAC)**: Workspace switching, invite links, and permission enforcement.
- **Clean Architecture**: Feature-first structure (`data`, `domain`, `presentation`).

---

## Getting Started

### 1. Environment Setup
Create a `.env` file in the root of `teamflow-front/`:
```env
API_BASE_URL=https://your-backend-or-devtunnel-url/api/v1
SOCKET_URL=
```

### 2. Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
flutter run --dart-define-from-file=.env
```

### 4. Run Tests
```bash
flutter test
```
*(All 32/32 unit & widget tests).*
