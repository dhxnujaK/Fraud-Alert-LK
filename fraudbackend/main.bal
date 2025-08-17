import ballerina/http;
import ballerina/io;
import ballerina/os;
import ballerina/log;
import ballerina/lang.'string as strings;
import ballerina/file;

// Define API endpoints
configurable string mlScriptPath = ?;
configurable boolean useOcrApi = true;
configurable string ocrScriptPath = ?;

// Define request/response types
public type JobPostingRequest record {
    string title;
    string description;
    string? imageData;
};

public type FraudResponse record {
    boolean isFraud;
    decimal confidenceScore;
    string message;
};

service / on new http:Listener(9091) {
    // Enable CORS for frontend communication
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000", "http://localhost:3001"],
            allowCredentials: true,
            allowHeaders: ["*"],
            allowMethods: ["GET", "OPTIONS"]
        }
    }
    resource function get health() returns string {
        io:println("Health check endpoint called");
        log:printInfo("Health check endpoint called");
        return "Fraud detection service is running";
    }

    // Endpoint to check job posting for fraud
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000", "http://localhost:3001"],
            allowCredentials: true,
            allowHeaders: ["*"],
            allowMethods: ["POST", "OPTIONS", "GET"]
        }
    }
    resource function post checkFraud(@http:Payload JobPostingRequest posting) returns FraudResponse|error {
        log:printInfo("Received request to check fraud for job posting: " + posting.title);
        
        // Prepare data for ML model
        string title = posting.title;
        string description = posting.description;
        
        // Call Python ML model
        FraudResponse response = check callMLModel(title, description);
        
        return response;
    }
    
    // Endpoint to handle image upload and text extraction
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000", "http://localhost:3001"],
            allowCredentials: true,
            allowHeaders: ["*"],
            allowMethods: ["POST", "OPTIONS", "GET"]
        }
    }
    resource function post extractText(http:Request request) returns json|error {
        var parts = check request.getBodyParts();
        string extractedText = "";
        
        foreach var part in parts {
            if (part.getContentDisposition().name == "image") {
                byte[] bytes = check part.getByteArray();
                // Here you would implement OCR or call an external OCR service
                io:println("Received image of size: " + bytes.length().toString() + " bytes");
                extractedText = check extractTextFromImage(bytes);
            }
        }
        
        return { text: extractedText };
    }
}

// Function to call Python ML model
function callMLModel(string title, string description) returns FraudResponse|error {
    // Create a temporary file with the job data
    string tempFilePath = "./temp_job_data.txt";  // Using current directory for temp file
    string jobData = title + "\n" + description;
    check io:fileWriteString(tempFilePath, jobData);
    
    log:printInfo("Calling ML model with job data: " + title);

    // Prepare the command for Python script execution
    os:Process|error execResult = os:exec({
        value: "python",
        arguments: [mlScriptPath, tempFilePath]
    });
    
    if (execResult is error) {
        log:printError("Failed to execute ML script: " + execResult.message());
        return error("Failed to process job posting");
    }
    
    os:Process process = execResult;
    int exitCode = check process.waitForExit();
    
    // Read output from the process
    string result = "";
    byte[]|os:Error outputResult = process.output();
    
    if (outputResult is byte[]) {
        string|error stringResult = strings:fromBytes(outputResult);
        if (stringResult is string) {
            result = stringResult;
        } else {
            log:printError("Failed to convert process output to string: " + stringResult.message());
        }
    }
    
    log:printInfo("ML model returned: " + result + " with exit code: " + exitCode.toString());
    
    // Clean up temporary file after processing
    check file:remove(tempFilePath);
    
    if (exitCode != 0) {
        return error("ML model execution failed");
    }
    
    // Parse the result (0 = real, 1 = fraud)
    boolean isFraud = strings:trim(result) == "1";
    
    return {
        isFraud: isFraud,
        confidenceScore: isFraud ? 0.85 : 0.98, // Using values from model_evaluation.txt
        message: isFraud ? 
            "This job posting has characteristics similar to fraudulent posts." : 
            "This job posting appears to be legitimate."
    };
}

// Function to extract text from image using OCR
function extractTextFromImage(byte[] imageData) returns string|error {
    if (!useOcrApi) {
        return "OCR is currently disabled. Please enter job details manually or enable OCR in the backend configuration.";
    }
    
    // Use local Tesseract OCR through Python script
    // Save the image to a temporary file
    string tempImagePath = "./temp_image.jpg";  // Using current directory for temp file
    check io:fileWriteBytes(tempImagePath, imageData);
    
    log:printInfo("Running OCR on image saved at: " + tempImagePath);
    
    // Call the Python OCR script
    os:Process|error execResult = os:exec({
        value: "python",
        arguments: [ocrScriptPath, tempImagePath]
    });
    
    if (execResult is error) {
        log:printError("Failed to execute OCR script: " + execResult.message());
        return "Failed to extract text from image. Make sure Tesseract OCR is installed and Python dependencies are set up.";
    }
    
    os:Process process = execResult;
    int exitCode = check process.waitForExit();
    
    // Read output from the process
    string extractedText = "";
    byte[]|os:Error outputResult = process.output();
    
    if (outputResult is byte[]) {
        string|error stringResult = strings:fromBytes(outputResult);
        if (stringResult is string) {
            extractedText = stringResult;
        } else {
            log:printError("Failed to convert process output to string: " + stringResult.message());
        }
    }
    
    // Clean up temporary file
    check file:remove(tempImagePath);
    
    return extractedText;
}
