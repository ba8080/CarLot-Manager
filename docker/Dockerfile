FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git\
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone repository from GitHub
ARG GITHUB_REPO=https://github.com/ba8080/CarLot-Manager
RUN git clone $GITHUB_REPO .

# Install Python dependencies
RUN pip3 install streamlit pandas numpy

# Expose port
EXPOSE 8501

# Run the web application
CMD ["python3", "-m", "streamlit", "run", "website/app.py", "--server.port=8501", "--server.address=0.0.0.0"]
