import ballerina/http;
import ballerina/io;
import ballerina/mime;
import ballerina/os;
import ballerina/log;
import ballerina/lang.'string as strings;
import ballerina/system;

// Define API endpoints
configurable string mlScriptPath = ?;

// Define request/response types
type JobPostingRequest record {
    string title;
    string description;
    string? imageData;
};

type FraudResponse record {
    boolean isFraud;
    decimal confidenceScore;
    string message;
};

service / on new http:Listener(9090) {
    // Enable CORS for frontend communication
    resource function get health() returns string {
        return "Fraud detection service is running";
    }

    // Endpoint to check job posting for fraud
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["*"],
            allowMethods: ["POST", "OPTIONS"]
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
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["*"],
            allowMethods: ["POST", "OPTIONS"]
        }
    }
    resource function post extractText(http:Request request) returns json|error {
        var parts = check request.getBodyParts();
        string extractedText = "";
        
        foreach var part in parts {
            if (part.getContentDisposition().name == "image") {
                byte[] bytes = check part.getByteArray();
                // Here you would implement OCR or call an external OCR service
                // For now, we'll just log that we received an image
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
    string tempFilePath = system:getTemporaryFolderPath() + "/job_data.txt";
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
    var outputResult = process.output();
    
    if (outputResult is io:ReadableByteChannel) {
        io:ReadableCharacterChannel characterChannel = new io:ReadableCharacterChannel(outputResult, "UTF-8");
        
        // Read line by line
        string? readLine = "";
        while (true) {
            readLine = check characterChannel.read(1024);
            if (readLine is string) {
                if (readLine != "") {
                    result = result + readLine;
                }
            } else {
                break;
            }
        }
        
        check characterChannel.close();
    }
    
    log:printInfo("ML model returned: " + result + " with exit code: " + exitCode.toString());
    
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

// Function to extract text from image (placeholder)
function extractTextFromImage(byte[] imageData) returns string|error {
    // In a real implementation, you would call an OCR service or library
    // For now, we'll return a placeholder message
    return "Text extraction from images not yet implemented. Please manually enter job details.";
}

// Function to extract text from image (placeholder)
function extractTextFromImage(byte[] imageData) returns string|error {
    // In a real implementation, you would call an OCR service or library
    // For now, we'll return a placeholder message
    return "Text extraction from images not yet implemented. Please manually enter job details.";
}
    
    if (exitCode != 0) {
        return error("ML model execution failed");
    }
    
    // Parse the result (0 = real, 1 = fraud)
    boolean isFraud = result.trim() == "1";
    
    return {
        isFraud: isFraud,
        confidenceScore: isFraud ? 0.85 : 0.98, // Using values from model_evaluation.txt
        message: isFraud ? 
            "This job posting has characteristics similar to fraudulent posts." : 
            "This job posting appears to be legitimate."
    };
}

// Function to extract text from image (placeholder)
function extractTextFromImage(byte[] imageData) returns string|error {
    // In a real implementation, you would call an OCR service or library
    // For now, we'll return a placeholder message
    return "Text extraction from images not yet implemented. Please manually enter job details.";
}
