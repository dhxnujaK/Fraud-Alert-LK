import React, { useState } from 'react';

const FraudDetectionUpload = () => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [analyzing, setAnalyzing] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);

  const handleFileSelect = (event) => {
    const file = event.target.files[0];
    if (file) {
      if (file.type.startsWith('image/')) {
        setSelectedFile(file);
        setError(null);
        setResult(null);
      } else {
        setError('Please select a valid image file (JPEG, PNG, etc.)');
        setSelectedFile(null);
      }
    }
  };

  const analyzeImage = async () => {
    if (!selectedFile) {
      setError('Please select an image file first');
      return;
    }

    setAnalyzing(true);
    setError(null);
    setResult(null);

    try {
      const formData = new FormData();
      formData.append('image', selectedFile);

      const response = await fetch('http://localhost:8080/fraud-detection/analyze', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      if (data.error) {
        setError(data.message || 'Analysis failed');
      } else {
        setResult(data.jobPost);
      }
    } catch (err) {
      setError(`Failed to analyze image: ${err.message}`);
    } finally {
      setAnalyzing(false);
    }
  };

  const getRiskColor = (score) => {
    if (score >= 80) return '#d32f2f'; // Critical - Red
    if (score >= 60) return '#f57c00'; // High - Orange
    if (score >= 40) return '#fbc02d'; // Medium - Yellow
    if (score >= 20) return '#689f38'; // Low - Light Green
    return '#388e3c'; // Minimal - Green
  };

  const getRiskLevel = (score) => {
    if (score >= 80) return 'CRITICAL';
    if (score >= 60) return 'HIGH';
    if (score >= 40) return 'MEDIUM';
    if (score >= 20) return 'LOW';
    return 'MINIMAL';
  };

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto', padding: '20px' }}>
      <h2>Job Post Fraud Detection</h2>
      <p>Upload an image of a job post to analyze it for potential fraud indicators.</p>

      {/* File Upload Section */}
      <div style={{ 
        border: '2px dashed #ccc', 
        borderRadius: '8px', 
        padding: '20px', 
        textAlign: 'center',
        marginBottom: '20px'
      }}>
        <input
          type="file"
          accept="image/*"
          onChange={handleFileSelect}
          style={{ marginBottom: '10px' }}
        />
        {selectedFile && (
          <p style={{ color: '#666', margin: '10px 0' }}>
            Selected: {selectedFile.name} ({Math.round(selectedFile.size / 1024)} KB)
          </p>
        )}
        <button
          onClick={analyzeImage}
          disabled={!selectedFile || analyzing}
          style={{
            backgroundColor: '#007bff',
            color: 'white',
            border: 'none',
            padding: '10px 20px',
            borderRadius: '4px',
            cursor: selectedFile && !analyzing ? 'pointer' : 'not-allowed',
            opacity: selectedFile && !analyzing ? 1 : 0.6
          }}
        >
          {analyzing ? 'Analyzing...' : 'Analyze Job Post'}
        </button>
      </div>

      {/* Error Display */}
      {error && (
        <div style={{
          backgroundColor: '#f8d7da',
          color: '#721c24',
          padding: '10px',
          borderRadius: '4px',
          marginBottom: '20px',
          border: '1px solid #f5c6cb'
        }}>
          <strong>Error:</strong> {error}
        </div>
      )}

      {/* Results Display */}
      {result && (
        <div style={{
          border: '1px solid #ddd',
          borderRadius: '8px',
          padding: '20px',
          backgroundColor: '#f9f9f9'
        }}>
          <h3>Analysis Results</h3>
          
          {/* Fraud Score */}
          <div style={{ marginBottom: '20px' }}>
            <h4>Fraud Score: {result.fraudScore.toFixed(1)}/100</h4>
            <div style={{
              width: '100%',
              backgroundColor: '#e0e0e0',
              borderRadius: '10px',
              height: '20px',
              marginBottom: '10px'
            }}>
              <div style={{
                width: `${result.fraudScore}%`,
                backgroundColor: getRiskColor(result.fraudScore),
                height: '20px',
                borderRadius: '10px',
                transition: 'width 0.3s ease'
              }}></div>
            </div>
            <p style={{
              color: getRiskColor(result.fraudScore),
              fontWeight: 'bold',
              fontSize: '18px'
            }}>
              Risk Level: {getRiskLevel(result.fraudScore)}
            </p>
          </div>

          {/* Fraud Status */}
          <div style={{
            padding: '15px',
            borderRadius: '4px',
            marginBottom: '20px',
            backgroundColor: result.isFraudulent ? '#f8d7da' : '#d4edda',
            color: result.isFraudulent ? '#721c24' : '#155724',
            border: `1px solid ${result.isFraudulent ? '#f5c6cb' : '#c3e6cb'}`
          }}>
            <strong>
              {result.isFraudulent ? '⚠️ POTENTIAL FRAUD DETECTED' : '✅ APPEARS LEGITIMATE'}
            </strong>
            <p style={{ margin: '10px 0 0 0' }}>
              {result.isFraudulent 
                ? 'This job post shows signs of potential fraud. Exercise extreme caution.'
                : 'This job post appears to be legitimate, but always verify independently.'
              }
            </p>
          </div>

          {/* Suspicious Keywords */}
          {result.suspiciousKeywords && result.suspiciousKeywords.length > 0 && (
            <div style={{ marginBottom: '20px' }}>
              <h4>Suspicious Keywords Found:</h4>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                {result.suspiciousKeywords.map((keyword, index) => (
                  <span
                    key={index}
                    style={{
                      backgroundColor: '#fff3cd',
                      color: '#856404',
                      padding: '4px 8px',
                      borderRadius: '4px',
                      border: '1px solid #ffeaa7',
                      fontSize: '14px'
                    }}
                  >
                    {keyword}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Extracted Text */}
          <div style={{ marginBottom: '20px' }}>
            <h4>Extracted Text:</h4>
            <div style={{
              backgroundColor: 'white',
              padding: '15px',
              borderRadius: '4px',
              border: '1px solid #ddd',
              maxHeight: '300px',
              overflowY: 'auto',
              whiteSpace: 'pre-wrap',
              fontSize: '14px',
              fontFamily: 'monospace'
            }}>
              {result.extractedText}
            </div>
          </div>

          {/* Timestamp */}
          <p style={{ color: '#666', fontSize: '12px', margin: '0' }}>
            Analysis ID: {result.id}<br/>
            Analyzed at: {new Date(result.timestamp).toLocaleString()}
          </p>
        </div>
      )}

      {/* Help Section */}
      <div style={{
        marginTop: '30px',
        padding: '20px',
        backgroundColor: '#e7f3ff',
        borderRadius: '8px',
        border: '1px solid #b3d9ff'
      }}>
        <h4>How it works:</h4>
        <ol>
          <li>Upload an image of a job post (screenshot, photo, etc.)</li>
          <li>Our system extracts text from the image using OCR technology</li>
          <li>Advanced algorithms analyze the text for fraud indicators</li>
          <li>Get a detailed report with risk assessment and recommendations</li>
        </ol>
        
        <h4>Common fraud indicators:</h4>
        <ul>
          <li>Requests for registration fees or advance payments</li>
          <li>Unrealistic salary promises with no requirements</li>
          <li>Urgent hiring with immediate joining requirements</li>
          <li>Work-from-home jobs requiring upfront investment</li>
          <li>Contact only through informal channels (WhatsApp, personal email)</li>
        </ul>
      </div>
    </div>
  );
};

export default FraudDetectionUpload;
