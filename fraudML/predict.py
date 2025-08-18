import sys
import json
import re
import joblib
import numpy as np
import nltk
from nltk.corpus import stopwords
from scipy.sparse import hstack, csr_matrix

try:
    with open("threshold.txt") as f:
        THRESHOLD = float(f.read().strip())
except Exception:
    THRESHOLD = 0.50

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

EXTRA_COLS = ["keyword_hits","has_money","num_links","has_phone","has_email","num_exclaim","upper_ratio","word_count"]

model = joblib.load("fraud_model.pkl")
vectorizer = joblib.load("tfidf_vectorizer.pkl")

nltk.download("stopwords", quiet=True)
stop_words = set(stopwords.words("english"))

money_pat = r'(\$|usd|rs\.?|lkr|₹|rs|r\.s\.?)\s?\d[\d,\.]*'
url_pat   = r'(http[s]?://|www\.)\S+'
phone_pat = r'(\+?\d[\d\-\s]{7,}\d)'
email_pat = r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'

def clean_text(text: str) -> str:
    text = text.lower()
    text = re.sub(r"http\S+|www\.\S+", "", text)
    text = re.sub(r"[^a-z\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    tokens = [w for w in text.split() if w not in stop_words]
    return " ".join(tokens)


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


def predict_text(text: str):
    cleaned = clean_text(text)
    X_text = vectorizer.transform([cleaned])
    ef = extra_features(text)
    extra_row = np.array([[ef[c] for c in EXTRA_COLS]], dtype=np.float32)
    X_extra = csr_matrix(extra_row)
    X_input = hstack([X_text, X_extra])
    prob = model.predict_proba(X_input)[0][1]
    pred = int(prob >= THRESHOLD)
    return {"prediction": pred, "probability": float(prob)}


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(json.dumps({"error": "usage: python predict.py 'text'"}))
        sys.exit(1)
    res = predict_text(sys.argv[1])
    print(json.dumps(res))
