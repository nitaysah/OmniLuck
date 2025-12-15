"""
Cosmic Signals Service: Weather, Lunar Phase, Geomagnetic Activity.
Integrates external APIs to provide environmental context for luck predictions.
"""
import httpx
import asyncio
from datetime import datetime, date, timedelta
from typing import Optional
import math
import swisseph as swe
from app.config import settings
from app.models.schemas import (
    LunarPhaseResponse,
    WeatherResponse,
    GeomagneticResponse,
    CosmicSignalsResponse
)


class SignalsService:
    """Service for fetching cosmic/environmental signals"""
    
    def __init__(self):
        self.openweather_key = settings.OPENWEATHER_API_KEY
        self.openweather_key = settings.OPENWEATHER_API_KEY
        self.client = httpx.AsyncClient(timeout=10.0)
        
        # Initialize Swiss Ephemeris
        try:
            swe.set_ephe_path("/usr/share/swisseph")
        except:
            swe.set_ephe_path(".")
    
    async def get_lunar_phase(self, target_date: Optional[date] = None) -> LunarPhaseResponse:
        """
        Get lunar phase information using FarmSense Moon Phases API.
        
        Args:
            target_date: Date to query (defaults to today)
            
        Returns:
            LunarPhaseResponse with phase info and influence score
        """
        if target_date is None:
            target_date = date.today()
        
        try:
            # Use local Swiss Ephemeris calculation
            # Convert date to Julian Day (noon UTC)
            jd = swe.julday(target_date.year, target_date.month, target_date.day, 12.0)
            
            # Calculate Moon position
            # Result: longitude, latitude, distance, speed, etc.
            moon_res, _ = swe.calc_ut(jd, swe.MOON)
            moon_lon = moon_res[0]
            
            # Calculate Sun position
            sun_res, _ = swe.calc_ut(jd, swe.SUN)
            sun_lon = sun_res[0]
            
            # Calculate phase angle (0-360)
            # 0=New, 90=First Quarter, 180=Full, 270=Last Quarter
            phase_angle = (moon_lon - sun_lon) % 360
            
            # Convert to percentage (0.0 - 1.0) where 0=New, 0.5=Full, 1.0=New
            # This matches the previous API's format roughly, but continuous
            # Note: API might have used 0->1 cycling through all phases
            # Let's verify standard: 0=New, 0.5=Full is standard "age"/phase
            phase_pct = phase_angle / 360.0
            
            # Determine phase name
            phase_name = self._get_moon_phase_name(phase_pct)
            
            # Calculate influence
            influence_score = self._calculate_lunar_influence(phase_pct)
            
            # Estimate next Full/New Moon (simplified)
            # Synodic month is ~29.53 days
            days_to_new = (360 - phase_angle) / (360/29.53)
            days_to_full = (180 - phase_angle) % 360 / (360/29.53)
            
            next_new = target_date + timedelta(days=round(days_to_new))
            next_full = target_date + timedelta(days=round(days_to_full))
            
            # Illumination percentage (0-100)
            # 100 * (1 - cos(radians(phase_angle))) / 2
            illumination = 50 * (1 - math.cos(math.radians(phase_angle)))
            
            return LunarPhaseResponse(
                phase_name=phase_name,
                phase_percentage=round(phase_pct, 3),
                illumination=round(illumination, 1),
                next_full_moon=next_full,
                next_new_moon=next_new,
                influence_score=influence_score
            )
            
        except Exception as e:
            print(f"❌ Lunar calculation error: {e}")
            return self._calculate_lunar_phase_fallback(target_date)
    
    def _get_moon_phase_name(self, phase: float) -> str:
        """Convert phase decimal to readable name"""
        if phase < 0.03:
            return "New Moon"
        elif phase < 0.22:
            return "Waxing Crescent"
        elif phase < 0.28:
            return "First Quarter"
        elif phase < 0.47:
            return "Waxing Gibbous"
        elif phase < 0.53:
            return "Full Moon"
        elif phase < 0.72:
            return "Waning Gibbous"
        elif phase < 0.78:
            return "Last Quarter"
        elif phase < 0.97:
            return "Waning Crescent"
        else:
            return "New Moon"
    
    def _calculate_lunar_influence(self, phase: float) -> int:
        """Calculate luck influence from lunar phase (0-100 scale)"""
        # Full Moon (0.5) and New Moon (0.0 or 1.0) have highest influence
        # Quarters have moderate influence
        
        if 0.47 <= phase <= 0.53:  # Full Moon
            return 90 + int((0.5 - abs(phase - 0.5)) * 200)  # 90-100
        elif phase < 0.03 or phase > 0.97:  # New Moon
            return 80 + int((0.03 - min(phase, 1.0 - phase)) * 333)  # 80-90
        elif 0.22 <= phase <= 0.28 or 0.72 <= phase <= 0.78:  # Quarters
            return 60 + int((0.06 - abs(phase - round(phase / 0.25) * 0.25)) * 333)  # 60-70
        else:
            return 40 + int(20 * (1 - abs(phase - 0.5) * 2))  # 40-60
    
    def _calculate_lunar_phase_fallback(self, target_date: date) -> LunarPhaseResponse:
        """Fallback lunar calculation using astronomical formula"""
        # Simplified lunar phase calculation
        # Based on synodic month (29.53 days)
        known_new_moon = date(2000, 1, 6)  # A known new moon
        days_since = (target_date - known_new_moon).days
        phase = (days_since % 29.53) / 29.53
        
        return LunarPhaseResponse(
            phase_name=self._get_moon_phase_name(phase),
            phase_percentage=round(phase, 3),
            illumination=round(phase * 100, 1),
            next_full_moon=target_date,  # Simplified
            next_new_moon=target_date,
            influence_score=self._calculate_lunar_influence(phase)
        )
    
    async def get_weather(self, lat: float, lon: float) -> WeatherResponse:
        """
        Get current weather from OpenWeatherMap.
        
        Args:
            lat: Latitude
            lon: Longitude
            
        Returns:
            WeatherResponse with weather data and influence score
        """
        if not self.openweather_key:
            print("⚠️  OpenWeatherMap API key not set, using dummy data")
            return self._get_dummy_weather()
        
        url = "https://api.openweathermap.org/data/2.5/weather"
        params = {
            "lat": lat,
            "lon": lon,
            "appid": self.openweather_key,
            "units": "metric"
        }
        
        try:
            response = await self.client.get(url, params=params)
            response.raise_for_status()
            data = response.json()
            
            # Extract weather data
            main = data["main"]
            weather = data["weather"][0]
            
            temp_c = main["temp"]
            temp_f = temp_c * 9/5 + 32
            humidity = main["humidity"]
            pressure = main["pressure"]
            condition = weather["main"].lower()  # "clear", "clouds", "rain", etc.
            
            # Calculate influence
            influence_score = self._calculate_weather_influence(condition, temp_c, humidity)
            
            return WeatherResponse(
                condition=condition,
                temp_c=round(temp_c, 1),
                temp_f=round(temp_f, 1),
                humidity=humidity,
                pressure=pressure,
                uv_index=None,  # Requires separate API call
                influence_score=influence_score
            )
            
        except Exception as e:
            print(f"❌ Weather API error: {e}")
            return self._get_dummy_weather()
    
    def _calculate_weather_influence(self, condition: str, temp: float, humidity: int) -> int:
        """Calculate luck influence from weather (0-100 scale)"""
        score = 50  # Neutral baseline
        
        # Condition influence
        if condition in ["clear", "sun"]:
            score += 25
        elif condition in ["clouds", "mist"]:
            score += 10
        elif condition in ["rain", "drizzle"]:
            score -= 10
        elif condition in ["thunderstorm", "snow"]:
            score -= 20
        
        # Temperature influence (optimal: 18-25°C)
        if 18 <= temp <= 25:
            score += 10
        elif 10 <= temp < 18 or 25 < temp <= 30:
            score += 5
        elif temp < 5 or temp > 35:
            score -= 10
        
        # Humidity influence (optimal: 40-60%)
        if 40 <= humidity <= 60:
            score += 5
        elif humidity > 80:
            score -= 5
        
        return max(0, min(100, score))
    
    def _get_dummy_weather(self) -> WeatherResponse:
        """Fallback dummy weather data"""
        return WeatherResponse(
            condition="clear",
            temp_c=22.0,
            temp_f=71.6,
            humidity=50,
            pressure=1013,
            uv_index=None,
            influence_score=75
        )
    
    async def get_geomagnetic_activity(self) -> GeomagneticResponse:
        """
        Get geomagnetic activity from NOAA SWPC.
        
        Returns:
            GeomagneticResponse with Kp index and influence
        """
        # NOAA SWPC Kp Index (3-day forecast)
        url = "https://services.swpc.noaa.gov/json/planetary_k_index_1m.json"
        
        try:
            response = await self.client.get(url)
            response.raise_for_status()
            data = response.json()
            
            # Get the most recent Kp value
            if not data:
                raise ValueError("No geomagnetic data received")
            
            latest = data[-1]
            kp = float(latest["kp_index"]) if "kp_index" in latest else 2.0
            
            # Determine activity level
            activity_level = self._get_geomagnetic_level(kp)
            
            # Calculate influence (lower Kp = better luck, high Kp = disruption)
            influence_score = self._calculate_geomagnetic_influence(kp)
            
            return GeomagneticResponse(
                kp_index=round(kp, 1),
                activity_level=activity_level,
                solar_wind_speed=None,  # Would require additional API
                influence_score=influence_score
            )
            
        except Exception as e:
            print(f"❌ Geomagnetic API error: {e}")
            # Fallback: assume quiet conditions
            return GeomagneticResponse(
                kp_index=2.0,
                activity_level="quiet",
                solar_wind_speed=None,
                influence_score=10
            )
    
    def _get_geomagnetic_level(self, kp: float) -> str:
        """Convert Kp index to activity level"""
        if kp < 4:
            return "quiet"
        elif kp < 5:
            return "unsettled"
        elif kp < 6:
            return "active"
        elif kp < 7:
            return "minor storm"
        else:
            return "major storm"
    
    def _calculate_geomagnetic_influence(self, kp: float) -> int:
        """Calculate influence from geomagnetic activity (-20 to +20)"""
        # Low Kp (0-2) = positive influence
        # High Kp (5+) = negative influence
        
        if kp < 2:
            return int(15 + (2 - kp) * 2.5)  # +15 to +20
        elif kp < 4:
            return int(10 - (kp - 2) * 5)     # +10 to 0
        elif kp < 6:
            return int(-(kp - 4) * 5)         # 0 to -10
        else:
            return int(-10 - (kp - 6) * 3.3)  # -10 to -20
    
    async def get_all_signals(self, lat: float, lon: float, 
                            target_date: Optional[date] = None) -> CosmicSignalsResponse:
        """
        Get all cosmic signals in parallel.
        
        Args:
            lat: Latitude for weather
            lon: Longitude for weather
            target_date: Date for lunar phase
            
        Returns:
            CosmicSignalsResponse with all signals
        """
        # Fetch all data in parallel
        lunar, weather, geomagnetic = await asyncio.gather(
            self.get_lunar_phase(target_date),
            self.get_weather(lat, lon),
            self.get_geomagnetic_activity()
        )
        
        # Calculate total influence
        total_influence = (
            lunar.influence_score * 0.3 +      # 30% weight
            weather.influence_score * 0.5 +    # 50% weight
            geomagnetic.influence_score * 0.2  # 20% weight (can be negative)
        )
        
        return CosmicSignalsResponse(
            lunar=lunar,
            weather=weather,
            geomagnetic=geomagnetic,
            total_influence_score=int(total_influence)
        )
    
    async def close(self):
        """Close HTTP client"""
        await self.client.aclose()


# Singleton instance
signals_service = SignalsService()
