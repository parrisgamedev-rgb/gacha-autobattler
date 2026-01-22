@echo off
echo ========================================
echo  Gacha Autobattler Content Editor
echo  Build Script
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.10+ from https://www.python.org/
    pause
    exit /b 1
)

echo Installing dependencies...
pip install -r requirements.txt

echo.
echo Building executable...
pyinstaller --onefile --windowed --name "ContentEditor" --icon=NONE editor.py

echo.
echo ========================================
echo  Build complete!
echo  Executable: dist\ContentEditor.exe
echo ========================================
pause
