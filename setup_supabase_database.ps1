# Supabase Database Setup Script
# This script will set up your Supabase database automatically

param(
    [string]$ServiceRoleKey = ""
)

$supabaseUrl = "https://dqeahphtfvqiqaprkwmi.supabase.co"
$sqlFile = "SUPABASE_DATABASE_SCHEMA.sql"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Supabase Database Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if SQL file exists
if (-not (Test-Path $sqlFile)) {
    Write-Host "❌ Error: $sqlFile not found!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found SQL schema file: $sqlFile" -ForegroundColor Green
Write-Host ""

# Read SQL file
$sqlContent = Get-Content $sqlFile -Raw

if ([string]::IsNullOrWhiteSpace($ServiceRoleKey)) {
    Write-Host "⚠️  Service Role Key not provided." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To automate this setup, you need your Supabase Service Role Key:" -ForegroundColor White
    Write-Host "1. Go to: https://app.supabase.com/project/dqeahphtfvqiqaprkwmi/settings/api" -ForegroundColor Cyan
    Write-Host "2. Find 'service_role' key (secret key)" -ForegroundColor Cyan
    Write-Host "3. Run this script again with: .\setup_supabase_database.ps1 -ServiceRoleKey 'your-key'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "OR manually:" -ForegroundColor Yellow
    Write-Host "1. Go to Supabase Dashboard → SQL Editor" -ForegroundColor White
    Write-Host "2. Copy the contents of $sqlFile" -ForegroundColor White
    Write-Host "3. Paste and run in SQL Editor" -ForegroundColor White
    Write-Host ""
    
    # Open SQL file in default editor
    $openFile = Read-Host "Open SQL file in editor? (Y/N)"
    if ($openFile -eq "Y" -or $openFile -eq "y") {
        notepad $sqlFile
    }
    
    exit 0
}

Write-Host "Setting up database via Supabase API..." -ForegroundColor Yellow
Write-Host ""

# Split SQL into individual statements (basic splitting)
$statements = $sqlContent -split ";\s*\n" | Where-Object { $_.Trim() -ne "" }

$successCount = 0
$errorCount = 0

foreach ($statement in $statements) {
    $stmt = $statement.Trim()
    if ([string]::IsNullOrWhiteSpace($stmt) -or $stmt.StartsWith("--")) {
        continue
    }
    
    try {
        $body = @{
            query = $stmt
        } | ConvertTo-Json
        
        $headers = @{
            "apikey" = $ServiceRoleKey
            "Authorization" = "Bearer $ServiceRoleKey"
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/exec_sql" -Method Post -Headers $headers -Body $body -ErrorAction Stop
        
        Write-Host "✅ Executed statement" -ForegroundColor Green
        $successCount++
    }
    catch {
        # Try alternative endpoint
        try {
            $response = Invoke-WebRequest -Uri "$supabaseUrl/rest/v1/" -Method Post -Headers $headers -Body $body -ErrorAction Stop
            Write-Host "✅ Executed statement" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host "⚠️  Could not execute via API. Please run manually in SQL Editor." -ForegroundColor Yellow
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
    }
}

if ($errorCount -gt 0) {
    Write-Host ""
    Write-Host "⚠️  Some statements could not be executed via API." -ForegroundColor Yellow
    Write-Host "   Please run the SQL manually in Supabase SQL Editor." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Manual Steps:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://app.supabase.com/project/dqeahphtfvqiqaprkwmi/sql/new" -ForegroundColor White
    Write-Host "2. Copy contents of $sqlFile" -ForegroundColor White
    Write-Host "3. Paste and click 'Run'" -ForegroundColor White
}
else {
    Write-Host ""
    Write-Host "✅ Database setup complete!" -ForegroundColor Green
    Write-Host "   Executed $successCount statements successfully" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next: Create storage buckets in Supabase Storage" -ForegroundColor Cyan

