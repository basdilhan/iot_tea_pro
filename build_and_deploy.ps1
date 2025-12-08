<#
.SYNOPSIS
Build and deploy Tea Leaf App with all fixes applied
#>

param(
    [switch]$Clean = $false,
    [switch]$Release = $false
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Status {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Header
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Tea Leaf App - Build & Deploy" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check Flutter
Write-Status "Checking Flutter installation..."
try {
    $flutterVersion = flutter --version | Select-Object -First 1
    Write-Success "Flutter found: $flutterVersion"
} catch {
    Write-Error-Custom "Flutter not found: $_"
    exit 1
}

# Navigate to project
$projectRoot = "c:\iot\tea_leaf_app_v2"
Set-Location $projectRoot
Write-Status "Project directory: $(Get-Location)"

# Get dependencies
Write-Status "Getting Flutter dependencies..."
try {
    flutter pub get | Out-Null
    Write-Success "Dependencies retrieved"
} catch {
    Write-Error-Custom "Failed to get dependencies: $_"
    exit 1
}

# Clean if requested
if ($Clean) {
    Write-Status "Cleaning build artifacts..."
    flutter clean | Out-Null
    Write-Success "Clean completed"
    
    Write-Status "Getting dependencies again..."
    flutter pub get | Out-Null
}

# Build APK
Write-Host ""
Write-Status "Building APK..."
$buildType = if ($Release) { "release" } else { "debug" }
Write-Status "Build type: $buildType"

try {
    if ($Release) {
        flutter build apk --release
    } else {
        flutter build apk --debug
    }
    Write-Success "APK built successfully!"
} catch {
    Write-Error-Custom "Build failed: $_"
    exit 1
}

# Check APK
$apkPath = if ($Release) {
    "$projectRoot\build\app\outputs\flutter-apk\app-release.apk"
} else {
    "$projectRoot\build\app\outputs\flutter-apk\app-debug.apk"
}

if (Test-Path $apkPath) {
    $size = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
    Write-Success "APK found: $apkPath"
    Write-Success "Size: $size MB"
} else {
    Write-Error-Custom "APK not found at: $apkPath"
    exit 1
}

# Summary
Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Success "BUILD COMPLETED!"
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "Fixes Applied:" -ForegroundColor Green
Write-Host "  1. Fixed Today's Harvest showing zero" -ForegroundColor Green
Write-Host "  2. Fixed Daily Average calculation" -ForegroundColor Green  
Write-Host "  3. Enhanced OTP authentication" -ForegroundColor Green
Write-Host ""

Write-Host "APK: $apkPath" -ForegroundColor Cyan
Write-Host ""

# Optional install
$install = Read-Host "Install on device now? (y/n)"
if ($install -eq 'y') {
    Write-Status "Installing APK..."
    try {
        adb install -r "$apkPath"
        Write-Success "APK installed!"
    } catch {
        Write-Error-Custom "Install failed: $_"
    }
}

Write-Host ""
Write-Success "Done!" $Green
