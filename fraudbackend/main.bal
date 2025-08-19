import ballerina/http;
import ballerina/io;
import ballerina/os;
import ballerina/log;
import ballerina/lang.'string as strings;
import ballerina/file;

import ballerinax/mysql;


// Import your submodule defined under modules/cache
import fraudalert/fraudbackend.cache;

// --------------------
// Config
// --------------------
configurable string pythonBin = "/usr/bin/python3";      // or your venv python
configurable string mlScriptPath = ?;                    // e.g., "../fraudML/classify.py"
configurable boolean useOcrApi = true;
configurable string ocrScriptPath = ?;                   // e.g., "../fraudML/extract_text.py"

// DB config (override in Config.toml if needed)
configurable string dbHost = "127.0.0.1";
configurable string dbUser = "root";
configurable string dbPassword = "";
configurable string dbName = "job_fraud_db";
configurable int    dbPort = 3306;

// --------------------
// Types
// --------------------
public type JobPostingRequest record {|
    string title;
    string description;
    string imageData?;
|};

public type FraudResponse record {|
    boolean isFraud;
    decimal confidenceScore;
    string message;
|};

// --------------------
// Helpers
// --------------------
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

// Normalize title + description before hashing so the same content maps to the same key
function normalizeForHash(string title, string description) returns string {
    // Join title + description, trim ends, and lowercase (stable hashing).
    string raw = title + " " + description;
    raw = strings:trim(raw);
    return strings:toLowerAscii(raw);
}
// --------------------
// Singletons: DB + Cache service
// --------------------
mysql:Client dbClient = checkpanic new (dbHost, dbUser, dbPassword, dbName, dbPort);
cache:CacheService cacheService = new (dbClient);

// --------------------
// HTTP Service
// --------------------
service / on new http:Listener(9091) {

    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000", "http://localhost:3001"],
            allowCredentials: true,
            allowHeaders: ["content-type", "authorization", "*"],
            allowMethods: ["GET", "POST", "OPTIONS"]
        }
    }
    resource function get health() returns string {
        return "Fraud detection service is running";
    }

    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000", "http://localhost:3001"],
            allowCredentials: true,
            allowHeaders: ["content-type", "authorization", "*"],
            allowMethods: ["GET", "POST", "OPTIONS"]
        }
    }
    resource function post checkFraud(@http:Payload JobPostingRequest posting)
            returns FraudResponse|error {

        // 0) Normalize & hash for cache key
        string norm = normalizeForHash(posting.title, posting.description);
        string hash = cacheService.generateHash(norm);

        // 1) Try cache
        var cached = cacheService.checkCache(hash);
        if cached is cache:CacheRow {
            log:printInfo("CACHE HIT hash=" + hash);
            return {
                isFraud: cached.classification == "fraud",
                confidenceScore: cached.confidence,
                message: (cached.classification == "fraud")
                    ? "This job posting has characteristics similar to fraudulent posts. (cached)"
                    : "This job posting appears to be legitimate. (cached)"
            };
        }

        log:printInfo("CACHE MISS hash=" + hash + " -> calling ML");

        // 2) Fallback to ML
        FraudResponse mlRes = check callMLModel(posting.title, posting.description);

        // 3) Store in cache (normalized original_input)
        string cls = mlRes.isFraud ? "fraud" : "real";
        error? storeErr = cacheService.storeResult(hash, "text", norm, cls, mlRes.confidenceScore);
        if storeErr is error {
            log:printError("Cache store failed", 'error = storeErr);
        } else {
            log:printInfo("CACHE SAVE hash=" + hash + " class=" + cls);
        }

        return mlRes;
    }

    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000", "http://localhost:3001"],
            allowCredentials: true,
            allowHeaders: ["content-type", "authorization", "*"],
            allowMethods: ["GET", "POST", "OPTIONS"]
        }
    }
    resource function post extractText(http:Request request) returns json|error {
        var parts = check request.getBodyParts();
        string extractedText = "";

        foreach var part in parts {
            string? name = part.getContentDisposition().name;
            if name is string && name == "image" {
                byte[] bytes = check part.getByteArray();
                extractedText = check extractTextFromImage(bytes);
            }
        }
        return { text: extractedText };
    }
}

// --------------------
// ML bridge
// --------------------
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

// --------------------
// OCR bridge
// --------------------
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

    if (execResult is os:Process) {
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