const express = require('express');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}

// Configure multer for file uploads
const upload = multer({ 
  dest: 'uploads/',
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    // Accept only image files
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Please upload only image files'), false);
    }
  }
});

// Mock fraud detection function
function analyzeJobPost(extractedText) {
  const suspiciousKeywords = [];
  let fraudScore = 0;
  
  // Fraud patterns with weights
  const fraudPatterns = {
    'registration fee': 35,
    'processing fee': 30,
    'security deposit': 25,
    'training fee': 25,
    'joining fee': 30,
    'guaranteed income': 30,
    'easy money': 25,
    'quick money': 25,
    'work from home': 15,
    'no experience': 10,
    'urgent hiring': 20,
    'immediate joining': 20,
    'whatsapp only': 30,
    'limited seats': 25,
    'cash payment': 25,
    'advance payment': 35,
    'deposit required': 30,
    'copy paste': 35,
    'data entry': 15,
    'earn daily': 25,
    'refundable': 20,
    'investment required': 35
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
  
  // Check for phone numbers (mobile patterns)
  if (lowerText.includes('+94 7') || lowerText.includes('077') || lowerText.includes('071')) {
    fraudScore += 10;
  }
  
  // Check for high salary with no experience
  if ((lowerText.includes('50,000') || lowerText.includes('1000 daily')) && 
      lowerText.includes('no experience')) {
    fraudScore += 25;
    suspiciousKeywords.push('unrealistic salary');
  }
  
  // Check for urgency indicators
  if (lowerText.includes('urgent') || lowerText.includes('immediate') || lowerText.includes('limited time')) {
    fraudScore += 15;
  }
  
  // Positive indicators (reduce fraud score)
  if (lowerText.includes('company') || lowerText.includes('pvt ltd') || lowerText.includes('office')) {
    fraudScore -= 10;
  }
  
  if (lowerText.includes('experience required') || lowerText.includes('skills:')) {
    fraudScore -= 15;
  }
  
  if (lowerText.includes('email:') || lowerText.includes('careers@')) {
    fraudScore -= 20;
  }
  
  // Ensure score is within bounds
  fraudScore = Math.min(Math.max(fraudScore, 0), 100);
  
  return {
    id: Date.now().toString() + Math.random().toString(36).substr(2, 5),
    extractedText,
    fraudScore,
    isFraudulent: fraudScore >= 60,
    suspiciousKeywords,
    timestamp: new Date().toISOString()
  };
}

// Mock OCR function - simulates text extraction from images
function extractTextFromImage(filename) {
  const mockTexts = [
    // High fraud example
    `URGENT HIRING! 
Data Entry Operator Required

💰 Salary: Rs. 50,000 per month
🏠 Work from Home - No Experience Required
📋 Simple copy-paste work only

Registration Process:
✅ Pay registration fee: Rs. 2,500 
✅ Get training materials immediately
✅ Start earning from day 1

📞 Contact: +94 77 123 4567 (WhatsApp Only)
⏰ Join Immediately! Limited Seats Available!
💯 Guaranteed Income! No target pressure!

Company: DataWork Solutions
Note: Registration fee is mandatory and non-refundable`,
    
    // Legitimate example
    `Software Engineer - Full Stack Developer
ABC Technology Solutions Pvt Ltd

📍 Location: Colombo 03, Sri Lanka
💼 Experience: 2-3 years required
🛠️ Skills Required:
   • React.js, Node.js, MongoDB
   • JavaScript, TypeScript
   • RESTful API development
   • Git version control

💰 Salary: Rs. 80,000 - 120,000 (Negotiable based on experience)
📧 Email: careers@abctech.lk
🏢 Office: World Trade Center, Colombo
📞 Phone: +94 11 234 5678

Interview Process:
1. Resume screening
2. Technical assessment
3. Panel interview
4. Final discussion

Apply with your CV and portfolio`,
    
    // Medium fraud example
    `🔥 EARN Rs. 1000 DAILY FROM HOME! 🔥

📋 Copy-Paste Jobs Available
✅ No Qualification Required
⏰ Just 2-3 hours daily work
💻 Basic computer knowledge enough

💰 Investment: Rs. 5000 (100% Refundable)
📱 WhatsApp: +94 71 999 8888
⚡ Register NOW! Limited time offer - 24 Hours Only!

Benefits:
• Daily payment guaranteed
• Training provided
• Flexible timing
• Work from anywhere

Processing fee: Rs. 1500 (One time)
Join thousands of satisfied workers!`,
    
    // Another legitimate example
    `Marketing Executive Position
Lanka Marketing Company (Pvt) Ltd

Requirements:
• Bachelor's degree in Marketing/Business
• 1-2 years experience in digital marketing
• Good English communication skills
• Knowledge of social media platforms

Responsibilities:
• Develop marketing campaigns
• Manage social media accounts
• Conduct market research
• Prepare marketing reports

Salary: Rs. 45,000 - 60,000 + Incentives
Location: Kandy
Working Hours: 8:30 AM - 5:30 PM

Send CV to: hr@lankamarketing.lk
Contact: 081-234-5678 (Office Hours)`
  ];
  
  // Use filename hash to determine which text to return for consistency
  const hash = filename.split('').reduce((a, b) => {
    a = ((a << 5) - a) + b.charCodeAt(0);
    return a & a;
  }, 0);
  
  return mockTexts[Math.abs(hash) % mockTexts.length];
}

// Routes

// Health check endpoint
app.get('/fraud-detection/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'Fraud Detection Backend (Node.js)',
    version: '1.0.0'
  });
});

// Main analysis endpoint
app.post('/fraud-detection/analyze', upload.single('image'), (req, res) => {
  try {
    console.log('📥 Received image upload request');
    
    if (!req.file) {
      console.log('❌ No file uploaded');
      return res.status(400).json({
        error: 'MISSING_FILE',
        message: 'No image file uploaded'
      });
    }
    
    console.log(`📸 Processing image: ${req.file.originalname} (${req.file.size} bytes)`);
    
    // Mock OCR extraction based on filename
    const extractedText = extractTextFromImage(req.file.originalname || req.file.filename);
    console.log('🔍 Text extracted from image');
    
    // Analyze for fraud
    const jobPost = analyzeJobPost(extractedText);
    console.log(`📊 Analysis complete. Fraud score: ${jobPost.fraudScore}`);
    
    // Clean up uploaded file after processing
    fs.unlink(req.file.path, (err) => {
      if (err) console.error('Error deleting temp file:', err);
    });
    
    res.json({
      message: 'Image analyzed successfully',
      jobPost,
      error: false
    });
  } catch (error) {
    console.error('💥 Error processing request:', error);
    res.status(500).json({
      error: 'INTERNAL_ERROR',
      message: 'Internal server error'
    });
  }
});

// Text analysis endpoint for testing
app.post('/fraud-detection/analyze-text', (req, res) => {
  try {
    const { text } = req.body;
    
    if (!text) {
      return res.status(400).json({
        error: 'MISSING_TEXT',
        message: 'Text field is required'
      });
    }
    
    console.log('📝 Analyzing text input');
    const analysis = analyzeJobPost(text);
    
    res.json({
      isFraudulent: analysis.isFraudulent,
      fraudScore: analysis.fraudScore,
      suspiciousKeywords: analysis.suspiciousKeywords,
      reasoning: `Analysis complete. Risk level: ${analysis.fraudScore >= 80 ? 'CRITICAL' : 
                  analysis.fraudScore >= 60 ? 'HIGH' : 
                  analysis.fraudScore >= 40 ? 'MEDIUM' : 
                  analysis.fraudScore >= 20 ? 'LOW' : 'MINIMAL'}`
    });
  } catch (error) {
    console.error('💥 Error analyzing text:', error);
    res.status(500).json({
      error: 'INTERNAL_ERROR',
      message: 'Internal server error'
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        error: 'FILE_TOO_LARGE',
        message: 'File size too large. Maximum 10MB allowed.'
      });
    }
  }
  
  if (error.message === 'Please upload only image files') {
    return res.status(400).json({
      error: 'INVALID_FILE_TYPE',
      message: 'Please upload only image files (JPEG, PNG, etc.)'
    });
  }
  
  console.error('💥 Unhandled error:', error);
  res.status(500).json({
    error: 'INTERNAL_ERROR',
    message: 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'NOT_FOUND',
    message: 'Endpoint not found'
  });
});

const PORT = process.env.PORT || 9090;

app.listen(PORT, () => {
  console.log('🚀 Fraud Detection Backend (Node.js) is running!');
  console.log(`📡 Server: http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/fraud-detection/health`);
  console.log(`📁 Upload endpoint: http://localhost:${PORT}/fraud-detection/analyze`);
  console.log('');
  console.log('Ready to detect fraud in job posts! 🔍');
});
