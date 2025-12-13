"""
Cosmic Signals API endpoints (Weather, Lunar, Geomagnetic).
"""
from fastapi import APIRouter, HTTPException, Query
from datetime import date as date_type
from typing import Optional
from app.models.schemas import (
    LunarPhaseResponse,
    WeatherResponse,
    GeomagneticResponse,
    CosmicSignalsResponse
)
from app.services.signals_service import signals_service

router = APIRouter()


@router.get("/lunar-phase", response_model=LunarPhaseResponse)
async def get_lunar_phase(date: Optional[str] = None):
    """
    Get lunar phase information for a specific date.
    
    Args:
    - date: Optional date (YYYY-MM-DD), defaults to today
    
    Returns:
    - Phase name (New Moon, Waxing Crescent, etc.)
    - Phase percentage (0.0 to 1.0)
    - Illumination percentage
    - Influence score (0-100)
    """
    try:
        target_date = None
        if date:
            target_date = date_type.fromisoformat(date)
        
        lunar = await signals_service.get_lunar_phase(target_date)
        return lunar
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid date format: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch lunar data: {str(e)}")


@router.get("/weather", response_model=WeatherResponse)
async def get_weather(
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude")
):
    """
    Get current weather for a location.
    
    Args:
    - lat: Latitude
    - lon: Longitude
    
    Returns:
    - Weather condition
    - Temperature (C and F)
    - Humidity, pressure
    - Influence score (0-100)
    """
    try:
        weather = await signals_service.get_weather(lat, lon)
        return weather
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch weather: {str(e)}")


@router.get("/geomagnetic", response_model=GeomagneticResponse)
async def get_geomagnetic():
    """
    Get current geomagnetic activity (Kp index).
    
    Returns:
    - Kp index (0-9 scale)
    - Activity level (quiet, unsettled, active, storm)
    - Influence score (-20 to +20, can be negative during storms)
    """
    try:
        geomagnetic = await signals_service.get_geomagnetic_activity()
        return geomagnetic
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch geomagnetic data: {str(e)}")


@router.get("/all", response_model=CosmicSignalsResponse)
async def get_all_signals(
    lat: float = Query(..., description="Latitude for weather"),
    lon: float = Query(..., description="Longitude for weather"),
    date: Optional[str] = None
):
    """
    Get all cosmic signals at once (lunar, weather, geomagnetic).
    
    This is the recommended endpoint for efficiency as it fetches all data in parallel.
    
    Args:
    - lat: Latitude
    - lon: Longitude
    - date: Optional date (YYYY-MM-DD) for lunar phase
    
    Returns:
    - Combined response with all signals and total influence score
    """
    try:
        target_date = None
        if date:
            target_date = date_type.fromisoformat(date)
        
        signals = await signals_service.get_all_signals(lat, lon, target_date)
        return signals
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid date format: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch signals: {str(e)}")
