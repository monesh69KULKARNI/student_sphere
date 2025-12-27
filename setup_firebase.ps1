# Firebase Setup Helper Script for StudentSphere
# This script helps you set up Firebase configuration

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  StudentSphere Firebase Setup Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if FlutterFire CLI is installed
Write-Host "Checking FlutterFire CLI..." -ForegroundColor Yellow
$flutterfire = dart pub global list | Select-String "flutterfire_cli"
if (-not $flutterfire) {
    Write-Host "FlutterFire CLI not found. Installing..." -ForegroundColor Yellow
    dart pub global activate flutterfire_cli
    Write-Host "FlutterFire CLI installed!" -ForegroundColor Green
} else {
    Write-Host "FlutterFire CLI is installed." -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Options:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Automatic Setup (Recommended)" -ForegroundColor Yellow
Write-Host "   - Run: flutterfire configure" -ForegroundColor White
Write-Host "   - This will automatically download and configure Firebase" -ForegroundColor White
Write-Host ""
Write-Host "2. Manual Setup" -ForegroundColor Yellow
Write-Host "   - Follow instructions in FIREBASE_SETUP_GUIDE.md" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Choose option (1 or 2)"

if ($choice -eq "1") {
    Write-Host ""
    Write-Host "Running flutterfire configure..." -ForegroundColor Yellow
    Write-Host "This will open Firebase in your browser..." -ForegroundColor White
    Write-Host ""
    flutterfire configure
} else {
    Write-Host ""
    Write-Host "Manual Setup Instructions:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Go to: https://console.firebase.google.com/" -ForegroundColor White
    Write-Host "2. Create a new project or select existing one" -ForegroundColor White
    Write-Host "3. Add Android app:" -ForegroundColor White
    Write-Host "   - Package name: com.example.student_sphere" -ForegroundColor Gray
    Write-Host "   - Download google-services.json" -ForegroundColor Gray
    Write-Host "   - Place in: android/app/google-services.json" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Add iOS app (if needed):" -ForegroundColor White
    Write-Host "   - Bundle ID: com.example.studentSphere" -ForegroundColor Gray
    Write-Host "   - Download GoogleService-Info.plist" -ForegroundColor Gray
    Write-Host "   - Place in: ios/Runner/GoogleService-Info.plist" -ForegroundColor Gray
    Write-Host ""
    Write-Host "5. Enable Authentication:" -ForegroundColor White
    Write-Host "   - Go to Authentication → Get Started" -ForegroundColor Gray
    Write-Host "   - Enable Email/Password provider" -ForegroundColor Gray
    Write-Host ""
    Write-Host "6. Create Firestore Database:" -ForegroundColor White
    Write-Host "   - Go to Firestore Database → Create database" -ForegroundColor Gray
    Write-Host "   - Start in production mode" -ForegroundColor Gray
    Write-Host ""
    Write-Host "See FIREBASE_SETUP_GUIDE.md for detailed instructions and security rules." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Setup complete! Run 'flutter run' to test the app." -ForegroundColor Green

