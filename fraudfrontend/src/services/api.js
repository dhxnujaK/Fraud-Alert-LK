const API_URL = 'http://localhost:9091';

export const checkHealth = async () => {
    try {
        console.log("Trying to connect to backend at:", `${API_URL}/health`);
        const response = await fetch(`${API_URL}/health`);
        const result = await response.text();
        console.log("Health check result:", result);
        return result;
    } catch (error) {
        console.error('Error checking API health:', error);
        throw error;
    }
};

export const checkFraud = async (jobData) => {
    try {
        const response = await fetch(`${API_URL}/checkFraud`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(jobData),
        });

        const bodyText = await response.text(); // read raw body once
        console.log('[checkFraud] status:', response.status, 'body:', bodyText);

        if (!response.ok) {
            try {
                const errJson = JSON.parse(bodyText);
                throw new Error(errJson.message || errJson.error || bodyText || `HTTP ${response.status}`);
            } catch {
                throw new Error(bodyText || `HTTP ${response.status}`);
            }
        }

        try {
            return JSON.parse(bodyText);
        } catch (e) {
            throw new Error(`Failed to parse fraud API response: ${e.message}. Raw body: ${bodyText}`);
        }
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

        const bodyText = await response.text();
        console.log('[extractTextFromImage] status:', response.status, 'body:', bodyText);

        if (!response.ok) {
            try {
                const errJson = JSON.parse(bodyText);
                throw new Error(errJson.message || errJson.error || bodyText || `HTTP ${response.status}`);
            } catch {
                throw new Error(bodyText || `HTTP ${response.status}`);
            }
        }

        try {
            return JSON.parse(bodyText);
        } catch (e) {
            throw new Error(`Failed to parse OCR response: ${e.message}. Raw body: ${bodyText}`);
        }
    } catch (error) {
        console.error('Error extracting text:', error);
        throw error;
    }
};