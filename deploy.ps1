<#
.SYNOPSIS
    BankGuard AI (SessionLock) - Easy Deployment Script
.DESCRIPTION
    Build and deploy the Flutter app for Android (APK/AAB), Web, or Windows.
    Run from the project root directory.
.EXAMPLE
    .\deploy.ps1 apk          # Build a release APK
    .\deploy.ps1 aab          # Build an Android App Bundle (Play Store)
    .\deploy.ps1 web          # Build for Web deployment
    .\deploy.ps1 windows      # Build a Windows desktop app
    .\deploy.ps1 all          # Build for all platforms
    .\deploy.ps1 clean        # Clean build artifacts
    .\deploy.ps1 doctor       # Run flutter doctor to check environment
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet("apk", "aab", "web", "windows", "all", "clean", "doctor", "help")]
    [string]$Target = "help"
)

# ── Configuration ────────────────────────────────────────────────────────────
$ProjectRoot  = $PSScriptRoot
$BuildOutput  = Join-Path $ProjectRoot "build"
$DeployDir    = Join-Path $ProjectRoot "deploy_output"
$AppName      = "BankGuard AI"
$Timestamp    = Get-Date -Format "yyyyMMdd_HHmmss"

# ── Helpers ──────────────────────────────────────────────────────────────────
function Write-Banner {
    param([string]$Message)
    $line = "=" * 60
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor White
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "  >> $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Err {
    param([string]$Message)
    Write-Host "  [ERROR] $Message" -ForegroundColor Red
}

function Assert-Flutter {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Write-Err "Flutter SDK not found in PATH. Install Flutter first: https://docs.flutter.dev/get-started/install"
        exit 1
    }
}

function Ensure-DeployDir {
    if (-not (Test-Path $DeployDir)) {
        New-Item -ItemType Directory -Path $DeployDir -Force | Out-Null
    }
}

function Run-FlutterPubGet {
    Write-Step "Fetching dependencies (flutter pub get)..."
    flutter pub get --directory $ProjectRoot
    if ($LASTEXITCODE -ne 0) {
        Write-Err "flutter pub get failed."
        exit 1
    }
    Write-Success "Dependencies resolved."
}

# ── Build Targets ────────────────────────────────────────────────────────────

function Build-APK {
    Write-Banner "Building Android APK (Release)"
    Run-FlutterPubGet

    Write-Step "Running: flutter build apk --release"
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { Write-Err "APK build failed."; return }

    Ensure-DeployDir
    $src = Join-Path $BuildOutput "app\outputs\flutter-apk\app-release.apk"
    $dst = Join-Path $DeployDir "bankguard_ai_$Timestamp.apk"
    if (Test-Path $src) {
        Copy-Item $src $dst -Force
        Write-Success "APK copied to: $dst"
    } else {
        Write-Success "APK built. Check: $BuildOutput\app\outputs\flutter-apk\"
    }
}

function Build-AAB {
    Write-Banner "Building Android App Bundle (Release)"
    Run-FlutterPubGet

    Write-Step "Running: flutter build appbundle --release"
    flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) { Write-Err "AAB build failed."; return }

    Ensure-DeployDir
    $src = Join-Path $BuildOutput "app\outputs\bundle\release\app-release.aab"
    $dst = Join-Path $DeployDir "bankguard_ai_$Timestamp.aab"
    if (Test-Path $src) {
        Copy-Item $src $dst -Force
        Write-Success "AAB copied to: $dst"
    } else {
        Write-Success "AAB built. Check: $BuildOutput\app\outputs\bundle\release\"
    }
}

function Build-Web {
    Write-Banner "Building Web App (Release)"
    Run-FlutterPubGet

    Write-Step "Running: flutter build web --release"
    flutter build web --release
    if ($LASTEXITCODE -ne 0) { Write-Err "Web build failed."; return }

    Ensure-DeployDir
    $src = Join-Path $BuildOutput "web"
    $dst = Join-Path $DeployDir "web_$Timestamp"
    Copy-Item $src $dst -Recurse -Force
    Write-Success "Web build copied to: $dst"
    Write-Host ""
    Write-Host "  To preview locally:" -ForegroundColor Magenta
    Write-Host "    cd `"$dst`"" -ForegroundColor Gray
    Write-Host "    python -m http.server 8080" -ForegroundColor Gray
    Write-Host "    # Then open http://localhost:8080" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  To deploy to Firebase Hosting:" -ForegroundColor Magenta
    Write-Host "    firebase init hosting   # one-time setup" -ForegroundColor Gray
    Write-Host "    firebase deploy --only hosting" -ForegroundColor Gray
    Write-Host ""
}

function Build-Windows {
    Write-Banner "Building Windows Desktop App (Release)"
    Run-FlutterPubGet

    Write-Step "Running: flutter build windows --release"
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { Write-Err "Windows build failed."; return }

    Ensure-DeployDir
    $src = Join-Path $BuildOutput "windows\x64\runner\Release"
    $dst = Join-Path $DeployDir "windows_$Timestamp"
    if (Test-Path $src) {
        Copy-Item $src $dst -Recurse -Force
        Write-Success "Windows build copied to: $dst"
        Write-Host "  Run it:  $dst\bankguard_ai.exe" -ForegroundColor Gray
    } else {
        Write-Success "Build complete. Check: $BuildOutput\windows\"
    }
}

function Invoke-Clean {
    Write-Banner "Cleaning Build Artifacts"
    Write-Step "Running: flutter clean"
    flutter clean
    if (Test-Path $DeployDir) {
        Write-Step "Removing deploy_output directory..."
        Remove-Item $DeployDir -Recurse -Force
    }
    Write-Success "Clean complete."
}

function Invoke-Doctor {
    Write-Banner "Flutter Doctor"
    flutter doctor -v
}

function Build-All {
    Write-Banner "Building All Platforms"
    Build-APK
    Build-AAB
    Build-Web
    Build-Windows
    Write-Banner "All Builds Complete"
    Write-Host "  Artifacts are in: $DeployDir" -ForegroundColor Green
}

function Show-Help {
    Write-Banner "$AppName - Deployment Script"
    Write-Host "  Usage:  .\deploy.ps1 <target>" -ForegroundColor White
    Write-Host ""
    Write-Host "  Targets:" -ForegroundColor Yellow
    Write-Host "    apk       Build a release APK (Android)" -ForegroundColor Gray
    Write-Host "    aab       Build an App Bundle for Play Store (Android)" -ForegroundColor Gray
    Write-Host "    web       Build for web deployment" -ForegroundColor Gray
    Write-Host "    windows   Build a Windows desktop executable" -ForegroundColor Gray
    Write-Host "    all       Build for all platforms above" -ForegroundColor Gray
    Write-Host "    clean     Remove all build artifacts" -ForegroundColor Gray
    Write-Host "    doctor    Check Flutter environment" -ForegroundColor Gray
    Write-Host "    help      Show this help message" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Examples:" -ForegroundColor Yellow
    Write-Host "    .\deploy.ps1 apk" -ForegroundColor Gray
    Write-Host "    .\deploy.ps1 web" -ForegroundColor Gray
    Write-Host "    .\deploy.ps1 all" -ForegroundColor Gray
    Write-Host ""
}

# ── Main ─────────────────────────────────────────────────────────────────────
Assert-Flutter

switch ($Target) {
    "apk"     { Build-APK }
    "aab"     { Build-AAB }
    "web"     { Build-Web }
    "windows" { Build-Windows }
    "all"     { Build-All }
    "clean"   { Invoke-Clean }
    "doctor"  { Invoke-Doctor }
    "help"    { Show-Help }
}
