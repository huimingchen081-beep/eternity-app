@echo off
cd /d D:\eternity_app
echo ============================================
echo  Starting release APK build...
echo  This will take 10-20 minutes.
echo  Do NOT close this window!
echo ============================================
echo.
D:\flutter\bin\flutter build apk --release --target-platform android-arm64
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ============================================
    echo  BUILD FAILED! Error code: %ERRORLEVEL%
    echo ============================================
    echo.
    pause
    exit /b 1
)
echo.
echo ============================================
echo  Build complete! APK location:
echo  D:\eternity_app\build\app\outputs\flutter-apk\app-release.apk
echo ============================================
pause
