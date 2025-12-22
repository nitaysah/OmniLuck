## 🧠 Core Optimization Algorithms (The Jackpot Engine)

The algorithm has been upgraded from simple numerology to a **Statistical-Cosmic Fusion** engine. Every number generated is passed through 6 intelligence layers:

### **1. Deterministic Identity Seeding (The Cosmic Key)**
- **Logic**: Uses a cryptographic MD5 hash of the user's **Full Name + DOB**.
- **Impact**: Ensures "Personal" numbers are unique to the user and stay permanent for life. Zero randomness.

### **2. Historical Frequency Weighting ("Hot & Cold" Nudging)**
- **Logic**: Maps numbers against a database of historical Powerball frequency.
- **Impact**: If a cosmic seed lands on a "Cold" number (rarely drawn), the engine nudges it toward a nearby "Hot" number while maintaining the user's vibrational link.

### **3. Harmonic Sum Balancing**
- **Logic**: Most jackpot winning sets (5 white balls) sum between **130 and 220**.
- **Impact**: The engine runs "Micro-Transits" and rejects any combination that is too light or too heavy, ensuring your set sits in the historical "win-zone."

### **4. Parity & Range Validation (The 2:3 Split)**
- **Logic**: Checks for **Odd/Even** and **High/Low** balance.
- **Impact**: Validates that every set has a healthy split (3:2 or 2:3). Sets that are all odd, all even, all high, or all low are filtered out.

### **5. Planetary Territory Mapping**
- **Logic**: Maps the **360° Zodiac Wheel** directly onto the **69 Powerball slots**.
- **Impact**: Uses daily `astro_score` (planetary transits like Jupiter or Venus) to "magnetize" number selection based on real-time cosmic positions.

### **6. Delta Strategy Integration (Daily Sets)**
- **Logic**: Focuses on the **mathematical spacing (gap)** between numbers rather than just the digits.
- **Impact**: Generates patterns that mirror the natural physical distribution of balls in the mixing machine, far outperforming standard random picks.

---

## ✅ COMPLETED (Backend & Data Models)


### Backend Service
- **File**: `OmniLuck_Backend_Python/app/services/powerball_service.py`
- **PowerballService** class created with:
  - `generate_personal_powerball()` - Static lucky numbers based on user'sname + DOB
  - `generate_daily_powerballs()` - 5 daily combinations by default (configurable 1-50) based on daily transits
  - Deterministic seeding using MD5 hashing for consistency
  - Numerology integration (name → number 1-9)
  - Birth date component extraction

### Data Models
- **File**: `OmniLuck_Backend_Python/app/models/schemas.py`
- Added `PowerballNumbers` model:
  - `white_balls`: List[int] - 5 white balls (1-69)
  - `powerball`: int - Red powerball (1-26)
  - `type`: str - 'personal' or 'daily'
  - `index`: Optional[int] - For daily combos (1-50)

- Updated `LuckCalculationResponse`:
  - `personal_powerball`: PowerballNumbers - User's static lucky numbers
  - `daily_powerballs`: List[PowerballNumbers] - 10 daily combinations

### API Integration
- **File**: `OmniLuck_Backend_Python/app/routes/luck.py`
- `/api/luck/calculate` endpoint now generates:
  1. Personal powerball (consistent for user)
  2. 5 daily powerballs (default) - changes each day based on transits, supports `powerball_count` param (1-50)
- Error handling for powerball generation
- Uses luck_score, astro_score, and natal_score as inputs

### iOS Data Models
- **File**: `OmniLuckiOSApp/NetworkService.swift`
- Added `PowerballNumbers` struct
- Updated `LuckResponse` to include powerball fields

---

## ✅ COMPLETED (Frontend UI - Web & iOS)

### Web App
1. **Modal UI**:
   - Personal Powerball section
   - Daily Powerball section with manual line control (1-50, default 5).
2. **Retailer Bridge (Digital Play Slip)**:
   - **QR Code Generation**: Native generation using `qrcode.min.js`.
   - **Scan Personal**: Button to generate QR for personal numbers.
   - **Scan Daily**: Button to generate bulk QR for all daily lines (e.g. 5 lines).
   - **Individual Row Scan**: Button on each daily line to scan that specific combination.
   - **Age Verification**: 18+ toggle required to unlock scanning features.
   - **Retailer Locator**: Mocked/Linked Google Maps search for nearby retailers.

### iOS App
1. **ResultView Integration**:
   - Added `showPowerballModal` state and button.
   - Modal matches Web design with native SwiftUI components.
2. **Retailer Bridge**:
   - **Native QR Generation**: Uses `CoreImage` CIFilter.
   - **Digital Play Slip Overlay**: Modal overlay showing the generated QR code, label, and deterministic seed.
   - **Features**: Scan Personal, Scan Daily (Bulk), and Age Verification toggle.
   - **Retalier Locator**: Link to Google Maps.
3. **Data Sync**: Updated `NetworkService` to request default 5 lines.

---

## 📊 Powerball Display Format

### Personal Lucky Numbers (Static)
```
🌟 YOUR PERSONAL LUCKY NUMBERS
[12] [24] [36] [48] [57] 🔴[15]
Based on your birth chart
```

### Daily Lucky Combinations (Default 5, Max 50)
```
📅 TODAY'S COSMIC COMBINATIONS
[Lines: 5] [Generate Request]

#1  [03] [21] [45] [52] [68] 🔴[09]  [📱 Scan]
#2  [07] [14] [33] [41] [65] 🔴[22]  [📱 Scan]
...
```

---

## 🎨 Styling Notes
- White balls: White circles with purple border
- Powerball: Red circle with white text
- Personal powerball: Larger, gold accent border
- Daily combos: Smaller, numbered list with individual scan buttons
- **QR Modal**: Clean overlay with high-contrast QR code and seed display

---

## 🔐 Security & Determinism
- Personal numbers: Always same for user (name + DOB seed)
- Daily numbers: Change each day (includes current date in seed)
- **Play Slip**: QR data structure mimics standard lottery format strings (mocked).
- **Age Gating**: UI-level 18+ verification check.

---

## Next Steps
- [x] Backend logic
- [x] Web App UI
- [x] iOS App UI
- [x] Retailer Bridge / QR Codes
- [ ] User Testing

