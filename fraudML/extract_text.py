import sys
import os
import pytesseract
from PIL import Image
import io


def extract_text_from_image(image_path):
    """
    Extract text from an image using Tesseract OCR
    
    Args:
        image_path: Path to the image file
        
    Returns:
        Extracted text as a string
    """
    try:
        
        if os.path.isfile(image_path):
            image = Image.open(image_path)
        else:
            with open(image_path, 'rb') as f:
                image_data = f.read()
                image = Image.open(io.BytesIO(image_data))
        
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
