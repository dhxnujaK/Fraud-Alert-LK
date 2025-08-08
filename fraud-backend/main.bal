import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/mime;
import ballerina/os;
import ballerina/regex;
import ballerina/time;
import ballerina/uuid;

// Configuration for the service
configurable int PORT = 9090;
configurable string UPLOAD_PATH = "./uploads";
configurable string[] FRAUD_KEYWORDS = [
    "quick money", "easy money", "work from home", "guaranteed income",
    "no experience required", "make money fast", "urgent hiring",
    "high salary", "no interview", "immediate joining", "cash payment",
    "pay first", "registration fee", "processing fee", "advance payment",
    "deposit required", "training fee", "security deposit"
];

// Types for request/response
type JobPost record {|
    string id;
    string title?;
    string description?;
    string company?;
    string extractedText;
    boolean isFraudulent;
    decimal fraudScore;
    string[] suspiciousKeywords;
    time:Utc timestamp;
|};

type AnalysisResult record {|
    boolean isFraudulent;
    decimal fraudScore;
    string[] suspiciousKeywords;
    string reasoning;
|};

type UploadResponse record {|
    string message;
    JobPost jobPost;
    boolean? error;
|};

type ErrorResponse record {|
    string 'error;
    string message;
|};

// CORS configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000", "http://127.0.0.1:3000"],
        allowCredentials: false,
        allowHeaders: ["CORELATION_ID", "Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        maxAge: 84900
    }
}
service /fraud-detection on new http:Listener(PORT) {

    # Health check endpoint
    # + return - Health status
    resource function get health() returns json {
        return {
            status: "healthy",
            timestamp: time:utcNow(),
            service: "Fraud Detection Backend"
        };
    }

    # Upload and analyze job post image
    # + request - HTTP request with multipart form data containing image
    # + return - Analysis result or error
    resource function post analyze(http:Request request) returns UploadResponse|ErrorResponse|http:InternalServerError {
        log:printInfo("Received image upload request for fraud analysis");

        // Create uploads directory if it doesn't exist
        error? dirResult = io:createDir(UPLOAD_PATH, io:RECURSIVE);
        if dirResult is error {
            log:printError("Failed to create upload directory", dirResult);
        }

        // Parse multipart form data
        mime:Entity[]|http:ClientError bodyParts = request.getBodyParts();
        
        if bodyParts is http:ClientError {
            log:printError("Failed to parse multipart form data", bodyParts);
            return <ErrorResponse>{
                'error: "INVALID_REQUEST",
                message: "Failed to parse multipart form data"
            };
        }

        string? fileName = ();
        string? extractedText = ();

        // Process each part of the form data
        foreach mime:Entity part in bodyParts {
            mime:ContentDisposition? contentDisposition = part.getContentDisposition();
            if contentDisposition is mime:ContentDisposition {
                string? partName = contentDisposition.name;
                
                if partName == "image" {
                    // Handle image upload
                    string? originalFileName = contentDisposition.fileName;
                    if originalFileName is string {
                        string fileExtension = getFileExtension(originalFileName);
                        string uniqueFileName = uuid:createType4AsString() + fileExtension;
                        fileName = uniqueFileName;
                        
                        string filePath = UPLOAD_PATH + "/" + uniqueFileName;
                        
                        // Save uploaded file
                        byte[]|mime:Error fileContent = part.getByteArray();
                        if fileContent is byte[] {
                            error? writeResult = io:fileWriteBytes(filePath, fileContent);
                            if writeResult is error {
                                log:printError("Failed to save uploaded file", writeResult);
                                return <ErrorResponse>{
                                    'error: "FILE_SAVE_ERROR",
                                    message: "Failed to save uploaded file"
                                };
                            }
                            
                            // Extract text from image using OCR
                            extractedText = extractTextFromImage(filePath);
                            
                        } else {
                            log:printError("Failed to read file content", fileContent);
                            return <ErrorResponse>{
                                'error: "FILE_READ_ERROR",
                                message: "Failed to read uploaded file content"
                            };
                        }
                    }
                }
            }
        }

        if fileName is () || extractedText is () {
            return <ErrorResponse>{
                'error: "MISSING_DATA",
                message: "No valid image file uploaded or text extraction failed"
            };
        }

        // Analyze extracted text for fraud indicators
        AnalysisResult analysisResult = analyzeJobPostForFraud(extractedText);

        // Create job post record
        JobPost jobPost = {
            id: uuid:createType4AsString(),
            extractedText: extractedText,
            isFraudulent: analysisResult.isFraudulent,
            fraudScore: analysisResult.fraudScore,
            suspiciousKeywords: analysisResult.suspiciousKeywords,
            timestamp: time:utcNow()
        };

        log:printInfo(string `Analysis completed for job post ${jobPost.id}. Fraud score: ${jobPost.fraudScore}`);

        return <UploadResponse>{
            message: "Image analyzed successfully",
            jobPost: jobPost,
            error: false
        };
    }

    # Get fraud analysis for text input (for testing)
    # + request - HTTP request with JSON body containing text
    # + return - Analysis result
    resource function post analyze\-text(http:Request request) returns AnalysisResult|ErrorResponse|http:InternalServerError {
        json|http:ClientError payload = request.getJsonPayload();
        
        if payload is http:ClientError {
            return <ErrorResponse>{
                'error: "INVALID_JSON",
                message: "Invalid JSON payload"
            };
        }

        json textJson = payload;
        string|error text = textJson.text;
        
        if text is error {
            return <ErrorResponse>{
                'error: "MISSING_TEXT",
                message: "Text field is required"
            };
        }

        AnalysisResult result = analyzeJobPostForFraud(text);
        return result;
    }
}

# Extract text from image using OCR services
# + imagePath - Path to the image file
# + return - Extracted text or empty string if extraction fails
function extractTextFromImage(string imagePath) returns string {
    log:printInfo(string `Extracting text from image: ${imagePath}`);
    
    // Use the OCR service with fallback strategy
    OCRResult result = extractTextWithFallback(imagePath);
    
    if result.success {
        log:printInfo("OCR extraction successful");
        return result.text;
    } else {
        log:printError(string `OCR extraction failed: ${result.errorMessage ?: "Unknown error"}`);
        return "";
    }
}

# Analyze job post text for fraud indicators using advanced patterns
# + text - Text content to analyze
# + return - Analysis result with fraud score and suspicious keywords
function analyzeJobPostForFraud(string text) returns AnalysisResult {
    // Use the advanced pattern analysis from fraud_patterns module
    map<anydata> analysis = analyzeWithPatterns(text);
    
    decimal fraudScore = <decimal>analysis["fraudScore"];
    boolean isFraudulent = <boolean>analysis["isFraudulent"];
    string[] suspiciousKeywords = <string[]>analysis["suspiciousKeywords"];
    string recommendation = <string>analysis["recommendation"];
    string riskLevel = <string>analysis["riskLevel"];
    
    string reasoning = string `Risk Level: ${riskLevel}. ${recommendation}`;
    
    return {
        isFraudulent: isFraudulent,
        fraudScore: fraudScore,
        suspiciousKeywords: suspiciousKeywords,
        reasoning: reasoning
    };
}

# Get file extension from filename
# + fileName - Name of the file
# + return - File extension including the dot
function getFileExtension(string fileName) returns string {
    int? lastDotIndex = fileName.lastIndexOf(".");
    if lastDotIndex is int && lastDotIndex > 0 {
        return fileName.substring(lastDotIndex);
    }
    return ".jpg"; // Default extension
}

# Extract text with fallback strategy (mock implementation)
# + imagePath - Path to the image file
# + return - OCR result
function extractTextWithFallback(string imagePath) returns OCRResult {
    log:printInfo(string `Mock OCR extraction for: ${imagePath}`);
    
    // Mock implementation - in real scenario, this would call actual OCR services
    string[] mockTexts = [
        // Fraudulent job post example
        `URGENT HIRING! 
        Data Entry Operator Required
        Salary: Rs. 50,000 per month
        Work from Home - No Experience Required
        Registration Fee: Rs. 2,500 
        Contact: +94 77 123 4567 (WhatsApp Only)
        Join Immediately! Limited Seats Available!
        Guaranteed Income!`,
        
        // Legitimate job post example
        `Software Engineer - Full Stack
        ABC Technology Solutions Pvt Ltd
        Location: Colombo 03
        Experience: 2-3 years required
        Skills: React.js, Node.js, MongoDB
        Salary: Rs. 80,000 - 120,000 (Negotiable)
        Email: careers@abctech.lk
        Office: World Trade Center, Colombo`,
        
        // Another fraudulent example
        `EARN Rs. 1000 DAILY FROM HOME!
        Copy-Paste Jobs Available
        No Qualification Required
        Investment: Rs. 5000 (Refundable)
        WhatsApp: +94 71 999 8888
        Register NOW! 24 Hours Only!
        Processing Fee: Rs. 1500`
    ];
    
    // Simulate OCR based on file path hash
    int textIndex = imagePath.length() % mockTexts.length();
    
    return {
        success: true,
        text: mockTexts[textIndex],
        errorMessage: ()
    };
}

# OCR Result type for the mock implementation
type OCRResult record {|
    boolean success;
    string text;
    string? errorMessage;
|};

# Analyze text with fraud detection patterns
# + text - Text to analyze
# + return - Analysis result map
function analyzeWithPatterns(string text) returns map<anydata> {
    string lowerText = text.toLowerAscii();
    decimal fraudScore = 0.0;
    string[] suspiciousKeywords = [];
    
    // Define fraud indicators with their weights
    map<decimal> fraudPatterns = {
        "registration fee": 35.0,
        "processing fee": 30.0,
        "security deposit": 25.0,
        "training fee": 25.0,
        "joining fee": 30.0,
        "investment required": 35.0,
        "deposit required": 30.0,
        "pay first": 40.0,
        "advance payment": 35.0,
        "guaranteed income": 30.0,
        "easy money": 25.0,
        "quick money": 25.0,
        "work from home": 15.0,
        "no experience": 10.0,
        "urgent hiring": 20.0,
        "immediate joining": 20.0,
        "limited seats": 25.0,
        "whatsapp only": 30.0,
        "cash payment": 25.0,
        "refundable": 20.0,
        "copy paste": 35.0,
        "data entry": 15.0,
        "earn daily": 25.0,
        "24 hours only": 30.0,
        "register now": 20.0
    };
    
    // Check for each fraud pattern
    foreach var [keyword, weight] in fraudPatterns.entries() {
        if lowerText.includes(keyword) {
            suspiciousKeywords.push(keyword);
            fraudScore += weight;
        }
    }
    
    // Additional checks
    
    // Check for phone numbers (mobile patterns)
    if lowerText.includes("+94 7") || lowerText.includes("077") || lowerText.includes("071") || lowerText.includes("076") {
        fraudScore += 10.0;
    }
    
    // Check for high salary with no experience
    if (lowerText.includes("50,000") || lowerText.includes("1000 daily") || lowerText.includes("high salary")) && 
       (lowerText.includes("no experience") || lowerText.includes("no qualification")) {
        fraudScore += 25.0;
        suspiciousKeywords.push("unrealistic salary");
    }
    
    // Check for urgency indicators
    if lowerText.includes("urgent") || lowerText.includes("immediate") || lowerText.includes("limited time") {
        fraudScore += 15.0;
    }
    
    // Positive indicators (reduce fraud score)
    if lowerText.includes("company") || lowerText.includes("pvt ltd") || lowerText.includes("office") {
        fraudScore -= 10.0;
    }
    
    if lowerText.includes("experience required") || lowerText.includes("skills:") || lowerText.includes("qualifications:") {
        fraudScore -= 15.0;
    }
    
    if lowerText.includes("email:") || lowerText.includes("careers@") || lowerText.includes(".lk") {
        fraudScore -= 20.0;
    }
    
    // Ensure score bounds
    if fraudScore < 0.0 {
        fraudScore = 0.0;
    }
    if fraudScore > 100.0 {
        fraudScore = 100.0;
    }
    
    boolean isFraudulent = fraudScore >= 60.0;
    
    string riskLevel;
    string recommendation;
    
    if fraudScore >= 80.0 {
        riskLevel = "CRITICAL";
        recommendation = "Extremely high risk of fraud. Do not proceed without thorough verification.";
    } else if fraudScore >= 60.0 {
        riskLevel = "HIGH";
        recommendation = "High risk of fraud. Exercise extreme caution and verify independently.";
    } else if fraudScore >= 40.0 {
        riskLevel = "MEDIUM";
        recommendation = "Moderate risk. Additional verification recommended.";
    } else if fraudScore >= 20.0 {
        riskLevel = "LOW";
        recommendation = "Low risk, but remain cautious.";
    } else {
        riskLevel = "MINIMAL";
        recommendation = "Appears legitimate, but always verify independently.";
    }
    
    return {
        "fraudScore": fraudScore,
        "isFraudulent": isFraudulent,
        "suspiciousKeywords": suspiciousKeywords,
        "riskLevel": riskLevel,
        "recommendation": recommendation
    };
}
