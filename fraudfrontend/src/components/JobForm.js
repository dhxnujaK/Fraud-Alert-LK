import React, { useState } from 'react';
import { checkFraud, extractTextFromImage } from '../services/api';
import './JobForm.css';

const JobForm = () => {
    const [formData, setFormData] = useState({
        title: '',
        description: '',
    });
    const [image, setImage] = useState(null);
    const [result, setResult] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData({
            ...formData,
            [name]: value,
        });
    };

    const handleImageChange = (e) => {
        if (e.target.files && e.target.files[0]) {
            setImage(e.target.files[0]);
        }
    };

    const handleExtractText = async () => {
        if (!image) {
            setError('Please upload an image first');
            return;
        }

        setLoading(true);
        setError('');
        
        try {
            const result = await extractTextFromImage(image);
            
            if (result && result.text) {
                // Auto-fill the description field with extracted text
                setFormData({
                    ...formData,
                    description: result.text,
                });
            }
        } catch (err) {
            setError('Failed to extract text from image. Please try again or enter text manually.');
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        setResult(null);
        
        try {
            const result = await checkFraud(formData);
            setResult(result);
        } catch (err) {
            setError('Failed to analyze job posting. Please try again.');
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="job-form-container">
            <h2>Job Posting Fraud Checker</h2>
            <form onSubmit={handleSubmit} className="job-form">
                <div className="form-group">
                    <label htmlFor="title">Job Title</label>
                    <input
                        type="text"
                        id="title"
                        name="title"
                        value={formData.title}
                        onChange={handleChange}
                        required
                        placeholder="Enter job title"
                    />
                </div>
                
                <div className="form-group">
                    <label htmlFor="description">Job Description</label>
                    <textarea
                        id="description"
                        name="description"
                        value={formData.description}
                        onChange={handleChange}
                        required
                        placeholder="Enter job description or extract from image"
                        rows={6}
                    />
                </div>
                
                <div className="form-group image-upload-group">
                    <label htmlFor="image">Upload Job Posting Image (OCR Enabled)</label>
                    <input
                        type="file"
                        id="image"
                        accept="image/*"
                        onChange={handleImageChange}
                    />
                    <button 
                        type="button" 
                        onClick={handleExtractText}
                        disabled={!image || loading}
                        className="extract-button"
                    >
                        Extract Text from Image
                    </button>
                    {image && <p className="help-text">Click "Extract Text" to use OCR to analyze this image</p>}
                </div>
                
                {error && <div className="error-message">{error}</div>}
                
                <button type="submit" disabled={loading} className="submit-button">
                    {loading ? 'Analyzing...' : 'Check for Fraud'}
                </button>
            </form>
            
            {result && (
                <div className={`result-container ${result.isFraud ? 'fraud' : 'legitimate'}`}>
                    <h3>{result.isFraud ? '⚠️ Potential Fraud Detected' : '✅ Legitimate Job Posting'}</h3>
                    <p>{result.message}</p>
                    <p className="confidence">Confidence: {(result.confidenceScore * 100).toFixed(1)}%</p>
                </div>
            )}
        </div>
    );
};

export default JobForm;
