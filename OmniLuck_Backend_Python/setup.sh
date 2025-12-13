#!/bin/bash

# Celestial Fortune - Quick Setup Script
# This script automates the backend setup process

set -e  # Exit on error

echo "🌟 Celestial Fortune - Quick Setup"
echo "===================================="
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.9+ first."
    exit 1
fi

echo "✓ Python 3 found: $(python3 --version)"

# Navigate to backend directory (already here)
# cd backend

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv venv
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "📦 Upgrading pip..."
pip install --upgrade pip --quiet

# Install dependencies
echo "📦 Installing Python dependencies (this may take a few minutes)..."
pip install -r requirements.txt --quiet

echo "✓ All dependencies installed"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "✓ .env file created"
    echo ""
    echo "⚠️  IMPORTANT: Edit backend/.env and add your API keys:"
    echo "   1. OPENWEATHER_API_KEY (get from https://openweathermap.org/api)"
    echo "   2. FIREBASE_CREDENTIALS_PATH (path to your Firebase credentials)"
    echo ""
else
    echo "✓ .env file already exists"
fi

# Check for Swiss Ephemeris data
if [ ! -d "/usr/share/swisseph" ]; then
    echo ""
    echo "⚠️  Swiss Ephemeris data not found at /usr/share/swisseph"
    echo "   For full astrology features, install ephemeris data:"
    echo ""
    echo "   sudo mkdir -p /usr/share/swisseph"
    echo "   cd /usr/share/swisseph"
    echo "   sudo wget https://www.astro.com/ftp/swisseph/ephe/seas_18.se1"
    echo "   sudo wget https://www.astro.com/ftp/swisseph/ephe/semo_18.se1"
    echo "   sudo wget https://www.astro.com/ftp/swisseph/ephe/sepl_18.se1"
    echo ""
    echo "   Or download from: https://www.astro.com/ftp/swisseph/ephe/"
    echo ""
else
    echo "✓ Swiss Ephemeris data found"
fi

echo ""
echo "===================================="
echo "✅ Setup Complete!"
echo "===================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Edit backend/.env and add your API keys"
echo ""
echo "2. Start the backend:"
echo "   cd backend"
echo "   source venv/bin/activate"
echo "   uvicorn app.main:app --reload --port 8000"
echo ""
echo "3. Test the backend:"
echo "   python test_backend.py"
echo ""
echo "4. View API docs:"
echo "   http://localhost:8000/docs"
echo ""
echo "5. Integrate with frontend:"
echo "   Use webapp/api-client.js in your HTML/JS files"
echo ""
echo "📚 Documentation:"
echo "   • Setup Guide: .agent/artifacts/SETUP_GUIDE.md"
echo "   • Architecture: .agent/artifacts/ARCHITECTURE.md"
echo "   • Features Plan: .agent/artifacts/enhanced_features_plan.md"
echo ""
echo "Happy coding! 🚀"
