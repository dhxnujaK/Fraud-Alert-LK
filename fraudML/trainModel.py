import pandas as pd
import numpy as np
import re
import nltk
import joblib
from nltk.corpus import stopwords
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import classification_report, confusion_matrix, precision_recall_curve, average_precision_score
from imblearn.over_sampling import SMOTE
from xgboost import XGBClassifier
from scipy.sparse import hstack, csr_matrix

# -----------------------------
# 1) Load & basic preprocessing
# -----------------------------
df = pd.read_csv("fake_job_postings.csv")

# keep rows with text
df = df.dropna(subset=["title", "description"])

# Helper to safely include optional columns if present
def _safe(col_name: str):
    return df[col_name].fillna("") if col_name in df.columns else ""

# Build a richer text field
df["full_text"] = (
    df["title"].fillna("") + " " +
    df["description"].fillna("") + " " +
    _safe("requirements") + " " +
    _safe("benefits") + " " +
    _safe("company_profile")
)

# -----------------------------
# 2) Clean text
# -----------------------------
nltk.download("stopwords", quiet=True)
stop_words = set(stopwords.words("english"))

def clean_text(text: str) -> str:
    # lowercase
    text = text.lower()
    # remove urls
    text = re.sub(r"http\S+|www\.\S+", "", text)
    # keep only letters & spaces
    text = re.sub(r"[^a-z\s]", " ", text)
    # collapse whitespace
    text = re.sub(r"\s+", " ", text).strip()
    # remove stopwords
    tokens = [w for w in text.split() if w not in stop_words]
    return " ".join(tokens)

df["cleaned_text"] = df["full_text"].apply(clean_text)

# ----------------------------------
# 3) Feature engineering (extra signal)
# ----------------------------------
money_pat = r'(\$|usd|rs\.?|lkr|₹|rs|r\.s\.?)\s?\d[\d,\.]*'
url_pat   = r'(http[s]?://|www\.)\S+'
phone_pat = r'(\+?\d[\d\-\s]{7,}\d)'
email_pat = r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'

SCAM_KEYWORDS = [
    # general scammy phrasing
    "no experience", "earn money", "work from home", "quick money", "easy money",
    "guaranteed", "limited openings", "instant payout", "start immediately",
    "be your own boss", "unlimited income", "financial freedom",
    # upfront payments / fees
    "processing fee", "registration fee", "verification fee", "refundable deposit",
    "upfront cost", "pay to", "bank slip", "training kit",
    # comms channels often abused
    "whatsapp", "telegram", "viber", "+94", "071", "077",
    # payments / crypto
    "upi", "paypal", "skrill", "usdt", "crypto", "binance",
    # urgency / pressure
    "apply now", "limited slots", "act fast", "immediate start"
]

def extra_features(raw_text: str) -> dict:
    t = raw_text
    low = t.lower()
    words = re.findall(r"[a-zA-Z]+", t)
    wc = max(len(words), 1)
    caps = sum(1 for w in words if len(w) > 2 and w.isupper())

    return {
        "keyword_hits": sum(low.count(k) for k in SCAM_KEYWORDS),
        "has_money": int(bool(re.search(money_pat, low))),
        "num_links": len(re.findall(url_pat, low)),
        "has_phone": int(bool(re.search(phone_pat, t))),
        "has_email": int(bool(re.search(email_pat, low))),
        "num_exclaim": t.count("!"),
        "upper_ratio": caps / wc,
        "word_count": wc
    }

# Build extra features from title+description (same as inference)
feats_source = df["title"].fillna("") + " " + df["description"].fillna("")
feats = feats_source.apply(extra_features).apply(pd.Series)
df = pd.concat([df, feats], axis=1)

EXTRA_COLS = ["keyword_hits","has_money","num_links","has_phone","has_email","num_exclaim","upper_ratio","word_count"]

# -----------------------------
# 4) TF-IDF vectorization
# -----------------------------
vectorizer = TfidfVectorizer(
    max_features=20000,       # richer vocabulary
    ngram_range=(1, 2),       # include bigrams
    min_df=3                  # ignore super-rare tokens
)
X_tfidf = vectorizer.fit_transform(df["cleaned_text"])

extra_matrix = csr_matrix(df[EXTRA_COLS].values.astype("float32"))
X = hstack([X_tfidf, extra_matrix])
y = df["fraudulent"].astype(int)

# -----------------------------
# 5) Split & balance (SMOTE on train only)
# -----------------------------
X_train, X_val, y_train, y_val = train_test_split(
    X, y, test_size=0.2, stratify=y, random_state=42
)

smote = SMOTE(random_state=42)
Xtr, ytr = smote.fit_resample(X_train, y_train)

# -----------------------------
# 6) Train XGBoost (tuned defaults)
# -----------------------------
model = XGBClassifier(
    eval_metric="logloss",
    objective="binary:logistic",
    tree_method="hist",
    n_estimators=800,
    learning_rate=0.06,
    max_depth=6,
    subsample=0.9,
    colsample_bytree=0.8,
    reg_lambda=2.0,
    random_state=42
)
model.fit(Xtr, ytr)

# -----------------------------
# 7) Evaluate & choose best threshold (favor recall with F2)
# -----------------------------
y_prob = model.predict_proba(X_val)[:, 1]
y_pred_default = (y_prob >= 0.5).astype(int)

# Default-threshold report
conf_mat = confusion_matrix(y_val, y_pred_default)
report = classification_report(y_val, y_pred_default)

# pick threshold via F2
prec, rec, thr = precision_recall_curve(y_val, y_prob)
beta = 2.0
# precision_recall_curve returns thresholds shorter by 1 than prec/rec
thr_full = np.append(thr, 1.0)
f_beta = (1 + beta**2) * (prec * rec) / (beta**2 * prec + rec + 1e-12)
best_idx = np.nanargmax(f_beta)
best_thr = float(thr_full[best_idx])

ap = average_precision_score(y_val, y_prob)

# Save evaluation summary
with open("model_evaluation.txt", "w") as f:
    f.write("=== Default threshold (0.50) ===\n")
    f.write("Confusion Matrix:\n")
    f.write(str(conf_mat) + "\n\n")
    f.write("Classification Report:\n")
    f.write(report + "\n")
    f.write("=== Threshold tuning (F2) ===\n")
    f.write(f"Best threshold: {best_thr:.4f}\n")
    f.write(f"Average Precision (AUC-PR): {ap:.4f}\n")

# -----------------------------
# 8) Persist artifacts
# -----------------------------
joblib.dump(model, "fraud_model.pkl")
joblib.dump(vectorizer, "tfidf_vectorizer.pkl")

# persist threshold and metadata for inference to match features
with open("threshold.txt", "w") as f:
    f.write(str(best_thr))

with open("extra_columns.txt", "w") as f:
    f.write(",".join(EXTRA_COLS))

with open("scam_keywords.txt", "w") as f:
    for kw in SCAM_KEYWORDS:
        f.write(kw + "\n")

print("✅ Training complete. Saved: fraud_model.pkl, tfidf_vectorizer.pkl, threshold.txt, extra_columns.txt, scam_keywords.txt, model_evaluation.txt")