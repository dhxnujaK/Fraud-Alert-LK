import ballerina/http;
import ballerina/io;
import ballerina/test;

# Test configuration
final string BASE_URL = "http://localhost:8080/fraud-detection";

# Test the health endpoint
@test:Config {}
function testHealthEndpoint() returns error? {
    http:Client testClient = check new (BASE_URL);
    
    http:Response response = check testClient->get("/health");
    test:assertEquals(response.statusCode, 200);
    
    json payload = check response.getJsonPayload();
    test:assertEquals(payload.status, "healthy");
    
    io:println("✓ Health endpoint test passed");
}

# Test text analysis endpoint
@test:Config {}
function testTextAnalysis() returns error? {
    http:Client testClient = check new (BASE_URL);
    
    json requestPayload = {
        "text": "Urgent hiring! Pay registration fee Rs. 5000. Guaranteed income Rs. 50000/month. No experience required. Work from home. Apply now!"
    };
    
    http:Response response = check testClient->post("/analyze-text", requestPayload);
    test:assertEquals(response.statusCode, 200);
    
    json payload = check response.getJsonPayload();
    
    // Should detect fraud
    boolean|error isFraudulent = payload.isFraudulent;
    test:assertTrue(isFraudulent is boolean && isFraudulent);
    
    // Should have a high fraud score
    decimal|error fraudScore = payload.fraudScore;
    test:assertTrue(fraudScore is decimal && fraudScore > 50.0);
    
    io:println("✓ Text analysis test passed");
    io:println(string `   Fraud Score: ${fraudScore}`);
}

# Test legitimate job post
@test:Config {}
function testLegitimateJobPost() returns error? {
    http:Client testClient = check new (BASE_URL);
    
    json requestPayload = {
        "text": "Software Engineer position at Tech Corp. Requirements: 3+ years experience in Java. Competitive salary based on experience. Interview process includes technical assessment. Office-based work in Mumbai."
    };
    
    http:Response response = check testClient->post("/analyze-text", requestPayload);
    test:assertEquals(response.statusCode, 200);
    
    json payload = check response.getJsonPayload();
    
    // Should not detect fraud
    boolean|error isFraudulent = payload.isFraudulent;
    test:assertTrue(isFraudulent is boolean && !isFraudulent);
    
    // Should have a low fraud score
    decimal|error fraudScore = payload.fraudScore;
    test:assertTrue(fraudScore is decimal && fraudScore < 50.0);
    
    io:println("✓ Legitimate job post test passed");
    io:println(string `   Fraud Score: ${fraudScore}`);
}

# Test invalid request
@test:Config {}
function testInvalidRequest() returns error? {
    http:Client testClient = check new (BASE_URL);
    
    json requestPayload = {
        "invalid_field": "test"
    };
    
    http:Response response = check testClient->post("/analyze-text", requestPayload);
    test:assertEquals(response.statusCode, 200);
    
    json payload = check response.getJsonPayload();
    
    // Should return error
    string|error errorField = payload.'error;
    test:assertTrue(errorField is string);
    
    io:println("✓ Invalid request test passed");
}

# Run all tests
public function main() returns error? {
    io:println("Starting Fraud Detection Backend Tests...\n");
    
    error? healthTest = testHealthEndpoint();
    if healthTest is error {
        io:println("✗ Health test failed: " + healthTest.message());
        return healthTest;
    }
    
    error? textTest = testTextAnalysis();
    if textTest is error {
        io:println("✗ Text analysis test failed: " + textTest.message());
        return textTest;
    }
    
    error? legitTest = testLegitimateJobPost();
    if legitTest is error {
        io:println("✗ Legitimate job test failed: " + legitTest.message());
        return legitTest;
    }
    
    error? invalidTest = testInvalidRequest();
    if invalidTest is error {
        io:println("✗ Invalid request test failed: " + invalidTest.message());
        return invalidTest;
    }
    
    io:println("\n🎉 All tests passed successfully!");
    io:println("Fraud Detection Backend is working correctly.");
}
