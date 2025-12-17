
from app.services.powerball_service import powerball_service
from datetime import datetime

# User Data
name = "Nitay Kumar Sah"
dob = "1987-11-13"
current_date = datetime.now().strftime("%Y-%m-%d")

# Step 1: Numerology Calculation
def get_numerology(name):
    name = name.upper().replace(" ", "")
    total = sum(ord(char) - ord('A') + 1 for char in name if char.isalpha())
    while total > 9:
        total = sum(int(digit) for digit in str(total))
    return total

num_val = get_numerology(name)

# Step 2: Generate Personal Powerball
personal = powerball_service.generate_personal_powerball(name, dob)

# Step 3: Generate Daily Powerballs (Simulated scores)
# Note: In real app, these scores come from the live astro/natal engines
luck_score = 85 
astro_score = 78
natal_score = 92
daily = powerball_service.generate_daily_powerballs(name, dob, current_date, luck_score, astro_score, natal_score)

print(f"--- Powerball Logic Analysis for {name} ---")
print(f"1. Name Numerology Value: {num_val}")
print(f"2. Birth Date Components: Year=1987, Month=11, Day=13")
print(f"\n3. PERSONAL LUCKY NUMBERS (Static):")
print(f"   White Balls: {personal['white_balls']}")
print(f"   Powerball:   {personal['powerball']}")
print(f"\n4. TODAY'S TOP DAILY COMBINATION (#1):")
print(f"   White Balls: {daily[0]['white_balls']}")
print(f"   Powerball:   {daily[0]['powerball']}")
print("\n--- Logic Breakdown ---")
print("- Personal Seed: Hash(Name + DOB)")
print("- Daily Seed: Hash(Name + DOB + Date + LuckScore)")
print("- White Ball Range: 1-69")
print("- Powerball Range: 1-26")
