"""
Enhanced Luck Calculation API endpoints.
Combines numerology, astrology, and cosmic signals.
"""
from fastapi import APIRouter, HTTPException, Body
from datetime import datetime
from typing import Optional, Dict
from app.models.schemas import LuckCalculationRequest, LuckCalculationResponse, LuckComponents
from app.services.llm_service import llm_service

router = APIRouter()


@router.post("/calculate", response_model=LuckCalculationResponse)
async def calculate_luck(request: LuckCalculationRequest):
    """
    Calculate comprehensive luck score using 3 Weighted Pillars:
    1. AI Intuition (Gemini 1.5) - 40%
    2. Astrology Transits (Swiss Ephemeris) - 40%
    3. Cosmic Signals (Moon, Weather, Space Weather) - 20%
    """
    from app.services.astrology_service import astrology_service
    from app.services.signals_service import signals_service
    from app.models.schemas import BirthInfo
    
    # 1. Fetch Cosmic Signals (20%)
    try:
        # Use provided current location or default to 0,0 (signals service handles fallback)
        lat = request.current_lat or 0.0
        lon = request.current_lon or 0.0
        signals = await signals_service.get_all_signals(lat, lon)
        signals_score = signals.total_influence_score
        signals_dict = signals.dict()
    except Exception as e:
        print(f"⚠️ Signals Error: {e}")
        signals_score = 50
        signals_dict = {}

    # 2. Calculate Astrology Score (40%)
    astro_score = 50 # Default neutral
    astro_data = {}
    
    if request.birth_lat and request.birth_lon and request.birth_time:
        try:
            # Calculate Natal Chart
            birth_info = BirthInfo(
                dob=request.dob,
                time=request.birth_time,
                lat=request.birth_lat,
                lon=request.birth_lon,
                timezone="UTC" # in production, find timezone from coords
            )
            natal_chart = astrology_service.calculate_natal_chart(birth_info)
            
            # Calculate Daily Transits relative to Natal Chart
            transits = astrology_service.calculate_daily_transits(datetime.now(), natal_chart)
            astro_score = transits.influence_score
            
            astro_data = {
                "sun_sign": natal_chart.sun_sign,
                "moon_sign": natal_chart.moon_sign,
                "ascendant": natal_chart.ascendant,
                "transits_score": transits.influence_score
            }
        except Exception as e:
            print(f"⚠️ Astrology Error: {e}")
    else:
        print("ℹ️ Missing birth time/location for full astrology. Using neutral score.")

    # 3. AI Intuition & Content Generation (40%)
    user_context = {
        "name": request.name,
        "dob": request.dob,
        "birth_place": request.birth_place_name or "Unknown",
        "birth_time": request.birth_time or "Unknown",
        "timezone": request.timezone or "UTC",
        "uid": request.uid,

        "history": {
            "lottery": request.history_lottery,
            "games": request.history_games,
            "sports": request.history_sports
        },

    }
    
    # Analyze with Gemini
    ai_result = llm_service.analyze_luck_and_generate_content(
        user_data=user_context,
        cosmic_signals=signals_dict,
        astrology_data=astro_data
    )
    
    ai_score = ai_result.get("score", 70)
    
    # === FINAL WEIGHTED CALCULATION ===
    # Weights: AI (40%) + Astro (40%) + Signals (20%)
    final_score = int(
        (ai_score * 0.40) + 
        (astro_score * 0.40) + 
        (signals_score * 0.20)
    )
    
    # Clamp to 0-100
    final_score = max(0, min(100, final_score))
    
    return LuckCalculationResponse(
        luck_score=final_score,
        components=LuckComponents(
            base_numerology=ai_score, # Rebranding 'base_numerology' field as 'AI/Intuition'
            astrology_score=astro_score,
            cosmic_weather=signals_score,
            personal_trend=0,
            total=final_score
        ),
        confidence=0.9,
        caption=ai_result.get("caption"),
        summary=ai_result.get("summary"),
        explanation=ai_result.get("explanation"),
        recommended_actions=ai_result.get("actions")
    )


@router.get("/history/{uid}")
async def get_luck_history(uid: str, days: int = 30):
    """
    Get user's historical luck scores.
    
    Args:
    - uid: User ID
    - days: Number of days to retrieve (default 30)
    
    Returns:
    - List of daily luck scores with dates
    """
    # TODO: Implement with Firestore integration
    return {
        "uid": uid,
        "days": days,
        "history": [
            {"date": "2025-12-11", "score": 75},
            {"date": "2025-12-10", "score": 68},
            {"date": "2025-12-09", "score": 82},
        ]
    }
