import sys
import os
import pytesseract
from PIL import Image
import io

# Configure Tesseract path if needed (uncomment and set the path if Tesseract is not in PATH)
# pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

def extract_text_from_image(image_path):
    """
    Extract text from an image using Tesseract OCR
    
    Args:
        image_path: Path to the image file
        
    Returns:
        Extracted text as a string
    """
    try:
        # Open the image
        if os.path.isfile(image_path):
            # If it's a file path, open it directly
            image = Image.open(image_path)
        else:
            # If it's base64 encoded or binary data
            with open(image_path, 'rb') as f:
                image_data = f.read()
                image = Image.open(io.BytesIO(image_data))
        
        # Extract text using pytesseract
        text = pytesseract.image_to_string(image)
        return text
    except Exception as e:
        return f"Error extracting text: {str(e)}"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python extract_text.py <image_file_path>")
        sys.exit(1)
    
    image_path = sys.argv[1]
    extracted_text = extract_text_from_image(image_path)
    print(extracted_text)
