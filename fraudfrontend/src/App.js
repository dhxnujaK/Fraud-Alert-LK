import React, { useState } from 'react';
import JobForm from './components/JobForm';
import logo from './LOGO/logo.png';
import './App.css';

function App() {
  const [activeSection, setActiveSection] = useState('analyzer');

  const scrollToSection = (sectionId) => {
    setActiveSection(sectionId);
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <div className="App-header-main">
          <div className="App-header-left">
            <img src={logo} className="App-logo" alt="Fraud Alert LK logo" />
            <div className="App-brand">
              <h1>Fraud Alert LK</h1>
              <p className="App-subtitle">Smart Detection, Safer Opportunities</p>
            </div>
          </div>
          
          <nav className="App-nav">
            <button 
              className={`nav-button ${activeSection === 'analyzer' ? 'active' : ''}`}
              onClick={() => scrollToSection('analyzer')}
            >
              Analyzer
            </button>
            <button 
              className={`nav-button ${activeSection === 'features' ? 'active' : ''}`}
              onClick={() => scrollToSection('features')}
            >
              Features
            </button>
            <button 
              className={`nav-button ${activeSection === 'about' ? 'active' : ''}`}
              onClick={() => scrollToSection('about')}
            >
              About
            </button>
          </nav>
        </div>
      </header>
      
      <main className="App-main">
        {/* Analyzer Section */}
        <section id="analyzer" className="section analyzer-section">
          <div className="section-content">
            <h2 className="section-title">Job Fraud Analyzer</h2>
            <p className="section-description">
              Upload job postings or enter details manually to detect potential fraud using advanced machine learning algorithms.
            </p>
            <JobForm />
          </div>
        </section>

        {/* Features Section */}
        <section id="features" className="section features-section">
          <div className="section-content">
            <h2 className="section-title">Why Choose Our Platform ?</h2>
            <div className="features-grid">
              <div className="feature-card">
                <div className="feature-icon">🤖</div>
                <h3>AI-Powered Detection</h3>
                <p>Advanced machine learning algorithms trained on thousands of job postings to identify fraudulent patterns.</p>
              </div>
              <div className="feature-card">
                <div className="feature-icon">📱</div>
                <h3>OCR Technology</h3>
                <p>Extract text from images of job postings using cutting-edge Optical Character Recognition technology.</p>
              </div>
              <div className="feature-card">
                <div className="feature-icon">⚡</div>
                <h3>Real-time Analysis</h3>
                <p>Get instant results with confidence scores to help you make informed decisions quickly.</p>
              </div>
              <div className="feature-card">
                <div className="feature-icon">🛡️</div>
                <h3>Comprehensive Protection</h3>
                <p>Detects various fraud indicators including suspicious keywords, unrealistic promises, and scam patterns.</p>
              </div>
              <div className="feature-card">
                <div className="feature-icon">📊</div>
                <h3>Detailed Reports</h3>
                <p>Receive comprehensive analysis reports with explanations for fraud detection decisions.</p>
              </div>
              <div className="feature-card">
                <div className="feature-icon">🌐</div>
                <h3>Sri Lankan Context</h3>
                <p>Specifically trained for the Sri Lankan job market to understand local employment patterns and fraud tactics.</p>
              </div>
            </div>
          </div>
        </section>

        {/* About Section */}
        <section id="about" className="section about-section">
          <div className="section-content">
            <h2 className="section-title">About Fraud Alert LK</h2>
            <div className="about-content">
              <div className="about-text">
                <h3>Protecting Job Seekers in Sri Lanka</h3>
                <p>
                  Fraud Alert LK is a cutting-edge platform designed to protect job seekers from fraudulent job postings 
                  that are increasingly common in today's digital job market. Our mission is to create a safer job search 
                  environment for everyone in Sri Lanka.
                </p>
                
                <h3>How It Works</h3>
                <p>
                  Our system uses advanced machine learning algorithms trained on a comprehensive dataset of legitimate 
                  and fraudulent job postings. The AI analyzes various factors including:
                </p>
                <ul>
                  <li>Language patterns and suspicious keywords</li>
                  <li>Salary promises vs. job requirements</li>
                  <li>Contact information legitimacy</li>
                  <li>Job description coherence and realism</li>
                  <li>Company information verification</li>
                </ul>

                <h3>Technology Stack</h3>
                <p>
                  Built with modern technologies including React for the frontend, Ballerina for the backend API, 
                  Python for machine learning models, and advanced OCR capabilities for image processing.
                </p>
              </div>
              <div className="about-stats">
                <div className="stat-card">
                  <div className="stat-number">95%</div>
                  <div className="stat-label">Accuracy Rate</div>
                </div>
                <div className="stat-card">
                  <div className="stat-number">10k+</div>
                  <div className="stat-label">Jobs Analyzed</div>
                </div>
                <div className="stat-card">
                  <div className="stat-number">500+</div>
                  <div className="stat-label">Frauds Detected</div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>
      
      <footer className="App-footer">
        <div className="footer-content">
          <div className="footer-main">
            <div className="footer-section footer-brand">
              <div className="footer-logo">
                <img src={logo} alt="Fraud Alert LK" className="footer-logo-img" />
                <div className="footer-brand-text">
                  <h3>Fraud Alert LK</h3>
                  <p>Smart Detection, Safer Opportunities</p>
                </div>
              </div>
              <p className="footer-description">
                Protecting job seekers in Sri Lanka with advanced AI-powered fraud detection technology. 
                Stay safe, stay informed, stay protected.
              </p>
              <div className="footer-social">
                <a href="#" className="social-link" aria-label="Facebook">
                  <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
                  </svg>
                </a>
                <a href="#" className="social-link" aria-label="Twitter">
                  <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/>
                  </svg>
                </a>
                <a href="#" className="social-link" aria-label="LinkedIn">
                  <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                  </svg>
                </a>
                <a href="#" className="social-link" aria-label="GitHub">
                  <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                  </svg>
                </a>
              </div>
            </div>

            <div className="footer-section">
              <h4>Services</h4>
              <ul>
                <li><a href="#analyzer">Job Fraud Detection</a></li>
                <li><a href="#analyzer">OCR Text Analysis</a></li>
                <li><a href="#analyzer">AI-Powered Screening</a></li>
                <li><a href="#features">Real-time Results</a></li>
                <li><a href="#features">Smart Recommendations</a></li>
              </ul>
            </div>

            <div className="footer-section">
              <h4>Resources</h4>
              <ul>
                <li><a href="#about">About Us</a></li>
                <li><a href="#features">How It Works</a></li>
                <li><a href="#">Safety Tips</a></li>
                <li><a href="#">FAQ</a></li>
                <li><a href="#">Help Center</a></li>
              </ul>
            </div>

            <div className="footer-section">
              <h4>Legal</h4>
              <ul>
                <li><a href="#">Privacy Policy</a></li>
                <li><a href="#">Terms of Service</a></li>
                <li><a href="#">Cookie Policy</a></li>
                <li><a href="#">Disclaimer</a></li>
                <li><a href="#">Contact Us</a></li>
              </ul>
            </div>

            <div className="footer-section footer-contact">
              <h4>Get In Touch</h4>
              <div className="contact-info">
                <div className="contact-item">
                  <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
                  </svg>
                  <span>Colombo, Sri Lanka</span>
                </div>
                <div className="contact-item">
                  <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>
                  </svg>
                  <span>contact@fraudalertlk.com</span>
                </div>
                <div className="contact-item">
                  <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z"/>
                  </svg>
                  <span>+94 11 234 5678</span>
                </div>
              </div>
              <div className="footer-newsletter">
                <p>Stay updated with latest security alerts</p>
                <div className="newsletter-form">
                  <input type="email" placeholder="Enter your email" />
                  <button>Subscribe</button>
                </div>
              </div>
            </div>
          </div>

          <div className="footer-bottom">
            <div className="footer-bottom-content">
              <div className="footer-copyright">
                <p>&copy; {new Date().getFullYear()} Fraud Alert LK. All rights reserved.</p>
                <p className="footer-tagline">Powered by Advanced Machine Learning & AI Technology</p>
              </div>
              <div className="footer-badges">
                <div className="badge">
                  <span className="badge-icon"></span>
                  <span>Secure Platform</span>
                </div>
                <div className="badge">
                  <span className="badge-icon"></span>
                  <span>AI Powered</span>
                </div>
                <div className="badge">
                  <span className="badge-icon"></span>
                  <span>Made in Sri Lanka</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;
