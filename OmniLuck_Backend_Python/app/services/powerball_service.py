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
        
        # Statistical Intelligence Data (Historical frequent balls)
        self.hot_numbers = [61, 32, 63, 21, 69, 36, 62, 39, 37, 23, 10, 24, 59, 20, 3, 27]
        self.cold_numbers = [13, 34, 4, 46, 51, 26, 60, 16, 35, 29]
        
        # Statistical Harmonic Sum Range (Most common sums for winning 5-ball sets)
        self.min_harmonic_sum = 130
        self.max_harmonic_sum = 220

    def _get_seed_from_data(self, *args) -> int:
        """Create a deterministic seed from input data."""
        combined = "".join(str(arg) for arg in args)
        hash_obj = hashlib.md5(combined.encode())
        return int(hash_obj.hexdigest(), 16)

    def _is_statistically_balanced(self, white_balls: List[int]) -> bool:
        """Check if the set of balls meets all balance criteria: Sum, Parity, Range."""
        # 1. Harmonic Sum
        s = sum(white_balls)
        if not (self.min_harmonic_sum <= s <= self.max_harmonic_sum):
            return False
            
        # 2. Parity Balance (Odd/Even) - Winning sets are usually 3:2 or 2:3
        odds = len([b for b in white_balls if b % 2 != 0])
        if odds not in [2, 3]: return False
        
        # 3. Range Balance (High/Low) - Split at 34
        lows = len([b for b in white_balls if b <= 34])
        if lows not in [2, 3]: return False
        
        return True

    def _planetary_territory_map(self, degree: float) -> int:
        """
        Maps a Zodiac degree (0-360) to a Powerball white ball (1-69).
        Used for aligning picks with planetary positions.
        """
        return int((degree % 360) / (360 / self.white_ball_max)) + 1

    def _apply_statistical_weight(self, ball: int, seed: int) -> int:
        """Nudges cosmic balls towards 'hot' numbers or away from 'cold' ones."""
        if ball in self.cold_numbers and (seed % 10) > 3:
            return (ball + seed) % self.white_ball_max + 1
        for hot in self.hot_numbers:
            if abs(ball - hot) <= 1: return hot
        return ball

    def _numerology_number(self, name: str) -> int:
        name = name.upper().replace(" ", "")
        total = sum(ord(char) - ord('A') + 1 for char in name if char.isalpha())
        while total > 9: total = sum(int(digit) for digit in str(total))
        return total

    def _date_to_numbers(self, date_str: str) -> List[int]:
        parts = date_str.split('-')
        return [int(p) for p in parts]

    def generate_personal_powerball(self, name: str, dob: str) -> Dict:
        """Enhanced Personal Powerball with Parity, Range, and Harmonic Balancing."""
        name_num = self._numerology_number(name)
        date_nums = self._date_to_numbers(dob)
        base_seed = self._get_seed_from_data(name, dob)
        
        for attempt in range(50): # More attempts for tighter balancing
            white_balls = []
            temp_seed = base_seed + attempt * 17
            
            # Ball 1: Name Numerology
            ball1 = (name_num * 7 + attempt) % self.white_ball_max + 1
            white_balls.append(self._apply_statistical_weight(ball1, temp_seed))
            
            # Life Path
            lp = sum(date_nums)
            while lp > 9: lp = sum(int(d) for d in str(lp))
            
            # Generate remaining via tempered birth seeds
            for i, num in enumerate(date_nums + [lp]):
                temp_seed = (temp_seed * 1103515245 + 12345 + num + i) & 0x7fffffff
                ball = (temp_seed % self.white_ball_max) + 1
                ball = self._apply_statistical_weight(ball, temp_seed)
                while ball in white_balls:
                    temp_seed = (temp_seed * 1103515245 + 12345) & 0x7fffffff
                    ball = (temp_seed % self.white_ball_max) + 1
                white_balls.append(ball)
            
            white_balls.sort()
            if self._is_statistically_balanced(white_balls) or attempt == 49:
                break
        
        powerball = ((lp + name_num) % self.powerball_max) + 1
        return {
            "white_balls": white_balls[:5],
            "powerball": powerball,
            "type": "personal"
        }

    def generate_daily_powerballs(
        self, name: str, dob: str, current_date: str,
        luck_score: int, astro_score: int = 50, natal_score: int = 50,
        num_lines: int = 5
    ) -> List[Dict]:
        """
        Generate daily combinations using Delta Strategy (Spacing) 
        and Planetary Territory Mapping.
        """
        combinations = []
        base_seed = self._get_seed_from_data(name, dob, current_date, luck_score)
        
        for i in range(num_lines):
            for attempt in range(20):
                combo_seed = base_seed + i * 1009 + attempt * 71
                
                # Use Delta Strategy: Generate gaps between numbers
                # Standard Delta: [low, low-mid, low-mid, mid, mid-high, high]
                # We'll use cosmic data to influence the gaps
                deltas = []
                temp_seed = combo_seed
                
                # 1. Map planetary territory (Simulated based on astro_score)
                # In real use, we'd pass actual planet degrees here
                planet_ball = self._planetary_territory_map(astro_score * 3.6 + i * 5)
                
                # 2. Build the set using the Delta spacing logic
                # Delta 1: Tiny (1-5)
                deltas.append((temp_seed % 5) + 1)
                # Delta 2-4: Mid (3-12)
                for _ in range(3):
                    temp_seed = (temp_seed * 742938285 + 1) % 2147483647
                    deltas.append((temp_seed % 10) + 3)
                # Delta 5: Larger (8-15)
                temp_seed = (temp_seed * 742938285 + 1) % 2147483647
                deltas.append((temp_seed % 8) + 8)
                
                # Convert Deltas to Balls
                white_balls = []
                current_sum = planet_ball % 15 + 1 # Start with a small cosmic base
                for d in deltas:
                    current_sum += d
                    if current_sum > self.white_ball_max:
                        current_sum = (current_sum % self.white_ball_max) + 1
                    white_balls.append(current_sum)
                
                white_balls = list(set(white_balls))
                while len(white_balls) < 5:
                    temp_seed = (temp_seed * 742938285 + 1) % 2147483647
                    new_ball = (temp_seed % self.white_ball_max) + 1
                    if new_ball not in white_balls: white_balls.append(new_ball)
                
                white_balls.sort()
                
                if self._is_statistically_balanced(white_balls) or attempt == 19:
                    break
            
            # Powerball
            temp_seed = (temp_seed * 742938285 + 1 + i) % 2147483647
            powerball = (temp_seed % self.powerball_max) + 1
            
            combinations.append({
                "white_balls": white_balls[:5],
                "powerball": powerball,
                "type": "daily",
                "index": i + 1
            })
            
        return combinations


# Singleton instance
powerball_service = PowerballService()
