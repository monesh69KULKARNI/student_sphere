# StudentSphere Setup Guide

## Step-by-Step Setup Instructions

### 1. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "StudentSphere"
4. Follow the setup wizard

#### Enable Authentication
1. In Firebase Console, go to **Authentication**
2. Click **Get Started**
3. Enable **Email/Password** provider
4. Click **Save**

#### Create Firestore Database
1. Go to **Firestore Database**
2. Click **Create database**
3. Start in **production mode** (you'll add security rules later)
4. Choose a location close to your users
5. Click **Enable**

#### Add Firebase to Flutter
1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. Configure Firebase:
   ```bash
   flutterfire configure
   ```
   This will automatically:
   - Download configuration files
   - Add them to your project
   - Configure platform-specific settings

#### Firestore Security Rules
Add these rules in Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId || 
                     (request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Events collection
    match /events/{eventId} {
      allow read: if resource.data.isPublic == true || request.auth != null;
      allow create: if request.auth != null && 
                      (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'faculty' ||
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow update, delete: if request.auth != null && 
                              (resource.data.organizerId == request.auth.uid ||
                               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Announcements collection
    match /announcements/{announcementId} {
      allow read: if resource.data.isPublic == true || request.auth != null;
      allow create: if request.auth != null && 
                      (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'faculty' ||
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow update, delete: if request.auth != null && 
                              (resource.data.authorId == request.auth.uid ||
                               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Resources collection
    match /resources/{resourceId} {
      allow read: if resource.data.isPublic == true || request.auth != null;
      allow create: if request.auth != null && 
                      (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'faculty' ||
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow update, delete: if request.auth != null && 
                              (resource.data.uploaderId == request.auth.uid ||
                               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Achievements collection
    match /achievements/{achievementId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                      (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'faculty' ||
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow update, delete: if request.auth != null && 
                              get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Careers collection
    match /careers/{careerId} {
      allow read: if resource.data.isActive == true;
      allow create: if request.auth != null && 
                      (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'faculty' ||
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow update, delete: if request.auth != null && 
                              (resource.data.postedById == request.auth.uid ||
                               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

### 2. Supabase Setup (Optional - for file storage)

1. Go to [Supabase](https://supabase.com/)
2. Create a new project
3. Go to **Settings** → **API**
4. Copy your:
   - Project URL
   - Anon public key
5. Update `lib/core/services/supabase_service.dart`:
   ```dart
   static const String supabaseUrl = 'https://your-project.supabase.co';
   static const String supabaseAnonKey = 'your-anon-key';
   ```
6. Uncomment Supabase initialization in `lib/main.dart`:
   ```dart
   await SupabaseService.initialize();
   ```

### 3. Android Configuration

1. Ensure `google-services.json` is in `android/app/`
2. Update `android/build.gradle`:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
3. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

### 4. iOS Configuration

1. Ensure `GoogleService-Info.plist` is in `ios/Runner/`
2. Open `ios/Runner.xcworkspace` in Xcode
3. The configuration should be automatic with FlutterFire CLI

### 5. Run the App

```bash
flutter pub get
flutter run
```

## Creating Test Users

### Create Admin User (via Firebase Console)
1. Go to Authentication → Users
2. Add user manually or use the app to sign up
3. Go to Firestore → users collection
4. Find the user document
5. Update the `role` field to `"admin"`

### Create Faculty User
1. Sign up through the app with role "Faculty"
2. Or manually update role in Firestore to `"faculty"`

## Troubleshooting

### Firebase not initialized
- Ensure `google-services.json` and `GoogleService-Info.plist` are in correct locations
- Run `flutter clean` and `flutter pub get`

### Firestore permission denied
- Check security rules in Firebase Console
- Ensure user is authenticated
- Verify role assignments in Firestore

### Supabase errors
- Verify URL and key are correct
- Check Supabase project is active
- Ensure storage buckets are created if using file uploads

