@echo off
echo Starting Node.js Fraud Detection Backend...
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js from: https://nodejs.org/
    pause
    exit /b 1
)

REM Check if npm is installed
where npm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: npm is not installed or not in PATH
    pause
    exit /b 1
)

echo Node.js found! Installing dependencies...
echo.

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
    echo Installing npm packages...
    npm install
    if %ERRORLEVEL% NEQ 0 (
        echo Failed to install dependencies!
        pause
        exit /b 1
    )
)

REM Create uploads directory if it doesn't exist
if not exist "uploads" (
    mkdir uploads
    echo Created uploads directory
)

echo.
echo Starting Fraud Detection Backend...
echo Backend will be available at: http://localhost:9090
echo Health check: http://localhost:9090/fraud-detection/health
echo.

REM Start the Node.js server
npm start

pause
