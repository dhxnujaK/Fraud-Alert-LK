# Fraud Alert LK - Job Post Fraud Detection System

A comprehensive fraud detection system for job posts in Sri Lanka, using AI-powered image analysis and text extraction.

## 🚀 Features

- **Image Upload & OCR**: Upload job post images and extract text using OCR technology
- **AI-Powered Analysis**: Advanced fraud detection algorithms analyze job posts for suspicious patterns
- **Real-time Risk Assessment**: Get instant fraud scores and risk levels
- **Comprehensive Reporting**: Detailed analysis with suspicious keywords and recommendations
- **Modern UI**: Clean, responsive React frontend
- **Robust Backend**: High-performance Ballerina backend with CORS support

## 📋 Prerequisites

### For Backend (Ballerina):
- [Ballerina Swan Lake 2201.10.0+](https://ballerina.io/downloads/)
- Java 11 or later

### For Frontend (React):
- [Node.js 16+](https://nodejs.org/)
- npm (comes with Node.js)

## 🛠️ Installation & Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd Fraud-Alert-LK
```

### 2. Backend Setup

```bash
cd fraud-backend

# Install Ballerina dependencies (automatic on first run)
bal build

# Start the backend server
# Option 1: Use the startup script
start.bat

# Option 2: Run directly
bal run main.bal
```

The backend will start on `http://localhost:9090`

### 3. Frontend Setup

```bash
cd fraudfrontend

# Install dependencies
npm install

# Start the development server
# Option 1: Use the startup script
start.bat

# Option 2: Run directly
npm start
```

The frontend will start on `http://localhost:3000`

## 🔧 Configuration

### Backend Configuration (Config.toml)

```toml
# Server Configuration
PORT = 9090
UPLOAD_PATH = "./uploads"

# Fraud Detection Settings
FRAUD_THRESHOLD = 60.0
MAX_FILE_SIZE = 10485760  # 10MB

# OCR Service Configuration (Optional)
GOOGLE_VISION_API_KEY = ""
AZURE_VISION_ENDPOINT = ""
AZURE_VISION_KEY = ""
```

## 📚 API Documentation

### Health Check
```
GET /fraud-detection/health
```
Response:
```json
{
  "status": "healthy",
  "timestamp": "2024-08-08T10:00:00Z",
  "service": "Fraud Detection Backend"
}
```

### Analyze Job Post Image
```
POST /fraud-detection/analyze
Content-Type: multipart/form-data
```

Request:
- `image`: Image file (JPEG, PNG, etc.)

Response:
```json
{
  "message": "Image analyzed successfully",
  "jobPost": {
    "id": "uuid-string",
    "extractedText": "Job post content...",
    "fraudScore": 75.5,
    "isFraudulent": true,
    "suspiciousKeywords": ["registration fee", "urgent hiring"],
    "timestamp": "2024-08-08T10:00:00Z"
  },
  "error": false
}
```

### Analyze Text (Testing)
```
POST /fraud-detection/analyze-text
Content-Type: application/json
```

Request:
```json
{
  "text": "Job post content to analyze..."
}
```

## 🎯 Fraud Detection Patterns

### High Risk Indicators (Critical)
- Registration fees or advance payments
- Processing fees or deposits
- "Pay first" schemes
- Guaranteed income promises
- Unrealistic salary with no qualifications

### Medium Risk Indicators
- Work from home opportunities
- Urgent hiring calls
- WhatsApp-only contact
- Copy-paste job descriptions
- Limited time offers

### Low Risk Indicators
- No experience required
- Data entry positions
- High salary promises

## 🔍 How It Works

1. **Image Upload**: User uploads a job post image
2. **OCR Processing**: System extracts text from the image
3. **Pattern Analysis**: Advanced algorithms analyze text for fraud indicators
4. **Risk Scoring**: Calculate fraud score based on suspicious patterns
5. **Report Generation**: Provide detailed analysis with recommendations

## 🧪 Testing

### Backend Tests
```bash
cd fraud-backend
bal test
```

### Frontend Tests
```bash
cd fraudfrontend
npm test
```

## 🚀 Deployment

### Using Docker

#### Backend
```bash
cd fraud-backend
docker build -t fraud-backend .
docker run -p 9090:9090 fraud-backend
```

#### Frontend
```bash
cd fraudfrontend
npm run build
# Serve the build folder with your preferred web server
```

### Manual Deployment

#### Backend
```bash
cd fraud-backend
bal build
# Deploy the generated .jar file to your server
```

#### Frontend
```bash
cd fraudfrontend
npm run build
# Deploy the build folder to your web server
```

## 🔧 Development

### Project Structure
```
Fraud-Alert-LK/
├── fraud-backend/           # Ballerina backend
│   ├── main.bal            # Main service
│   ├── ocr_service.bal     # OCR integration
│   ├── fraud_patterns.bal  # Fraud detection rules
│   ├── Ballerina.toml      # Project configuration
│   └── Config.toml         # Runtime configuration
├── fraudfrontend/          # React frontend
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── App.js         # Main app component
│   │   └── index.js       # Entry point
│   └── package.json       # Dependencies
└── README.md              # This file
```

### Adding New Fraud Patterns

Edit `fraud-backend/fraud_patterns.bal` and add new patterns:

```ballerina
{
    pattern: ".*your-regex-pattern.*",
    description: "Description of the fraud indicator",
    weight: 25.0,
    category: "CATEGORY_NAME"
}
```

### Integrating Real OCR Services

Update `fraud-backend/ocr_service.bal` with your OCR API credentials:

1. Google Cloud Vision API
2. Azure Computer Vision
3. AWS Textract
4. Tesseract OCR

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Email: support@fraudalert.lk (if applicable)

## 🔄 Changelog

### v1.0.0
- Initial release
- Basic fraud detection functionality
- React frontend with image upload
- Ballerina backend with OCR integration
- Pattern-based fraud analysis

## 🛡️ Security

This system is designed to help identify potentially fraudulent job posts but should not be the only verification method. Always:

- Verify job posts through official company channels
- Never pay fees for job applications
- Research companies independently
- Be cautious of unrealistic promises

## 🎨 UI Screenshots

[Add screenshots of your application here]

## 🌟 Acknowledgments

- Ballerina Language Team
- React Development Team
- Contributors and testers
