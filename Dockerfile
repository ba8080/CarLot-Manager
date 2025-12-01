FROM python:3.9-slim

WORKDIR /app

# Copy requirements and install dependencies
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ .

# Create data directory with proper permissions
RUN mkdir -p /app/data && chmod 777 /app/data

# Set environment variable
ENV DATA_FILE=/app/data/inventory.json

# Expose port
EXPOSE 5000

# Run application
CMD ["python", "app.py"]
