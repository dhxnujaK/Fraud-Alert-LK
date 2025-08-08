import sys
import joblib
import re
import nltk
from nltk.corpus import stopwords

nltk.download("stopwords", quiet=True)
stop_words = set(stopwords.words("english"))

def clean_text(text):
    text = text.lower()
    text = re.sub(r"http\S+", "", text)
    text = re.sub(r"[^a-z\s]", "", text)
    tokens = text.split()
    tokens = [word for word in tokens if word not in stop_words]
    return " ".join(tokens)

# Load model + vectorizer
model = joblib.load("fraud_model.pkl")
vectorizer = joblib.load("tfidf_vectorizer.pkl")

# Combine input from command line
title = sys.argv[1]
description = sys.argv[2]
text = title + " " + description

# Clean and vectorize
cleaned = clean_text(text)
X = vectorizer.transform([cleaned])
prediction = model.predict(X)[0]

print(int(prediction))  # 0 = real, 1 = fraud