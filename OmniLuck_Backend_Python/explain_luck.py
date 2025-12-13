import asyncio
import sys
import os
from datetime import datetime

# Setup path to include 'backend' folder so 'app' module is found
sys.path.append(os.path.join(os.getcwd(), "backend"))

# Import services (using app.x since backend is in path)
from app.services.astrology_service import astrology_service
from app.services.signals_service import signals_service
from app.services.llm_service import llm_service
from app.models.schemas import BirthInfo

async def explain_luck_calculation():
    print("\n🔮 --- LUCK SCORE CALCULATION BREAKDOWN --- 🔮\n")
    
    # 1. User Data
    user_data = {
        "name": "Nitay Sah",
        "dob": "1987-11-14",
        "birth_place": "Sitamadhi, India",
        "birth_lat": 26.5937,
        "birth_lon": 85.4960,
        "time": "12:00"
    }
    print(f"👤 User: {user_data['name']}")
    print(f"📍 Born: {user_data['birth_place']} ({user_data['birth_lat']}, {user_data['birth_lon']})")
    print(f"📅 Date: {user_data['dob']}")
    
    print("\n--- STEP 1: COSMIC SIGNALS (Weight: 20%) ---")
    try:
        # Use birth location as current location proxy
        signals = await signals_service.get_all_signals(user_data['birth_lat'], user_data['birth_lon'])
        signals_score = signals.total_influence_score
        
        print(f"  • Moon Phase: {signals.lunar.phase_name} ({signals.lunar.influence_score}/100)")
        print(f"  • Weather: {signals.weather.condition} ({signals.weather.influence_score}/100)")
        print(f"  • Geomagnetic: Kp {signals.geomagnetic.kp_index} ({signals.geomagnetic.influence_score})")
        print(f"  👉 SIGNAL SCORE: {signals_score}/100")
        
    except Exception as e:
        print(f"⚠️ Signal Error: {e}")
        signals_score = 50

    print("\n--- STEP 2: ASTROLOGY TRANSITS (Weight: 40%) ---")
    try:
        birth_info = BirthInfo(
            dob=user_data['dob'],
            time=user_data['time'],
            lat=user_data['birth_lat'],
            lon=user_data['birth_lon'],
            timezone="UTC"
        )
        chart = astrology_service.calculate_natal_chart(birth_info)
        print(f"  • Sun Sign: {chart.sun_sign}")
        print(f"  • Moon Sign: {chart.moon_sign}")
        print(f"  • Rising Sign: {chart.ascendant}")
        
        transits = astrology_service.calculate_daily_transits(datetime.now(), chart)
        astro_score = transits.influence_score
        print(f"  • Active Aspects: {len(transits.aspects)}")
        print(f"  👉 ASTRO SCORE: {astro_score}/100")
        
        astro_context = {
            "sun_sign": chart.sun_sign,
            "moon_sign": chart.moon_sign,
            "ascendant": chart.ascendant
        }
    except Exception as e:
        print(f"⚠️ Astro Error: {e}")
        astro_score = 50
        astro_context = {}

    print("\n--- STEP 3: AI INTUITION (Weight: 40%) ---")
    try:
        # Context passed to AI
        llm_context = {
            "name": user_data['name'],
            "dob": user_data['dob'],
            "birth_place": user_data['birth_place']
        }
        
        result = llm_service.analyze_luck_and_generate_content(
            user_data=llm_context, 
            cosmic_signals=signals.dict(),
            astrology_data=astro_context
        )
        ai_score = result.get("score")
        print(f"  • AI Analysis: {result.get('explanation')[:100]}...")
        print(f"  👉 AI SCORE: {ai_score}/100")
        
    except Exception as e:
        print(f"⚠️ AI Error: {e}")
        ai_score = 65

    print("\n--- FINAL CALCULATION ---")
    weighted_signals = signals_score * 0.20
    weighted_astro = astro_score * 0.40
    weighted_ai = ai_score * 0.40
    
    total = int(weighted_signals + weighted_astro + weighted_ai)
    
    print(f"  Signals ({signals_score}) × 0.20 = {weighted_signals:.1f}")
    print(f"  Astro   ({astro_score}) × 0.40 = {weighted_astro:.1f}")
    print(f"  AI      ({ai_score}) × 0.40 = {weighted_ai:.1f}")
    print(f"  ------------------------------")
    print(f"  🏆 FINAL LUCK SCORE: {total}/100")
    print("\n==============================================\n")

if __name__ == "__main__":
    asyncio.run(explain_luck_calculation())
