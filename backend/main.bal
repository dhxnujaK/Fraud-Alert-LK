import ballerina/http;
import ballerina/io;
import ballerina/crypto;
import ballerina/file;
import ballerina/encoding;
import ballerina/lang.'json as jsonutils;
import ballerina/os;

const string DATA_FILE = "backend/results.json";

function loadResults() returns json {
    if file:exists(DATA_FILE) {
        string content = check io:fileReadString(DATA_FILE);
        return check jsonutils:fromString(content);
    }
    return {};
}

function saveResults(json j) {
    string content = j.toJsonString();
    checkpanic io:fileWriteString(DATA_FILE, content);
}

service / on new http:Listener(8080) {
    resource function post check(http:Request req) returns json|http:InternalServerError {
        json payload = check req.getJsonPayload();
        string|error? url = payload.url?.toString();
        string|error? img = payload.imageBase64?.toString();

        string key;
        string[] args;
        if url is string && url.trim().length() > 0 {
            key = url;
            args = ["python3","fraudML/process.py","--url",url];
        } else if img is string && img.trim().length() > 0 {
            key = img;
            args = ["python3","fraudML/process.py","--image",img];
        } else {
            return {"error":"No input provided"};
        }

        string hash = encoding:hexEncode(crypto:hashMd5(key.toBytes()));
        json results = loadResults();
        var cached = results[hash];
        if cached is json {
            return cached;
        }

        var process = os:exec(args);
        if process.exitCode != 0 {
            io:println(process.stderr);
            return {"error":"Processing failed"};
        }
        json output = check jsonutils:fromString(process.stdout);
        results[hash] = output;
        saveResults(results);
        return output;
    }
}
