"""
Pydantic models for request/response validation.
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date


# ============================================================================
# ASTROLOGY MODELS
# ============================================================================

class BirthInfo(BaseModel):
    """User birth information for natal chart calculation"""
    dob: str = Field(..., description="Date of birth in YYYY-MM-DD format")
    time: str = Field(..., description="Birth time in HH:MM format (24-hour)")
    lat: float = Field(..., description="Latitude of birth location")
    lon: float = Field(..., description="Longitude of birth location")
    timezone: str = Field(default="UTC", description="IANA timezone string")


class PlanetPosition(BaseModel):
    """Position of a single planet"""
    name: str
    longitude: float  # 0-360 degrees
    latitude: float
    sign: str  # Zodiac sign
    house: int  # 1-12
    retrograde: bool = False


class NatalChartResponse(BaseModel):
    """Complete natal chart data"""
    sun_sign: str
    moon_sign: str
    ascendant: str  # Rising sign
    planets: Dict[str, PlanetPosition]
    houses: Dict[int, float]  # House cusps
    strength_score: int = Field(..., ge=0, le=100, description="Overall chart strength")
    computed_at: datetime


class DailyTransitsResponse(BaseModel):
    """Current planetary transits"""
    date: str
    planets: Dict[str, PlanetPosition]
    aspects: List[Dict[str, Any]]  # Major aspects to natal chart
    influence_score: int = Field(..., ge=0, le=100)


# ============================================================================
# COSMIC SIGNALS MODELS
# ============================================================================

class LunarPhaseResponse(BaseModel):
    """Moon phase information"""
    phase_name: str  # "New Moon", "Waxing Crescent", etc.
    phase_percentage: float  # 0.0 to 1.0
    illumination: float  # 0 to 100
    next_full_moon: date
    next_new_moon: date
    influence_score: int = Field(..., ge=0, le=100)


class WeatherResponse(BaseModel):
    """Weather data"""
    condition: str  # "clear", "clouds", "rain", etc.
    temp_c: float
    temp_f: float
    humidity: int  # 0-100
    pressure: int  # hPa
    uv_index: Optional[float] = None
    influence_score: int = Field(..., ge=0, le=100)


class GeomagneticResponse(BaseModel):
    """Geomagnetic activity data"""
    kp_index: float  # 0-9 scale
    activity_level: str  # "quiet", "unsettled", "active", "storm"
    solar_wind_speed: Optional[float] = None  # km/s
    influence_score: int = Field(..., ge=-20, le=20, description="Can be negative during storms")


class CosmicSignalsResponse(BaseModel):
    """All cosmic signals combined"""
    lunar: LunarPhaseResponse
    weather: WeatherResponse
    geomagnetic: GeomagneticResponse
    total_influence_score: int = Field(..., description="Sum of all influences")


# ============================================================================
# LUCK CALCULATION MODELS
# ============================================================================

class LuckCalculationRequest(BaseModel):
    """Request for luck score calculation"""
    uid: str
    name: str = "User"
    dob: str  # YYYY-MM-DD
    birth_place_name: Optional[str] = None
    birth_lat: Optional[float] = None
    birth_lon: Optional[float] = None
    birth_time: Optional[str] = "12:00"
    timezone: Optional[str] = "UTC"
    intention: Optional[str] = None
    # Daily Calibration
    past_luck_rating: Optional[int] = Field(None, ge=1, le=10, description="Yesterday's luck 1-10")
    sleep_quality: Optional[str] = Field(None, description="Deep, Restless, Vivid Dreams, etc")
    energy_level: Optional[str] = Field(None, description="High, Low, Scattered, Focused")
    
    # Powerball Settings
    powerball_count: Optional[int] = Field(5, ge=1, le=100, description="Number of Powerball lines to generate")
    
    # Historical Luck Profile
    history_lottery: Optional[str] = Field(None, description="Experience with chance/lottery")
    history_games: Optional[str] = Field(None, description="Luck in board/digital games")
    history_sports: Optional[str] = Field(None, description="Luck in physical sports")
    current_lat: Optional[float] = None
    current_lon: Optional[float] = None
    date: Optional[str] = None  # Defaults to today


class LuckComponents(BaseModel):
    """Breakdown of luck score components"""
    base_numerology: int = Field(..., ge=0, le=100)
    astrology_score: int = Field(..., ge=0, le=100)
    natal_potential: Optional[int] = Field(50, ge=0, le=100, description="Birth chart strength")
    cosmic_weather: int = Field(..., ge=0, le=100) # Updated range
    personal_trend: int = Field(..., ge=-100, le=100, description="ML adjustment")
    total: int = Field(..., ge=0, le=100)


class PowerballNumbers(BaseModel):
    """Powerball lottery numbers"""
    white_balls: List[int] = Field(..., description="5 white balls (1-69)")
    powerball: int = Field(..., description="Red powerball (1-26)")
    type: str = Field(..., description="'personal' or 'daily'")
    index: Optional[int] = Field(None, description="For daily numbers, which combo (1-10)")


class LuckCalculationResponse(BaseModel):
    luck_score: int = Field(..., ge=0, le=100)
    components: LuckComponents
    confidence: float = Field(..., ge=0.0, le=1.0, description="ML model confidence")
    caption: Optional[str] = Field(None, description="Short headline")
    summary: Optional[str] = Field(None, description="Simple factor explanation")
    explanation: str = Field(..., description="LLM-generated explanation")
    recommended_actions: List[str] = Field(default_factory=list)
    strategic_advice: Optional[str] = Field(None, description="Detailed strategy for conflicting energies")
    lucky_time_slots: List[str] = Field(default_factory=list, description="Best times of day based on astro-numerology")
    personal_powerball: Optional[PowerballNumbers] = Field(None, description="User's personal lucky powerball")
    daily_powerballs: List[PowerballNumbers] = Field(default_factory=list, description="10 daily powerball combinations")


class ForecastDay(BaseModel):
    """Single day forecast data"""
    date: str
    luck_score: int
    transits_score: int
    major_aspects: List[str] = Field(default_factory=list)

class ForecastResponse(BaseModel):
    """7-day forecast response"""
    trajectory: List[ForecastDay]
    trend_direction: str # "Rising", "Falling", "Stable"
    best_day: str # Date of highest score


# ============================================================================
# ML / PERSONALIZATION MODELS
# ============================================================================

class DailyCheckIn(BaseModel):
    """User's daily mood/energy check-in"""
    uid: str
    date: str  # YYYY-MM-DD
    mood_score: int = Field(..., ge=1, le=10)
    energy_level: str = Field(..., pattern="^(low|medium|high)$")
    mood_tags: List[str] = Field(default_factory=list)
    journal_text: Optional[str] = None


class DailyCheckInResponse(BaseModel):
    """Saved check-in with computed sentiment"""
    uid: str
    date: str
    mood_score: int
    energy_level: str
    mood_tags: List[str]
    journal_sentiment: Optional[float] = Field(None, ge=-1.0, le=1.0)
    saved_at: datetime


class PersonalTrendResponse(BaseModel):
    """User's personal trend analysis"""
    uid: str
    avg_mood_7d: float
    avg_mood_30d: float
    trend_direction: str  # "improving", "stable", "declining"
    best_days: List[str]  # Weekdays
    ml_model_accuracy: Optional[float] = None
    total_logs: int
