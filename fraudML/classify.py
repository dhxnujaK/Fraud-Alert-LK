# classify.py
import sys
import re
import joblib
import numpy as np
import nltk
import os
from nltk.corpus import stopwords
from scipy.sparse import hstack, csr_matrix

# --------------------------
# Threshold (fallback 0.50)
# --------------------------
try:
    with open("threshold.txt") as f:
        THRESHOLD = float(f.read().strip())
except Exception:
    THRESHOLD = 0.50

# --------------------------
# NLTK stopwords
# --------------------------
try:
    nltk.data.find('corpora/stopwords')
except LookupError:
    nltk.download("stopwords", quiet=True)
stop_words = set(stopwords.words("english"))

# --------------------------
# Scam keywords (fallback)
# --------------------------
try:
    with open("scam_keywords.txt") as f:
        SCAM_KEYWORDS = [line.strip().lower() for line in f if line.strip()]
except Exception:
    SCAM_KEYWORDS = [
        "no experience","earn money","work from home","quick money","easy money",
        "guaranteed","limited openings","instant payout","processing fee",
        "deposit","click here","sign up now","whatsapp","telegram","crypto",
        "daily payout","be your own boss"
    ]

# The engineered feature columns (length must be 8)
EXTRA_COLS = [
    "keyword_hits","has_money","num_links","has_phone",
    "has_email","num_exclaim","upper_ratio","word_count"
]

# Load model + vectorizer from this directory (robust to CWD)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
model = joblib.load(os.path.join(SCRIPT_DIR, "fraud_model.pkl"))
vectorizer = joblib.load(os.path.join(SCRIPT_DIR, "tfidf_vectorizer.pkl"))

# --------------------------
# Helpers
# --------------------------
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

def model_expected_features(m):
    # Try scikit-learn's attribute
    n = getattr(m, "n_features_in_", None)
    if isinstance(n, (int, np.integer)) and n > 0:
        return int(n)
    # Try xgboost booster
    try:
        booster = m.get_booster()
        n2 = booster.num_features()
        if isinstance(n2, (int, np.integer)):  # xgboost returns int
            return int(n2)
        # some versions return str
        return int(str(n2))
    except Exception:
        pass
    return None  # unknown

def predict_label(title: str, description: str) -> int:
    raw_text = f"{title} {description}"

    # TF-IDF
    cleaned = clean_text(raw_text)
    X_text = vectorizer.transform([cleaned])
    vec_dim = X_text.shape[1]

    # What does the model expect?
    expected = model_expected_features(model)

    # By default, try to match training setup:
    # if expected == vec_dim + 8 -> add engineered features
    # if expected == vec_dim     -> use TF-IDF only
    # if unknown -> try TF-IDF + engineered features first
    X_input = X_text

    need_extra = False
    if expected is not None:
        if expected == vec_dim + len(EXTRA_COLS):
            need_extra = True
        elif expected == vec_dim:
            need_extra = False
        else:
            # model expects something else; best effort: if smaller than vec_dim+8, try TF-IDF only
            need_extra = (expected > vec_dim)
    else:
        # Unknown expected size: prefer adding engineered features (matches your training)
        need_extra = True

    if need_extra:
        ef = extra_features(raw_text)
        extra_row = np.array([[ef[c] for c in EXTRA_COLS]], dtype=np.float32)
        X_extra = csr_matrix(extra_row)
        X_input = hstack([X_text, X_extra])

    prob = model.predict_proba(X_input)[0][1]
    pred = int(prob >= THRESHOLD)
    return pred

# --------------------------
# CLI entry
# --------------------------
if __name__ == "__main__":
    try:
        # Accept either: classify.py <input_file>
        #            or: classify.py "<title>" "<description>"
        if len(sys.argv) == 2:
            input_file = sys.argv[1]
            with open(input_file, 'r', encoding='utf-8', errors='ignore') as f:
                lines = [ln.strip() for ln in f.readlines()]
            title = lines[0] if lines else ""
            description = " ".join(lines[1:]) if len(lines) > 1 else ""
        elif len(sys.argv) == 3:
            title = sys.argv[1]
            description = sys.argv[2]
        else:
            print("1")  # be conservative on bad usage
            sys.exit(0)

        result = predict_label(title, description)
        print(result)  # IMPORTANT: only '0' or '1'
        sys.exit(0)
    except Exception as e:
        # Send details to stderr for backend logs; stdout must stay parseable
        print(f"Error: {e}", file=sys.stderr)
        print("1")  # conservative default: treat as fraud on error
        sys.exit(0)