# Use official Python runtime as a parent image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies required for pyswisseph (C-extension)
RUN apt-get update && apt-get install -y \
    gcc \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Download Swiss Ephemeris Data
RUN mkdir -p /usr/share/swisseph
WORKDIR /usr/share/swisseph
# Download main ephemeris files (years 1800-2399 approx)
RUN wget -q https://www.astro.com/ftp/swisseph/ephe/seas_18.se1 \
    && wget -q https://www.astro.com/ftp/swisseph/ephe/semo_18.se1 \
    && wget -q https://www.astro.com/ftp/swisseph/ephe/sepl_18.se1

# Switch back to app directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Expose the port the app runs on
EXPOSE 8000

# Command to run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
