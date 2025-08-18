import ballerina/http;
import ballerina/io;
import ballerina/crypto;
import ballerina/file;
import ballerina/lang.'json as jsonutils;
import ballerina/os;

const string DATA_FILE = "backend/results.json";

function loadResults() returns json {
    if file:exists(DATA_FILE) {
        return check io:fileReadJson(DATA_FILE);
    }
    return {};
}

function saveResults(json j) {
    checkpanic io:fileWriteJson(DATA_FILE, j);
}

service / on new http:Listener(8080) {
    resource function post check(http:Request req) returns json|http:InternalServerError {
        json payload = check req.getJsonPayload();
        string|error? url = payload.url?.toString();
        string|error? img = payload.imageBase64?.toString();

        string key;
        string pythonCmd = os:getEnv("PYTHON_CMD") ?: "python3";
        string[] args;
        if url is string && url.trim().length() > 0 {
            key = url;
            args = [pythonCmd, "fraudML/process.py", "--url", url];
        } else if img is string && img.trim().length() > 0 {
            key = img;
            args = [pythonCmd, "fraudML/process.py", "--image", img];
        } else {
            return {"error": "No input provided"};
        }

        string hash = crypto:hashMd5Hex(key.toBytes());
        json results = loadResults();
        var cached = results[hash];
        if cached is json {
            return cached;
        }

        var execResult = os:exec(args);
        json output;
        if execResult is os:Process {
            if execResult.exitCode != 0 {
                io:println(execResult.stderr);
                return {"error": "Processing failed"};
            }
            output = check jsonutils:fromString(execResult.stdout);
        } else {
            io:println(execResult.toString());
            return {"error": "Python executable not found"};
        }
        results[hash] = output;
        saveResults(results);
        return output;
    }
}
