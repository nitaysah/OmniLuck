# Celestial Fortune Backend

AI-powered personalized luck prediction system with astrology, machine learning, and cosmic signals.

## Features
- 🔮 Swiss Ephemeris integration for accurate astrological calculations
- 🤖 Machine learning personalization (LightGBM)
- 🌙 Lunar phase tracking
- ☁️ Weather influence analysis
- 🌍 Geomagnetic activity monitoring
- 💬 LLM-powered explanations

## Setup

### Prerequisites
- Python 3.9+
- pip

### Installation

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Environment Variables

Create a `.env` file in the backend directory:

```
OPENWEATHER_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here  # Optional, for cloud LLM
FIREBASE_CREDENTIALS_PATH=../firebase-credentials.json
```

### Run

```bash
uvicorn app.main:app --reload --port 8000
```

API will be available at `http://localhost:8000`

## API Documentation

Once running, visit `http://localhost:8000/docs` for interactive API documentation.

## Project Structure

```
backend/
├── app/
│   ├── main.py              # FastAPI app entry point
│   ├── config.py            # Configuration management
│   ├── models/              # Pydantic models (request/response)
│   ├── routes/              # API endpoints
│   │   ├── astrology.py     # Natal charts, transits
│   │   ├── luck.py          # Luck calculation
│   │   ├── signals.py       # Weather, moon, geomagnetic
│   │   └── ml.py            # ML predictions, training
│   └── services/            # Business logic
│       ├── astrology_service.py
│       ├── signals_service.py
│       ├── ml_service.py
│       └── llm_service.py
├── requirements.txt
└── README.md
```
