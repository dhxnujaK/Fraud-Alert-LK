import ballerina/http;
import ballerina/io;
import ballerina/os;
import ballerina/log;
import ballerina/lang.'string as strings;
import ballerina/file;

// ---- Config ----
configurable string pythonBin = "/usr/bin/python3";   // or your venv python
configurable string mlScriptPath = ?;                 // e.g., "../fraudML/classify.py"
configurable boolean useOcrApi = true;
configurable string ocrScriptPath = ?;                // e.g., "../fraudML/extract_text.py"

// ---- Types ----
public type JobPostingRequest record {|
    string title;
    string description;
    string? imageData;
|};

public type FraudResponse record {|
    boolean isFraud;
    decimal confidenceScore;
    string message;
|};

// Helper: pick a temp directory (TMPDIR -> /tmp)
function getTmpDir() returns string {
    string tmp = "/tmp";
    string? envTmp = os:getEnv("TMPDIR");
    if envTmp is string && envTmp.length() > 0 {
        tmp = envTmp;
    }
    if tmp.endsWith("/") {
        tmp = tmp.substring(0, tmp.length() - 1);
    }
    return tmp;
}

service / on new http:Listener(9091) {

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

    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000", "http://localhost:3001"],
            allowCredentials: true,
            allowHeaders: ["*"],
            allowMethods: ["POST", "OPTIONS", "GET"]
        }
    }
    resource function post checkFraud(@http:Payload JobPostingRequest posting)
            returns FraudResponse|error {
        log:printInfo("Received request to check fraud for job posting: " + posting.title);
        FraudResponse response = check callMLModel(posting.title, posting.description);
        return response;
    }

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
            string? name = part.getContentDisposition().name;
            if name is string && name == "image" {
                byte[] bytes = check part.getByteArray();
                io:println("Received image of size: " + bytes.length().toString() + " bytes");
                extractedText = check extractTextFromImage(bytes);
            }
        }

        return { text: extractedText };
    }
}

// ---- ML bridge ----
function callMLModel(string title, string description) returns FraudResponse|error {
    string tmp = getTmpDir();
    string tempFilePath = tmp + "/fraudlk_temp_job_data.txt";
    string jobData = title + "\n" + description;
    check io:fileWriteString(tempFilePath, jobData);

    log:printInfo(string `Calling ML model: ${pythonBin} ${mlScriptPath} ${tempFilePath}`);

    os:Process|os:Error execResult = os:exec({
        value: pythonBin,
        arguments: [mlScriptPath, tempFilePath]
    });

    if execResult is os:Process {
        os:Process process = execResult;
        int exitCode = check process.waitForExit();

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

        // cleanup AFTER process finished
        var delRes = file:remove(tempFilePath);
        if delRes is error {
            log:printError("Failed to remove temp file", 'error = delRes);
        }

        log:printInfo("ML model returned: " + result + " with exit code: " + exitCode.toString());

        if (exitCode != 0) {
            return error("ML model execution failed");
        }

        boolean isFraud = strings:trim(result) == "1";
        return {
            isFraud: isFraud,
            confidenceScore: isFraud ? 0.85 : 0.98,
            message: isFraud
                ? "This job posting has characteristics similar to fraudulent posts."
                : "This job posting appears to be legitimate."
        };
    } else {
        // ensure cleanup even on spawn failure
        var delRes = file:remove(tempFilePath);
        if delRes is error {
            log:printError("Failed to remove temp file (spawn error path)", 'error = delRes);
        }
        os:Error e = execResult;
        log:printError("Failed to execute ML script: " + e.message());
        return error("Failed to process job posting");
    }
}

// ---- OCR bridge ----
function extractTextFromImage(byte[] imageData) returns string|error {
    if !useOcrApi {
        return "OCR is currently disabled. Please enter job details manually or enable OCR in the backend configuration.";
    }

    string tmp = getTmpDir();
    string tempImagePath = tmp + "/fraudlk_temp_image.jpg";
    check io:fileWriteBytes(tempImagePath, imageData);
    log:printInfo("Saved image for OCR at: " + tempImagePath);

    os:Process|os:Error execResult = os:exec({
        value: pythonBin,
        arguments: [ocrScriptPath, tempImagePath]
    });

    if execResult is os:Process {
        os:Process process = execResult;
        int exitCode = check process.waitForExit();

        string extractedText = "";
        byte[]|os:Error outputResult = process.output();
        if (outputResult is byte[]) {
            string|error stringResult = strings:fromBytes(outputResult);
            if (stringResult is string) {
                extractedText = stringResult;
            } else {
                log:printError("Failed to convert OCR output to string: " + stringResult.message());
            }
        }

        // cleanup AFTER process finished
        var delRes = file:remove(tempImagePath);
        if delRes is error {
            log:printError("Failed to remove temp image", 'error = delRes);
        }

        if (exitCode != 0) {
            log:printError("OCR script failed with exit code: " + exitCode.toString());
            return "Failed to extract text from image. Make sure Python/Tesseract and dependencies are installed.";
        }

        return extractedText;
    } else {
        // ensure cleanup even on spawn failure
        var delRes = file:remove(tempImagePath);
        if delRes is error {
            log:printError("Failed to remove temp image (spawn error path)", 'error = delRes);
        }
        os:Error e = execResult;
        log:printError("Failed to execute OCR script: " + e.message());
        return "Failed to extract text from image. Cannot start Python process.";
    }
}