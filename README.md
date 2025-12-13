# 🌟 Celestial Fortune - AI-Powered Personalized Luck Prediction

> Transform daily numerology into a sophisticated, multi-dimensional luck prediction system powered by astrology, machine learning, and cosmic signals.

[![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green.svg)](https://fastapi.tiangolo.com/)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

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
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│   Web Frontend  │ ←→   │  Python Backend  │ ←→   │  External APIs  │
│  (HTML/CSS/JS)  │ HTTP │    (FastAPI)     │      │  (Weather, etc) │
└─────────────────┘      └──────────────────┘      └─────────────────┘
        ↓                         ↓                         ↓
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  Firebase Auth  │      │ Swiss Ephemeris  │      │   Firestore DB  │
│   + Firestore   │      │   (Astrology)    │      │   (User Data)   │
└─────────────────┘      └──────────────────┘      └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- **Python 3.9+**
- **Node.js** (optional, for frontend dev server)
- **Firebase Account** (free tier OK)
- **OpenWeatherMap API Key** (free tier OK)

### 1. Clone the Repository
```bash
cd /Users/nitaysah/Documents/Antigravity
```

### 2. Run Automated Setup
```bash
./setup.sh
```

This will:
- Create Python virtual environment
- Install all dependencies
- Create `.env` configuration file

### 3. Configure API Keys

Edit `backend/.env`:
```bash
OPENWEATHER_API_KEY=your_key_here  # Get from https://openweathermap.org/api
FIREBASE_CREDENTIALS_PATH=../firebase-credentials.json
```

### 4. Start the Backend
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --port 8000
```

### 5. Test the Backend
```bash
python test_backend.py
```

### 6. Open Frontend
Open `webapp/index.html` in your browser or use a local server:
```bash
cd webapp
python -m http.server 8080
# Visit http://localhost:8080
```

## 📁 Project Structure

```
Antigravity/
├── backend/                    # Python FastAPI Backend
│   ├── app/
│   │   ├── main.py            # FastAPI app entry
│   │   ├── config.py          # Configuration
│   │   ├── models/
│   │   │   └── schemas.py     # Pydantic models
│   │   ├── routes/            # API endpoints
│   │   │   ├── astrology.py   # Natal charts, transits
│   │   │   ├── signals.py     # Weather, lunar, geomagnetic
│   │   │   ├── luck.py        # Luck calculation
│   │   │   └── ml.py          # ML personalization
│   │   └── services/          # Business logic
│   │       ├── astrology_service.py  # Swiss Ephemeris
│   │       └── signals_service.py    # External APIs
│   ├── requirements.txt       # Python dependencies
│   ├── test_backend.py        # Test suite
│   └── .env.example           # Config template
│
├── webapp/                     # Frontend
│   ├── index.html             # Login page
│   ├── signup.html            # Registration
│   ├── app.html               # Main application
│   ├── script.js              # Frontend logic
│   ├── style.css              # Styling
│   ├── firebase-config.js     # Firebase init
│   └── api-client.js          # Backend API client
│
├── .agent/artifacts/          # Documentation
│   ├── ARCHITECTURE.md        # System architecture
│   ├── SETUP_GUIDE.md         # Detailed setup
│   ├── enhanced_features_plan.md  # Implementation plan
│   └── ENHANCED_FEATURES_SUMMARY.md
│
└── setup.sh                   # Automated setup script
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

### ML Personalization
```
POST /api/ml/daily-checkin             # Submit mood check-in
GET  /api/ml/personal-trend/{uid}      # Trend analysis
POST /api/ml/train-model/{uid}         # Train personal model
```

### Documentation
```
GET /docs                              # Interactive API docs (Swagger)
GET /health                            # Health check
```

## 📊 Usage Example

### Frontend Integration

```javascript
import CelestialAPI from './api-client.js';

const api = new CelestialAPI('http://localhost:8000');

// Calculate natal chart
const chart = await api.calculateNatalChart({
    dob: "1995-06-15",
    time: "14:30",
    lat: 28.6139,
    lon: 77.2090,
    timezone: "Asia/Kolkata"
});

console.log('Sun Sign:', chart.sun_sign);
console.log('Moon Sign:', chart.moon_sign);
console.log('Rising Sign:', chart.ascendant);

// Get cosmic signals
if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(async (position) => {
        const signals = await api.getAllSignals(
            position.coords.latitude,
            position.coords.longitude
        );
        
        console.log('Lunar Phase:', signals.lunar.phase_name);
        console.log('Weather:', signals.weather.condition);
        console.log('Total Influence:', signals.total_influence_score);
    });
}
```

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Backend Framework | FastAPI | High-performance async API |
| Astrology | Swiss Ephemeris (pyswisseph) | Professional-grade calculations |
| ML Framework | LightGBM + scikit-learn | Personalized predictions |
| NLP | HuggingFace Transformers | Sentiment analysis |
| LLM | GPT4All / OpenAI | Explanations |
| Weather API | OpenWeatherMap | Environmental data |
| Lunar API | FarmSense | Moon phases |
| Geomagnetic | NOAA SWPC | Space weather |
| Database | Firebase Firestore | User data & history |
| Frontend | Vanilla HTML/CSS/JS | Simple, fast, no frameworks |

## 📈 Roadmap

### ✅ Phase 1: Core Backend (Complete)
- [x] FastAPI setup
- [x] Swiss Ephemeris integration
- [x] External API integrations (weather, lunar, geomagnetic)
- [x] API routes and models

### 🔄 Phase 2: ML Pipeline (In Progress)
- [ ] Daily check-in modal UI
- [ ] HuggingFace sentiment analysis
- [ ] LightGBM model training
- [ ] Personal trend visualization

### 📅 Phase 3: LLM Integration (Planned)
- [ ] Local LLM setup (GPT4All)
- [ ] Prompt engineering
- [ ] Lucky actions generation
- [ ] Natural language explanations

### 🎨 Phase 4: UI Enhancements (Planned)
- [ ] Natal chart visualization
- [ ] Historical trend charts
- [ ] Enhanced dashboard with mini-cards
- [ ] Mobile-responsive improvements

## 📚 Documentation

- **[Setup Guide](.agent/artifacts/SETUP_GUIDE.md)** - Detailed setup instructions
- **[Architecture](.agent/artifacts/ARCHITECTURE.md)** - System architecture diagrams
- **[Features Plan](.agent/artifacts/enhanced_features_plan.md)** - Complete implementation plan
- **[API Docs](http://localhost:8000/docs)** - Interactive API documentation (when backend running)

## 🐛 Troubleshooting

### "Module not found: swisseph"
```bash
pip install pyswisseph
```

### "Weather API returns 401"
Check your `OPENWEATHER_API_KEY` in `backend/.env`

### "CORS error in browser"
Ensure backend is running and CORS origins are configured in `backend/app/config.py`

### "Swiss Ephemeris data files not found"
Download ephemeris files:
```bash
sudo mkdir -p /usr/share/swisseph
cd /usr/share/swisseph
sudo wget https://www.astro.com/ftp/swisseph/ephe/seas_18.se1
sudo wget https://www.astro.com/ftp/swisseph/ephe/semo_18.se1
sudo wget https://www.astro.com/ftp/swisseph/ephe/sepl_18.se1
```

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

## 📄 License

MIT License - feel free to use for personal or educational purposes.

## 🙏 Acknowledgments

- **Swiss Ephemeris** - Astrologische Gesellschaft Zürich (Free for personal use)
- **OpenWeatherMap** - Weather data API
- **NOAA Space Weather** - Geomagnetic activity data
- **FarmSense** - Lunar phase API

## 📧 Support

For issues or questions, check the documentation in `.agent/artifacts/` or review the API docs at `http://localhost:8000/docs`.

---

**Built with ✨ by Antigravity AI**

*Unlock the secrets of your daily luck through the cosmos!*
