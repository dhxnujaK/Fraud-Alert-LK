# 🔎 Fraud Alert LK — Job Posting Scam Classifier

Fraud Alert LK is a full-stack platform developed by Team Uplinkers to protect job seekers from fraudulent job postings.
The system analyzes both text and image-based job ads using OCR and machine learning, classifying them as legitimate or fraudulent.
With a caching and database layer powered by Ballerina and MySQL, repeated scam ads are flagged instantly, making the system efficient and reliable.

---

## 🚀 Features

* Upload job ads as text or images
* OCR integration for image-based ads
* Machine learning classifier for fraud detection
* Confidence scores for predictions
* Caching system to avoid redundant ML calls
* Fast backend services built in Ballerina
* User-friendly React frontend

---

## 🛠 Tech Stack

* Frontend: React (fraudfrontend/)
* Backend: Ballerina (fraudbackend/)
* Machine Learning: Python (fraudML/)
* Database & Cache: MySQL

---

## 📂 Project Structure

📦 Fraud-Alert-LK
├── fraudbackend/      - Ballerina backend
├── fraudfrontend/     - React frontend
├── fraudML/           - Python ML model (classify + OCR)
└── README.md

---

## ⚙️ Installation & Running the Project

### 1. Clone the Repository

git clone <repo-url>
cd fraud-alert-lk

### 2. Set Up the Database

* Install MySQL and create the database:

CREATE DATABASE IF NOT EXISTS job_fraud_db;
USE job_fraud_db;

CREATE TABLE IF NOT EXISTS job_posts (
  hash           CHAR(64) PRIMARY KEY,
  input_type     VARCHAR(20) NOT NULL,
  original_input TEXT NOT NULL,
  classification ENUM('fraud','real') NOT NULL,
  confidence     DECIMAL(5,2) NOT NULL,
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

---

### 3. Configure Backend (fraudbackend/config.toml)

Before running the backend, update the config file with your environment:


#### --- DB config (set your own password) ---

dbHost = "127.0.0.1"
dbUser = "root"
dbPassword = "YOUR_PASSWORD_HERE"
dbName = "job_fraud_db"
dbPort = 3306

---

### 4. Set Up Python ML Environment

cd fraudML
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt

The ML module includes:

* classify.py → takes job title + description, outputs fraud / real classification
* extract\_text.py → OCR-based extraction from images (used if useOcrApi=true)

Ballerina automatically spawns these scripts using the config values, so you don’t need to run ML separately.

---

### 5. Run the Backend (Ballerina)

cd fraudbackend
bal run

---

### 6. Run the Frontend (React)

cd fraudfrontend
npm install
npm start

---

## 🔗 How It Works

1. User uploads a job ad (text/image) via the React frontend.
2. The Ballerina backend receives the request, generates a hash key, and checks the MySQL database/cache.
3. If it’s a cache hit → return the stored result instantly.
4. If it’s a cache miss → Ballerina spawns the Python ML script and gets the result.
5. The ML result is stored in the database and sent back to the frontend.

---

## 👥 Team Uplinkers

* Dhanuja Kahatapitiya
* Nethmini Herath
* Bipuli Wanniarachchi
* Bumeega Vikurandha

---
