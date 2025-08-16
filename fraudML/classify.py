import sys
import joblib
import re
import nltk
import os
from nltk.corpus import stopwords

# Ensure NLTK data is downloaded
try:
    nltk.data.find('corpora/stopwords')
except LookupError:
    nltk.download("stopwords", quiet=True)

stop_words = set(stopwords.words("english"))

def clean_text(text):
    text = text.lower()
    text = re.sub(r"http\S+", "", text)
    text = re.sub(r"[^a-z\s]", "", text)
    tokens = text.split()
    tokens = [word for word in tokens if word not in stop_words]
    return " ".join(tokens)

def classify_job(title, description):
    # Get the directory of the current script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Load model + vectorizer with absolute paths
    model_path = os.path.join(script_dir, "fraud_model.pkl")
    vectorizer_path = os.path.join(script_dir, "tfidf_vectorizer.pkl")
    
    model = joblib.load(model_path)
    vectorizer = joblib.load(vectorizer_path)

    # Combine input
    text = title + " " + description

    # Clean and vectorize
    cleaned = clean_text(text)
    X = vectorizer.transform([cleaned])
    prediction = model.predict(X)[0]
    
    return int(prediction)  # 0 = real, 1 = fraud

if __name__ == "__main__":
    try:
        if len(sys.argv) == 2:  # Input from file
            input_file = sys.argv[1]
            with open(input_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                if len(lines) >= 2:
                    title = lines[0].strip()
                    description = ' '.join([line.strip() for line in lines[1:]])
                else:
                    title = lines[0].strip() if lines else ""
                    description = ""
        elif len(sys.argv) == 3:  # Direct input arguments
            title = sys.argv[1]
            description = sys.argv[2]
        else:
            print("Usage: python classify.py <input_file> OR python classify.py <title> <description>")
            sys.exit(1)
        
        # Make prediction
        result = classify_job(title, description)
        print(result)
        sys.exit(0)
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)