FROM python:3.9-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

# Create data directory
RUN mkdir -p data && chmod 777 data

ENV DATA_FILE=/app/data/inventory.json

EXPOSE 5000

CMD ["python", "app.py"]
