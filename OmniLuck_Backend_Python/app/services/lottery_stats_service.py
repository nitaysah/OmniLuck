"""
Lottery Statistics Service.
Fetches live Powerball data and calculates hot/cold numbers dynamically.
Data source: New York State Open Data (Official Powerball Results)

Now with FILE-BASED PERSISTENCE - survives server restarts!
Cache refreshes only after Powerball drawings (Mon, Wed, Sat at 10:59 PM ET).
"""
import httpx
import json
import os
from datetime import datetime, timedelta
from typing import Dict, List, Tuple
from collections import Counter
from pathlib import Path
import pytz

# Cache file location (in app/data directory)
CACHE_DIR = Path(__file__).parent.parent / "data"
CACHE_FILE = CACHE_DIR / "lottery_cache.json"

# Powerball drawing schedule: Monday, Wednesday, Saturday at 10:59 PM ET
# Drawing days: 0=Mon, 2=Wed, 5=Sat
DRAWING_DAYS = [0, 2, 5]
DRAWING_HOUR = 23  # 11 PM ET (drawings at 10:59 PM, results available ~11 PM)
ET_TIMEZONE = pytz.timezone('America/New_York')

# In-memory cache (faster than reading file every time)
_memory_cache = {
    "hot_numbers": None,
    "cold_numbers": None,
    "hot_powerballs": None,
    "cold_powerballs": None,
    "historical_drawings": None,  # NEW: Cached historical drawings
    "last_updated": None,
}


def _get_last_drawing_time() -> datetime:
    """Get the datetime of the most recent Powerball drawing."""
    now_et = datetime.now(ET_TIMEZONE)
    
    # Find the most recent drawing day
    for days_back in range(7):
        check_date = now_et - timedelta(days=days_back)
        if check_date.weekday() in DRAWING_DAYS:
            # Check if drawing has happened (after 11 PM)
            drawing_time = check_date.replace(hour=DRAWING_HOUR, minute=0, second=0, microsecond=0)
            if drawing_time <= now_et:
                return drawing_time
    
    # Fallback (shouldn't happen)
    return now_et - timedelta(days=1)


def _is_cache_valid(last_updated: datetime) -> bool:
    """Check if cache is still valid (no new drawing since last update)."""
    if not last_updated:
        return False
    
    # Make last_updated timezone-aware if it isn't
    if last_updated.tzinfo is None:
        last_updated = ET_TIMEZONE.localize(last_updated)
    
    last_drawing = _get_last_drawing_time()
    
    # Cache is valid if it was updated after the last drawing
    return last_updated > last_drawing


def _get_next_drawing_time() -> datetime:
    """Get the datetime of the next Powerball drawing."""
    now_et = datetime.now(ET_TIMEZONE)
    
    # Find the next drawing day
    for days_ahead in range(7):
        check_date = now_et + timedelta(days=days_ahead)
        if check_date.weekday() in DRAWING_DAYS:
            drawing_time = check_date.replace(hour=DRAWING_HOUR, minute=0, second=0, microsecond=0)
            if drawing_time > now_et:
                return drawing_time
    
    # Fallback
    return now_et + timedelta(days=1)


def _load_cache_from_file() -> Dict:
    """Load cached stats from JSON file."""
    global _memory_cache
    
    try:
        if CACHE_FILE.exists():
            with open(CACHE_FILE, 'r') as f:
                data = json.load(f)
                # Convert last_updated back to datetime
                if data.get("last_updated"):
                    data["last_updated"] = datetime.fromisoformat(data["last_updated"])
                # Update memory cache
                _memory_cache.update(data)
                return data
    except Exception as e:
        print(f"⚠️ Failed to load cache file: {e}")
    
    return {}


def _save_cache_to_file(data: Dict):
    """Save stats to JSON file for persistence."""
    try:
        # Ensure directory exists
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        
        # Prepare data for JSON (convert datetime to string)
        save_data = data.copy()
        if isinstance(save_data.get("last_updated"), datetime):
            save_data["last_updated"] = save_data["last_updated"].isoformat()
        
        with open(CACHE_FILE, 'w') as f:
            json.dump(save_data, f, indent=2)
        
        print(f"💾 Lottery stats saved to {CACHE_FILE}")
    except Exception as e:
        print(f"⚠️ Failed to save cache file: {e}")


class LotteryStatsService:
    """
    Fetches live Powerball statistics from NY State Open Data API.
    Calculates hot/cold numbers based on last 100 draws.
    Uses file-based caching for persistence across restarts.
    """
    
    # NY State Open Data API - Official Powerball Results
    API_URL = "https://data.ny.gov/resource/d6yy-54nr.json"
    
    def __init__(self):
        self.white_ball_max = 69
        self.powerball_max = 26
        # Load cache from file on startup
        _load_cache_from_file()
        if _memory_cache.get("hot_numbers"):
            print(f"📂 Loaded lottery stats from file cache")
    
    async def fetch_recent_draws(self, limit: int = 100) -> List[Dict]:
        """Fetch the last N Powerball draws from official API."""
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(
                    self.API_URL,
                    params={"$limit": limit, "$order": "draw_date DESC"}
                )
                response.raise_for_status()
                return response.json()
        except Exception as e:
            print(f"⚠️ Lottery API Error: {e}")
            return []
    
    def parse_winning_numbers(self, draw: Dict) -> Tuple[List[int], int]:
        """
        Parse a draw record into white balls and powerball.
        Format: "03 18 36 41 54 07" (last number is Powerball)
        """
        numbers_str = draw.get("winning_numbers", "")
        parts = numbers_str.split()
        if len(parts) != 6:
            return [], 0
        
        white_balls = [int(p) for p in parts[:5]]
        powerball = int(parts[5])
        return white_balls, powerball
    
    def calculate_frequency(self, draws: List[Dict]) -> Dict:
        """
        Calculate frequency of each number appearing.
        Returns hot (most frequent) and cold (least frequent) numbers.
        """
        white_counter = Counter()
        powerball_counter = Counter()
        
        for draw in draws:
            white_balls, powerball = self.parse_winning_numbers(draw)
            if white_balls:
                white_counter.update(white_balls)
                powerball_counter[powerball] += 1
        
        # Sort by frequency
        white_sorted = white_counter.most_common()
        powerball_sorted = powerball_counter.most_common()
        
        # Top 16 hot, Bottom 10 cold for white balls
        hot_white = [num for num, count in white_sorted[:16]]
        cold_white = [num for num, count in white_sorted[-10:]]
        
        # Top 5 hot, Bottom 5 cold for powerball
        hot_pb = [num for num, count in powerball_sorted[:5]]
        cold_pb = [num for num, count in powerball_sorted[-5:]]
        
        return {
            "hot_numbers": hot_white,
            "cold_numbers": cold_white,
            "hot_powerballs": hot_pb,
            "cold_powerballs": cold_pb,
            "white_frequency": dict(white_counter),
            "powerball_frequency": dict(powerball_counter),
            "total_draws_analyzed": len(draws)
        }
    
    async def get_live_stats(self, force_refresh: bool = False) -> Dict:
        """
        Get hot/cold numbers. Uses cache until next Powerball drawing!
        Cache is stored in file and survives server restarts!
        Refreshes only after drawings (Mon/Wed/Sat at 10:59 PM ET).
        """
        global _memory_cache
        
        now = datetime.now()
        
        # Try to load from file if memory cache is empty
        if not _memory_cache.get("last_updated"):
            _load_cache_from_file()
        
        # Check if cache is valid (no new drawing since last update)
        if not force_refresh and _memory_cache.get("last_updated"):
            last_updated = _memory_cache["last_updated"]
            if isinstance(last_updated, str):
                last_updated = datetime.fromisoformat(last_updated)
            
            if _is_cache_valid(last_updated):
                last_drawing = _get_last_drawing_time()
                print(f"📊 Using cached lottery stats (last drawing: {last_drawing.strftime('%a %m/%d %I:%M %p ET')})")
                return {
                    "hot_numbers": _memory_cache["hot_numbers"],
                    "cold_numbers": _memory_cache["cold_numbers"],
                    "hot_powerballs": _memory_cache["hot_powerballs"],
                    "cold_powerballs": _memory_cache["cold_powerballs"],
                    "last_updated": last_updated.isoformat() if isinstance(last_updated, datetime) else last_updated,
                    "next_refresh": _get_next_drawing_time().isoformat(),
                    "cached": True
                }
        
        # Fetch fresh data
        print("🔄 Fetching live Powerball statistics...")
        draws = await self.fetch_recent_draws(limit=100)
        
        if not draws:
            # Fallback to hardcoded if API fails
            print("⚠️ Using fallback statistics")
            return {
                "hot_numbers": [61, 32, 63, 21, 69, 36, 62, 39, 37, 23, 10, 24, 59, 20, 3, 27],
                "cold_numbers": [13, 34, 4, 46, 51, 26, 60, 16, 35, 29],
                "hot_powerballs": [6, 9, 14, 18, 21],
                "cold_powerballs": [1, 12, 15, 17, 25],
                "last_updated": now.isoformat(),
                "cached": False,
                "fallback": True
            }
        
        # Calculate stats
        stats = self.calculate_frequency(draws)
        
        # Update memory cache
        _memory_cache["hot_numbers"] = stats["hot_numbers"]
        _memory_cache["cold_numbers"] = stats["cold_numbers"]
        _memory_cache["hot_powerballs"] = stats["hot_powerballs"]
        _memory_cache["cold_powerballs"] = stats["cold_powerballs"]
        _memory_cache["last_updated"] = now
        
        # Save to file for persistence
        _save_cache_to_file(_memory_cache)
        
        print(f"✅ Lottery stats updated! Hot: {stats['hot_numbers'][:5]}...")
        
        return {
            "hot_numbers": stats["hot_numbers"],
            "cold_numbers": stats["cold_numbers"],
            "hot_powerballs": stats["hot_powerballs"],
            "cold_powerballs": stats["cold_powerballs"],
            "white_frequency": stats["white_frequency"],
            "powerball_frequency": stats["powerball_frequency"],
            "total_draws": stats["total_draws_analyzed"],
            "last_updated": now.isoformat(),
            "cached": False
        }
    
    async def get_historical_drawings(self, limit: int = 20, force_refresh: bool = False) -> Dict:
        """
        Get recent Powerball drawing history with smart caching.
        Uses same refresh logic as hot/cold numbers (only after new drawings).
        """
        global _memory_cache
        
        now = datetime.now()
        
        # Try to load from file if memory cache is empty
        if not _memory_cache.get("last_updated"):
            _load_cache_from_file()
        
        # Check if cache is valid (no new drawing since last update)
        if not force_refresh and _memory_cache.get("historical_drawings") and _memory_cache.get("last_updated"):
            last_updated = _memory_cache["last_updated"]
            if isinstance(last_updated, str):
                last_updated = datetime.fromisoformat(last_updated)
            
            if _is_cache_valid(last_updated):
                print(f"📊 Using cached historical drawings ({len(_memory_cache['historical_drawings'])} draws)")
                return {
                    "drawings": _memory_cache["historical_drawings"][:limit],
                    "last_updated": last_updated.isoformat() if isinstance(last_updated, datetime) else last_updated,
                    "next_refresh": _get_next_drawing_time().isoformat(),
                    "cached": True
                }
        
        # Fetch fresh data
        print("🔄 Fetching historical Powerball drawings...")
        draws = await self.fetch_recent_draws(limit=limit)
        
        if not draws:
            # Return cached data if available, even if stale
            if _memory_cache.get("historical_drawings"):
                return {
                    "drawings": _memory_cache["historical_drawings"][:limit],
                    "last_updated": now.isoformat(),
                    "cached": True,
                    "stale": True
                }
            return {"drawings": [], "error": "Failed to fetch drawings"}
        
        # Parse draws into a cleaner format
        parsed_drawings = []
        for draw in draws:
            numbers_str = draw.get("winning_numbers", "")
            parts = numbers_str.split()
            if len(parts) == 6:
                parsed_drawings.append({
                    "date": draw.get("draw_date", "")[:10],
                    "white_balls": [int(p) for p in parts[:5]],
                    "powerball": int(parts[5]),
                    "multiplier": draw.get("multiplier")
                })
        
        # Update memory cache
        _memory_cache["historical_drawings"] = parsed_drawings
        _memory_cache["last_updated"] = now
        
        # Save to file for persistence
        _save_cache_to_file(_memory_cache)
        
        print(f"✅ Historical drawings updated! {len(parsed_drawings)} draws cached")
        
        return {
            "drawings": parsed_drawings[:limit],
            "last_updated": now.isoformat(),
            "next_refresh": _get_next_drawing_time().isoformat(),
            "cached": False
        }


# Singleton instance
lottery_stats_service = LotteryStatsService()


# Convenience function for sync code
def get_hot_cold_numbers() -> Tuple[List[int], List[int]]:
    """
    Synchronous helper to get hot/cold numbers.
    Uses cached values if available (memory or file).
    """
    global _memory_cache
    
    # Try memory cache first
    if _memory_cache.get("hot_numbers") and _memory_cache.get("cold_numbers"):
        return _memory_cache["hot_numbers"], _memory_cache["cold_numbers"]
    
    # Try file cache
    file_cache = _load_cache_from_file()
    if file_cache.get("hot_numbers") and file_cache.get("cold_numbers"):
        return file_cache["hot_numbers"], file_cache["cold_numbers"]
    
    # Fallback if both caches empty
    return (
        [61, 32, 63, 21, 69, 36, 62, 39, 37, 23, 10, 24, 59, 20, 3, 27],
        [13, 34, 4, 46, 51, 26, 60, 16, 35, 29]
    )
