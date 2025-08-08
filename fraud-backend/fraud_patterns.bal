import ballerina/regex;

# Fraud Detection Rules and Patterns Module
# This module contains comprehensive rules for detecting fraudulent job posts

# Advanced fraud patterns and their weights
public type FraudPattern record {|
    string pattern;
    string description;
    decimal weight;
    string category;
|};

# Comprehensive fraud detection patterns
public final FraudPattern[] FRAUD_PATTERNS = [
    // Payment-related fraud indicators (High Risk)
    {
        pattern: ".*(?:pay|payment|deposit).*(?:fee|amount|money).*",
        description: "Requires payment or fee",
        weight: 30.0,
        category: "PAYMENT_REQUIRED"
    },
    {
        pattern: ".*registration.*fee.*",
        description: "Registration fee required",
        weight: 35.0,
        category: "PAYMENT_REQUIRED"
    },
    {
        pattern: ".*processing.*fee.*",
        description: "Processing fee required",
        weight: 30.0,
        category: "PAYMENT_REQUIRED"
    },
    {
        pattern: ".*security.*deposit.*",
        description: "Security deposit required",
        weight: 25.0,
        category: "PAYMENT_REQUIRED"
    },
    {
        pattern: ".*training.*fee.*",
        description: "Training fee required",
        weight: 25.0,
        category: "PAYMENT_REQUIRED"
    },
    
    // Unrealistic promises (High Risk)
    {
        pattern: ".*(?:guaranteed|assured).*(?:income|salary|earning).*",
        description: "Guaranteed income promised",
        weight: 25.0,
        category: "UNREALISTIC_PROMISES"
    },
    {
        pattern: ".*earn.*(?:lakhs|50000|100000|₹|rs\\.?).*(?:month|monthly).*",
        description: "Unrealistic salary promises",
        weight: 20.0,
        category: "UNREALISTIC_PROMISES"
    },
    {
        pattern: ".*(?:quick|easy|fast).*money.*",
        description: "Quick money schemes",
        weight: 25.0,
        category: "UNREALISTIC_PROMISES"
    },
    {
        pattern: ".*(?:earn|make).*(?:from day 1|immediately|instantly).*",
        description: "Immediate earning promises",
        weight: 20.0,
        category: "UNREALISTIC_PROMISES"
    },
    
    // No qualification requirements (Medium Risk)
    {
        pattern: ".*no.*(?:experience|qualification|skill).*(?:required|needed).*",
        description: "No experience or qualification required",
        weight: 15.0,
        category: "NO_REQUIREMENTS"
    },
    {
        pattern: ".*(?:any|basic).*(?:qualification|education).*(?:accepted|sufficient).*",
        description: "Any qualification accepted",
        weight: 10.0,
        category: "NO_REQUIREMENTS"
    },
    
    // Urgency and pressure tactics (Medium Risk)
    {
        pattern: ".*(?:urgent|immediate|hurry|limited).*(?:hiring|opening|seats|vacancy).*",
        description: "Urgent hiring pressure",
        weight: 15.0,
        category: "PRESSURE_TACTICS"
    },
    {
        pattern: ".*(?:apply|join|register).*(?:now|today|immediately).*",
        description: "Immediate action required",
        weight: 10.0,
        category: "PRESSURE_TACTICS"
    },
    {
        pattern: ".*(?:limited|only|last).*(?:seats|positions|chance).*",
        description: "Limited opportunity pressure",
        weight: 12.0,
        category: "PRESSURE_TACTICS"
    },
    
    // Work from home schemes (Low-Medium Risk)
    {
        pattern: ".*work.*from.*home.*",
        description: "Work from home opportunity",
        weight: 8.0,
        category: "REMOTE_WORK"
    },
    {
        pattern: ".*(?:part.?time|flexible).*(?:work|job|timing).*",
        description: "Part-time or flexible work",
        weight: 5.0,
        category: "REMOTE_WORK"
    },
    
    // Contact and legitimacy issues (Medium Risk)
    {
        pattern: ".*(?:whatsapp|sms|telegram).*(?:only|contact).*",
        description: "Only informal communication channels",
        weight: 15.0,
        category: "CONTACT_ISSUES"
    },
    {
        pattern: ".*(?:gmail|yahoo|hotmail).*(?:com|in|org).*",
        description: "Free email services for business",
        weight: 8.0,
        category: "CONTACT_ISSUES"
    },
    
    // MLM and pyramid schemes (High Risk)
    {
        pattern: ".*(?:refer|bring).*(?:friends|people).*(?:earn|bonus).*",
        description: "Referral-based earning",
        weight: 20.0,
        category: "MLM_SCHEME"
    },
    {
        pattern: ".*(?:network|multi.?level|pyramid).*(?:marketing|business).*",
        description: "Network marketing or MLM",
        weight: 25.0,
        category: "MLM_SCHEME"
    },
    
    // Data entry scams (Medium Risk)
    {
        pattern: ".*(?:simple|easy).*(?:data.?entry|copy.?paste|form.?filling).*",
        description: "Simple data entry claims",
        weight: 12.0,
        category: "DATA_ENTRY_SCAM"
    },
    {
        pattern: ".*(?:typing|captcha).*(?:work|job).*(?:home|online).*",
        description: "Typing or captcha work from home",
        weight: 10.0,
        category: "DATA_ENTRY_SCAM"
    }
];

# High-risk fraud keywords
public final string[] HIGH_RISK_KEYWORDS = [
    "registration fee", "processing fee", "security deposit", "training fee",
    "guaranteed income", "quick money", "easy money", "make money fast",
    "no experience required", "any qualification", "immediate joining",
    "work from home", "part time job", "copy paste work", "data entry",
    "earn from day 1", "weekly payment", "no target", "flexible timing",
    "whatsapp only", "telegram contact", "refer friends", "bring people",
    "network marketing", "mlm", "pyramid scheme", "advance payment"
];

# Legitimate job indicators (negative weights)
public final FraudPattern[] LEGITIMATE_PATTERNS = [
    {
        pattern: ".*(?:interview|assessment|test).*(?:required|mandatory|process).*",
        description: "Proper interview process",
        weight: -10.0,
        category: "LEGITIMATE_PROCESS"
    },
    {
        pattern: ".*(?:office|workplace|on.?site).*(?:work|job|position).*",
        description: "Office-based work",
        weight: -8.0,
        category: "LEGITIMATE_PROCESS"
    },
    {
        pattern: ".*(?:experience|qualification|degree).*(?:required|preferred|mandatory).*",
        description: "Proper qualification requirements",
        weight: -5.0,
        category: "LEGITIMATE_PROCESS"
    },
    {
        pattern: ".*(?:salary|compensation).*(?:as per|based on|according to).*(?:experience|industry|standards).*",
        description: "Realistic salary based on experience",
        weight: -5.0,
        category: "LEGITIMATE_PROCESS"
    }
];

# Analyze text using comprehensive fraud patterns
# + text - Text to analyze
# + return - Detailed analysis result
public function analyzeWithPatterns(string text) returns map<anydata> {
    string lowerText = text.toLowerAscii();
    decimal totalScore = 0.0;
    string[] matchedPatterns = [];
    map<decimal> categoryScores = {};
    
    // Check fraud patterns
    foreach FraudPattern pattern in FRAUD_PATTERNS {
        if regex:matches(lowerText, pattern.pattern) {
            totalScore += pattern.weight;
            matchedPatterns.push(pattern.description);
            
            // Update category scores
            decimal currentScore = categoryScores[pattern.category] ?: 0.0;
            categoryScores[pattern.category] = currentScore + pattern.weight;
        }
    }
    
    // Check legitimate patterns
    foreach FraudPattern pattern in LEGITIMATE_PATTERNS {
        if regex:matches(lowerText, pattern.pattern) {
            totalScore += pattern.weight; // Negative weight reduces fraud score
            matchedPatterns.push(pattern.description + " (Positive indicator)");
        }
    }
    
    // Check for high-risk keywords
    string[] foundKeywords = [];
    foreach string keyword in HIGH_RISK_KEYWORDS {
        if lowerText.includes(keyword) {
            foundKeywords.push(keyword);
            totalScore += 5.0; // Each keyword adds 5 points
        }
    }
    
    // Ensure score is not negative
    if totalScore < 0.0 {
        totalScore = 0.0;
    }
    
    // Cap at 100
    if totalScore > 100.0 {
        totalScore = 100.0;
    }
    
    return {
        "fraudScore": totalScore,
        "isFraudulent": totalScore >= 50.0,
        "riskLevel": getRiskLevel(totalScore),
        "matchedPatterns": matchedPatterns,
        "suspiciousKeywords": foundKeywords,
        "categoryScores": categoryScores,
        "recommendation": getRecommendation(totalScore, categoryScores)
    };
}

# Get risk level based on fraud score
# + score - Fraud score
# + return - Risk level description
function getRiskLevel(decimal score) returns string {
    if score >= 80.0 {
        return "CRITICAL";
    } else if score >= 60.0 {
        return "HIGH";
    } else if score >= 40.0 {
        return "MEDIUM";
    } else if score >= 20.0 {
        return "LOW";
    } else {
        return "MINIMAL";
    }
}

# Get recommendation based on analysis
# + score - Fraud score
# + categoryScores - Scores by category
# + return - Recommendation text
function getRecommendation(decimal score, map<decimal> categoryScores) returns string {
    if score >= 80.0 {
        return "REJECT IMMEDIATELY - This job post shows multiple critical fraud indicators. Do not apply or provide any personal information.";
    } else if score >= 60.0 {
        string highestCategory = getHighestScoringCategory(categoryScores);
        return string `HIGH RISK - This job post shows significant fraud indicators, particularly in ${highestCategory}. Exercise extreme caution and verify independently before proceeding.`;
    } else if score >= 40.0 {
        return "MODERATE RISK - This job post has some concerning elements. Research the company thoroughly and be cautious of any requests for money or personal information.";
    } else if score >= 20.0 {
        return "LOW RISK - This job post appears mostly legitimate but has minor red flags. Proceed with normal caution and verify company details.";
    } else {
        return "APPEARS LEGITIMATE - This job post shows minimal fraud indicators. Still verify company information through official channels.";
    }
}

# Get the category with the highest fraud score
# + categoryScores - Map of category scores
# + return - Category name with highest score
function getHighestScoringCategory(map<decimal> categoryScores) returns string {
    decimal maxScore = 0.0;
    string maxCategory = "UNKNOWN";
    
    foreach var [category, score] in categoryScores.entries() {
        if score > maxScore {
            maxScore = score;
            maxCategory = category;
        }
    }
    
    return maxCategory;
}
