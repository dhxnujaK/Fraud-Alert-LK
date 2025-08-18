import React, { useState } from 'react';
import './App.css';

function App() {
  const [url, setUrl] = useState('');
  const [file, setFile] = useState(null);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);

  const toBase64 = (file) => new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => resolve(reader.result.split(',')[1]);
    reader.onerror = reject;
  });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setResult(null);
    setError(null);
    try {
      const payload = {};
      if (url) payload.url = url;
      if (file) {
        payload.imageBase64 = await toBase64(file);
      }
      const res = await fetch('http://localhost:8080/check', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      const data = await res.json();
      setResult(data);
    } catch (err) {
      setError('Request failed');
    }
  };

  return (
    <div className="App">
      <h1>Fraud Job Scam Finder</h1>
      <form onSubmit={handleSubmit}>
        <div>
          <label>Job Post URL:</label>
          <input type="text" value={url} onChange={e => setUrl(e.target.value)} />
        </div>
        <div>
          <label>Or Upload Image:</label>
          <input type="file" accept="image/*" onChange={e => setFile(e.target.files[0])} />
        </div>
        <button type="submit">Check</button>
      </form>
      {error && <p className="error">{error}</p>}
      {result && (
        <div className="result">
          <p>Prediction: {result.prediction === 1 ? 'Fraudulent' : 'Real'}</p>
          <p>Probability: {result.probability?.toFixed ? result.probability.toFixed(2) : result.probability}</p>
        </div>
      )}
    </div>
  );
}

export default App;
