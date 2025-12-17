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
        if (user.name) {
            nameInput.value = user.name;
            name = user.name;
            // Update Dashboard & Menu
            document.getElementById('user-greeting').textContent = `Hi, ${user.name.split(' ')[0]}`;
            if (dashboardUserName) dashboardUserName.textContent = user.name.split(' ')[0];
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
            }
        }

        // Auto-fill Place and Time from Firebase/Local DB
        const birthPlaceEl = document.getElementById('birth-place');
        if (user.birth_place && birthPlaceEl) {
            birthPlaceEl.value = user.birth_place;
            if (dashboardPlace) dashboardPlace.textContent = user.birth_place;
        }
        if (user.birth_time && birthTimeInput) {
            birthTimeInput.value = user.birth_time;
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
            // Logic: Use birth location as proxy if no current location is available (common for simple apps)
            // Ideally: We would ask for navigator.geolocation here
            let currentLat = birthLocation ? birthLocation.lat : 28.6139; // Default to New Delhi if unknown
            let currentLon = birthLocation ? birthLocation.lon : 77.2090;

            // Capture Personal Context



            // Update request with "current" location so backend uses it for signals too
            const requestData = {
                uid: localStorage.getItem('currentUser') ? JSON.parse(localStorage.getItem('currentUser')).uid : "guest",
                name: name,
                dob: dob,
                birth_time: (tobNaCheckbox && tobNaCheckbox.checked) ? "12:00" : (birthTimeInput ? birthTimeInput.value : ""),
                // Add Birth Location Data
                birth_place_name: birthPlaceVal || null,
                birth_lat: birthLocation ? birthLocation.lat : null,
                birth_lon: birthLocation ? birthLocation.lon : null,
                // Pass current location to backend
                current_lat: currentLat,
                current_lon: currentLon,
                // Personalization


            };

            console.log("Sending Request:", requestData); // Debug log

            const response = await api.calculateLuck(requestData);

            // 3. Fetch Cosmic Signals (Removed from UI)
            // const cosmicPromise = api.getAllSignals(currentLat, currentLon);

            // Process Luck Response
            const percentage = response.luck_score || 0;
            const explanation = response.explanation || "The stars are silent today...";
            const actions = response.recommended_actions || [];

            // Display Zodiac on Result
            displayZodiacResult();

            // New Fields
            let caption = response.caption;
            const summary = response.summary;

            // Fallback Caption Logic if backend didn't return one
            if (!caption) {
                if (percentage >= 80) caption = "🚀 Cosmic Jackpot!";
                else if (percentage >= 60) caption = "✨ Strong Vibes";
                else if (percentage >= 40) caption = "⚖️ Balanced Energy";
                else caption = "🛡️ Stay Grounded";
            }

            // Update UI Elements
            document.getElementById('result-caption').textContent = caption;

            fortuneText.innerHTML = explanation.replace(/\n/g, '<br>');

            if (summary) {
                document.getElementById('factors-text').textContent = summary;
                document.getElementById('factors-box').style.display = 'block';
            } else {
                document.getElementById('factors-box').style.display = 'none';
            }

            // Update Traits
            traitsList.innerHTML = '';
            // Zodiac Logic - EXACT match from OmniLuckLogic.swift or use defaults if not in API response yet
            // Note: Current API endpoint returns 'explanation' string.
            // We can parse traits or use a random selection for now if API doesn't return list
            // For MVP, if API strictly returns text, we can hide traits or generate local ones.
            // Let's generate simple local traits based on percentage for visual flare
            // Basic traits mapping just for visual (since API doesn't return distinct list yet)
            // In future, update backend to return "traits": ["Bold", "Lucky"]


            // Update Actions
            // actions logic removed

            // Switch Views
            inputView.classList.remove('active');
            if (dashboardView) dashboardView.classList.remove('active'); // Hide dashboard if active
            resultView.classList.add('active');

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

    function goBack() {
        resultView.classList.remove('active');

        // Determine where to go back to
        const currentUser = localStorage.getItem('currentUser');
        if (currentUser && dashboardView) {
            dashboardView.classList.add('active');
        } else {
            inputView.classList.add('active');
        }

        // Reset progress ring
        const progressRing = document.querySelector('.progress-ring-fill');
        if (progressRing) {
            progressRing.style.strokeDashoffset = 565.48; // Circumference
        }
        resultPercentage.textContent = '0';
    }

    backBtn.addEventListener('click', goBack);
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
