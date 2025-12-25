"""
FastAPI application entry point for Celestial Fortune backend.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.routes import astrology, luck, signals, ml, auth
from app.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events"""
    # Startup
    print("🌟 Celestial Fortune Backend starting...")
    print(f"📍 Environment: {settings.ENVIRONMENT}")
    
    yield
    
    # Shutdown
    print("🌙 Celestial Fortune Backend shutting down...")


app = FastAPI(
    title="Celestial Fortune API",
    description="AI-powered personalized luck prediction with astrology, ML, and cosmic signals",
    version="2.0.0",
    lifespan=lifespan
)

# CORS middleware - allow webapp to make requests
origins = [
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://localhost:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins, 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(astrology.router, prefix="/api/astrology", tags=["Astrology"])
app.include_router(luck.router, prefix="/api/luck", tags=["Luck Calculation"])
app.include_router(signals.router, prefix="/api/signals", tags=["Cosmic Signals"])
app.include_router(ml.router, prefix="/api/ml", tags=["Machine Learning"])

@app.get("/")
async def root():
    return {"message": "Celestial Fortune Backend API v2.0", "status": "online"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
