import React, { useState } from 'react';
import { checkFraud, extractTextFromImage } from '../services/api';
import './JobForm.css';

const JobForm = () => {
    const [formData, setFormData] = useState({
        title: '',
        description: '',
    });
    const [image, setImage] = useState(null);
    const [imagePreview, setImagePreview] = useState(null);
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
            const file = e.target.files[0];
            setImage(file);
            
            // Create preview URL
            const reader = new FileReader();
            reader.onloadend = () => {
                setImagePreview(reader.result);
            };
            reader.readAsDataURL(file);
        }
    };

    const removeImage = () => {
        setImage(null);
        setImagePreview(null);
        // Reset the file input
        const fileInput = document.getElementById('image');
        if (fileInput) {
            fileInput.value = '';
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
                {/* <div className="form-group">
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
                </div> */}
                
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
                
                <div className="form-group image-upload-section">
                    <label className="upload-section-title">Upload Job Posting Image</label>
                    
                    <div className="image-upload-container">
                        {!imagePreview ? (
                            <div className="upload-dropzone">
                                <div className="upload-icon">📁</div>
                                <p className="upload-text">Click to upload or drag and drop</p>
                                <p className="upload-subtext">PNG, JPG, JPEG up to 10MB</p>
                                <input
                                    type="file"
                                    id="image"
                                    accept="image/*"
                                    onChange={handleImageChange}
                                    className="file-input"
                                />
                            </div>
                        ) : (
                            <div className="image-preview-container">
                                <div className="image-preview">
                                    <img src={imagePreview} alt="Upload preview" />
                                    <button 
                                        type="button"
                                        onClick={removeImage}
                                        className="remove-image-btn"
                                        title="Remove image"
                                    >
                                        ❌
                                    </button>
                                </div>
                                <div className="image-info">
                                    <p className="image-name">📄 {image?.name}</p>
                                    <p className="image-size">📊 {(image?.size / 1024 / 1024).toFixed(2)} MB</p>
                                </div>
                            </div>
                        )}
                    </div>
                    
                    {image && (
                        <div className="extract-section">
                            <button 
                                type="button" 
                                onClick={handleExtractText}
                                disabled={loading}
                                className="extract-button"
                            >
                                {loading ? 'Extracting...' : ' Extract Text from Image'}
                            </button>
                        
                        </div>
                    )}
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
