# StudentSphere — Smart Campus Ecosystem

StudentSphere is a **full-scale, production-oriented Smart Campus Application** designed to digitally transform how colleges communicate, operate, and engage with students, faculty, administrators, and the public.

## 🎯 Features

### User Roles
- **Student**: View events, access resources, track achievements, explore career opportunities
- **Faculty**: Create events, upload resources, post announcements, award achievements
- **Administrator**: Full system control and user management
- **Guest**: Public view of college information (no authentication required)

### Core Modules
- ✅ **Authentication & User Management** (Firebase Auth)
- ✅ **Event Management** with registration and volunteer options
- ✅ **Resource Sharing** (Notes, PDFs, Videos)
- ✅ **Announcements System**
- ✅ **Achievement & Recognition System**
- ✅ **Career Guidance** (Internships, Jobs, Workshops)
- ✅ **Role-Based Dashboards**
- ✅ **Real-time Chat System** with group chats and direct messaging

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Firebase project
- Supabase account (for chat backend)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/monesh69KULKARNI/student_sphere.git
   cd student_sphere
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Create a Firestore database
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`

4. **Supabase Setup** (Required for Chat)
   - Create a Supabase project at [Supabase](https://supabase.com/)
   - Get your project URL and anon key
   - Update `lib/core/services/supabase_service.dart`:
     ```dart
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
     ```
   - Set up the required database tables (see `migrate_chat_to_text_ids.sql`)

5. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/          # App constants
│   ├── models/              # Data models
│   ├── providers/           # State management
│   └── services/            # Business logic & API calls
├── screens/
│   ├── auth/                # Authentication screens
│   ├── student/             # Student dashboard & screens
│   ├── faculty/             # Faculty dashboard & screens
│   ├── admin/               # Admin dashboard & screens
│   ├── guest/               # Guest/public screens
│   ├── events/              # Event management
│   ├── resources/           # Resource sharing
│   ├── announcements/       # Announcements
│   ├── achievements/        # Achievements
│   ├── careers/             # Career opportunities
│   └── chat/                # Chat system
└── main.dart                # App entry point
```

## 🔐 Security

- Firebase Authentication for secure user management
- Role-based access control (RBAC)
- Firestore security rules (configure in Firebase Console)
- Supabase Row Level Security for chat data

## 🗄️ Database Structure

### Firestore Collections
- `users` - User profiles and roles
- `events` - Event information
- `announcements` - Campus announcements
- `resources` - Resource metadata
- `achievements` - Student achievements
- `careers` - Career opportunities

### Supabase Tables (Chat System)
- `chat_rooms` - Chat room information
- `chat_participants` - Chat room participants
- `messages` - Chat messages
- `typing_indicators` - Real-time typing status

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📱 Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🔮 Recent Enhancements

- ✅ **Real-time Chat System** - Group chats and direct messaging
- ✅ **Null Safety Fixes** - Robust error handling throughout the app
- ✅ **UUID Type Compatibility** - Fixed database type mismatches
- ✅ **Duplicate Prevention** - Robust participant management in group chats

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For issues and questions, please open an issue on GitHub.

---

**One platform. One campus. Zero missed opportunities.**
