import CelestialAPI from './api-client.js?v=5';

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
    const actionsCard = document.getElementById('actions-card');
    const actionsList = document.getElementById('actions-list');

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

    const inputView = document.getElementById('input-view');
    const resultView = document.getElementById('result-view');

    // State
    let name = '';
    let dob = '';

    // Check for "Logged In" user from Get Started Page
    const storedUser = localStorage.getItem('currentUser');
    const logoutBtn = document.getElementById('logout-main-btn'); // Updated ID

    // Always wire up logout logic
    if (logoutBtn) {
        logoutBtn.addEventListener('click', () => {
            if (confirm('Are you sure you want to sign out?')) {
                localStorage.removeItem('currentUser');
                window.location.href = 'index.html';
            }
        });
    }

    if (storedUser) {
        try {
            const user = JSON.parse(storedUser);
            if (user.name) {
                // Auto-fill form
                nameInput.value = user.name;
                name = user.name;

                if (user.dob) {
                    dobInput.value = user.dob;
                    dob = user.dob;
                }

                // Auto-fill Place and Time from Firebase/Local DB
                const birthPlaceEl = document.getElementById('birth-place');
                if (user.birth_place && birthPlaceEl) {
                    birthPlaceEl.value = user.birth_place;
                }
                if (user.birth_time && birthTimeInput) {
                    birthTimeInput.value = user.birth_time;
                }

                // Show User Greeting / Logout Pill
                const userPillBtn = document.getElementById('user-pill-btn'); // Updated to button
                const userGreeting = document.getElementById('user-greeting');

                if (userPillBtn && userGreeting) {
                    userGreeting.textContent = `Hi, ${user.name.split(' ')[0]}`;
                    userPillBtn.style.display = 'flex';

                    // Attach Logout Listener
                    userPillBtn.addEventListener('click', () => {
                        if (confirm('Are you sure you want to sign out?')) {
                            localStorage.removeItem('currentUser');
                            window.location.href = 'index.html';
                        }
                    });
                }
            }
        } catch (e) {
            console.error("Error parsing user data", e);
        }
    }

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
    function updateActions(actions) {
        actionsList.innerHTML = ''; // Clear

        if (actions && actions.length > 0) {
            actions.forEach(action => {
                const li = document.createElement('li');
                li.className = 'action-item';
                li.textContent = action;
                actionsList.appendChild(li);
            });
            actionsCard.style.display = 'block';
        } else {
            actionsCard.style.display = 'none';
        }
    }

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
        if (!name || !dob) {
            alert("Please enter your Name and Date of Birth to reveal your fortune!");
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
                birth_time: (tobNaCheckbox && tobNaCheckbox.checked) ? "" : (birthTimeInput ? birthTimeInput.value : ""), // Send empty string if N/A or empty
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
            updateActions(actions);

            // Switch Views
            inputView.classList.remove('active');
            resultView.classList.add('active');

            // Animate
            setTimeout(() => {
                animatePercentage(percentage);
            }, 300);

            // === KUNDALI LOGIC START ===
            const kundaliBtn = document.getElementById('kundali-btn');
            const kundaliModal = document.getElementById('kundali-modal');
            const closeModal = document.querySelector('.close-modal');
            const kundaliContent = document.getElementById('kundali-report-content');

            // Store chart data for modal usage
            let chartData = null;

            // Fetch Natal Chart if birth time is present
            if (birthTimeInput && birthTimeInput.value) {
                // We will ask one more time to fill the modal content
                // In a real app we'd just use the response from calculateLuck if it had it
                // For now, let's fetch it specifically for the modal
                try {
                    const birthInfo = {
                        dob: dob,
                        time: birthTimeInput.value,
                        lat: birthLocation ? birthLocation.lat : 26.59,
                        lon: birthLocation ? birthLocation.lon : 85.48,
                        timezone: "UTC"
                    };
                    chartData = await api.calculateNatalChart(birthInfo);
                } catch (e) { console.log("Chart fetch error", e); }
            }

            // Modal Events
            if (kundaliBtn) {
                // Show button only if birth time was given
                kundaliBtn.style.display = (birthTimeInput && birthTimeInput.value) ? 'flex' : 'none';

                kundaliBtn.onclick = () => {
                    kundaliModal.classList.add('active'); // Use class for flex display
                    kundaliModal.style.display = 'flex';

                    if (chartData) {
                        // Generate Simple Human Report
                        let reportHtml = `
                            <div style="text-align: left; line-height: 1.6; color: var(--deep-purple);">
                                <p style="margin-bottom: 12px;"><strong>Your Rising Sign (Ascendant): </strong> ${chartData.ascendant}</p>
                                <p style="margin-bottom: 12px; font-size: 0.95em;">
                                    This sign represents your outer personality and how you interact with the world today.
                                </p>
                                
                                <h4 style="margin-top:20px; margin-bottom:10px; border-bottom:1px solid rgba(0,0,0,0.1); padding-bottom:5px;">Key Planetary Influences</h4>
                                <ul style="padding-left: 20px; font-size: 0.9em;">
                        `;

                        // Select only key planets for simplicity
                        const keyPlanets = ['Sun', 'Moon', 'Mars', 'Jupiter', 'Venus'];

                        for (const [planet, data] of Object.entries(chartData.planets)) {
                            if (keyPlanets.includes(planet)) {
                                reportHtml += `<li style="margin-bottom: 8px;">
                                    <strong>${planet} in ${data.sign}</strong>: Bringing ${getPlanetKeyword(planet)} energy to your life.
                                </li>`;
                            }
                        }

                        reportHtml += `</ul>
                                <div style="margin-top: 20px; background: rgba(255,230,128,0.3); padding: 12px; border-radius: 8px;">
                                    <strong>Chart Strength: ${chartData.strength_score}/100</strong> <br>
                                    <span style="font-size: 0.85em;">A higher score indicates stronger planetary support for your goals today.</span>
                                </div>
                            </div>`;

                        kundaliContent.innerHTML = reportHtml;
                    } else {
                        kundaliContent.innerHTML = "<p>Report unavailable. Please verify your birth time.</p>";
                    }
                };
            }

            if (closeModal) {
                closeModal.onclick = () => {
                    kundaliModal.classList.remove('active');
                    kundaliModal.style.display = 'none';
                };
            }

            window.onclick = (event) => {
                if (event.target == kundaliModal) {
                    kundaliModal.classList.remove('active');
                    kundaliModal.style.display = 'none';
                }
            };
            // === KUNDALI LOGIC END ===

            // === 7-DAY FORECAST (BACKGROUND -> UI) ===
            // Validating the new feature engine without strictly altering UI layout (but now revealing per user request)
            const forecastContainer = document.getElementById('forecast-container');
            const forecastList = document.getElementById('forecast-list');
            const forecastTrend = document.getElementById('forecast-trend');
            const forecastBest = document.getElementById('forecast-best');

            if (birthTimeInput && birthTimeInput.value) {
                console.log("🔮 Initiating 7-Day Trend Analysis...");
                api.getForecast(requestData).then(forecast => {
                    console.log("✨ 7-DAY PREDICTIVE TRAJECTORY GENERATED ✨");

                    if (forecastContainer && forecastList) {
                        console.log("✅ Container found, rendering forecast...");
                        // Populate Summary
                        forecastTrend.textContent = forecast.trend_direction;
                        // Format best day nicely
                        const bestDate = new Date(forecast.best_day);
                        forecastBest.textContent = bestDate.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' }); // e.g. "Sat, Dec 14"

                        // Populate List
                        forecastList.innerHTML = '';
                        forecast.trajectory.forEach(day => {
                            const d = new Date(day.date);
                            const dayName = d.toLocaleDateString('en-US', { weekday: 'short' }); // "Mon"
                            const score = day.luck_score;

                            const dayEl = document.createElement('div');
                            dayEl.className = 'forecast-day';
                            dayEl.style.cssText = `
                                flex: 1;
                                min-width: 0;
                                background: rgba(255,255,255,0.4);
                                border-radius: 8px;
                                padding: 6px 2px;
                                display: flex;
                                flex-direction: column;
                                align-items: center;
                                justify-content: space-between;
                                height: 80px;
                            `;

                            // Color code bar
                            let color = '#FFA000';
                            if (score >= 80) color = '#4CAF50';
                            else if (score < 50) color = '#FF5722';

                            dayEl.innerHTML = `
                                <span style="font-size: 0.65rem; font-weight: 600; color: #555;">${dayName}</span>
                                <div style="width: 4px; height: 35px; background: rgba(0,0,0,0.1); border-radius: 2px; position: relative;">
                                    <div style="position: absolute; bottom: 0; left: 0; width: 100%; height: ${score}%; background: ${color}; border-radius: 2px;"></div>
                                </div>
                                <span style="font-size: 0.65rem; font-weight: 700; color: ${color};">${score}</span>
                            `;
                            forecastList.appendChild(dayEl);
                        });

                        // Show container
                        forecastContainer.style.display = 'block';
                    }

                }).catch(err => {
                    console.warn("Forecast engine offline:", err);
                    if (forecastContainer) forecastContainer.style.display = 'none';
                });
            } else {
                if (forecastContainer) forecastContainer.style.display = 'none';
            }

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
        inputView.classList.add('active');

        // Reset progress ring
        const progressRing = document.querySelector('.progress-ring-fill');
        if (progressRing) {
            progressRing.style.strokeDashoffset = 565.48; // Circumference
        }
        resultPercentage.textContent = '0';
    }

    backBtn.addEventListener('click', goBack);
    tryAgainBtn.addEventListener('click', goBack);
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
