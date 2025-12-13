import asyncio
import sys
import os

# Add backend to path correctly
sys.path.append(os.path.join(os.getcwd(), "backend"))

from backend.app.services.astrology_service import astrology_service
from backend.app.models.schemas import BirthInfo
from backend.app.services.llm_service import llm_service

async def test_calculation():
    print("--- Testing Astrology Service ---")
    try:
        birth_info = BirthInfo(
            dob="1987-11-14",
            time="12:00",
            lat=26.59,
            lon=85.49,
            timezone="UTC"
        )
        print("Calculating chart...")
        chart = astrology_service.calculate_natal_chart(birth_info)
        print(f"✅ Natal Chart Calculated: Sun in {chart.sun_sign}, Moon in {chart.moon_sign}")
        
        from datetime import datetime
        print("Calculating transits...")
        transits = astrology_service.calculate_daily_transits(datetime.now(), chart)
        print(f"✅ Daily Transits Calculated: Score {transits.influence_score}")
        print(f"   Aspects found: {len(transits.aspects)}")
    except Exception as e:
        print(f"❌ Astrology Error: {e}")
        import traceback
        traceback.print_exc()

    print("\n--- Testing LLM Service ---")
    try:
        user_data = {
            "name": "Nitay Sah",
            "dob": "1987-11-14",
            "birth_place": "Sitamadhi, India"
        }
        print("Calling LLM...")
        res = llm_service.analyze_luck_and_generate_content(user_data)
        print(f"✅ LLM Result: Score {res.get('score')}")
        print(f"Explanation: {res.get('explanation')}")
    except Exception as e:
        print(f"❌ LLM Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_calculation())
