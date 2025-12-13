"""
LLM Service for generating personalized fortune explanations.
Uses Google Gemini API (free tier).
"""
import os
from typing import Dict, List
from app.config import settings


class LLMService:
    """Service for LLM-powered text generation"""
    
    def __init__(self):
        self.use_local = settings.USE_LOCAL_LLM
        self.gemini_key = settings.GEMINI_API_KEY
        
        print(f"🔧 LLM Service: use_local={self.use_local}, has_key={bool(self.gemini_key)}")
        
        if not self.use_local and self.gemini_key:
            try:
                # Use REST API directly to avoid v1beta issues
                self.api_key = self.gemini_key
                self.model = "gemini-1.5-flash"  # Store model name
                print("✅ Google Gemini 1.5 Flash configured (REST API)")
            except Exception as e:
                print(f"❌ Gemini configuration failed: {e}")
                self.api_key = None
                self.model = None
        else:
            if self.use_local:
                print("ℹ️  Using local LLM mode (fallback templates)")
            elif not self.gemini_key:
                print("⚠️  No Gemini API key found - using fallback templates")
            self.api_key = None
            self.model = None
    
    def generate_fortune_explanation(
        self,
        luck_score: int,
        user_data: Dict,
        cosmic_signals: Dict = None,
        astrology_data: Dict = None
    ) -> str:
        """
        Generate personalized fortune explanation using LLM.
        
        Args:
            luck_score: User's calculated luck score (0-100)
            user_data: User info (name, zodiac, etc.)
            cosmic_signals: Optional cosmic data (lunar, weather, etc.)
            astrology_data: Optional astrology data (transits, etc.)
            
        Returns:
            Personalized fortune text
        """
        # Build context prompt
        prompt = self._build_fortune_prompt(luck_score, user_data, cosmic_signals, astrology_data)
        
        # Generate using Gemini REST API if available
        if self.api_key and self.model:
            try:
                import requests
                
                url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"
                headers = {"Content-Type": "application/json"}
                data = {
                    "contents": [{
                        "parts": [{"text": prompt}]
                    }]
                }
                
                response = requests.post(url, headers=headers, json=data, timeout=10)
                response.raise_for_status()
                result = response.json()
                
                # Extract text from response
                text = result['candidates'][0]['content']['parts'][0]['text']
                return text.strip()
                
            except Exception as e:
                print(f"❌ LLM generation error: {e}")
                return self._fallback_template(luck_score, user_data)
        else:
            # Fallback to templates
            return self._fallback_template(luck_score, user_data)
    
    def _build_fortune_prompt(
        self,
        luck_score: int,
        user_data: Dict,
        cosmic_signals: Dict = None,
        astrology_data: Dict = None
    ) -> str:
        """Build prompt for LLM"""
        
        name = user_data.get("name", "friend")
        zodiac = user_data.get("zodiac", "your sign")
        
        prompt = f"""You are a mystical astrologer creating a personalized daily fortune reading.

USER PROFILE:
- Name: {name}
- Zodiac Sign: {zodiac}
- Today's Luck Score: {luck_score}/100

"""
        
        if cosmic_signals:
            lunar = cosmic_signals.get("lunar", {})
            weather = cosmic_signals.get("weather", {})
            geo = cosmic_signals.get("geomagnetic", {})
            
            prompt += f"""COSMIC CONDITIONS:
- Moon Phase: {lunar.get('phase_name', 'Unknown')} ({lunar.get('illumination', 0)}% illuminated)
- Weather: {weather.get('condition', 'clear')}, {weather.get('temp_c', 20)}°C
- Geomagnetic Activity: {geo.get('activity_level', 'quiet')} (Kp {geo.get('kp_index', 2)})

"""
        
        if astrology_data:
            prompt += f"""ASTROLOGICAL DATA:
- Sun Sign: {astrology_data.get('sun_sign', zodiac)}
- Moon Sign: {astrology_data.get('moon_sign', 'Unknown')}
- Rising Sign: {astrology_data.get('ascendant', 'Unknown')}

"""
        
        prompt += f"""Write a warm, encouraging fortune message (2-3 paragraphs, ~150 words) that:
1. Acknowledges the luck score ({luck_score}/100)
2. References relevant cosmic conditions
3. Provides actionable advice or insight
4. Maintains a mystical yet authentic tone
5. Is personalized to {name} as a {zodiac}

Fortune message:"""
        
        return prompt
    
    def _fallback_template(self, luck_score: int, user_data: Dict) -> str:
        """Fallback templates when LLM is unavailable"""
        
        zodiac = user_data.get("zodiac", "your sign")
        name = user_data.get("name", "friend")
        
        if luck_score >= 85:
            return f"✨ {name}, the stars shine brilliantly for you today! As a {zodiac}, you're experiencing exceptional cosmic alignment. Fortune favors the bold—embrace opportunities with confidence and trust your intuition."
        
        elif luck_score >= 70:
            return f"🌟 {name}, your {zodiac} energy is harmonizing beautifully with today's celestial movements. Great things await! Now is an excellent time to pursue your goals and connect with others."
        
        elif luck_score >= 50:
            return f"🌙 {name}, as a {zodiac}, you're navigating steady cosmic currents today. Balance is your superpower. Trust the journey you're on and stay grounded in your wisdom."
        
        elif luck_score >= 30:
            return f"🌾 {name}, the cosmic energy asks you to slow down and reflect. As a {zodiac}, use this time for inner growth and self-care. Tomorrow's fortunes are built on today's rest."
        
        else:
            return f"🕊️ {name}, the celestial bodies are in a protective formation. Remember your resilience as a {zodiac}. This too shall pass, and your inner strength remains unshakable."
    
    def analyze_luck_and_generate_content(
        self,
        user_data: Dict,
        cosmic_signals: Dict = None,
        astrology_data: Dict = None
    ) -> Dict:
        """
        Analyze user's profile and cosmic data to generate an Intuitive Luck Score and content.
        This provides the 'AI Pillar' of the luck calculation (replacing simple numerology).
        
        Returns:
            Dict containing:
            - score (int): 0-100
            - explanation (str)
            - actions (List[str])
        """
        # If no API key, return deterministic fallback immediately
        if not self.api_key:
            score = self._calculate_numerology_fallback(user_data)
            return {
                "score": score,
                "explanation": self._fallback_template(score, user_data),
                "actions": ["Stay positive", "Trust your intuition", "Help others today"]
            }

        # Build comprehensive analysis prompt
        prompt = self._build_analysis_prompt(user_data, cosmic_signals, astrology_data)
        
        try:
            import requests
            import json
            
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"
            headers = {"Content-Type": "application/json"}
            data = {
                "contents": [{
                    "parts": [{"text": prompt}]
                }],
                # We ask for JSON-like structure, but Gemini 1.5 Flash is smart enough with just text prompt too
                "generationConfig": {
                    "temperature": 0.7,
                    "maxOutputTokens": 500,
                }
            }
            
            response = requests.post(url, headers=headers, json=data, timeout=12)
            response.raise_for_status()
            result = response.json()
            
            text_response = result['candidates'][0]['content']['parts'][0]['text']
            
            # Clean and parse JSON from Markdown response
            clean_json = text_response.replace("```json", "").replace("```", "").strip()
            parsed_data = json.loads(clean_json)
            
            return {
                "score": max(0, min(100, parsed_data.get("score", 75))),
                "explanation": parsed_data.get("explanation", "The stars are aligning for you."),
                "actions": parsed_data.get("actions", ["Seize the day", "Reflect inward", "Smile often"])
            }
            
        except Exception as e:
            print(f"❌ AI Analysis error: {e}")
            # Fallback
            score = self._calculate_numerology_fallback(user_data)
            return {
                "score": score,
                "explanation": self._fallback_template(score, user_data),
                "actions": ["Focus on your goals", "Rest well", "Connect with nature"]
            }

    def _build_analysis_prompt(self, user, cosmic, astro) -> str:
        name = user.get("name", "User")
        dob = user.get("dob", "Unknown")
        birth_place = user.get("birth_place", "Unknown")
        birth_time = user.get("birth_time", "Unknown")
        timezone = user.get("timezone", "UTC")
        
        # Personalization Data
        intention = user.get("intention", "General Luck")
        sleep = user.get("sleep", "Unknown")
        energy = user.get("energy", "Unknown")
        past_rating = user.get("yesterday_luck", "Unknown")
        
        # History
        hist_lotto = user.get("history_lottery", "Unknown")
        hist_games = user.get("history_games", "Unknown")
        hist_sports = user.get("history_sports", "Unknown")
        
        lunar_phase = cosmic.get("lunar", {}).get("phase_name", "Unknown") if cosmic else "Unknown"
        weather = cosmic.get("weather", {}).get("condition", "Unknown") if cosmic else "Unknown"
        kp_index = cosmic.get("geomagnetic", {}).get("kp_index", 0) if cosmic else 0
        
        transit_info = "Unknown"
        if astro and "aspects" in astro:
            aspects = astro["aspects"]
            if aspects:
                top_aspect = aspects[0]
                transit_info = f"{top_aspect.get('type')} between {top_aspect.get('transit_planet')} and {top_aspect.get('natal_planet')}"

        return f"""
        You are an expert Astrologer, Nucleophysicist, and AI combined.
        User Profile:
        - Name: {name}
        - Born: {dob} at {birth_time} ({timezone}) in {birth_place}
        - Intention/Focus: {intention}
        - Current State: Sleep={sleep}, Energy={energy}
        - Yesterday's Luck: {past_rating}/10
        
        Cosmic Signals:
        - Moon: {lunar_phase}
        - Weather: {weather}
        - Geomagnetic Kp: {kp_index}
        - Major Transit: {transit_info}

        **TASK:**
        1. synthesize their "Historical Luck Type" (if inferred) with today's Astrology.
        2. Calculate today's "Intuitive Luck Score" (0-100).
        3. Create a short, punchy **Caption** (e.g. "Cosmic Jackpot!", "Build Your Foundation").
        4. Write a **"Why this score?"** summary in simple terms.
        5. **Vedic Analysis (Kundali):** 
           - IF Birth Time is provided ({birth_time}): Estimate Ascendant/Nakshatra.
           - Include a **"Kundali Insight"** but translate it into **simple, plain English**.
           - (e.g. Instead of "Jupiter in 10th house", say "A major planet is boosting your career sector today").
        6. Write the detailed Daily Analysis incorporating the Vedic Insight if possible.

        Output ONLY valid JSON:
        {{
            "score": <integer 0-100>,
            "caption": "<short headline>",
            "summary": "<simple explanation of factors used>",
            "explanation": "<detailed reading with Vedic Insight if applicable>",
            "actions": ["<action 1>", "<action 2>", "<action 3>"]
        }}
        """

    def _calculate_numerology_fallback(self, user_data) -> int:
        # Simple life path calculation for fallback
        try:
            dob = user_data.get("dob", "2000-01-01").replace("-", "")
            return sum(int(d) for d in dob) % 9 * 11 + 10 # Rough mock
        except:
            return 75
    
    def generate_lucky_actions(
        self,
        luck_score: int,
        user_data: Dict,
        cosmic_signals: Dict = None
    ) -> List[str]:
        """Generate 3 personalized lucky actions"""
        
        if self.api_key and self.model:
            try:
                import requests
                
                zodiac = user_data.get("zodiac", "your sign")
                prompt = f"""Generate 3 short, specific lucky actions for someone with {luck_score}/100 luck score as a {zodiac}.

Format as a simple list, each action 5-10 words maximum. Examples:
- Wear green for Venus energy
- Best time for calls: 2-4 PM
- Avoid major decisions before 6 PM

Lucky actions:"""
                
                url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"
                headers = {"Content-Type": "application/json"}
                data = {
                    "contents": [{
                        "parts": [{"text": prompt}]
                    }]
                }
                
                response = requests.post(url, headers=headers, json=data, timeout=10)
                response.raise_for_status()
                result = response.json()
                
                text = result['candidates'][0]['content']['parts'][0]['text']
                actions = [line.strip("- ").strip() for line in text.strip().split("\n") if line.strip()]
                return actions[:3]
            except:
                pass
        
        # Fallback actions
        return [
            "Trust your intuition on important decisions",
            "Wear purple or gold for enhanced luck",
            "Best time for key activities: afternoon"
        ]


# Singleton instance
llm_service = LLMService()
