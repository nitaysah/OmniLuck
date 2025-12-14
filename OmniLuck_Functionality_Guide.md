# OmniLuck Architecture & Functionality Guide

This document provides a comprehensive overview of the **OmniLuck** application functionality, architecture, and code structure for both the iOS and Web platforms.

---

## 1. High-Level Overview

**OmniLuck** is a cross-platform application (iOS & Web) designed to predict a user's daily luck and provide astrological insights. It leverages a shared Python backend to perform complex calculations based on **Astrology** (Natal Charts), **Numerology**, and **AI-driven predictions**.

### Core Workflow
1.  **Identity:** User authenticates (Login/Signup) to retrieve their stored profile.
2.  **Input:** User provides or confirms Birth Details (Date, Time, Location).
3.  **Processing:** Data is sent to the central Python backend via API.
4.  **Output:** The backend returns a calculated "Luck Score" (0-100), detailed insights, and a 7-day forecast.

---

## 2. Architecture Diagram

```mermaid
graph TD
    User([User]) -->|Interacts| iOS[iOS App (Swift)]
    User -->|Interacts| Web[Web App (HTML/JS)]
    
    subgraph Frontend Logic
        iOS -->|NetworkService.swift| API
        Web -->|api-client.js| API
        iOS -->|OmniLuckLogic.swift| Offline[Offline Fallback Logic]
    end
    
    subgraph Backend Services
        API[Python Backend (FastAPI)] -->|Calculates| Astro[Astrology Engine]
        API -->|Calculates| Numerology[Numerology Engine]
        API -->|Stores/Reads| DB[(Database / Firestore)]
    end
    
    API -->|Returns JSON| Frontend_Logic
```

---

## 3. detailed Functionality Breakdown

### Step 1: Authentication (Entry)
The entry point serves to verify identity or streamline the process for returning users.

*   **iOS (`LoginView.swift`, `SignupView.swift`, `UserSession.swift`)**
    *   **Logic:** Checks `UserSession` state on launch. If logged out, presents `LoginView`.
    *   **Action:** `NetworkService` sends credentials to `/api/auth/login` or `/api/auth/signup`.
    *   **Storage:** Session token and user profile are stored in memory (`UserSession` observable object).

*   **Web (`index.html`, `signup.html`)**
    *   **Logic:** Uses **Firebase Authentication** SDK directly in the browser.
    *   **Action:** 
        *   **Signup:** Captures inputs, geocodes the birth city via OpenStreetMap API (client-side), and saves a document to **Firestore**.
        *   **Login:** Authenticates via Firebase Auth, fetches the user doc from Firestore, and caches it in `localStorage` for the main app.

### Step 2: Input & Personalization
Users configure the data used for the prediction.

*   **iOS (`ContentView.swift`)**
    *   **Pre-fill:** Auto-populates fields from the `UserSession` profile.
    *   **UX Features:** 
        *   **Manual Date Toggle:** Switch between a Wheel Picker and Text Input for speed.
        *   **"Time Unknown":** A checkbox to explicitly handle missing birth prices (disables specific astrological charts).
    *   **Design:** Background uses `GalaxyView.swift` for a consistent, animated cosmic theme.

*   **Web (`app.html` (Input View), `script.js`)**
    *   **Pre-fill:** detailed form auto-fills from `localStorage` object.
    *   **Geocoding:** When "Forecast" is clicked, `script.js` calls the OpenStreetMap API to convert the text "City, Country" into `lat, lon` coordinates required by the backend.

### Step 3: Calculation (The "Magic")
The core request that generates the user's fortune.

*   **API Endpoint:** `POST /api/luck/calculate`
*   **Request Payload:**
    *   `name`: User's name
    *   `dob`: Date of Birth (`YYYY-MM-DD`)
    *   `birth_time`: Birth Time (`HH:MM`) (Optional)
    *   `birth_lat/lon`: Geographic coordinates of birth.
    *   `current_lat/lon`: Geographic coordinates of current location.

*   **Offline Capability (iOS Only):** 
    *   If the network fails, `ContentView.swift` detects the error and calls `OmniLuckLogic.calculateLuckyPercentage`.
    *   This logic uses a hashing algorithm on the User's Name + Life Path Number + Current Date to deterministically generate a score locally.

### Step 4: Result & Visualization
Displaying the data returned from the backend.

*   **iOS (`ResultView.swift`)**
    *   **Visuals:** Animated circular progress ring. Colors shift based on score (Green > 70%, Gold > 40%, Orange < 40%).
    *   **Traits:** Renders specific keywords (e.g., "Bold", "creative") returned by the logic.
    *   **Forecast:** Asynchronously fetches `/api/luck/forecast` to display a bar chart for the next 7 days.

*   **Web (`app.html` (Result View), `script.js`)**
    *   **SPA Behavior:** JavaScript swaps the active CSS class from `#input-view` to `#result-view`.
    *   **Animation:** Custom JS function animates the percentage number counting up.
    *   **Elements:** Displays the "Luck Explanation", "Cosmic Jackpot" caption, and dynamically renders the Zodiac sign based on DOB.

### Step 5: Detailed Reports (Deep Dive)
Users can request a technical breakdown of the astrology behind the score.

*   **Action:** User clicks "Read my Daily Astro Report".
*   **API Endpoint:** `POST /api/astrology/natal-chart`
*   **Data Returned:** 
    *   **Ascendant (Rising Sign):** The mask the user wears for the world.
    *   **Planetary Positions:** (e.g., "Sun in Leo", "Moon in Pisces").
    *   **Chart Strength:** A calculated numerical strength (0-100).
*   **Display:** Both platforms render this data in a modal/sheet overlay, translating technical terms into simple sentences (e.g., "Sun in Leo brings vitality...").

---

## 4. Key Files Reference

| Component | iOS File (`Swift`) | Web File (`HTML/JS`) | Purpose |
| :--- | :--- | :--- | :--- |
| **App Entry** | `OmniLuckApp.swift` / `LoginView.swift` | `index.html` | App initialization and Login interface. |
| **Signup** | `SignupView.swift` | `signup.html` | User registration and profile creation. |
| **Main Dashboard** | `ContentView.swift` | `app.html` (Input View) | Main form for entering prediction details. |
| **Results** | `ResultView.swift` | `app.html` (Result View) | Visualization of Score, Explanation, and Charts. |
| **Networking** | `NetworkService.swift` | `api-client.js` | Handling all API HTTP requests. |
| **Logic/Utils** | `OmniLuckLogic.swift` | `script.js` | Helper functions (e.g., Zodiac calc, Offline Fallback). |
| **Animations** | `GalaxyView.swift` | `style.css` | Rendering the cosmic background and effects. |
