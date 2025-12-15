"""
Configuration management using Pydantic Settings.
"""
from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """Application settings"""
    
    # Environment
    ENVIRONMENT: str = "development"
    
    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:5500",
        "http://localhost:8080",
        "http://localhost:8081",
        "http://127.0.0.1:5500",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:8081",
        "file://*",  # Allow local file access
        "*", # Allow all domains (including GitHub Pages and Render)
    ]
    
    # External APIs
    OPENWEATHER_API_KEY: str = ""
    GEMINI_API_KEY: str = ""  # Google Gemini for AI fortune generation
    GROQ_API_KEY: str = ""    # Groq API Key (Fallback for Gemini)
    OPENAI_API_KEY: str = ""  # Optional
    
    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = "../firebase-credentials.json"
    
    # ML Model
    ML_MODEL_PATH: str = "models/luck_predictor.pkl"
    SENTIMENT_MODEL: str = "distilbert-base-uncased-finetuned-sst-2-english"
    
    # Swiss Ephemeris data path
    EPHEMERIS_PATH: str = "/usr/share/swisseph"  # Default Linux path
    
    # LLM Settings
    USE_LOCAL_LLM: bool = True  # Set to False to use OpenAI
    LOCAL_LLM_MODEL: str = "orca-mini-3b-gguf2-q4_0.gguf"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
