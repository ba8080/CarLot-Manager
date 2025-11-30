from pypdf import PdfReader

reader = PdfReader("DevOps_Final_Project_Requirements (2).pdf")
text = ""
for page in reader.pages:
    text += page.extract_text() + "\n"

with open("requirements_text.txt", "w", encoding="utf-8") as f:
    f.write(text)
