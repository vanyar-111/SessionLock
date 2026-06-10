@echo off
REM ============================================================
REM  BankGuard AI (SessionLock) - Easy Deploy (CMD)
REM  Usage:  deploy.bat [apk|aab|web|windows|all|clean|doctor]
REM ============================================================

setlocal
set TARGET=%1
if "%TARGET%"=="" set TARGET=help

REM -- Check Flutter --
where flutter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter not found in PATH.
    echo         Install from https://docs.flutter.dev/get-started/install
    exit /b 1
)

if /i "%TARGET%"=="apk"     goto :apk
if /i "%TARGET%"=="aab"     goto :aab
if /i "%TARGET%"=="web"     goto :web
if /i "%TARGET%"=="windows" goto :windows
if /i "%TARGET%"=="all"     goto :all
if /i "%TARGET%"=="clean"   goto :clean
if /i "%TARGET%"=="doctor"  goto :doctor
goto :help

:apk
echo.
echo === Building Android APK (Release) ===
flutter pub get
flutter build apk --release
echo.
echo Done. APK at: build\app\outputs\flutter-apk\app-release.apk
goto :eof

:aab
echo.
echo === Building Android App Bundle (Release) ===
flutter pub get
flutter build appbundle --release
echo.
echo Done. AAB at: build\app\outputs\bundle\release\app-release.aab
goto :eof

:web
echo.
echo === Building Web App (Release) ===
flutter pub get
flutter build web --release
echo.
echo Done. Web output at: build\web\
echo To preview: cd build\web ^& python -m http.server 8080
goto :eof

:windows
echo.
echo === Building Windows Desktop App (Release) ===
flutter pub get
flutter build windows --release
echo.
echo Done. Windows output at: build\windows\x64\runner\Release\
goto :eof

:all
call :apk
call :aab
call :web
call :windows
echo.
echo === All builds complete ===
goto :eof

:clean
echo.
echo === Cleaning build artifacts ===
flutter clean
if exist deploy_output rmdir /s /q deploy_output
echo Done.
goto :eof

:doctor
echo.
flutter doctor -v
goto :eof

:help
echo.
echo  BankGuard AI - Deployment Script
echo  ================================
echo  Usage:  deploy.bat ^<target^>
echo.
echo  Targets:
echo    apk       Build release APK (Android)
echo    aab       Build App Bundle for Play Store
echo    web       Build for web deployment
echo    windows   Build Windows desktop executable
echo    all       Build all platforms
echo    clean     Remove build artifacts
echo    doctor    Check Flutter environment
echo.
goto :eof
