# Multi-stage lightweight Python container for Cloud Run
FROM python:3.11-slim as base

# Prevent Python from writing .pyc and buffer stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Cloud Run healthcheck & execution
EXPOSE 8080

# Cloud Run memory limit friendly (max 2 workers for 512Mi instance)
CMD exec uvicorn main:app --host 0.0.0.0 --port ${PORT} --workers 1
