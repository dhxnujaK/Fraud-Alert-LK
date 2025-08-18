
# classify.py
import sys
import re
import joblib
import numpy as np
import nltk
from nltk.corpus import stopwords
from scipy.sparse import hstack, csr_matrix

# --------------------------
# Load persisted artifacts
# --------------------------
# Threshold tuned during training (fallback 0.50)
try:
    with open("threshold.txt") as f:
        THRESHOLD = float(f.read().strip())
except Exception:
    THRESHOLD = 0.50

# Scam keywords used in training (fallback list)
try:
    with open("scam_keywords.txt") as f:
        SCAM_KEYWORDS = [line.strip().lower() for line in f if line.strip()]
except Exception:
    SCAM_KEYWORDS = [
        "no experience", "earn money", "work from home", "quick money", "easy money",
        "guaranteed", "limited openings", "instant payout", "processing fee",
        "deposit", "click here", "sign up now", "whatsapp", "telegram", "crypto",
        "daily payout", "be your own boss"
    ]

# The extra feature columns and order must match training
EXTRA_COLS = ["keyword_hits","has_money","num_links","has_phone","has_email","num_exclaim","upper_ratio","word_count"]

# Model + vectorizer
model = joblib.load("fraud_model.pkl")
vectorizer = joblib.load("tfidf_vectorizer.pkl")

# --------------------------
# Preprocessing utilities
# --------------------------
nltk.download("stopwords", quiet=True)
stop_words = set(stopwords.words("english"))

def clean_text(text: str) -> str:
    text = text.lower()
    text = re.sub(r"http\S+|www\.\S+", "", text)
    text = re.sub(r"[^a-z\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    tokens = [w for w in text.split() if w not in stop_words]
    return " ".join(tokens)

money_pat = r'(\$|usd|rs\.?|lkr|₹|rs|r\.s\.?)\s?\d[\d,\.]*'
url_pat   = r'(http[s]?://|www\.)\S+'
phone_pat = r'(\+?\d[\d\-\s]{7,}\d)'
email_pat = r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'

def extra_features(raw_text: str):
    t = raw_text
    low = t.lower()
    words = re.findall(r"[a-zA-Z]+", t)
    wc = max(len(words), 1)
    caps = sum(1 for w in words if len(w) > 2 and w.isupper())
    return {
        "keyword_hits": sum(1 for k in SCAM_KEYWORDS if k in low),
        "has_money": int(bool(re.search(money_pat, low))),
        "num_links": len(re.findall(url_pat, low)),
        "has_phone": int(bool(re.search(phone_pat, t))),
        "has_email": int(bool(re.search(email_pat, low))),
        "num_exclaim": t.count("!"),
        "upper_ratio": caps / wc,
        "word_count": wc
    }

# --------------------------
# CLI args
# --------------------------
if len(sys.argv) != 3:
    print("Usage: python classify.py '<title>' '<description>'")
    sys.exit(1)

title = sys.argv[1]
description = sys.argv[2]

# Build raw text (same fields used for engineered features during training)
raw_text = f"{title} {description}"
cleaned = clean_text(raw_text)

# Vectorize text
X_text = vectorizer.transform([cleaned])

# Build engineered features in the correct order
ef = extra_features(raw_text)
extra_row = np.array([[ef[c] for c in EXTRA_COLS]], dtype=np.float32)
X_extra = csr_matrix(extra_row)

# Combine TF-IDF + engineered features
X_input = hstack([X_text, X_extra])

# Predict probability and apply tuned threshold
prob = model.predict_proba(X_input)[0][1]
pred = int(prob >= THRESHOLD)

# Output
if pred == 1:
    print("🔴 This job post is predicted to be: FRAUDULENT (1)")
else:
    print("🟢 This job post is predicted to be: REAL (0)")

print(f"🔍 Fraud Probability Score: {prob:.2f}")
print(f"(Threshold used: {THRESHOLD:.2f})")