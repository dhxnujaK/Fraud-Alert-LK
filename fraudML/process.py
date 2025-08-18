import argparse
import base64
import io
import json
import requests
from bs4 import BeautifulSoup
from PIL import Image
import pytesseract
from predict import predict_text

parser = argparse.ArgumentParser()
parser.add_argument("--url")
parser.add_argument("--image")
args = parser.parse_args()

text = None
if args.url:
    resp = requests.get(args.url, timeout=10)
    soup = BeautifulSoup(resp.text, "html.parser")
    text = soup.get_text(separator=" ", strip=True)
elif args.image:
    img_bytes = base64.b64decode(args.image)
    img = Image.open(io.BytesIO(img_bytes))
    text = pytesseract.image_to_string(img)
else:
    print(json.dumps({"error": "no input"}))
    exit(1)

result = predict_text(text)
result["text"] = text
print(json.dumps(result))
