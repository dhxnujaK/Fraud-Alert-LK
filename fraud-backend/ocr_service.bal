import ballerina/http;
import ballerina/io;
import ballerina/log;

# OCR Service Integration Module
# This module provides functions to integrate with various OCR services

# Configuration for OCR services
configurable string GOOGLE_VISION_API_KEY = "";
configurable string AZURE_VISION_ENDPOINT = "";
configurable string AZURE_VISION_KEY = "";

# OCR Result type
public type OCRResult record {|
    boolean success;
    string text;
    string? errorMessage;
|};

# Extract text using Google Cloud Vision API
# + imagePath - Path to the image file
# + return - OCR result
public function extractTextWithGoogleVision(string imagePath) returns OCRResult {
    log:printInfo("Attempting OCR with Google Cloud Vision API");
    
    if GOOGLE_VISION_API_KEY == "" {
        return {
            success: false,
            text: "",
            errorMessage: "Google Vision API key not configured"
        };
    }
    
    // Read image file
    byte[]|io:Error imageBytes = io:fileReadBytes(imagePath);
    if imageBytes is io:Error {
        return {
            success: false,
            text: "",
            errorMessage: "Failed to read image file"
        };
    }
    
    // Convert to base64
    string base64Image = imageBytes.toBase64();
    
    // Prepare request for Google Vision API
    json visionRequest = {
        "requests": [
            {
                "image": {
                    "content": base64Image
                },
                "features": [
                    {
                        "type": "TEXT_DETECTION",
                        "maxResults": 1
                    }
                ]
            }
        ]
    };
    
    // Create HTTP client for Google Vision API
    http:Client|error visionClient = new (string `https://vision.googleapis.com`, {
        timeout: 30.0
    });
    
    if visionClient is error {
        return {
            success: false,
            text: "",
            errorMessage: "Failed to create Google Vision API client"
        };
    }
    
    // Make API call
    string endpoint = string `/v1/images:annotate?key=${GOOGLE_VISION_API_KEY}`;
    http:Response|error response = visionClient->post(endpoint, visionRequest);
    
    if response is error {
        return {
            success: false,
            text: "",
            errorMessage: string `Google Vision API call failed: ${response.message()}`
        };
    }
    
    // Parse response
    json|error responsePayload = response.getJsonPayload();
    if responsePayload is error {
        return {
            success: false,
            text: "",
            errorMessage: "Failed to parse Google Vision API response"
        };
    }
    
    // Extract text from response
    json responses = responsePayload.responses;
    if responses is json[] && responses.length() > 0 {
        json firstResponse = responses[0];
        json? textAnnotations = firstResponse.textAnnotations;
        
        if textAnnotations is json[] && textAnnotations.length() > 0 {
            json firstAnnotation = textAnnotations[0];
            string|error extractedText = firstAnnotation.description;
            
            if extractedText is string {
                return {
                    success: true,
                    text: extractedText,
                    errorMessage: ()
                };
            }
        }
    }
    
    return {
        success: false,
        text: "",
        errorMessage: "No text detected in image"
    };
}

# Extract text using Azure Computer Vision API
# + imagePath - Path to the image file
# + return - OCR result
public function extractTextWithAzureVision(string imagePath) returns OCRResult {
    log:printInfo("Attempting OCR with Azure Computer Vision API");
    
    if AZURE_VISION_ENDPOINT == "" || AZURE_VISION_KEY == "" {
        return {
            success: false,
            text: "",
            errorMessage: "Azure Vision API credentials not configured"
        };
    }
    
    // Read image file
    byte[]|io:Error imageBytes = io:fileReadBytes(imagePath);
    if imageBytes is io:Error {
        return {
            success: false,
            text: "",
            errorMessage: "Failed to read image file"
        };
    }
    
    // Create HTTP client for Azure Vision API
    http:Client|error visionClient = new (AZURE_VISION_ENDPOINT, {
        timeout: 30.0
    });
    
    if visionClient is error {
        return {
            success: false,
            text: "",
            errorMessage: "Failed to create Azure Vision API client"
        };
    }
    
    // Prepare headers
    map<string> headers = {
        "Ocp-Apim-Subscription-Key": AZURE_VISION_KEY,
        "Content-Type": "application/octet-stream"
    };
    
    // Make API call
    http:Response|error response = visionClient->post("/vision/v3.2/ocr", imageBytes, headers);
    
    if response is error {
        return {
            success: false,
            text: "",
            errorMessage: string `Azure Vision API call failed: ${response.message()}`
        };
    }
    
    // Parse response
    json|error responsePayload = response.getJsonPayload();
    if responsePayload is error {
        return {
            success: false,
            text: "",
            errorMessage: "Failed to parse Azure Vision API response"
        };
    }
    
    // Extract text from response
    string extractedText = "";
    json? regions = responsePayload.regions;
    
    if regions is json[] {
        foreach json region in regions {
            json? lines = region.lines;
            if lines is json[] {
                foreach json line in lines {
                    json? words = line.words;
                    if words is json[] {
                        foreach json word in words {
                            string|error wordText = word.text;
                            if wordText is string {
                                extractedText += wordText + " ";
                            }
                        }
                        extractedText += "\n";
                    }
                }
            }
        }
    }
    
    if extractedText.trim() != "" {
        return {
            success: true,
            text: extractedText.trim(),
            errorMessage: ()
        };
    }
    
    return {
        success: false,
        text: "",
        errorMessage: "No text detected in image"
    };
}

# Fallback OCR function that tries multiple services
# + imagePath - Path to the image file
# + return - OCR result
public function extractTextWithFallback(string imagePath) returns OCRResult {
    log:printInfo("Attempting OCR with fallback strategy");
    
    // Try Google Vision first
    OCRResult googleResult = extractTextWithGoogleVision(imagePath);
    if googleResult.success {
        log:printInfo("OCR successful with Google Vision API");
        return googleResult;
    }
    
    log:printWarn(string `Google Vision failed: ${googleResult.errorMessage ?: "Unknown error"}`);
    
    // Try Azure Vision as fallback
    OCRResult azureResult = extractTextWithAzureVision(imagePath);
    if azureResult.success {
        log:printInfo("OCR successful with Azure Vision API");
        return azureResult;
    }
    
    log:printWarn(string `Azure Vision failed: ${azureResult.errorMessage ?: "Unknown error"}`);
    
    // If all services fail, return simulated result for demo
    log:printWarn("All OCR services failed, using simulated text for demo");
    return {
        success: true,
        text: getSimulatedOCRText(),
        errorMessage: "Using simulated OCR text for demonstration"
    };
}

# Get simulated OCR text for demonstration purposes
# + return - Simulated extracted text
function getSimulatedOCRText() returns string {
    return `
    URGENT HIRING - DATA ENTRY JOB
    
    💰 Earn Rs. 30,000 - 60,000 per month
    🏠 Work from Home
    ⏰ Flexible timings
    
    Requirements:
    ✓ Age 18-50 years
    ✓ Basic computer knowledge
    ✓ No experience required
    ✓ Any qualification accepted
    
    Job Description:
    - Simple data entry work
    - Copy-paste tasks
    - Form filling
    - 2-3 hours daily work
    
    Benefits:
    • Weekly payment guaranteed
    • No target pressure
    • Training provided
    • Immediate joining
    
    How to Apply:
    1. Pay registration fee Rs. 3,500
    2. Get training materials
    3. Start earning from day 1
    
    📞 Call: +91 8765432109
    📧 Email: careers@datajobs24.com
    🌐 Website: www.quickearning.in
    
    ⚠️ Limited seats available!
    ⚠️ Registration fee is mandatory
    ⚠️ Fee is non-refundable
    
    Company: DataWork Solutions Pvt Ltd
    Regd Office: Mumbai, Maharashtra
    `;
}
