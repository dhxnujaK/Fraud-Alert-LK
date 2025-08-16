const API_URL = 'http://localhost:9090';

export const checkHealth = async () => {
    try {
        const response = await fetch(`${API_URL}/health`);
        return await response.text();
    } catch (error) {
        console.error('Error checking API health:', error);
        throw error;
    }
};

export const checkFraud = async (jobData) => {
    try {
        const response = await fetch(`${API_URL}/checkFraud`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(jobData),
        });
        
        if (!response.ok) {
            throw new Error(`API error: ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error('Error checking fraud:', error);
        throw error;
    }
};

export const extractTextFromImage = async (imageFile) => {
    try {
        const formData = new FormData();
        formData.append('image', imageFile);
        
        const response = await fetch(`${API_URL}/extractText`, {
            method: 'POST',
            body: formData,
        });
        
        if (!response.ok) {
            throw new Error(`API error: ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error('Error extracting text:', error);
        throw error;
    }
};
