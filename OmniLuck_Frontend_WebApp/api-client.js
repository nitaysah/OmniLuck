/**
 * API client for OmniLuck frontend.
 * Use this in your webapp to communicate with the Python backend.
 */

class CelestialAPI {
    constructor(baseURL) {
        if (baseURL) {
            this.baseURL = baseURL;
        } else {
            // FORCE RENDER URL
            // TODO: REPLACE THIS WITH YOUR RENDER URL AFTER DEPLOYMENT
            const PROD_URL = "https://antigravity-ywlj.onrender.com";
            console.log("🚀 CelestialAPI: Using Production Backend:", PROD_URL);
            this.baseURL = PROD_URL;

            // Checking logic disabled to force Render usage
            // const customHost = window.location.hostname;
            // const isLocal = customHost === 'localhost' || customHost === '127.0.0.1' || window.location.protocol === 'file:';
            // this.baseURL = isLocal ? 'http://localhost:8000' : PROD_URL;
        }
    }

    // ============================================================================
    // ASTROLOGY ENDPOINTS
    // ============================================================================

    /**
     * Calculate natal chart (birth chart)
     * @param {Object} birthInfo - {dob, time, lat, lon, timezone}
     * @returns {Promise<Object>} Natal chart data
     */
    async calculateNatalChart(birthInfo) {
        const response = await fetch(`${this.baseURL}/api/astrology/natal-chart`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(birthInfo)
        });
        return response.json();
    }

    /**
     * Calculate daily transits
     * @param {Object} natalChart - User's natal chart
     * @param {string} date - Optional date (YYYY-MM-DD)
     * @returns {Promise<Object>} Transit data
     */
    async calculateDailyTransits(natalChart, date = null) {
        const url = new URL(`${this.baseURL}/api/astrology/daily-transits`);
        if (date) url.searchParams.append('date', date);

        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(natalChart)
        });
        return response.json();
    }

    /**
     * Get zodiac sign from date of birth (quick utility)
     * @param {string} dob - Date of birth (YYYY-MM-DD)
     * @returns {Promise<Object>} {name, emoji}
     */
    async getZodiacSign(dob) {
        const response = await fetch(`${this.baseURL}/api/astrology/zodiac-sign?dob=${dob}`);
        return response.json();
    }

    // ============================================================================
    // COSMIC SIGNALS ENDPOINTS
    // ============================================================================

    /**
     * Get lunar phase for a date
     * @param {string} date - Optional date (YYYY-MM-DD)
     * @returns {Promise<Object>} Lunar phase data
     */
    async getLunarPhase(date = null) {
        const url = new URL(`${this.baseURL}/api/signals/lunar-phase`);
        if (date) url.searchParams.append('date', date);

        const response = await fetch(url);
        return response.json();
    }

    /**
     * Get current weather
     * @param {number} lat - Latitude
     * @param {number} lon - Longitude
     * @returns {Promise<Object>} Weather data
     */
    async getWeather(lat, lon) {
        const response = await fetch(
            `${this.baseURL}/api/signals/weather?lat=${lat}&lon=${lon}`
        );
        return response.json();
    }

    /**
     * Get geomagnetic activity (Kp index)
     * @returns {Promise<Object>} Geomagnetic data
     */
    async getGeomagneticActivity() {
        const response = await fetch(`${this.baseURL}/api/signals/geomagnetic`);
        return response.json();
    }

    /**
     * Get ALL cosmic signals at once (recommended)
     * @param {number} lat - Latitude
     * @param {number} lon - Longitude
     * @param {string} date - Optional date
     * @returns {Promise<Object>} All signals (lunar, weather, geomagnetic)
     */
    async getAllSignals(lat, lon, date = null) {
        const url = new URL(`${this.baseURL}/api/signals/all`);
        url.searchParams.append('lat', lat);
        url.searchParams.append('lon', lon);
        if (date) url.searchParams.append('date', date);

        const response = await fetch(url);
        return response.json();
    }

    // ============================================================================
    // LUCK CALCULATION ENDPOINTS
    // ============================================================================

    /**
     * Calculate enhanced luck score
     * @param {Object} request - {uid, date?, location?}
     * @returns {Promise<Object>} Luck calculation with explanation
     */
    async calculateLuck(request) {
        const response = await fetch(`${this.baseURL}/api/luck/calculate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(request)
        });
        return response.json();
    }

    /**
     * Get user's luck history
     * @param {string} uid - User ID
     * @param {number} days - Number of days (default 30)
     * @returns {Promise<Object>} Historical luck scores
     */
    async getLuckHistory(uid, days = 30) {
        const response = await fetch(
            `${this.baseURL}/api/luck/history/${uid}?days=${days}`
        );
        return response.json();
    }

    // ============================================================================
    // ML / PERSONALIZATION ENDPOINTS
    // ============================================================================

    /**
     * Submit daily mood check-in
     * @param {Object} checkIn - {uid, date, mood_score, energy_level, mood_tags, journal_text}
     * @returns {Promise<Object>} Saved check-in with sentiment
     */
    async submitDailyCheckIn(checkIn) {
        const response = await fetch(`${this.baseURL}/api/ml/daily-checkin`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(checkIn)
        });
        return response.json();
    }

    /**
     * Get personal trend analysis
     * @param {string} uid - User ID
     * @returns {Promise<Object>} Trend data (averages, direction, best days)
     */
    async getPersonalTrend(uid) {
        const response = await fetch(`${this.baseURL}/api/ml/personal-trend/${uid}`);
        return response.json();
    }

    /**
     * Trigger ML model training
     * @param {string} uid - User ID
     * @returns {Promise<Object>} Training status
     */
    async trainPersonalModel(uid) {
        const response = await fetch(`${this.baseURL}/api/ml/train-model/${uid}`, {
            method: 'POST'
        });
        return response.json();
    }
}

// ============================================================================
// USAGE EXAMPLE
// ============================================================================

// Initialize API client
const api = new CelestialAPI('http://localhost:8000');

// Example: Get all cosmic signals for a location
async function checkCosmicWeather() {
    try {
        // Get user's location (browser geolocation API)
        navigator.geolocation.getCurrentPosition(async (position) => {
            const lat = position.coords.latitude;
            const lon = position.coords.longitude;

            const signals = await api.getAllSignals(lat, lon);

            console.log('🌙 Lunar Phase:', signals.lunar.phase_name);
            console.log('☁️ Weather:', signals.weather.condition, signals.weather.temp_c + '°C');
            console.log('🌍 Geomagnetic Activity:', signals.geomagnetic.activity_level);
            console.log('✨ Total Influence Score:', signals.total_influence_score);
        });
    } catch (error) {
        console.error('Error fetching cosmic signals:', error);
    }
}

// Example: Calculate natal chart
async function calculateMyBirthChart() {
    try {
        const chart = await api.calculateNatalChart({
            dob: "1995-06-15",
            time: "14:30",
            lat: 28.6139,
            lon: 77.2090,
            timezone: "Asia/Kolkata"
        });

        console.log('☀️ Sun Sign:', chart.sun_sign);
        console.log('🌙 Moon Sign:', chart.moon_sign);
        console.log('⬆️ Rising Sign:', chart.ascendant);
        console.log('💪 Chart Strength:', chart.strength_score);
        console.log('🪐 Planets:', chart.planets);
    } catch (error) {
        console.error('Error calculating natal chart:', error);
    }
}

// Example: Submit daily check-in
async function submitMyMood() {
    try {
        const checkIn = await api.submitDailyCheckIn({
            uid: "user123",
            date: "2025-12-11",
            mood_score: 8,
            energy_level: "high",
            mood_tags: ["excited", "focused"],
            journal_text: "Had a great day! Everything clicked into place."
        });

        console.log('📊 Check-in saved!');
        console.log('😊 Journal Sentiment:', checkIn.journal_sentiment);
    } catch (error) {
        console.error('Error submitting check-in:', error);
    }
}

// Export for use in webapp
export default CelestialAPI;
