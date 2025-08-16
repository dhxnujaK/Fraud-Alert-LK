import React, { useState, useEffect } from 'react';
import JobForm from './components/JobForm';
import { checkHealth } from './services/api';
import './App.css';

function App() {
  const [backendStatus, setBackendStatus] = useState('Checking...');

  useEffect(() => {
    const checkBackendStatus = async () => {
      try {
        const status = await checkHealth();
        setBackendStatus('Online');
      } catch (error) {
        setBackendStatus('Offline');
        console.error('Backend appears to be offline:', error);
      }
    };
    
    checkBackendStatus();
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <h1>Fraud Alert LK</h1>
        <p className="App-subtitle">Detect fraudulent job postings using AI</p>
        <div className={`backend-status ${backendStatus === 'Online' ? 'online' : 'offline'}`}>
          Backend Status: {backendStatus}
        </div>
      </header>
      
      <main className="App-main">
        <JobForm />
      </main>
      
      <footer className="App-footer">
        <p>Fraud Alert LK &copy; {new Date().getFullYear()} - Powered by ML</p>
      </footer>
    </div>
  );
}

export default App;
