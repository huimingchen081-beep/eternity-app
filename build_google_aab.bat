@echo off
title Eternity AAB Build
echo ========================================
echo  Eternity Google Play AAB Build
echo  Version: 1.0.0+4
echo ========================================
echo.
echo Step 1: Cleaning old build cache...
cd /d "D:\eternity_app"
if exist "build" (
    echo Removing build folder...
    rmdir /s /q "build" 2>nul
)
echo Done.
echo.
echo Step 2: Building AAB (optimized, 2-5 minutes)...
echo.
call D:\flutter\bin\flutter.bat build appbundle --release --no-tree-shake-icons --no-shrink
if %ERRORLEVEL% == 0 (
    echo ========================================
    echo  BUILD SUCCESS!
    echo ========================================
    echo.
    for /r "build\app\outputs\bundle" %%f in (*.aab) do (
        echo AAB file: %%f
        echo Size: %%~zf bytes
    )
) else (
    echo ========================================
    echo  BUILD FAILED! Error: %ERRORLEVEL%
    echo ========================================
)
echo.
pause
