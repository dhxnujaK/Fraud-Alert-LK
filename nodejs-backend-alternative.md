# Node.js Backend Alternative

If you want to test the frontend immediately while setting up Ballerina, here's a simple Node.js backend.

## Quick Setup

1. Create a new folder called `nodejs-backend`
2. Copy the files below
3. Run `npm install express cors multer`
4. Run `node server.js`

## server.js
```javascript
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Configure multer for file uploads
const upload = multer({ 
  dest: 'uploads/',
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// Mock fraud detection function
function analyzeJobPost(extractedText) {
  const suspiciousKeywords = [];
  let fraudScore = 0;
  
  const fraudPatterns = {
    'registration fee': 35,
    'processing fee': 30,
    'security deposit': 25,
    'training fee': 25,
    'guaranteed income': 30,
    'easy money': 25,
    'work from home': 15,
    'no experience': 10,
    'urgent hiring': 20,
    'whatsapp only': 30,
    'immediate joining': 20,
    'limited seats': 25
  };
  
  const lowerText = extractedText.toLowerCase();
  
  // Check for fraud patterns
  Object.entries(fraudPatterns).forEach(([keyword, weight]) => {
    if (lowerText.includes(keyword)) {
      suspiciousKeywords.push(keyword);
      fraudScore += weight;
    }
  });
  
  // Additional checks
  if (lowerText.includes('+94 7') || lowerText.includes('077')) {
    fraudScore += 10;
  }
  
  // Ensure score is within bounds
  fraudScore = Math.min(Math.max(fraudScore, 0), 100);
  
  return {
    id: Date.now().toString(),
    extractedText,
    fraudScore,
    isFraudulent: fraudScore >= 60,
    suspiciousKeywords,
    timestamp: new Date().toISOString()
  };
}

// Mock OCR function
function extractTextFromImage() {
  const mockTexts = [
    `URGENT HIRING! 
Data Entry Operator Required
Salary: Rs. 50,000 per month
Work from Home - No Experience Required
Registration Fee: Rs. 2,500 
Contact: +94 77 123 4567 (WhatsApp Only)
Join Immediately! Limited Seats Available!`,
    
    `Software Engineer - Full Stack
ABC Technology Solutions Pvt Ltd
Location: Colombo 03
Experience: 2-3 years required
Skills: React.js, Node.js, MongoDB
Salary: Rs. 80,000 - 120,000 (Negotiable)
Email: careers@abctech.lk`,
    
    `EARN Rs. 1000 DAILY FROM HOME!
Copy-Paste Jobs Available
No Qualification Required
Investment: Rs. 5000 (Refundable)
WhatsApp: +94 71 999 8888
Register NOW! 24 Hours Only!`
  ];
  
  return mockTexts[Math.floor(Math.random() * mockTexts.length)];
}

// Routes
app.get('/fraud-detection/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'Fraud Detection Backend (Node.js)'
  });
});

app.post('/fraud-detection/analyze', upload.single('image'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        error: 'MISSING_FILE',
        message: 'No image file uploaded'
      });
    }
    
    // Mock OCR extraction
    const extractedText = extractTextFromImage();
    
    // Analyze for fraud
    const jobPost = analyzeJobPost(extractedText);
    
    res.json({
      message: 'Image analyzed successfully',
      jobPost,
      error: false
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({
      error: 'INTERNAL_ERROR',
      message: 'Internal server error'
    });
  }
});

const PORT = 9090;
app.listen(PORT, () => {
  console.log(`🚀 Fraud Detection Backend running on http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/fraud-detection/health`);
});
```

## package.json
```json
{
  "name": "fraud-detection-nodejs-backend",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "multer": "^1.4.5-lts.1"
  },
  "scripts": {
    "start": "node server.js"
  }
}
```

## Run Commands
```bash
npm install
npm start
```

This temporary backend will work with your React frontend while you set up the full Ballerina backend!
