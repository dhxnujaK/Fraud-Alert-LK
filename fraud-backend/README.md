# Fraud Detection Backend

A Ballerina-based backend service for detecting fraudulent job posts through image text extraction and AI-powered analysis.

## Features

- **Image Upload & OCR**: Upload job post images and extract text using OCR services
- **Fraud Detection**: Advanced pattern matching and scoring algorithm to detect fraudulent job posts
- **Multiple OCR Support**: Integration with Google Vision API, Azure Computer Vision, with fallback options
- **RESTful API**: Clean REST endpoints for frontend integration
- **Comprehensive Analysis**: Detailed fraud scoring with risk levels and recommendations
- **CORS Support**: Configured for frontend integration
- **Docker Support**: Easy deployment with Docker and Docker Compose

## Prerequisites

- Ballerina 2201.10.0 or later
- Java 11 or later
- Docker (optional, for containerized deployment)

## Installation

### Local Development Setup

1. **Install Ballerina**
   ```bash
   # Download from https://ballerina.io/downloads/
   # Or use package manager (Windows)
   choco install ballerina
   ```

2. **Clone and Setup**
   ```bash
   cd fraud-backend
   ```

3. **Install Dependencies**
   ```bash
   bal build
   ```

4. **Configure OCR Services (Optional)**
   
   Create a `Config.toml` file in the project root:
   ```toml
   # Google Vision API
   GOOGLE_VISION_API_KEY = "your_google_vision_api_key"
   
   # Azure Computer Vision
   AZURE_VISION_ENDPOINT = "https://your-resource.cognitiveservices.azure.com/"
   AZURE_VISION_KEY = "your_azure_vision_key"
   
   # Server Configuration
   PORT = 8080
   UPLOAD_PATH = "./uploads"
   ```

5. **Run the Service**
   ```bash
   bal run
   ```

The service will start on `http://localhost:8080`

### Docker Deployment

1. **Build Docker Image**
   ```bash
   docker build -t fraud-detection-backend .
   ```

2. **Run with Docker Compose**
   ```bash
   docker-compose up -d
   ```

## API Endpoints

### Health Check
```
GET /fraud-detection/health
```
Returns service health status.

### Analyze Job Post Image
```
POST /fraud-detection/analyze
Content-Type: multipart/form-data

Form Data:
- image: [image file] (REQUIRED)
```

**Response:**
```json
{
  "message": "Image analyzed successfully",
  "jobPost": {
    "id": "uuid",
    "extractedText": "...",
    "isFraudulent": true,
    "fraudScore": 85.5,
    "suspiciousKeywords": ["registration fee", "guaranteed income"],
    "timestamp": "2025-08-08T10:30:00Z"
  }
}
```

### Analyze Text (Testing)
```
POST /fraud-detection/analyze-text
Content-Type: application/json

{
  "text": "Job post text to analyze..."
}
```

**Response:**
```json
{
  "isFraudulent": true,
  "fraudScore": 75.0,
  "suspiciousKeywords": ["quick money", "no experience"],
  "reasoning": "Analysis based on: Payment of fees required. Registration fee mentioned. ..."
}
```

## Fraud Detection Algorithm

### Scoring System
The fraud detection uses a weighted scoring system:

- **Payment Requirements** (25-35 points): Registration fees, processing fees, security deposits
- **Unrealistic Promises** (20-25 points): Guaranteed income, quick money schemes
- **No Requirements** (10-15 points): No experience needed, any qualification accepted
- **Pressure Tactics** (10-15 points): Urgent hiring, limited seats
- **Contact Issues** (8-15 points): Informal communication, free email services
- **MLM Indicators** (20-25 points): Referral schemes, network marketing

### Risk Levels
- **CRITICAL** (80-100): Immediate rejection recommended
- **HIGH** (60-79): High fraud probability, extreme caution
- **MEDIUM** (40-59): Some concerning elements, research required
- **LOW** (20-39): Minor red flags, normal caution
- **MINIMAL** (0-19): Appears legitimate, verify as usual

### Pattern Examples
```regex
# Registration fee detection
.*registration.*fee.*

# Guaranteed income
.*(?:guaranteed|assured).*(?:income|salary).*

# Unrealistic earnings
.*earn.*(?:lakhs|50000|100000).*(?:month|monthly).*

# Pressure tactics
.*(?:urgent|immediate).*(?:hiring|joining).*
```

## OCR Integration

### Supported Services

1. **Google Cloud Vision API**
   - High accuracy text detection
   - Supports multiple languages
   - Requires API key

2. **Azure Computer Vision**
   - Robust OCR capabilities
   - Good for handwritten text
   - Requires endpoint and subscription key

3. **Fallback Simulation**
   - For development/testing
   - Returns sample fraudulent job post text

### Adding New OCR Services

Implement in `ocr_service.bal`:

```ballerina
public function extractTextWithNewService(string imagePath) returns OCRResult {
    // Your OCR service integration
    return {
        success: true,
        text: extractedText,
        errorMessage: ()
    };
}
```

## Configuration

### Environment Variables

- `PORT`: Server port (default: 8080)
- `UPLOAD_PATH`: Directory for uploaded files (default: ./uploads)
- `GOOGLE_VISION_API_KEY`: Google Vision API key
- `AZURE_VISION_ENDPOINT`: Azure Vision endpoint URL
- `AZURE_VISION_KEY`: Azure Vision subscription key

### Fraud Keywords Configuration

Modify `FRAUD_KEYWORDS` array in `main.bal` to add/remove keywords:

```ballerina
configurable string[] FRAUD_KEYWORDS = [
    "registration fee",
    "quick money",
    "work from home",
    // Add more keywords...
];
```

## Frontend Integration

### React Example

```javascript
const analyzeJobPost = async (imageFile) => {
  const formData = new FormData();
  formData.append('image', imageFile);
  
  const response = await fetch('http://localhost:8080/fraud-detection/analyze', {
    method: 'POST',
    body: formData
  });
  
  const result = await response.json();
  return result;
};
```

### Handling Results

```javascript
const handleAnalysisResult = (result) => {
  const { jobPost } = result;
  
  if (jobPost.isFraudulent) {
    showWarning(`Fraud detected! Score: ${jobPost.fraudScore}/100`);
  } else {
    showSuccess('Job post appears legitimate');
  }
  
  displayKeywords(jobPost.suspiciousKeywords);
};
```

## Development

### Project Structure
```
fraud-backend/
├── main.bal              # Main service implementation
├── ocr_service.bal       # OCR service integrations
├── fraud_patterns.bal    # Fraud detection patterns
├── Ballerina.toml       # Project configuration
├── Config.toml          # Runtime configuration
├── Dockerfile           # Docker image definition
├── docker-compose.yml   # Docker Compose setup
└── uploads/             # Uploaded files directory
```

### Adding New Features

1. **New Fraud Patterns**: Add to `FRAUD_PATTERNS` in `fraud_patterns.bal`
2. **New OCR Services**: Implement in `ocr_service.bal`
3. **New Endpoints**: Add to main service in `main.bal`

### Testing

```bash
# Test text analysis
curl -X POST http://localhost:8080/fraud-detection/analyze-text \
  -H "Content-Type: application/json" \
  -d '{"text": "Urgent hiring! Pay registration fee Rs. 5000. Guaranteed income Rs. 50000/month."}'

# Test image upload
curl -X POST http://localhost:8080/fraud-detection/analyze \
  -F "image=@job_post.jpg"
```

## Production Deployment

### Security Considerations

1. **API Keys**: Store in secure configuration management
2. **File Upload**: Implement file size limits and type validation
3. **Rate Limiting**: Add request rate limiting
4. **Authentication**: Implement API authentication if needed
5. **HTTPS**: Use HTTPS in production

### Monitoring

1. **Logs**: Monitor application logs for errors
2. **Metrics**: Track API response times and success rates
3. **Storage**: Monitor upload directory disk usage
4. **OCR Costs**: Monitor OCR API usage and costs

### Scaling

1. **Load Balancer**: Use multiple service instances
2. **File Storage**: Use cloud storage for uploaded files
3. **Database**: Add database for storing analysis results
4. **Caching**: Implement caching for repeated analyses

## Troubleshooting

### Common Issues

1. **OCR Not Working**
   - Check API keys in configuration
   - Verify internet connectivity
   - Check service quotas/limits

2. **File Upload Errors**
   - Ensure upload directory exists and is writable
   - Check file size limits
   - Verify file format support

3. **CORS Issues**
   - Update allowed origins in service configuration
   - Check browser console for detailed errors

### Logs

Enable detailed logging:
```bash
# Set log level
bal run --debug
```

## Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new features
4. Submit pull request

## License

MIT License - see LICENSE file for details

## Support

For issues and questions:
- Create GitHub issues for bugs
- Check documentation for common problems
- Review logs for error details
