import asyncio
import sys
import os

# Add backend to path correctly
sys.path.append(os.getcwd())

from app.services.astrology_service import astrology_service
from app.models.schemas import BirthInfo
from app.services.llm_service import llm_service

async def test_calculation():
    print("--- Testing Astrology Service ---")
    try:
        birth_info = BirthInfo(
            dob="1987-11-14",
            time="12:00",
            lat=26.59,
            lon=85.49,
            timezone="Asia/Kolkata"
        )
        chart = astrology_service.calculate_natal_chart(birth_info)
        print(f"✅ Natal Chart Calculated: Sun in {chart.sun_sign}, Moon in {chart.moon_sign}")
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
        res = llm_service.analyze_luck_and_generate_content(user_data)
        print(f"✅ LLM Result: Score {res.get('score')}")
        print(f"Explanation: {res.get('explanation')}")
        print(f"Actions: {res.get('actions')}")

    except Exception as e:
        print(f"❌ LLM Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_calculation())
