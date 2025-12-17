"""
Powerball Lucky Number Generator Service.
Generates personalized powerball numbers based on astrology, numerology, and daily transits.
"""
from datetime import datetime, date
from typing import List, Dict
import hashlib


class PowerballService:
    """Generate lucky powerball numbers based on cosmic alignments."""
    
    def __init__(self):
        # Powerball rules: 5 white balls (1-69) + 1 red powerball (1-26)
        self.white_ball_max = 69
        self.powerball_max = 26
    
    def _get_seed_from_data(self, *args) -> int:
        """Create a deterministic seed from input data."""
        combined = "".join(str(arg) for arg in args)
        hash_obj = hashlib.md5(combined.encode())
        return int(hash_obj.hexdigest(), 16)
    
    def _numerology_number(self, name: str) -> int:
        """Calculate numerology number from name (1-9)."""
        name = name.upper().replace(" ", "")
        # A=1, B=2, ..., Z=26
        total = sum(ord(char) - ord('A') + 1 for char in name if char.isalpha())
        
        # Reduce to single digit
        while total > 9:
            total = sum(int(digit) for digit in str(total))
        
        return total
    
    def _date_to_numbers(self, date_str: str) -> List[int]:
        """Extract numbers from date (YYYY-MM-DD)."""
        parts = date_str.split('-')
        return [int(p) for p in parts]
    
    def generate_personal_powerball(self, name: str, dob: str) -> Dict:
        """
        Generate a personal/static powerball number based on birth chart.
        This should remain consistent for the user.
        
        Args:
            name: User's full name
            dob: Date of birth (YYYY-MM-DD)
            
        Returns:
            Dict with white_balls (list of 5 ints) and powerball (int)
        """
        # Use name numerology and birth date to generate consistent numbers
        name_num = self._numerology_number(name)
        date_nums = self._date_to_numbers(dob)
        
        # Create seed from birth data
        seed = self._get_seed_from_data(name, dob)
        
        # Generate 5 white balls
        white_balls = []
        temp_seed = seed
        
        # First ball: based on name numerology
        white_balls.append((name_num * 7) % self.white_ball_max + 1)
        
        # Remaining 4 balls: based on birth date components + life path
        life_path = sum(date_nums)
        while life_path > 9:
            life_path = sum(int(d) for d in str(life_path))
            
        components = date_nums + [life_path]
        for num in components:
            temp_seed = (temp_seed * 1103515245 + 12345 + num) & 0x7fffffff
            ball = (temp_seed % self.white_ball_max) + 1
            
            # Ensure uniqueness
            while ball in white_balls:
                temp_seed = (temp_seed * 1103515245 + 12345) & 0x7fffffff
                ball = (temp_seed % self.white_ball_max) + 1
            
            white_balls.append(ball)
        
        # Sort white balls
        white_balls.sort()
        
        # Powerball: based on life path number
        life_path = sum(date_nums)
        while life_path > 9:
            life_path = sum(int(d) for d in str(life_path))
        
        powerball = ((life_path + name_num) % self.powerball_max) + 1
        
        return {
            "white_balls": white_balls[:5],
            "powerball": powerball,
            "type": "personal"
        }
    
    def generate_daily_powerballs(
        self, 
        name: str, 
        dob: str, 
        current_date: str,
        luck_score: int,
        astro_score: int = 50,
        natal_score: int = 50
    ) -> List[Dict]:
        """
        Generate 10 powerball combinations for the day based on cosmic alignments.
        
        Args:
            name: User's name
            dob: Date of birth
            current_date: Current date (YYYY-MM-DD)
            luck_score: Today's luck score
            astro_score: Astrology transit score
            natal_score: Natal chart strength
            
        Returns:
            List of 10 powerball combinations
        """
        combinations = []
        
        # Base seed from personal + daily data
        base_seed = self._get_seed_from_data(name, dob, current_date, luck_score)
        
        for i in range(10):
            # Vary seed for each combination
            combo_seed = base_seed + i * 997 + luck_score + astro_score + natal_score
            
            white_balls = []
            temp_seed = combo_seed
            
            # Generate 5 unique white balls
            for j in range(5):
                temp_seed = (temp_seed * 1103515245 + 12345) & 0x7fffffff
                ball = (temp_seed % self.white_ball_max) + 1
                
                # Ensure uniqueness within this combination
                while ball in white_balls:
                    temp_seed = (temp_seed * 1103515245 + 12345) & 0x7fffffff
                    ball = (temp_seed % self.white_ball_max) + 1
                
                white_balls.append(ball)
            
            # Sort white balls
            white_balls.sort()
            
            # Generate powerball
            temp_seed = (temp_seed * 1103515245 + 12345 + i) & 0x7fffffff
            powerball = (temp_seed % self.powerball_max) + 1
            
            combinations.append({
                "white_balls": white_balls,
                "powerball": powerball,
                "type": "daily",
                "index": i + 1
            })
        
        return combinations


# Singleton instance
powerball_service = PowerballService()
