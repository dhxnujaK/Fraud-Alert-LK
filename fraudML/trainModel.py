import pandas as pd
import re
import nltk
import joblib
from nltk.corpus import stopwords
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import classification_report, confusion_matrix
from imblearn.over_sampling import SMOTE
from xgboost import XGBClassifier

# Step 1: Load dataset
df = pd.read_csv("fake_job_postings.csv")

# Step 2: Display dataset info
print("Dataset shape:", df.shape)
print("\nColumn names:\n", df.columns)

# Step 3: Drop missing titles or descriptions
df = df.dropna(subset=["title", "description"])

# Step 4: Combine title + description
df["text"] = df["title"] + " " + df["description"]
df = df[["text", "fraudulent"]]  # keep only necessary columns

# Step 5: Class distribution
print("\nClass distribution (0 = real, 1 = fake):")
print(df["fraudulent"].value_counts())
print("\nExample FAKE job ad:\n", df[df["fraudulent"] == 1]["text"].iloc[0])

# Step 6: Clean text
nltk.download("stopwords")
stop_words = set(stopwords.words("english"))

def clean_text(text):
    text = text.lower()
    text = re.sub(r"http\S+", "", text)
    text = re.sub(r"[^a-z\s]", "", text)
    tokens = text.split()
    tokens = [word for word in tokens if word not in stop_words]
    return " ".join(tokens)

df["cleaned_text"] = df["text"].apply(clean_text)
print("\nCleaned sample:\n", df["cleaned_text"].iloc[0])

# Step 7: TF-IDF Vectorization
vectorizer = TfidfVectorizer(max_features=5000)
X = vectorizer.fit_transform(df["cleaned_text"])
y = df["fraudulent"]

# Step 8: Train-Test Split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Step 9: Apply SMOTE
smote = SMOTE(random_state=42)
X_train_resampled, y_train_resampled = smote.fit_resample(X_train, y_train)
print("\nAfter SMOTE - Resampled class distribution:")
print(pd.Series(y_train_resampled).value_counts())

# Step 10: Train Model with XGBoost
model = XGBClassifier(use_label_encoder=False, eval_metric="logloss")
model.fit(X_train_resampled, y_train_resampled)

# Step 11: Evaluate
y_pred = model.predict(X_test)

conf_mat = confusion_matrix(y_test, y_pred)
report = classification_report(y_test, y_pred)

print("\n🧠 Model Evaluation Report:\n")
print(conf_mat)
print(report)

# Optionally save report to a file
with open("model_evaluation.txt", "w") as f:
    f.write("Confusion Matrix:\n")
    f.write(str(conf_mat))
    f.write("\n\nClassification Report:\n")
    f.write(report)

# Step 12: Save model and vectorizer
joblib.dump(model, "fraud_model.pkl")
joblib.dump(vectorizer, "tfidf_vectorizer.pkl")
print("\n✅ Model and vectorizer saved successfully.")