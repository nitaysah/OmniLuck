"""
Numerology Service for calculating Life Path, Destiny, and Daily Personal numbers.
Uses standard Pythagorean system (1-9).
"""
from datetime import date, datetime
import re

class NumerologyService:
    """Service for deterministic Numerology calculations"""
    
    def __init__(self):
        # Pythagorean Letter-to-Number Table
        self.letter_map = {
            'a': 1, 'j': 1, 's': 1,
            'b': 2, 'k': 2, 't': 2,
            'c': 3, 'l': 3, 'u': 3,
            'd': 4, 'm': 4, 'v': 4,
            'e': 5, 'n': 5, 'w': 5,
            'f': 6, 'o': 6, 'x': 6,
            'g': 7, 'p': 7, 'y': 7,
            'h': 8, 'q': 8, 'z': 8,
            'i': 9, 'r': 9
        }
        
        # Compatibility Matrix (Simplified)
        # 1=Great, 0.5=Neutral, 0=Friction
        # Groups: (1,5,7), (2,4,8), (3,6,9)
        self.concord_groups = {
            1: 1, 5: 1, 7: 1,
            2: 2, 4: 2, 8: 2, 11: 2, 22: 2,
            3: 3, 6: 3, 9: 3, 33: 3
        }
        
    def _reduce_sum(self, n: int, allow_master: bool = True) -> int:
        """
        Recursively sum digits until single digit or Master Number (11, 22, 33).
        Example: 1987 -> 25 -> 7
        """
        while n > 9:
            if allow_master and n in [11, 22, 33]:
                return n
            n = sum(int(d) for d in str(n))
        return n
        
    def calculate_life_path(self, dob_str: str) -> int:
        """
        Calculate Life Path Number from YYYY-MM-DD string.
        Strategy: Reduce Month, Reduce Day, Reduce Year -> Sum them -> Reduce Total.
        """
        try:
            dt = datetime.strptime(dob_str, "%Y-%m-%d")
            
            # Reduce each part independently first (Standard Method)
            m = self._reduce_sum(dt.month, allow_master=True)
            d = self._reduce_sum(dt.day, allow_master=True)
            y = self._reduce_sum(dt.year, allow_master=True)
            
            total = m + d + y
            return self._reduce_sum(total, allow_master=True)
        except:
            return 0

    def calculate_destiny_number(self, full_name: str) -> int:
        """
        Calculate Destiny (Expression) Number from Full Name.
        Sum of all letter values.
        """
        if not full_name:
            return 0
            
        clean_name = re.sub(r'[^a-zA-Z]', '', full_name.lower())
        total = 0
        for char in clean_name:
            total += self.letter_map.get(char, 0)
            
        return self._reduce_sum(total, allow_master=True)
        
    def calculate_personal_day(self, dob_str: str, target_date: date = None) -> int:
        """
        Calculate Personal Day Number for a specific date.
        Formula: Current Month + Current Day + (Birth Month + Birth Day reduced)
        Wait -> Standard Formula: Personal Year + Current Month + Current Day
        Personal Year = Birth Month + Birth Day + Current Year
        """
        if target_date is None:
            target_date = date.today()
            
        try:
            dt = datetime.strptime(dob_str, "%Y-%m-%d")
            
            # 1. Calculate Personal Year
            # Sum of Birth Month + Birth Day + CURRENT YEAR
            bm = self._reduce_sum(dt.month) # keep single digit for intermediate
            bd = self._reduce_sum(dt.day)
            cy = self._reduce_sum(target_date.year)
            
            personal_year = self._reduce_sum(bm + bd + cy)
            
            # 2. Calculate Personal Day
            # Personal Year + Current Month + Current Day
            cm = self._reduce_sum(target_date.month)
            cd = self._reduce_sum(target_date.day)
            
            total = personal_year + cm + cd
            return self._reduce_sum(total, allow_master=False) # Daily numbers usually 1-9
            
        except:
            return 1
            
    def calculate_daily_score(self, dob_str: str, full_name: str, target_date_str: str = None) -> dict:
        """
        Calculate the Daily Numerology Score (0-100).
        Logic: Synergy between Core Numbers and Today's Personal Day.
        
        Args:
            dob_str: Date of birth (YYYY-MM-DD)
            full_name: User's full name
            target_date_str: Optional target date for calculation (YYYY-MM-DD). Defaults to today.
        """
        from datetime import date
        
        # Parse target date if provided
        target_date = None
        if target_date_str:
            try:
                target_date = datetime.strptime(target_date_str, "%Y-%m-%d").date()
            except:
                target_date = None
        
        lp = self.calculate_life_path(dob_str)
        destiny = self.calculate_destiny_number(full_name)
        p_day = self.calculate_personal_day(dob_str, target_date)
        
        score = 50.0 # Base Neutral
        
        # 1. Personal Day vs Life Path Synergy (40 pts)
        group_lp = self.concord_groups.get(lp, 0)
        group_pd = self.concord_groups.get(p_day, 0)
        
        if lp == p_day:
            score += 40 # Perfect alignment
        elif group_lp == group_pd:
            score += 25 # Same Concord (Harmonious)
        elif (lp % 2) == (p_day % 2):
            score += 10 # Same Parity (Even/Odd) = Compatible
        else:
            score -= 5 # Friction
            
        # 2. Personal Day vs Destiny Synergy (30 pts)
        group_dest = self.concord_groups.get(destiny, 0)
        
        if destiny == p_day:
            score += 30
        elif group_dest == group_pd:
            score += 15
        elif (destiny % 2) == (p_day % 2):
            score += 5
            
        # 3. Master Number Bonus (Potential Energy)
        if lp in [11, 22, 33] or destiny in [11, 22, 33]:
            score += 10 # High potential user
            
        # 4. Personal Day 8 or 9 (Harvest/Completion) generally feels potent
        if p_day in [8, 9]:
            score += 5
            
        final_score = int(max(10, min(100, score)))
        
        return {
            "numerology_score": final_score,
            "life_path_number": lp,
            "destiny_number": destiny,
            "personal_day_number": p_day
        }

# Singleton
numerology_service = NumerologyService()
