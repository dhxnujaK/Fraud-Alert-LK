# Fraud Alert LK - Quick Setup Guide

## 🚀 Quick Start Instructions

### Prerequisites Installation

#### 1. Install Ballerina (Backend)
1. Visit [https://ballerina.io/downloads/](https://ballerina.io/downloads/)
2. Download Ballerina Swan Lake 2201.10.0 or later
3. Run the installer and follow installation instructions
4. Verify installation by opening Command Prompt and running:
   ```cmd
   bal version
   ```

#### 2. Install Node.js (Frontend) - Already Available ✅
Node.js is already installed on your system (version detected).

### Running the Application

#### Step 1: Start the Backend (Ballerina)

1. Open Command Prompt or PowerShell
2. Navigate to the backend directory:
   ```cmd
   cd "c:\Users\bumee\Downloads\fraud_lk\Fraud-Alert-LK\fraud-backend"
   ```
3. Start the backend:
   ```cmd
   bal run main.bal
   ```
   OR use the startup script:
   ```cmd
   start.bat
   ```

The backend will start on `http://localhost:9090`

#### Step 2: Start the Frontend (React)

1. Open a new Command Prompt or PowerShell window
2. Navigate to the frontend directory:
   ```cmd
   cd "c:\Users\bumee\Downloads\fraud_lk\Fraud-Alert-LK\fraudfrontend"
   ```
3. Install dependencies (first time only):
   ```cmd
   npm install
   ```
4. Start the frontend:
   ```cmd
   npm start
   ```
   OR use the startup script:
   ```cmd
   start.bat
   ```

The frontend will start on `http://localhost:3000`

### Testing the Application

1. Open your browser and go to `http://localhost:3000`
2. You should see the "Job Post Fraud Detection" interface
3. Upload an image of a job post
4. Click "Analyze Job Post" to test the fraud detection

### Troubleshooting

#### Backend Issues:
- **"bal is not recognized"**: Install Ballerina from the official website
- **Port already in use**: Change PORT in `fraud-backend/main.bal` from 9090 to another port
- **CORS errors**: Check that frontend is running on port 3000

#### Frontend Issues:
- **Dependencies not installed**: Run `npm install` in the fraudfrontend directory
- **Port 3000 in use**: React will automatically suggest port 3001
- **Backend connection failed**: Ensure backend is running on port 9090

### File Structure Summary

```
Fraud-Alert-LK/
├── fraud-backend/           # Ballerina backend (Port 9090)
│   ├── main.bal            # Main service file
│   ├── start.bat           # Windows startup script
│   └── Ballerina.toml      # Project configuration
│
├── fraudfrontend/          # React frontend (Port 3000)
│   ├── src/
│   │   ├── components/
│   │   │   └── FraudDetectionUpload.jsx
│   │   └── App.js
│   ├── start.bat           # Windows startup script
│   └── package.json
│
└── README.md               # Complete documentation
```

### Next Steps

1. **Install Ballerina** - This is required for the backend to work
2. **Test with sample images** - Try uploading different job post images
3. **Customize fraud patterns** - Edit detection rules in `fraud-backend/main.bal`
4. **Add real OCR integration** - Configure Google Vision or Azure Computer Vision APIs

### Demo Mode

The backend includes mock OCR functionality, so you can test the fraud detection even without real OCR services. It will return different sample job posts based on the uploaded image size.

### Contact & Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Ensure all prerequisites are installed
3. Verify ports 3000 and 9090 are available
4. Check the console for detailed error messages
