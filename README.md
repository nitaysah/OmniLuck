# 🌟 OmniLuck - AI-Powered Personalized Luck Prediction

> Transform daily numerology into a sophisticated, multi-dimensional luck prediction system powered by astrology, machine learning, and cosmic signals.

[![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green.svg)](https://fastapi.tiangolo.com/)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS-orange.svg)](https://developer.apple.com/xcode/swiftui/)

## ✨ Features

### 🔮 **Kundali / Astrology**
- Complete natal chart calculation using Swiss Ephemeris
- Sun, Moon, and Rising Sign analysis
- Planetary positions in houses
- Daily transits and aspects
- Chart strength scoring

### 🌍 **Cosmic Signals**
- **Lunar Phase Tracking**: Real-time moon phase influence
- **Weather Integration**: Environmental impact on luck (OpenWeatherMap)
- **Geomagnetic Activity**: Space weather monitoring (NOAA Kp Index)
- Combined cosmic influence scoring

### 🤖 **AI Personalization** _(In Development)_
- Daily mood/energy check-ins
- Journal sentiment analysis (HuggingFace Transformers)
- Machine learning model training (LightGBM)
- Personalized luck predictions based on user history

### 💬 **LLM Explanations** _(Planned)_
- Natural language explanations of luck scores
- Personalized lucky action recommendations
- Local LLM (GPT4All) or Cloud (OpenAI) options

## 🏗️ Architecture

```
┌─────────────────┐      ┌───────────────────────────┐      ┌─────────────────┐
│  Web Frontend   │ ←→   │      Python Backend       │ ←→   │  External APIs  │
│ OmniLuck_Web... │ HTTP │ (OmniLuck_Backend_Python) │      │  (Weather, etc) │
└─────────────────┘      └───────────────────────────┘      └─────────────────┘
                                      ↓
┌─────────────────┐      ┌───────────────────────────┐      ┌─────────────────┐
│  iOS Application│ ←→   │      Swiss Ephemeris      │      │   Firestore DB  │
│ (OmniLuckiOSApp)│ REST │        (Astrology)        │      │   (User Data)   │
└─────────────────┘      └───────────────────────────┘      └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- **Python 3.9+**
- **Node.js** (optional, for frontend dev server)
- **Firebase Account** (free tier OK)
- **OpenWeatherMap API Key** (free tier OK)
- **Xcode** (for iOS App)

### 1. Clone the Repository
```bash
git clone https://github.com/nitaysah/OmniLuck.git
cd OmniLuck
```

### 2. Run Automated Setup (Backend)
```bash
cd OmniLuck_Backend_Python
./setup.sh
```

This will:
- Create Python virtual environment
- Install all dependencies
- Create `.env` configuration file

### 3. Configure API Keys

Edit `OmniLuck_Backend_Python/.env`:
```bash
OPENWEATHER_API_KEY=your_key_here  # Get from https://openweathermap.org/api
FIREBASE_CREDENTIALS_PATH=../firebase-credentials.json
```

### 4. Start the Backend
```bash
# Inside OmniLuck_Backend_Python directory
source venv/bin/activate
uvicorn app.main:app --reload --port 8000
```

### 5. Test the Backend
```bash
python test_backend.py
```

### 6. Open Frontend
Open `OmniLuck_Frontend_WebApp/index.html` in your browser or use a local server:
```bash
cd ../OmniLuck_Frontend_WebApp
python -m http.server 8080
# Visit http://localhost:8080
```

## 📁 Project Structure

```
OmniLuck/
├── OmniLuck_Backend_Python/    # Python FastAPI Backend
│   ├── app/
│   │   ├── main.py            # FastAPI app entry
│   │   ├── config.py          # Configuration
│   │   ├── models/            # Pydantic models
│   │   ├── routes/            # API endpoints
│   │   └── services/          # Business logic
│   ├── requirements.txt       # Python dependencies
│   ├── setup.sh               # Setup script
│   └── .env.example           # Config template
│
├── OmniLuck_Frontend_WebApp/   # Web Frontend
│   ├── index.html             # Login page
│   ├── app.html               # Main application
│   ├── script.js              # Frontend logic
│   ├── style.css              # Styling
│   ├── firebase-config.js     # Firebase init
│   └── api-client.js          # Backend API client
│
├── OmniLuckiOSApp/            # iOS Application
│   ├── OmniLuckApp.swift      # App entry point
│   ├── ContentView.swift      # Main View
│   ├── ResultView.swift       # Results View
│   ├── OmniLuckLogic.swift    # Core Logic
│   └── Assets.xcassets        # Images/Icons
│
└── README.md
```

## 🔑 API Endpoints

### Astrology
```
POST /api/astrology/natal-chart        # Calculate birth chart
POST /api/astrology/daily-transits     # Current planetary positions
GET  /api/astrology/zodiac-sign        # Quick zodiac lookup
```

### Cosmic Signals
```
GET /api/signals/lunar-phase           # Moon phase
GET /api/signals/weather               # Current weather
GET /api/signals/geomagnetic           # Kp index
GET /api/signals/all                   # All signals combined ⭐
```

### Luck Calculation
```
POST /api/luck/calculate               # Enhanced luck score
GET  /api/luck/history/{uid}           # Historical scores
```

### Documentation
```
GET /docs                              # Interactive API docs (Swagger)
GET /health                            # Health check
```

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Backend Framework | FastAPI | High-performance async API |
| iOS App | SwiftUI | Mobile Experience |
| Astrology | Swiss Ephemeris (pyswisseph) | Professional-grade calculations |
| ML Framework | LightGBM + scikit-learn | Personalized predictions |
| Weather API | OpenWeatherMap | Environmental data |
| Database | Firebase Firestore | User data & history |
| Frontend | Vanilla HTML/CSS/JS | Simple, fast web interface |

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

## 📄 License

MIT License - feel free to use for personal or educational purposes.

## 🙏 Acknowledgments

- **Swiss Ephemeris**
- **OpenWeatherMap**
- **NOAA Space Weather**

---

**Built with ✨ by Nitay Sah**

*Unlock the secrets of your daily luck through the cosmos!*
