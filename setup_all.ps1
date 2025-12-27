# Complete Setup Script for StudentSphere
# This script helps you set up both Firebase and Supabase

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  StudentSphere Complete Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check FlutterFire CLI
Write-Host "Checking FlutterFire CLI..." -ForegroundColor Yellow
$flutterfire = dart pub global list | Select-String "flutterfire_cli"
if (-not $flutterfire) {
    Write-Host "Installing FlutterFire CLI..." -ForegroundColor Yellow
    dart pub global activate flutterfire_cli
    Write-Host "✓ FlutterFire CLI installed!" -ForegroundColor Green
} else {
    Write-Host "✓ FlutterFire CLI is installed." -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Options:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Firebase Only (Required)" -ForegroundColor Yellow
Write-Host "2. Firebase + Supabase (Recommended)" -ForegroundColor Yellow
Write-Host "3. View Setup Guides" -ForegroundColor Yellow
Write-Host ""

$choice = Read-Host "Choose option (1, 2, or 3)"

if ($choice -eq "1") {
    Write-Host ""
    Write-Host "Setting up Firebase..." -ForegroundColor Yellow
    Write-Host "This will open Firebase in your browser..." -ForegroundColor White
    Write-Host ""
    flutterfire configure
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Enable Authentication (Email/Password) in Firebase Console" -ForegroundColor White
    Write-Host "2. Create Firestore Database" -ForegroundColor White
    Write-Host "3. Add security rules (see SETUP.md)" -ForegroundColor White
    Write-Host ""
    Write-Host "Supabase is optional - app works without it!" -ForegroundColor Cyan
    
} elseif ($choice -eq "2") {
    Write-Host ""
    Write-Host "Setting up Firebase..." -ForegroundColor Yellow
    flutterfire configure
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Now setting up Supabase..." -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Go to: https://supabase.com/" -ForegroundColor White
    Write-Host "2. Create a new project" -ForegroundColor White
    Write-Host "3. Go to Settings → API" -ForegroundColor White
    Write-Host "4. Copy your Project URL and anon key" -ForegroundColor White
    Write-Host ""
    Write-Host "Opening Supabase..." -ForegroundColor Yellow
    Start-Process "https://supabase.com/"
    
    Write-Host ""
    $url = Read-Host "Enter your Supabase URL (e.g., https://xxxxx.supabase.co)"
    $key = Read-Host "Enter your Supabase anon key"
    
    # Update the config file
    $configPath = "lib\core\config\supabase_config.dart"
    if (Test-Path $configPath) {
        $content = Get-Content $configPath -Raw
        $content = $content -replace "static const String supabaseUrl = 'YOUR_SUPABASE_URL';", "static const String supabaseUrl = '$url';"
        $content = $content -replace "static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';", "static const String supabaseAnonKey = '$key';"
        Set-Content $configPath $content
        Write-Host "✓ Supabase config updated!" -ForegroundColor Green
    } else {
        Write-Host "⚠ Config file not found. Please update manually:" -ForegroundColor Yellow
        Write-Host "   lib/core/config/supabase_config.dart" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Create storage buckets in Supabase:" -ForegroundColor White
    Write-Host "   - resources (public, 50MB)" -ForegroundColor Gray
    Write-Host "   - profile-images (public, 5MB)" -ForegroundColor Gray
    Write-Host "   - event-images (public, 10MB)" -ForegroundColor Gray
    Write-Host "2. See SUPABASE_SETUP_GUIDE.md for storage policies" -ForegroundColor White
    Write-Host ""
    
} else {
    Write-Host ""
    Write-Host "Setup Guides:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Firebase:" -ForegroundColor Cyan
    Write-Host "  - QUICK_FIREBASE_SETUP.md" -ForegroundColor White
    Write-Host "  - FIREBASE_SETUP_GUIDE.md" -ForegroundColor White
    Write-Host ""
    Write-Host "Supabase:" -ForegroundColor Cyan
    Write-Host "  - QUICK_SUPABASE_SETUP.md" -ForegroundColor White
    Write-Host "  - SUPABASE_SETUP_GUIDE.md" -ForegroundColor White
    Write-Host ""
    Write-Host "Opening guides..." -ForegroundColor Yellow
    Start-Process "QUICK_FIREBASE_SETUP.md"
    Start-Process "QUICK_SUPABASE_SETUP.md"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Run 'flutter run' to test the app." -ForegroundColor Green

