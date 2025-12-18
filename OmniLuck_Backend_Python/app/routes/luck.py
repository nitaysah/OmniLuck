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
    from app.services.numerology_service import numerology_service
    from app.models.schemas import BirthInfo
    
    # 1. Fetch Cosmic Signals (20%)
    try:
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
    astro_score = 50 
    natal_score = 50 # Default neutral
    astro_data = {}
    
    birth_time = request.birth_time or "12:00"
    if request.birth_lat and request.birth_lon:
        try:
            birth_info = BirthInfo(
                dob=request.dob,
                time=birth_time,
                lat=request.birth_lat,
                lon=request.birth_lon,
                timezone="UTC"
            )
            natal_chart = astrology_service.calculate_natal_chart(birth_info)
            # Use current time but round to minute (no seconds) for consistency
            current_time = datetime.now().replace(second=0, microsecond=0)
            transits_result = astrology_service.calculate_daily_transits(current_time, natal_chart)
            astro_score = transits_result.influence_score
            natal_score = natal_chart.strength_score
            
            astro_data = {
                "sun_sign": natal_chart.sun_sign,
                "moon_sign": natal_chart.moon_sign,
                "ascendant": natal_chart.ascendant,
                "transits_score": transits_result.influence_score,
                "aspects": transits_result.aspects
            }
        except Exception as e:
            print(f"⚠️ Astrology Error: {e}")
    
    # 3. Calculate Numerology Score (30%)
    try:
        numerology_result = numerology_service.calculate_daily_score(request.dob, request.name)
        numero_score = numerology_result["numerology_score"]
    except Exception as e:
        print(f"⚠️ Numerology Error: {e}")
        numero_score = 50
        numerology_result = {}

    # Zodiac Symbol Mapping
    zodiac_symbols = {
        "Aries": "♈️", "Taurus": "♉️", "Gemini": "♊️", "Cancer": "♋️",
        "Leo": "♌️", "Virgo": "♍️", "Libra": "♎️", "Scorpio": "♏️",
        "Sagittarius": "♐️", "Capricorn": "♑️", "Aquarius": "♒️", "Pisces": "♓️"
    }
    
    # Get zodiac sign from astrology calculation (always calculated, not fallback)
    sun_sign = astro_data.get("sun_sign", "Traveler")
    zodiac_symbol = zodiac_symbols.get(sun_sign, "✨")
    formatted_zodiac = f"{zodiac_symbol} {sun_sign}"
    
    # 4. AI Interpretation (10% - Mostly for Context/Vibe)
    user_context = {
        "name": request.name,
        "dob": request.dob,
        "zodiac": formatted_zodiac,  # e.g., "♏️ Scorpio"
        "sun_sign": sun_sign,  # Raw sign name for AI prompt
        "birth_place": request.birth_place_name or "Unknown",
        "birth_time": request.birth_time or "Unknown",
        "timezone": request.timezone or "UTC",
        "uid": request.uid
    }
    
    # AI explains the DATA, it does not invent the score
    ai_result = llm_service.analyze_luck_and_generate_content(
        user_data=user_context,
        cosmic_signals=signals_dict,
        astrology_data=astro_data,
        numerology_data=numerology_result
    )
    
    ai_intuition_score = ai_result.get("score", 70)
    
    # === FINAL WEIGHTED CALCULATION ("OmniLuck Edge" Model) ===
    # Weights: Astro Transits (40%), Natal Potential (20%), Numerology (15%), Signals (15%), AI (10%)
    
    final_score = (
        (astro_score * 0.40) +
        (natal_score * 0.20) +
        (numero_score * 0.15) +
        (signals_score * 0.15) +
        (ai_intuition_score * 0.10)
    )
    
    final_score = max(0, min(100, final_score))
    
    # Generate explanation for the score components
    factors_summary = (
        f"Astro Transits ({astro_score}/100), "
        f"Numerology ({numero_score}/100), "
        f"Natal Potential ({natal_score}/100), "
        f"Cosmic Weather ({signals_score}/100), "
        f"AI Intuition ({ai_intuition_score}/100)"
    )

    # Generate Powerball Lucky Numbers
    from app.services.powerball_service import powerball_service
    personal_powerball = None
    daily_powerballs = []
    
    try:
        # Personal powerball (static for user)
        personal_pb_data = powerball_service.generate_personal_powerball(
            name=request.name,
            dob=request.dob
        )
        personal_powerball = personal_pb_data
        
        # Daily powerballs (10 combinations for today)
        daily_pb_list = powerball_service.generate_daily_powerballs(
            name=request.name,
            dob=request.dob,
            current_date=datetime.now().strftime("%Y-%m-%d"),
            luck_score=int(final_score),
            astro_score=astro_score,
            natal_score=natal_score
        )
        daily_powerballs = daily_pb_list
    except Exception as e:
        print(f"⚠️ Powerball Generation Error: {e}")

    return LuckCalculationResponse(
        luck_score=int(final_score),
        components=LuckComponents(
            astrology_score=astro_score,
            base_numerology=numero_score,
            natal_potential=natal_score,
            cosmic_weather=signals_score,
            personal_trend=ai_intuition_score, 
            total=int(final_score)
        ),
        confidence=0.9,
        caption=ai_result.get("caption"),
        summary=factors_summary,  # Populate summary with factor breakdown
        explanation=ai_result.get("explanation"),
        recommended_actions=ai_result.get("actions"),
        strategic_advice=ai_result.get("strategic_advice"),
        lucky_time_slots=ai_result.get("lucky_time_slots") or [],
        personal_powerball=personal_powerball,
        daily_powerballs=daily_powerballs
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


from app.models.schemas import ForecastResponse

@router.post("/forecast", response_model=ForecastResponse)
async def get_forecast(request: LuckCalculationRequest):
    """
    Calculate 7-day luck trajectory using the OmniLuck Edge weighted formula.
    """
    from app.services.astrology_service import astrology_service
    from app.services.numerology_service import numerology_service
    from app.models.schemas import BirthInfo, ForecastResponse, ForecastDay
    from datetime import timedelta
    
    if not request.birth_lat:
         raise HTTPException(status_code=400, detail="Birth location required for forecast")

    birth_time = request.birth_time or "12:00"

    # Calculate Natal Chart ONE time
    birth_info = BirthInfo(
        dob=request.dob,
        time=birth_time,
        lat=request.birth_lat,
        lon=request.birth_lon,
        timezone=request.timezone or "UTC"
    )
    natal_chart = astrology_service.calculate_natal_chart(birth_info)
    
    # Static components
    natal_score = natal_chart.strength_score  # Natal Potential (20%)
    signals_score = 50  # Neutral for future (can't predict weather)
    ai_score = 55  # Slightly positive baseline
    
    # Calculate Forecast with full weighted formula
    raw_forecast = astrology_service.calculate_weekly_forecast(natal_chart)
    
    trajectory = []
    max_score = -1
    best_date = ""
    
    for day in raw_forecast:
        # Get astrology transit score for this day
        astro_score = day['transits_score']
        
        # Calculate numerology score for this specific date
        try:
            future_date = day['date']  # Format: YYYY-MM-DD
            numero_result = numerology_service.calculate_daily_score(request.dob, request.name, future_date)
            numero_score = numero_result["numerology_score"]
        except Exception:
            numero_score = 50  # Fallback
        
        # Apply OmniLuck Edge weighted formula (40/20/15/15/10)
        weighted_score = (
            (astro_score * 0.40) +
            (natal_score * 0.20) +
            (numero_score * 0.15) +
            (signals_score * 0.15) +
            (ai_score * 0.10)
        )
        
        final_score = int(max(0, min(100, weighted_score)))
        
        trajectory.append(ForecastDay(
            date=day['date'],
            luck_score=final_score,
            transits_score=astro_score,
            major_aspects=day['major_aspects']
        ))
        
        if final_score > max_score:
            max_score = final_score
            best_date = day['date']
            
    # Determine trend
    first = trajectory[0].luck_score
    last = trajectory[-1].luck_score
    if last > first + 5:
        direction = "Rising"
    elif last < first - 5:
        direction = "Falling"
    else:
        direction = "Stable"
        
    return ForecastResponse(
        trajectory=trajectory,
        trend_direction=direction,
        best_day=best_date
    )
