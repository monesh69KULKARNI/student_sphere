# Firebase Setup Guide for StudentSphere

## Quick Setup (Recommended - Using FlutterFire CLI)

This is the easiest way to set up Firebase. It will automatically download and configure everything.

### Step 1: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### Step 2: Login to Firebase

```bash
firebase login
```

### Step 3: Configure Firebase

Run this command in your project root:

```bash
flutterfire configure
```

This will:
- ✅ Detect your Firebase projects
- ✅ Let you select or create a Firebase project
- ✅ Download `google-services.json` for Android
- ✅ Download `GoogleService-Info.plist` for iOS
- ✅ Configure your Flutter app automatically

### Step 4: Verify Setup

Check that these files exist:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### Step 5: Enable Firebase Services

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Enable **Authentication**:
   - Go to Authentication → Get Started
   - Enable **Email/Password** provider
4. Create **Firestore Database**:
   - Go to Firestore Database → Create database
   - Start in **production mode** (we'll add rules)
   - Choose a location

### Step 6: Add Firestore Security Rules

Go to Firestore → Rules and paste these rules:

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

### Step 7: Test the App

```bash
flutter run
```

---

## Manual Setup (Alternative)

If you prefer to set up manually:

### 1. Create Firebase Project
- Go to [Firebase Console](https://console.firebase.google.com/)
- Click "Add project"
- Enter project name: "StudentSphere"
- Follow the wizard

### 2. Add Android App
- Click "Add app" → Android
- Package name: `com.example.student_sphere`
- Download `google-services.json`
- Place it in `android/app/google-services.json`

### 3. Add iOS App (if needed)
- Click "Add app" → iOS
- Bundle ID: `com.example.studentSphere`
- Download `GoogleService-Info.plist`
- Place it in `ios/Runner/GoogleService-Info.plist`

### 4. Enable Services
- Authentication → Enable Email/Password
- Firestore → Create database

---

## Troubleshooting

### Error: "google-services.json not found"
- Make sure the file is in `android/app/google-services.json`
- Run `flutter clean` and `flutter pub get`

### Error: "Firebase not initialized"
- Check that Firebase is initialized in `main.dart`
- Verify `google-services.json` is correct

### Error: "Permission denied" in Firestore
- Check security rules
- Make sure user is authenticated
- Verify role is set correctly in Firestore

---

## Next Steps

Once Firebase is configured:
1. ✅ Run the app
2. ✅ Create a test account
3. ✅ Test authentication
4. ✅ Create events
5. ✅ Test role-based access

Your app is ready to use! 🚀

