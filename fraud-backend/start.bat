@echo off
echo Starting Fraud Detection Backend...
echo.

REM Check if Ballerina is installed
bal version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Ballerina is not installed or not in PATH
    echo Please install Ballerina from https://ballerina.io/downloads/
    pause
    exit /b 1
)

REM Create uploads directory if it doesn't exist
if not exist "uploads" (
    mkdir uploads
    echo Created uploads directory
)

REM Build and run the project
echo Building project...
bal build
if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Starting server on http://localhost:9090
echo Press Ctrl+C to stop the server
echo.

bal run

pause
