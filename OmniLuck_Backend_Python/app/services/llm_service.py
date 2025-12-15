"""
LLM Service for generating personalized fortune explanations.
Uses Google Gemini API (free tier).
"""
import os
from datetime import datetime
from typing import Dict, List
from app.config import settings


class LLMService:
    """Service for LLM-powered text generation"""
    
    def __init__(self):
        self.use_local = settings.USE_LOCAL_LLM
        self.gemini_key = settings.GEMINI_API_KEY
        self.groq_key = settings.GROQ_API_KEY
        self.model = None
        self.groq_client = None
        
        print(f"🔧 LLM Service: use_local={self.use_local}, has_gemini={bool(self.gemini_key)}, has_groq={bool(self.groq_key)}")
        
        if not self.use_local:
            # Initialize Gemini
            if self.gemini_key:
                try:
                    import google.generativeai as genai
                    genai.configure(api_key=self.gemini_key)
                    self.model = genai.GenerativeModel('models/gemini-2.0-flash')
                    # Test connection validity quickly? No, lazy load.
                    print("✅ Google Gemini 2.0 Flash configured (SDK)")
                except Exception as e:
                    print(f"❌ Gemini configuration failed: {e}")
                    self.model = None

            # Initialize Groq as fallback
            if self.groq_key:
                try:
                    from groq import Groq
                    self.groq_client = Groq(api_key=self.groq_key)
                    print("✅ Groq (Llama 3) configured as fallback")
                except Exception as e:
                    print(f"❌ Groq configuration failed: {e}")
                    self.groq_client = None
        else:
            if self.use_local:
                print("ℹ️  Using local LLM mode (fallback templates)")
            elif not self.gemini_key:
                print("⚠️  No Gemini API key found - using fallback templates")
    
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
        
            # Try Gemini first
        if self.model:
            try:
                response = self.model.generate_content(prompt)
                return response.text.strip()
            except Exception as e:
                print(f"⚠️ Gemini API error: {e}")
                # Fall through to Groq
        
        # Try Groq (Llama 3) fallback
        if self.groq_client:
            try:
                print("🔄 Falling back to Groq (Llama 3)...")
                chat_completion = self.groq_client.chat.completions.create(
                    messages=[
                        {
                            "role": "system",
                            "content": "You are a mystical and wise astrologer. Give personalized daily fortune readings."
                        },
                        {
                            "role": "user",
                            "content": prompt,
                        }
                    ],
                    model="llama3-70b-8192",
                    temperature=0.7,
                )
                return chat_completion.choices[0].message.content.strip()
            except Exception as e:
                print(f"❌ Groq API error: {e}")
                return self._fallback_template(luck_score, user_data)
                
        # Fallback to templates
        return self._fallback_template(luck_score, user_data)
    
    def _build_fortune_prompt(
        self,
        luck_score: int,
        user_data: Dict,
        cosmic_signals: Dict = None,
        astrology_data: Dict = None,
        numerology_data: Dict = None
    ) -> str:
        """Build prompt for LLM"""
        
        name = user_data.get("name", "friend")
        zodiac = user_data.get("zodiac", "your sign")
        
        prompt = f"""You are a mystical astrologer explaining a scientifically calculated daily fortune.

DATA INPUTS:
- User: {name} ({zodiac})
- Total OmniLuck Score: {luck_score}/100

"""
        if numerology_data:
            prompt += f"""NUMEROLOGY FACTORS:
- Life Path Number: {numerology_data.get('life_path_number')}
- Destiny Number: {numerology_data.get('destiny_number')}
- Personal Day Cycle: {numerology_data.get('personal_day_number')}
(Note: The score is high because their Core Numbers harmonize with today's cycle.)

"""

        if astrology_data:
            transits = astrology_data.get('transits_score', 50)
            prompt += f"""ASTROLOGY FACTORS (Transit Score: {transits}):
- Sun Sign: {astrology_data.get('sun_sign')}
- Moon Sign: {astrology_data.get('moon_sign')}
- Rising Sign: {astrology_data.get('ascendant')}

"""

        if cosmic_signals:
            lunar = cosmic_signals.get("lunar", {})
            weather = cosmic_signals.get("weather", {})
            prompt += f"""ENVIRONMENTAL FACTORS:
- Moon Phase: {lunar.get('phase_name')}
- Weather: {weather.get('condition')}

"""
        
        prompt += f"""Write a warm, insightful fortune message (150 words) that:
1. Explains WHY the score is {luck_score} based on the overlapping factors above.
2. Specifically mention their Numerology ("Your Personal Day X...") and Astrology ("Moon in Y...").
3. Give specific advice for this combination of energy.
4. Tone: Mystical but grounded in the data provided.

Fortune message:"""
        
        return prompt
    
    def _get_zodiac_sign(self, dob: str = None) -> str:
        """Helper to get zodiac sign from DOB string (YYYY-MM-DD)"""
        if not dob: return "Traveler"
        try:
            date = datetime.strptime(dob, "%Y-%m-%d")
            day = date.day; month = date.month
            signs = [(1, 20, "Capricorn"), (2, 19, "Aquarius"), (3, 20, "Pisces"), (4, 20, "Aries"),
                     (5, 21, "Taurus"), (6, 21, "Gemini"), (7, 22, "Cancer"), (8, 23, "Leo"),
                     (9, 23, "Virgo"), (10, 23, "Libra"), (11, 22, "Scorpio"), (12, 22, "Sagittarius"),
                     (12, 31, "Capricorn")]
            for m, d, sign in signs:
                if (month == m and day <= d) or (month < m): return sign
            return "Capricorn"
        except: return "Traveler"

    def _fallback_response(self, user_name: str, luck_score: int, zodiac: str = "Traveler") -> Dict:
        """Generate static fallback response if AI fails"""
        sign = zodiac if zodiac else "Traveler"

        return {
            "score": luck_score,
            "explanation": f"🌙 {user_name}, as a {sign}, you're navigating steady cosmic currents today. Balance is your superpower. Trust the journey you're on and stay grounded in your wisdom.",
            "actions": ["Focus on your goals", "Rest well", "Connect with nature"],
            "strategic_advice": "Focus on consolidating your gains today. The energy supports steady progress rather than bold leaps. Review your recent wins and plan the next phase carefully.",
            "lucky_time_slots": ["10:00 AM - 12:00 PM", "4:00 PM - 6:00 PM"],
            "archetype": "The Steady Navigator",
            "caption": "Cosmic Alignment",
            "summary": "Your numbers align for steady progress."
        }
    
    def analyze_luck_and_generate_content(
        self,
        user_data: Dict,
        cosmic_signals: Dict = None,
        astrology_data: Dict = None,
        numerology_data: Dict = None
    ) -> Dict:
        """
        Analyze user's profile and cosmic data to generate content.
        Note: AI no longer calculates the score; it explains the provided data.
        """
        # If no model configured, return deterministic fallback immediately
        if not self.model:
            score = self._calculate_numerology_fallback(user_data)
            return {
                "score": score,
                "explanation": self._fallback_template(score, user_data),
                "actions": ["Stay positive", "Trust your intuition", "Help others today"]
            }

        # Build comprehensive analysis prompt
        prompt = self._build_analysis_prompt(user_data, cosmic_signals, astrology_data, numerology_data)
        
        try:
            import json
            
            # Use SDK to generate content
            response = self.model.generate_content(
                prompt,
                generation_config={
                    "temperature": 0.7,
                    "max_output_tokens": 500,
                }
            )
            
            text_response = response.text
            
            # Clean and parse JSON from Markdown response
            clean_json = text_response.replace("```json", "").replace("```", "").strip()
            parsed_data = json.loads(clean_json)
            
            return {
                "score": max(0, min(100, parsed_data.get("score", 75))),
                "explanation": parsed_data.get("explanation", "The stars are aligning for you."),
                "actions": parsed_data.get("actions", ["Seize the day", "Reflect inward", "Smile often"]),
                "caption": f"{parsed_data.get('archetype', 'Cosmic Traveler')} | {parsed_data.get('caption', 'Cosmic Alignment')}",
                "summary": parsed_data.get("summary", "Your chart is balanced today."),
                "strategic_advice": parsed_data.get("strategy", "Balance your internal drive with external patience."),
                "lucky_time_slots": parsed_data.get("schedule", [])
            }
            
        except Exception as e:
            print(f"❌ AI Analysis error: {e}")
            # Fallback
            score = self._calculate_numerology_fallback(user_data)
            return self._fallback_response(
                user_data.get("name", "Traveler"), 
                score, 
                user_data.get("zodiac", "Traveler")
            )

    def _build_analysis_prompt(self, user, cosmic, astro, numero) -> str:
        name = user.get("name", "User")
        dob = user.get("dob", "Unknown")
        birth_place = user.get("birth_place", "Unknown")
        birth_time = user.get("birth_time", "Unknown")
        timezone = user.get("timezone", "UTC")
        
        # Personalization Data
        intention = user.get("intention", "General Luck")
        
        # Environmental
        lunar_phase = cosmic.get("lunar", {}).get("phase_name", "Unknown") if cosmic else "Unknown"
        weather = cosmic.get("weather", {}).get("condition", "Unknown") if cosmic else "Unknown"
        
        # Numerology Data (Pre-calculated)
        num_str = "Unknown"
        if numero:
            num_str = f"""
            - Life Path: {numero.get('life_path_number')}
            - Destiny: {numero.get('destiny_number')}
            - Personal Day: {numero.get('personal_day_number')}
            - Numerology Harmony Score: {numero.get('numerology_score')}
            """

        transit_info = "Unknown"
        if astro and "aspects" in astro:
            aspects = astro["aspects"]
            if aspects:
                top_aspect = aspects[0]
                transit_info = f"{top_aspect.get('type')} between {top_aspect.get('transit_planet')} and {top_aspect.get('natal_planet')}"

        return f"""
        You are an expert Astrologer and Numerologist.
        
        USER CONTEXT:
        - Name: {name}
        - Born: {dob}
        - Intention: {intention}
        
        SCIENTIFIC FACTORS (Already Calculated):
        1. NUMEROLOGY: {num_str}
        2. ASTROLOGY: Major Transit: {transit_info}
        3. ENVIRONMENT: Moon: {lunar_phase}, Weather: {weather}

        **TASK:**
        1. Explain the User's Fortune based on the overlapping Numerology and Astrology data.
        2. Specifically, compare their Personal Day Number ({numero.get('personal_day_number') if numero else '?'}) with the Transit info.
        3. Create a unique "Luck Archetype" title for them today (e.g. "The Empire Builder", "The Mystic").
        4. Develop a "Strategy" to resolve any conflict between their Numbers (Internal) and Transits (External).
        5. Suggest 2-3 specific time blocks for action (e.g. "9AM-11AM: Focus").

        Output ONLY valid JSON:
        {{
            "score": <integer 0-100 (Suggestion based on explanation)>,
            "caption": "<short headline>",
            "summary": "<simple explanation of why numbers+stars matter today>",
            "explanation": "<detailed reading blending the Life Path and Transits>",
            "archetype": "<Today's Persona Title>",
            "strategy": "<Strategic advice paragraph for handling conflicting energies>",
            "schedule": ["<Time Block 1>", "<Time Block 2>"],
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
        
        if self.model:
            try:
                zodiac = user_data.get("zodiac", "your sign")
                prompt = f"""Generate 3 short, specific lucky actions for someone with {luck_score}/100 luck score as a {zodiac}.

Format as a simple list, each action 5-10 words maximum. Examples:
- Wear green for Venus energy
- Best time for calls: 2-4 PM
- Avoid major decisions before 6 PM

Lucky actions:"""
                
                response = self.model.generate_content(prompt)
                text = response.text
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
