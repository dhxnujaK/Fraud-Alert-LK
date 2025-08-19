# 🔎 Fraud Alert LK — Job Posting Scam Classifier

A full-stack web application built with **React, Ballerina, and Python ML**, designed to detect fraudulent job postings in Sri Lanka. This project was developed to combine **machine learning, backend orchestration, and frontend UI** into a real-world solution.

---

## 🎯 Project Objective

* ✅ Detect and classify scam vs legitimate job posts
* ✅ Support **image upload**, **URL input**, and **text entry**
* ✅ Demonstrate ML pipeline integration with caching & database
* ✅ Provide an efficient, user-friendly system

---

## 🧠 Core Concepts Covered

* 📸 **OCR Integration**: Extract text from uploaded job screenshots
* 🌐 **Web Extraction**: Scrape/parse job text from URLs
* 🤖 **Machine Learning**: Train & deploy a fraud detection model (Logistic Regression / RoBERTa)
* ⚡ **Database & Caching**: Store results and avoid duplicate ML runs
* 🔗 **Full-stack Integration**: React (UI) ↔ Ballerina (backend) ↔ Python (ML)

---

## 🖥️ Application Modules

### 1. 🖼️ Frontend 

* Developed with **React**
* Features:

  * Upload job ad images
  * Enter job posting URLs
  * Display fraud/legit result with confidence score

### 2. ⚙️ Backend Integration 

* Developed in **Ballerina**
* Responsibilities:

  * Accept input from frontend
  * Handle OCR (images) and scraping (URLs)
  * Communicate with ML service and return results

### 3. 🤖 Machine Learning Service 

* Built in **Python** with **scikit-learn / transformers**
* Responsibilities:

  * Preprocess job text (cleaning, stopword removal, normalization)
  * Train model (e.g., Logistic Regression, fine-tuned RoBERTa)
  * Expose **/predict** REST API (Flask/FastAPI)
  * Return JSON output with result + confidence

### 4. 🗃️ Database & Caching 

* Stores all job entries and results 
* On repeated submissions, returns cached results instead of rerunning ML
* Provides a base for future dashboard analytics (scam ratios, patterns)

---

## 🛠️ Technologies Used

* **Frontend**: React, Axios
* **Backend**: Ballerina (HTTP Services)
* **ML Service**: Python (Flask / FastAPI, scikit-learn, transformers)
* **OCR & Extraction**: Tesseract OCR, web scraping libraries
* **Database**: MySQL 

---

## 📂 Folder & File Structure

```plaintext
📦 Fraud-Alert-LK
├── frontend/              # React frontend
├── backend/               # Ballerina backend (HTTP services, cache logic)
├── fraudML/               # Python ML model + API
├── db/                    # Database schema & migrations
├── scripts/               # Utility scripts (dev/build)
└── README.md
```

---

## 👨‍💻 Authors

* **Dhanuja Kahatapitiya**
* **Nethmini Herath**
* **Bipuli Wanniarachchi** 
* **Bumeega Vikurananda** 

---

