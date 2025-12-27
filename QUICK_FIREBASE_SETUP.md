# Quick Firebase Setup - 5 Minutes

## Option 1: Automatic (Easiest) ⚡

### Step 1: Run the setup script
```powershell
.\setup_firebase.ps1
```
Choose option 1 when prompted.

### Step 2: Follow the prompts
- It will open Firebase in your browser
- Login if needed
- Select or create a Firebase project
- The configuration files will be downloaded automatically

### Step 3: Enable Firebase Services
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. **Authentication** → Get Started → Enable **Email/Password**
4. **Firestore Database** → Create database → Production mode

### Step 4: Add Security Rules
Copy the rules from `SETUP.md` or `FIREBASE_SETUP_GUIDE.md` to Firestore → Rules

**Done!** ✅

---

## Option 2: Manual Setup

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name: "StudentSphere"
4. Follow the wizard

### Step 2: Add Android App
1. Click "Add app" → Android icon
2. Package name: `com.example.student_sphere`
3. Click "Register app"
4. Download `google-services.json`
5. **Place it in:** `android/app/google-services.json`

### Step 3: Add iOS App (Optional)
1. Click "Add app" → iOS icon
2. Bundle ID: `com.example.studentSphere`
3. Download `GoogleService-Info.plist`
4. **Place it in:** `ios/Runner/GoogleService-Info.plist`

### Step 4: Enable Services
1. **Authentication**:
   - Go to Authentication → Get Started
   - Enable **Email/Password** provider
   - Click Save

2. **Firestore Database**:
   - Go to Firestore Database
   - Click "Create database"
   - Start in **Production mode**
   - Choose location
   - Click Enable

### Step 5: Add Security Rules
1. Go to Firestore → Rules
2. Copy rules from `SETUP.md` or `FIREBASE_SETUP_GUIDE.md`
3. Click Publish

### Step 6: Test
```bash
flutter clean
flutter pub get
flutter run
```

---

## Verify Setup

Check these files exist:
- ✅ `android/app/google-services.json`
- ✅ `ios/Runner/GoogleService-Info.plist` (if using iOS)

---

## Troubleshooting

**"google-services.json not found"**
- Make sure file is in `android/app/` folder
- Run `flutter clean` then `flutter pub get`

**"Firebase not initialized"**
- Check that Firebase.initializeApp() is called in main.dart
- Verify google-services.json is correct

**"Permission denied"**
- Check Firestore security rules
- Make sure user is authenticated
- Verify role field exists in user document

---

## Next Steps

Once Firebase is set up:
1. ✅ Run the app: `flutter run`
2. ✅ Create a test account
3. ✅ Test login/logout
4. ✅ Create an event (as Faculty/Admin)
5. ✅ Register for event (as Student)

**You're all set!** 🚀

