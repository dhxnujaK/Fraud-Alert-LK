import ballerina/sql;
import ballerina/crypto;

public type CacheRow record {|
    string classification;
    decimal confidence;
|};

public isolated class CacheService {
    private final sql:Client db;

    public function init(sql:Client dbClient) {
        self.db = dbClient;
    }

    public function generateHash(string input) returns string {
        byte[] digest = crypto:hashSha256(input.toBytes());
        return self.toHex(digest); 
    }

    function toHex(byte[] bytes) returns string {
        string s = "";
        string[] HEX = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"];
        foreach byte b in bytes {
            int ub = (<int>b) & 0xFF;
            s = s + HEX[ub >> 4] + HEX[ub & 0x0F];
        }
        return s;
    }

    public function checkCache(string hash) returns CacheRow|sql:NoRowsError|error {
        sql:ParameterizedQuery q =
            `SELECT classification, confidence FROM job_posts WHERE hash = ${hash}`;
        return self.db->queryRow(q, CacheRow);
    }

    public function storeResult(
        string hash, string inputType, string originalInput,
        string classification, decimal confidence
    ) returns error? {
        sql:ParameterizedQuery q =
            `INSERT INTO job_posts (hash, input_type, original_input, classification, confidence)
             VALUES (${hash}, ${inputType}, ${originalInput}, ${classification}, ${confidence})
             ON DUPLICATE KEY UPDATE
                input_type = VALUES(input_type),
                original_input = VALUES(original_input),
                classification = VALUES(classification),
                confidence = VALUES(confidence)`;
        _ = check self.db->execute(q);
    }
}