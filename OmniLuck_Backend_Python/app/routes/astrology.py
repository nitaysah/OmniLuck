"""
Astrology API endpoints.
"""
from fastapi import APIRouter, HTTPException
from datetime import datetime, timezone
from app.models.schemas import (
    BirthInfo,
    NatalChartResponse,
    DailyTransitsResponse
)
from app.services.astrology_service import astrology_service

router = APIRouter()


@router.post("/natal-chart", response_model=NatalChartResponse)
async def calculate_natal_chart(birth_info: BirthInfo):
    """
    Calculate a complete natal chart (birth chart).
    
    Requires:
    - Date of birth (YYYY-MM-DD)
    - Birth time (HH:MM in 24-hour format)
    - Birth location (latitude, longitude)
    - Timezone
    
    Returns:
    - Sun, Moon, Rising signs
    - All planetary positions
    - House cusps
    - Overall chart strength score
    """
    try:
        chart = astrology_service.calculate_natal_chart(birth_info)
        return chart
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to calculate natal chart: {str(e)}")


@router.post("/daily-transits", response_model=DailyTransitsResponse)
async def calculate_daily_transits(natal_chart: NatalChartResponse, date: str = None):
    """
    Calculate current planetary transits and aspects to natal chart.
    
    Args:
    - natal_chart: User's natal chart data
    - date: Optional date (YYYY-MM-DD), defaults to today
    
    Returns:
    - Current planetary positions
    - Aspects between transit and natal planets
    - Overall influence score
    """
    try:
        if date:
            target_date = datetime.strptime(date, "%Y-%m-%d").replace(tzinfo=timezone.utc)
        else:
            target_date = datetime.now(timezone.utc)
        
        transits = astrology_service.calculate_daily_transits(target_date, natal_chart)
        return transits
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid date format: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to calculate transits: {str(e)}")


@router.get("/zodiac-sign")
async def get_zodiac_sign(dob: str):
    """
    Quick endpoint to get just the zodiac sign from date of birth.
    
    Args:
    - dob: Date of birth (YYYY-MM-DD)
    
    Returns:
    - Zodiac sign name and emoji
    """
    zodiac_signs = [
        {"name": "Capricorn", "emoji": "♑", "start": (12, 22), "end": (1, 19)},
        {"name": "Aquarius", "emoji": "♒", "start": (1, 20), "end": (2, 18)},
        {"name": "Pisces", "emoji": "♓", "start": (2, 19), "end": (3, 20)},
        {"name": "Aries", "emoji": "♈", "start": (3, 21), "end": (4, 19)},
        {"name": "Taurus", "emoji": "♉", "start": (4, 20), "end": (5, 20)},
        {"name": "Gemini", "emoji": "♊", "start": (5, 21), "end": (6, 21)},
        {"name": "Cancer", "emoji": "♋", "start": (6, 22), "end": (7, 22)},
        {"name": "Leo", "emoji": "♌", "start": (7, 23), "end": (8, 22)},
        {"name": "Virgo", "emoji": "♍", "start": (8, 23), "end": (9, 22)},
        {"name": "Libra", "emoji": "♎", "start": (9, 23), "end": (10, 23)},
        {"name": "Scorpio", "emoji": "♏", "start": (10, 24), "end": (11, 22)},
        {"name": "Sagittarius", "emoji": "♐", "start": (11, 23), "end": (12, 21)},
    ]
    
    try:
        date_obj = datetime.strptime(dob, "%Y-%m-%d")
        month, day = date_obj.month, date_obj.day
        
        for sign in zodiac_signs:
            start_month, start_day = sign["start"]
            end_month, end_day = sign["end"]
            
            if start_month == end_month:
                if month == start_month and start_day <= day <= end_day:
                    return sign
            else:
                if (month == start_month and day >= start_day) or \
                   (month == end_month and day <= end_day):
                    return sign
        
        return zodiac_signs[0]  # Fallback
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid date: {str(e)}")
