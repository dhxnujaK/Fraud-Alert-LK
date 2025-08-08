import React from 'react';
import './App.css';
import FraudDetectionUpload from './components/FraudDetectionUpload';

function App() {
  return (
    <div className="App">
      <header className="App-header" style={{ backgroundColor: '#282c34', padding: '20px 0', marginBottom: '20px' }}>
        <h1 style={{ color: 'white', margin: 0 }}>🔍 Fraud Alert LK</h1>
        <p style={{ color: '#61dafb', margin: '10px 0 0 0' }}>
          Detect fraudulent job posts using AI-powered image analysis
        </p>
      </header>
      <main>
        <FraudDetectionUpload />
      </main>
    </div>
  );
}

export default App;
