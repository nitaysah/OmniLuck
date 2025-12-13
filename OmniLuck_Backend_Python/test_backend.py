"""
Quick test script to verify backend is working.
Run this after setting up the backend to test all features.
"""
import asyncio
import httpx
from datetime import date


BASE_URL = "http://localhost:8000"


async def test_health():
    """Test basic health check"""
    print("🏥 Testing Health Check...")
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/health")
        data = response.json()
        print(f"   ✓ Status: {data['status']}")
        print(f"   ✓ Services: {data['services']}")


async def test_zodiac():
    """Test zodiac sign endpoint"""
    print("\n♊ Testing Zodiac Sign...")
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/api/astrology/zodiac-sign?dob=1995-06-15")
        data = response.json()
        print(f"   ✓ Sign: {data['name']} {data['emoji']}")


async def test_lunar_phase():
    """Test lunar phase"""
    print("\n🌙 Testing Lunar Phase...")
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/api/signals/lunar-phase")
        data = response.json()
        print(f"   ✓ Phase: {data['phase_name']}")
        print(f"   ✓ Illumination: {data['illumination']}%")
        print(f"   ✓ Influence: {data['influence_score']}/100")


async def test_geomagnetic():
    """Test geomagnetic activity"""
    print("\n🌍 Testing Geomagnetic Activity...")
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/api/signals/geomagnetic")
        data = response.json()
        print(f"   ✓ Kp Index: {data['kp_index']}")
        print(f"   ✓ Level: {data['activity_level']}")
        print(f"   ✓ Influence: {data['influence_score']}")


async def test_weather():
    """Test weather (New York coordinates)"""
    print("\n☁️ Testing Weather...")
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/api/signals/weather?lat=40.7128&lon=-74.0060")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✓ Condition: {data['condition']}")
            print(f"   ✓ Temperature: {data['temp_c']}°C / {data['temp_f']}°F")
            print(f"   ✓ Humidity: {data['humidity']}%")
            print(f"   ✓ Influence: {data['influence_score']}/100")
        else:
            print(f"   ⚠️  Weather API returned {response.status_code}")
            print(f"   💡 Tip: Check your OPENWEATHER_API_KEY in .env")


async def test_all_signals():
    """Test combined signals endpoint"""
    print("\n✨ Testing All Cosmic Signals (Combined)...")
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/api/signals/all?lat=40.7128&lon=-74.0060")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✓ Lunar Phase: {data['lunar']['phase_name']}")
            print(f"   ✓ Weather: {data['weather']['condition']}")
            print(f"   ✓ Geomagnetic: {data['geomagnetic']['activity_level']}")
            print(f"   ✓ TOTAL INFLUENCE: {data['total_influence_score']}/100")
        else:
            print(f"   ⚠️  Combined signals returned {response.status_code}")


async def test_natal_chart():
    """Test natal chart calculation"""
    print("\n🪐 Testing Natal Chart Calculation...")
    async with httpx.AsyncClient(timeout=30.0) as client:
        payload = {
            "dob": "1995-06-15",
            "time": "14:30",
            "lat": 28.6139,
            "lon": 77.2090,
            "timezone": "Asia/Kolkata"
        }
        
        try:
            response = await client.post(f"{BASE_URL}/api/astrology/natal-chart", json=payload)
            
            if response.status_code == 200:
                data = response.json()
                print(f"   ✓ Sun Sign: {data['sun_sign']}")
                print(f"   ✓ Moon Sign: {data['moon_sign']}")
                print(f"   ✓ Ascendant: {data['ascendant']}")
                print(f"   ✓ Chart Strength: {data['strength_score']}/100")
                print(f"   ✓ Planets calculated: {len(data['planets'])}")
            else:
                print(f"   ⚠️  Natal chart returned {response.status_code}")
                print(f"   💡 Error: {response.text}")
        except Exception as e:
            print(f"   ❌ Error: {e}")
            print(f"   💡 Tip: Make sure Swiss Ephemeris data files are installed")


async def main():
    """Run all tests"""
    print("=" * 60)
    print("🌟 CELESTIAL FORTUNE BACKEND TEST SUITE")
    print("=" * 60)
    
    try:
        await test_health()
        await test_zodiac()
        await test_lunar_phase()
        await test_geomagnetic()
        await test_weather()
        await test_all_signals()
        await test_natal_chart()
        
        print("\n" + "=" * 60)
        print("✅ ALL TESTS COMPLETED!")
        print("=" * 60)
        print("\n💡 Next Steps:")
        print("   1. Check the API docs: http://localhost:8000/docs")
        print("   2. Integrate with frontend using api-client.js")
        print("   3. Add birth time/location to signup.html")
        print("\n")
        
    except httpx.ConnectError:
        print("\n❌ Connection Error!")
        print("💡 Make sure the backend is running:")
        print("   cd backend")
        print("   uvicorn app.main:app --reload --port 8000")
    except Exception as e:
        print(f"\n❌ Unexpected Error: {e}")


if __name__ == "__main__":
    asyncio.run(main())
