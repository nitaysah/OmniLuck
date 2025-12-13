"""
Astrology calculations using Swiss Ephemeris (pyswisseph).
Supports both Western and Vedic astrology.
"""
import swisseph as swe
from datetime import datetime, timezone
import pytz
from typing import Dict, List, Tuple
from app.models.schemas import BirthInfo, NatalChartResponse, PlanetPosition, DailyTransitsResponse


# Zodiac sign names (Western)
ZODIAC_SIGNS = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"
]

# Planet constants
PLANETS = {
    "Sun": swe.SUN,
    "Moon": swe.MOON,
    "Mercury": swe.MERCURY,
    "Venus": swe.VENUS,
    "Mars": swe.MARS,
    "Jupiter": swe.JUPITER,
    "Saturn": swe.SATURN,
    "Uranus": swe.URANUS,
    "Neptune": swe.NEPTUNE,
    "Pluto": swe.PLUTO,
}

# Major aspects (degrees and orbs)
ASPECTS = {
    "Conjunction": (0, 8),
    "Sextile": (60, 6),
    "Square": (90, 8),
    "Trine": (120, 8),
    "Opposition": (180, 8),
}


class AstrologyService:
    """Service for astrological calculations"""
    
    def __init__(self):
        # Set ephemeris path (Swiss Ephemeris data files)
        # Default paths: /usr/share/ephe on Linux, custom on Windows/Mac
        try:
            swe.set_ephe_path("/usr/share/swisseph")
        except:
            swe.set_ephe_path(".")  # Current directory fallback
    
    def _datetime_to_jd(self, dt: datetime) -> float:
        """Convert datetime to Julian Day"""
        return swe.julday(dt.year, dt.month, dt.day, dt.hour + dt.minute / 60.0)
    
    def _longitude_to_sign(self, longitude: float) -> str:
        """Convert longitude (0-360) to zodiac sign"""
        sign_index = int(longitude / 30)
        return ZODIAC_SIGNS[sign_index % 12]
    
    def _calculate_house(self, longitude: float, house_cusps: List[float]) -> int:
        """Determine which house a planet is in"""
        for i in range(12):
            next_i = (i + 1) % 12
            cusp = house_cusps[i]
            next_cusp = house_cusps[next_i]
            
            # Handle the wrap-around at 360/0 degrees
            if next_cusp < cusp:
                if longitude >= cusp or longitude < next_cusp:
                    return i + 1
            else:
                if cusp <= longitude < next_cusp:
                    return i + 1
        return 1  # Fallback
    
    def calculate_natal_chart(self, birth_info: BirthInfo) -> NatalChartResponse:
        """
        Calculate complete natal chart.
        
        Args:
            birth_info: User's birth details
            
        Returns:
            NatalChartResponse with all planetary positions and house cusps
        """
        # Parse birth date and time
        dob_parts = birth_info.dob.split("-")
        time_parts = birth_info.time.split(":")
        
        # Create timezone-aware datetime
        tz = pytz.timezone(birth_info.timezone)
        birth_dt = tz.localize(datetime(
            int(dob_parts[0]), int(dob_parts[1]), int(dob_parts[2]),
            int(time_parts[0]), int(time_parts[1])
        ))
        
        # Convert to UTC for Swiss Ephemeris
        birth_dt_utc = birth_dt.astimezone(timezone.utc)
        jd = self._datetime_to_jd(birth_dt_utc)
        
        # Calculate house cusps and ascendant (using Placidus house system)
        houses, ascmc = swe.houses(jd, birth_info.lat, birth_info.lon, b'P')
        ascendant_longitude = ascmc[0]
        mc_longitude = ascmc[1]  # Midheaven
        
        # Calculate planetary positions
        planets_data = {}
        for name, planet_id in PLANETS.items():
            result, flags = swe.calc_ut(jd, planet_id)
            longitude = result[0]
            latitude = result[1]
            speed = result[3]  # Daily motion
            
            retrograde = speed < 0
            sign = self._longitude_to_sign(longitude)
            house = self._calculate_house(longitude, houses)
            
            planets_data[name] = PlanetPosition(
                name=name,
                longitude=round(longitude, 2),
                latitude=round(latitude, 2),
                sign=sign,
                house=house,
                retrograde=retrograde
            )
        
        # Determine Sun, Moon, and Rising signs
        sun_sign = self._longitude_to_sign(planets_data["Sun"].longitude)
        moon_sign = self._longitude_to_sign(planets_data["Moon"].longitude)
        ascendant_sign = self._longitude_to_sign(ascendant_longitude)
        
        # Calculate overall chart strength (simplified algorithm)
        strength_score = self._calculate_chart_strength(planets_data, houses)
        
        # House cusps dictionary
        houses_dict = {i + 1: round(houses[i], 2) for i in range(12)}
        
        return NatalChartResponse(
            sun_sign=sun_sign,
            moon_sign=moon_sign,
            ascendant=ascendant_sign,
            planets=planets_data,
            houses=houses_dict,
            strength_score=strength_score,
            computed_at=datetime.now(timezone.utc)
        )
    
    def calculate_daily_transits(self, date: datetime, natal_chart: NatalChartResponse) -> DailyTransitsResponse:
        """
        Calculate current planetary transits and aspects to natal chart.
        
        Args:
            date: Date to calculate transits for
            natal_chart: User's natal chart
            
        Returns:
            DailyTransitsResponse with current positions and aspects
        """
        jd = self._datetime_to_jd(date)
        
        # Calculate current planetary positions
        transit_planets = {}
        for name, planet_id in PLANETS.items():
            result, flags = swe.calc_ut(jd, planet_id)
            longitude = result[0]
            latitude = result[1]
            speed = result[3]
            
            transit_planets[name] = PlanetPosition(
                name=name,
                longitude=round(longitude, 2),
                latitude=round(latitude, 2),
                sign=self._longitude_to_sign(longitude),
                house=1,  # Not calculated for transits
                retrograde=speed < 0
            )
        
        # Calculate aspects to natal planets
        aspects = self._calculate_aspects(transit_planets, natal_chart.planets)
        
        # Calculate influence score based on aspects
        influence_score = self._calculate_transit_influence(aspects)
        
        return DailyTransitsResponse(
            date=date.strftime("%Y-%m-%d"),
            planets=transit_planets,
            aspects=aspects,
            influence_score=influence_score
        )
    
    def _calculate_aspects(self, transit_planets: Dict[str, PlanetPosition], 
                          natal_planets: Dict[str, PlanetPosition]) -> List[Dict]:
        """Calculate aspects between transit and natal planets"""
        aspects_list = []
        
        for t_name, t_planet in transit_planets.items():
            for n_name, n_planet in natal_planets.items():
                # Calculate angular difference
                diff = abs(t_planet.longitude - n_planet.longitude)
                if diff > 180:
                    diff = 360 - diff
                
                # Check for major aspects
                for aspect_name, (aspect_angle, orb) in ASPECTS.items():
                    if abs(diff - aspect_angle) <= orb:
                        aspects_list.append({
                            "type": aspect_name,
                            "transit_planet": t_name,
                            "natal_planet": n_name,
                            "angle": round(diff, 2),
                            "orb": round(abs(diff - aspect_angle), 2),
                            "strength": round((orb - abs(diff - aspect_angle)) / orb * 100, 2)
                        })
        
        return aspects_list
    
    def _calculate_chart_strength(self, planets: Dict[str, PlanetPosition], 
                                  houses: List[float]) -> int:
        """
        Calculate overall chart strength (0-100).
        Considers: planetary dignity, house positions, aspects.
        Simplified version.
        """
        score = 50  # Base score
        
        # Bonus for planets in their ruling signs (simplified)
        dignities = {
            "Sun": "Leo",
            "Moon": "Cancer",
            "Mercury": ["Gemini", "Virgo"],
            "Venus": ["Taurus", "Libra"],
            "Mars": ["Aries", "Scorpio"],
            "Jupiter": ["Sagittarius", "Pisces"],
            "Saturn": ["Capricorn", "Aquarius"],
        }
        
        for name, planet in planets.items():
            if name in dignities:
                ruling = dignities[name]
                if isinstance(ruling, list):
                    if planet.sign in ruling:
                        score += 5
                elif planet.sign == ruling:
                    score += 5
        
        # Bonus for benefic planets (Venus, Jupiter) in angular houses (1, 4, 7, 10)
        if planets["Venus"].house in [1, 4, 7, 10]:
            score += 3
        if planets["Jupiter"].house in [1, 4, 7, 10]:
            score += 3
        
        # Penalty for malefic planets (Mars, Saturn) in angular houses
        if planets["Mars"].house in [1, 4, 7, 10]:
            score -= 2
        if planets["Saturn"].house in [1, 4, 7, 10]:
            score -= 2
        
        return max(0, min(100, score))
    
    def _calculate_transit_influence(self, aspects: List[Dict]) -> int:
        """Calculate overall influence score from transits"""
        score = 50  # Neutral base
        
        # Positive aspects
        benefic_aspects = ["Trine", "Sextile"]
        # Challenging aspects
        malefic_aspects = ["Square", "Opposition"]
        # Neutral but strong
        neutral_aspects = ["Conjunction"]
        
        for aspect in aspects:
            strength = aspect["strength"]
            
            if aspect["type"] in benefic_aspects:
                score += strength * 0.2
            elif aspect["type"] in malefic_aspects:
                score -= strength * 0.15
            elif aspect["type"] in neutral_aspects:
                # Conjunction is neutral, depends on planets involved
                score += strength * 0.1
        
        return max(0, min(100, int(score)))


# Singleton instance
astrology_service = AstrologyService()
