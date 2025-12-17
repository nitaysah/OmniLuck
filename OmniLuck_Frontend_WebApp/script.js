import CelestialAPI from './api-client.js?v=5';
import { initUserSession } from './user-session.js';

document.addEventListener('DOMContentLoaded', () => {
    // Initialize API Client
    const api = new CelestialAPI();

    // Elements
    const nameInput = document.getElementById('name');
    const dobInput = document.getElementById('dob');
    const birthTimeInput = document.getElementById('birth-time');
    const tobInfoBtn = document.getElementById('tob-info-btn');
    const tobExplainer = document.getElementById('tob-explainer');
    const tobNaCheckbox = document.getElementById('tob-na-checkbox'); // New
    const timeInputsContainer = document.getElementById('time-inputs-container'); // New
    const tobNaMessage = document.getElementById('tob-na-message'); // New
    const revealBtn = document.getElementById('reveal-btn');

    // ... (rest of elements)

    // Toggle TOB Explainer
    if (tobInfoBtn) {
        tobInfoBtn.addEventListener('click', (e) => {
            e.preventDefault(); // Prevent label click trigger
            tobExplainer.style.display = tobExplainer.style.display === 'none' ? 'block' : 'none';
        });
    }
    const backBtn = document.getElementById('back-btn');
    const tryAgainBtn = document.getElementById('try-again-btn');
    const resultPercentage = document.getElementById('result-percentage');
    const fortuneText = document.getElementById('fortune-text');
    const traitsList = document.getElementById('traits-list');

    // New Elements
    const btnText = document.querySelector('.btn-text');
    const loadingSpinner = document.querySelector('.loading-spinner');


    // Populate Timezones (Removed)

    // Toggle "Don't Know" Logic
    if (tobNaCheckbox) {
        tobNaCheckbox.addEventListener('change', (e) => {
            const isChecked = e.target.checked;
            if (isChecked) {
                // Hide inputs, show N/A message
                timeInputsContainer.style.display = 'none';
                tobNaMessage.style.display = 'block';
                birthTimeInput.value = ''; // Clear time
            } else {
                // Show inputs, hide N/A message
                timeInputsContainer.style.display = 'block';
                tobNaMessage.style.display = 'none';
            }
        });
    }

    // Dashboard Elements (Removed)
    // const moonPhaseEl = document.getElementById('moon-phase');
    // const weatherTempEl = document.getElementById('weather-temp');
    // const geoActivityEl = document.getElementById('geo-activity');

    // State
    const inputView = document.getElementById('input-view');
    const resultView = document.getElementById('result-view');
    const dashboardView = document.getElementById('dashboard-view');

    // Dashboard Elements
    const dashboardUserName = document.getElementById('dashboard-user-name');
    const dashboardDob = document.getElementById('dashboard-dob-display');
    const dashboardPlace = document.getElementById('dashboard-birthplace-display');
    const dashboardZodiacIcon = document.getElementById('dashboard-zodiac-icon');
    const dashboardRevealBtn = document.getElementById('dashboard-reveal-btn');
    const dashboardLogoutBtn = document.getElementById('dashboard-logout-main-btn');
    const menuLogoutBtn = document.getElementById('menu-logout-btn');

    // Toggle User Menu
    const userMenuBtn = document.getElementById('user-menu-btn');
    const userDropdown = document.getElementById('user-dropdown');
    if (userMenuBtn) {
        userMenuBtn.addEventListener('click', () => {
            userDropdown.classList.toggle('active');
        });
    }

    // State
    let name = '';
    let dob = '';

    // Check for "Logged In" user via Session Manager
    const user = initUserSession();

    if (user) {
        // === LOGGED IN FLOW ===
        // Show Dashboard, Hide Input Form
        if (dashboardView) {
            dashboardView.classList.add('active');
            inputView.classList.remove('active');
        }

        // Show User Menu
        const userMenuContainer = document.getElementById('user-menu-container');
        if (userMenuContainer) userMenuContainer.style.display = 'block';

        // Populate User Info
        // Populate User Info
        const dName = document.getElementById('dashboard-name-display');
        const dPlace = document.getElementById('dashboard-place-display');
        const dTime = document.getElementById('dashboard-time-display');

        if (user.name) {
            nameInput.value = user.name;
            name = user.name;
            // Update Dashboard & Menu
            document.getElementById('user-greeting').textContent = `Hi, ${user.name.split(' ')[0]}`;
            if (dashboardUserName) dashboardUserName.textContent = user.name.split(' ')[0];
            if (dName) dName.textContent = user.name;
        }

        if (user.dob) {
            dobInput.value = user.dob;
            dob = user.dob;

            // Format DOB for Dashboard
            if (dashboardDob) {
                // manual parse to avoid timezone shift from new Date("YYYY-MM-DD")
                const [y, m, d] = user.dob.split('-').map(Number);
                const dateObj = new Date(y, m - 1, d);
                dashboardDob.textContent = dateObj.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });

                // Zodiac Icon
                const z = getZodiacSign(d, m);
                if (dashboardZodiacIcon) dashboardZodiacIcon.textContent = z.icon;
                const dashboardZodiacName = document.getElementById('dashboard-zodiac-name');
                if (dashboardZodiacName) dashboardZodiacName.textContent = z.name;
            }
        }

        // Auto-fill Place and Time from Firebase/Local DB
        const birthPlaceEl = document.getElementById('birth-place');
        if (user.birth_place) {
            if (birthPlaceEl) birthPlaceEl.value = user.birth_place;
            if (dPlace) dPlace.textContent = user.birth_place;
        }
        if (user.birth_time) {
            if (birthTimeInput) birthTimeInput.value = user.birth_time;
            if (dTime) {
                // Format 14:30 -> 2:30 PM
                try {
                    const [h, m] = user.birth_time.split(':');
                    const d = new Date(); d.setHours(h); d.setMinutes(m);
                    dTime.textContent = d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
                } catch (e) { dTime.textContent = user.birth_time; }
            }
        } else {
            if (dTime) dTime.textContent = "Unknown (12:00 PM)";
        }
    } else {
        // === GUEST FLOW ===
        // Ensure Input View is Active (Default)
        if (dashboardView) dashboardView.classList.remove('active');
        inputView.classList.add('active');

        // Update Logout Button to Home Button for Guests
        const logoutMainBtn = document.getElementById('logout-main-btn');
        if (logoutMainBtn) {
            logoutMainBtn.innerHTML = '<span>🏠</span> Back to Home';
        }
    }

    // Connect Dashboard "Forecast" button to Main "Reveal" button
    if (dashboardRevealBtn) {
        dashboardRevealBtn.addEventListener('click', () => {
            // Trigger the main logic
            if (revealBtn) revealBtn.click();
        });
    }

    // Connect Menu Items
    const menuAboutBtn = document.getElementById('menu-about-btn');
    const menuContactBtn = document.getElementById('menu-contact-btn');
    const menuSettingsBtn = document.getElementById('menu-settings-btn');

    // Navigate to respective pages
    if (menuAboutBtn) menuAboutBtn.addEventListener('click', () => window.location.href = 'about.html');
    if (menuContactBtn) menuContactBtn.addEventListener('click', () => window.location.href = 'contact.html');
    if (menuSettingsBtn) menuSettingsBtn.addEventListener('click', () => window.location.href = 'settings.html');

    // Connect Logouts
    function handleLogout() {
        localStorage.removeItem('currentUser');
        window.location.href = 'index.html';
    }

    if (dashboardLogoutBtn) dashboardLogoutBtn.addEventListener('click', handleLogout);
    if (menuLogoutBtn) menuLogoutBtn.addEventListener('click', handleLogout);

    // Ensure the main entry logout button (visible to guests) also works
    const logoutMainBtn = document.getElementById('logout-main-btn');
    if (logoutMainBtn) logoutMainBtn.addEventListener('click', handleLogout);

    // Set default date to 25 years ago ONLY if empty
    if (!dobInput.value) {
        const defaultDate = new Date();
        defaultDate.setFullYear(defaultDate.getFullYear() - 25);
        dobInput.valueAsDate = defaultDate;
    }

    // Initial check to enable button/update zodiac
    checkInputs();

    // Add SVG gradient definition for the progress ring
    const svg = document.querySelector('.progress-ring');
    if (svg) {
        const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
        defs.innerHTML = `
            <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" style="stop-color:rgba(255, 230, 128, 1);stop-opacity:1" />
                <stop offset="100%" style="stop-color:rgba(191, 153, 242, 1);stop-opacity:1" />
            </linearGradient>
        `;
        svg.insertBefore(defs, svg.firstChild);
    }

    // Helper: Local Zodiac Logic (Keep for instant UI feedback)
    function getZodiacSign(day, month) {
        switch (month) {
            case 1: return (day >= 20) ? { name: "Aquarius", icon: "♒️" } : { name: "Capricorn", icon: "♑️" };
            case 2: return (day >= 19) ? { name: "Pisces", icon: "♓️" } : { name: "Aquarius", icon: "♒️" };
            case 3: return (day >= 21) ? { name: "Aries", icon: "♈️" } : { name: "Pisces", icon: "♓️" };
            case 4: return (day >= 20) ? { name: "Taurus", icon: "♉️" } : { name: "Aries", icon: "♈️" };
            case 5: return (day >= 21) ? { name: "Gemini", icon: "♊️" } : { name: "Taurus", icon: "♉️" };
            case 6: return (day >= 22) ? { name: "Cancer", icon: "♋️" } : { name: "Gemini", icon: "♊️" };
            case 7: return (day >= 23) ? { name: "Leo", icon: "♌️" } : { name: "Cancer", icon: "♋️" };
            case 8: return (day >= 23) ? { name: "Virgo", icon: "♍️" } : { name: "Leo", icon: "♌️" };
            case 9: return (day >= 23) ? { name: "Libra", icon: "♎️" } : { name: "Virgo", icon: "♍️" };
            case 10: return (day >= 24) ? { name: "Scorpio", icon: "♏️" } : { name: "Libra", icon: "♎️" };
            case 11: return (day >= 23) ? { name: "Sagittarius", icon: "♐️" } : { name: "Scorpio", icon: "♏️" };
            case 12: return (day >= 22) ? { name: "Capricorn", icon: "♑️" } : { name: "Sagittarius", icon: "♐️" };
            default: return { name: "Unknown", icon: "❓" };
        }
    }

    // Update zodiac display
    // Display Zodiac (Moved to Result View)
    function displayZodiacResult() {
        if (!dob) return;

        const [y, m, d] = dob.split('-').map(Number);
        const zodiac = getZodiacSign(d, m);

        const zodiacNameEl = document.getElementById('zodiac-name-result');
        const zodiacIconEl = document.getElementById('zodiac-icon-result');

        if (zodiacNameEl && zodiacIconEl) {
            zodiacNameEl.textContent = zodiac.name;
            zodiacIconEl.textContent = zodiac.icon;
        }
    }

    // Animate percentage counter
    function animatePercentage(target) {
        let current = 0;
        const duration = 1500;
        const steps = 60;
        const stepTime = duration / steps;

        const progressRing = document.querySelector('.progress-ring-fill');
        const circumference = 2 * Math.PI * 90; // radius is 90

        // Update progress ring color based on percentage
        let ringColor;
        if (target >= 70) {
            ringColor = '#4CAF50'; // Green
        } else if (target >= 40) {
            ringColor = 'rgba(255, 230, 128, 1)'; // Gold
        } else {
            ringColor = '#FF9800'; // Orange
        }
        progressRing.style.stroke = ringColor;

        const offset = circumference - (target / 100) * circumference;

        // Reset progress ring
        // progressRing.style.strokeDashoffset = circumference; // Don't reset fully if animating nicely

        let step = 0;
        function update() {
            step++;
            const progress = step / steps;
            current = Math.floor(target * progress);
            resultPercentage.textContent = current;

            if (step < steps) {
                setTimeout(update, stepTime);
            } else {
                resultPercentage.textContent = target;
            }
        }

        setTimeout(() => {
            progressRing.style.strokeDashoffset = offset;
            update();
        }, 100);
    }



    // Update Actions List


    // Event listeners
    function checkInputs() {
        name = nameInput.value.trim();
        dob = dobInput.value;
        // Zodiac not shown on input anymore
    }

    nameInput.addEventListener('input', checkInputs);
    dobInput.addEventListener('input', checkInputs);
    dobInput.addEventListener('change', checkInputs);

    // Geocoding Helper
    async function geocodeCity(city) {
        if (!city) return null;
        try {
            // Using OpenStreetMap Nominatim API (Free, no key required)
            const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(city)}`;
            const response = await fetch(url);
            const data = await response.json();
            if (data && data.length > 0) {
                return {
                    lat: parseFloat(data[0].lat),
                    lon: parseFloat(data[0].lon),
                    name: data[0].display_name
                };
            }
        } catch (e) {
            console.error("Geocoding failed", e);
        }
        return null;
    }

    // ==========================================
    // REVEAL BUTTON - CONNECTED TO BACKEND API
    // ==========================================
    revealBtn.addEventListener('click', async () => {
        const birthPlaceVal = document.getElementById('birth-place').value.trim();

        if (!name || !dob || !birthPlaceVal) {
            alert("Please enter your Name, Date of Birth, and Place of Birth to reveal your fortune!");
            return;
        }

        // UI Loading State
        revealBtn.disabled = true;
        btnText.style.display = 'none';
        loadingSpinner.style.display = 'inline-block';

        try {
            // 1. Geocode Birth Place (if provided)
            const birthPlaceInput = document.getElementById('birth-place');
            const birthPlaceVal = birthPlaceInput ? birthPlaceInput.value.trim() : null;
            let birthLocation = null;

            if (birthPlaceVal) {
                birthLocation = await geocodeCity(birthPlaceVal);
                if (!birthLocation) {
                    alert("Could not find location '" + birthPlaceVal + "'. Please validate the city and country name (e.g. Dallas, USA).");
                    revealBtn.disabled = false;
                    btnText.style.display = 'inline-block';
                    loadingSpinner.style.display = 'none';
                    return;
                }
            }

            // 2. Determine "Current" Location for Weather
            let currentLat = birthLocation ? birthLocation.lat : 28.6139;
            let currentLon = birthLocation ? birthLocation.lon : 77.2090;

            // Update request
            const requestData = {
                uid: localStorage.getItem('currentUser') ? JSON.parse(localStorage.getItem('currentUser')).uid : "guest",
                name: name,
                dob: dob,
                birth_time: (tobNaCheckbox && tobNaCheckbox.checked) ? "" : (birthTimeInput ? birthTimeInput.value : ""),
                birth_place_name: birthPlaceVal || null,
                birth_lat: birthLocation ? birthLocation.lat : null,
                birth_lon: birthLocation ? birthLocation.lon : null,
                current_lat: currentLat,
                current_lon: currentLon,
            };

            console.log("Sending Request:", requestData);

            // Fetch Luck and Forecast in parallel
            const [response, forecastResponse] = await Promise.all([
                api.calculateLuck(requestData),
                api.getForecast(requestData).catch(e => null) // Fail silently for forecast
            ]);

            // Process Luck Response
            const percentage = response.luck_score || 0;
            const explanation = response.explanation || "The stars are silent today...";

            // Display Zodiac
            displayZodiacResult();

            // Caption
            let caption = response.caption;
            const summary = response.summary;
            if (!caption) {
                if (percentage >= 80) caption = "🚀 Cosmic Jackpot!";
                else if (percentage >= 60) caption = "✨ Strong Vibes";
                else if (percentage >= 40) caption = "⚖️ Balanced Energy";
                else caption = "🛡️ Stay Grounded";
            }

            // Update UI Elements
            document.getElementById('result-caption').textContent = caption;
            fortuneText.innerHTML = explanation.replace(/\n/g, '<br>');

            // Summary
            if (summary) {
                document.getElementById('factors-text').textContent = summary;
                document.getElementById('factors-box').style.display = 'block';
            } else {
                document.getElementById('factors-box').style.display = 'none';
            }

            // Render Traits (Visual Flair)
            renderTraits(percentage);

            // Render Strategy Card
            renderStrategy(response.strategic_advice, response.lucky_time_slots);

            // Render Forecast Card
            if (forecastResponse && forecastResponse.trajectory) {
                renderForecast(forecastResponse);
            } else {
                document.getElementById('forecast-flip-card').style.display = 'none';
            }

            // Switch Views
            inputView.classList.remove('active');
            if (dashboardView) dashboardView.classList.remove('active');
            resultView.classList.add('active');

            // Hide User Menu on Result Page (Focus on Result)
            const userMenuContainer = document.getElementById('user-menu-container');
            if (userMenuContainer) userMenuContainer.style.display = 'none';

            // Animate
            setTimeout(() => {
                animatePercentage(percentage);
            }, 300);

        } catch (error) {
            console.error("API Error:", error);
            alert("The stars are cloudy right now (Connection Error). Please try again.");
        } finally {
            // Reset Button State
            revealBtn.disabled = false;
            btnText.style.display = 'inline-block';
            loadingSpinner.style.display = 'none';
        }
    });

    // --- Helper Functions ---

    function renderTraits(score) {
        // Simple logic to generate trait pills based on score if backend doesn't provide them
        const traitsList = document.getElementById('traits-list');
        traitsList.innerHTML = '';

        let tags = [];
        if (score >= 90) tags = ["Cosmic", "Unstoppable", "Lucky"];
        else if (score >= 75) tags = ["Bold", "Positive", "Radiant"];
        else if (score >= 50) tags = ["Steady", "Balanced", "Calm"];
        else tags = ["Grounded", "Caution", "Introspective"];

        tags.forEach(tag => {
            const span = document.createElement('span');
            span.className = 'trait-pill'; // Defined in style.css hopefully, or use inline
            span.style.cssText = "display: inline-block; background: rgba(124, 77, 255, 0.15); color: var(--deep-purple); padding: 6px 14px; border-radius: 20px; font-size: 0.75rem; font-weight: 600; border: 1px solid rgba(124, 77, 255, 0.3);";
            span.textContent = tag;
            traitsList.appendChild(span);
        });
    }

    function renderStrategy(strategy, slots) {
        const card = document.getElementById('strategy-card');
        if (!strategy) {
            card.style.display = 'none';
            return;
        }

        card.style.display = 'block';
        document.getElementById('strategy-text').textContent = strategy;

        const slotsList = document.getElementById('time-slots-list');
        slotsList.innerHTML = '';

        if (slots && slots.length > 0) {
            slots.forEach(slot => {
                const div = document.createElement('div');
                div.style.cssText = "background: white; border: 1px solid var(--accent-gold); color: var(--deep-purple); font-size: 0.75rem; font-weight: 700; padding: 6px 10px; border-radius: 8px;";
                div.textContent = slot;
                slotsList.appendChild(div);
            });
        }
    }

    function renderForecast(data) {
        const card = document.getElementById('forecast-flip-card');
        card.style.display = 'block';

        // Listeners for Flip
        const inner = document.getElementById('forecast-flip-inner');
        card.onclick = (e) => {
            // Prevent drag/select issues
            e.preventDefault();
            card.classList.toggle('flipped');
        };

        // Populate Top Stats
        // Find best day
        let best = data.trajectory[0];
        data.trajectory.forEach(d => { if (d.luck_score > best.luck_score) best = d; });

        document.getElementById('forecast-trend').textContent = data.trend_direction;

        // Format date: YYYY-MM-DD -> MMM DD
        const formatDate = (ds) => {
            const d = new Date(ds);
            return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', timeZone: 'UTC' }); // Force UTC to avoid shift
        };

        document.getElementById('forecast-best').textContent = `${formatDate(best.date)} (${best.luck_score}%)`;

        // Render Bar Chart
        const list = document.getElementById('forecast-list');
        list.innerHTML = '';

        data.trajectory.forEach(day => {
            // Day Name
            const dateObj = new Date(day.date);
            const dayName = dateObj.toLocaleDateString('en-US', { weekday: 'short', timeZone: 'UTC' });

            const container = document.createElement('div');
            container.style.cssText = "display: flex; flex-direction: column; align-items: center; flex: 1; min-width: 0;";

            const scoreLabel = document.createElement('span');
            scoreLabel.textContent = day.luck_score;
            scoreLabel.style.cssText = "font-size: 9px; font-weight: bold; color: var(--deep-purple); margin-bottom: 2px;";

            const barHeight = Math.max(10, day.luck_score * 0.7); // scale
            const bar = document.createElement('div');
            // Gradient based on score
            let colorStart = day.luck_score >= 80 ? '#4CAF50' : (day.luck_score < 50 ? '#FF9800' : '#FFD700');

            bar.style.cssText = `width: 100%; height: ${barHeight}px; background: linear-gradient(to bottom, ${colorStart}, rgba(255,255,255,0.5)); border-radius: 4px 4px 0 0; opacity: 0.8;`;

            const dateLabel = document.createElement('span');
            dateLabel.textContent = dayName;
            dateLabel.style.cssText = "font-size: 9px; color: var(--deep-purple); margin-top: 4px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;";

            container.appendChild(scoreLabel);
            container.appendChild(bar);
            container.appendChild(dateLabel);
            list.appendChild(container);
        });
    }

    function goBack() {
        resultView.classList.remove('active');

        const currentUser = localStorage.getItem('currentUser');
        if (currentUser && dashboardView) {
            dashboardView.classList.add('active');
            // Show Menu again if logged in
            const userMenuContainer = document.getElementById('user-menu-container');
            if (userMenuContainer) userMenuContainer.style.display = 'block';
        } else {
            inputView.classList.add('active');
            // Hide Menu if guest (should be handled by initUserSession but safe to ensure)
            const userMenuContainer = document.getElementById('user-menu-container');
            if (userMenuContainer) userMenuContainer.style.display = 'none';
        }

        const progressRing = document.querySelector('.progress-ring-fill');
        if (progressRing) {
            progressRing.style.strokeDashoffset = 565.48; // Circumference
        }
        resultPercentage.textContent = '0';
    }

    if (backBtn) backBtn.addEventListener('click', goBack);
    tryAgainBtn.addEventListener('click', goBack);

    // Guest Home Button Logic
    const guestHomeBtn = document.getElementById('guest-home-btn');
    if (guestHomeBtn) {
        guestHomeBtn.addEventListener('click', () => {
            window.location.href = 'index.html';
        });
    }
});

// Helper for human-readable planet keywords
function getPlanetKeyword(planet) {
    const keywords = {
        'Sun': 'vitality & ego',
        'Moon': 'emotional & intuitive',
        'Mars': 'drive & action',
        'Mercury': 'communication',
        'Jupiter': 'growth & luck',
        'Venus': 'love & creative',
        'Saturn': 'discipline',
        'Rahu': 'obsessive',
        'Ketu': 'spiritual'
    };
    return keywords[planet] || 'cosmic';
}
