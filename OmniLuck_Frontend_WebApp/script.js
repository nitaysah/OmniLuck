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
    // const loadingSpinner = document.querySelector('.loading-spinner'); // Removed


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

                // If time is 12:00, it's likely an unknown time (Astrology standard)
                if (user.birth_time === "12:00" && tobNaCheckbox) {
                    tobNaCheckbox.checked = true;
                    tobNaCheckbox.dispatchEvent(new Event('change'));
                }
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
        dashboardRevealBtn.addEventListener('click', async () => {
            // Get stored user data
            const user = JSON.parse(localStorage.getItem('currentUser'));
            if (!user) return;

            // UI Loading State for Dashboard Button
            dashboardRevealBtn.disabled = true;
            dashboardRevealBtn.classList.add('loading');
            const dashBtnText = dashboardRevealBtn.querySelector('.btn-text');
            if (dashBtnText) dashBtnText.style.display = 'none';

            try {

                const birthPlaceVal = user.birth_place || user.birthPlace || '';
                let birthLocation = null;

                // Check for birth coordinates (prioritize snake_case as requested)
                if (user.birth_lat && user.birth_lon) {
                    birthLocation = { lat: user.birth_lat, lon: user.birth_lon };
                } else if (user.birthLat && user.birthLon) {
                    birthLocation = { lat: user.birthLat, lon: user.birthLon };
                } else if (user.lat && user.lon) {
                    birthLocation = { lat: user.lat, lon: user.lon };
                } else if (birthPlaceVal) {
                    // Fallback to geocoding if only place name is stored
                    birthLocation = await geocodeCity(birthPlaceVal);
                }

                // Current location fallback to null if no birth location found
                const currentLat = birthLocation ? birthLocation.lat : null;
                const currentLon = birthLocation ? birthLocation.lon : null;

                const requestData = {
                    uid: user.uid || "guest",
                    name: user.name || name,
                    dob: user.dob || dob,
                    birth_time: user.birthTime || "12:00",
                    birth_place_name: birthPlaceVal || null,
                    birth_lat: birthLocation ? birthLocation.lat : null,
                    birth_lon: birthLocation ? birthLocation.lon : null,
                    current_lat: currentLat,
                    current_lon: currentLon,
                };

                console.log("Dashboard Sending Request:", requestData);

                // Fetch Luck and Forecast
                // We only fetch forecast if we have a valid birth location
                const luckPromise = api.calculateLuck(requestData);
                const forecastPromise = birthLocation
                    ? api.getForecast(requestData).catch(e => {
                        console.error('Forecast API error:', e);
                        return null;
                    })
                    : Promise.resolve(null);

                const [response, forecastResponse] = await Promise.all([luckPromise, forecastPromise]);


                const percentage = response.luck_score || 0;
                const explanation = response.explanation || "The stars are silent today...";

                displayZodiacResult();

                let caption = response.caption;
                const summary = response.summary;
                if (!caption) {
                    if (percentage >= 80) caption = "🚀 Cosmic Jackpot!";
                    else if (percentage >= 60) caption = "✨ Strong Vibes";
                    else if (percentage >= 40) caption = "⚖️ Balanced Energy";
                    else caption = "🛡️ Stay Grounded";
                }

                document.getElementById('result-caption').textContent = caption;
                fortuneText.innerHTML = explanation.replace(/\n/g, '<br>');

                if (summary) {
                    document.getElementById('factors-text').textContent = summary;
                    document.getElementById('factors-box').style.display = 'block';
                } else {
                    document.getElementById('factors-box').style.display = 'none';
                }

                renderTraits(percentage);
                renderStrategy(response.strategic_advice, response.lucky_time_slots);

                console.log('Forecast Response:', forecastResponse);
                if (forecastResponse && forecastResponse.trajectory) {
                    console.log('Rendering forecast with', forecastResponse.trajectory.length, 'days');
                    renderForecast(forecastResponse);
                } else {
                    console.log('No forecast data available');
                    document.getElementById('forecast-flip-card').style.display = 'none';
                }

                renderPowerball(response.personal_powerball, response.daily_powerballs);

                // Switch Views
                inputView.classList.remove('active');
                if (dashboardView) dashboardView.classList.remove('active');
                resultView.classList.add('active');

                const userMenuContainer = document.getElementById('user-menu-container');
                if (userMenuContainer) userMenuContainer.style.display = 'none';

                setTimeout(() => {
                    animatePercentage(percentage);
                }, 300);

            } catch (error) {
                console.error("Dashboard API Error:", error);
                alert("The stars are cloudy right now (Connection Error). Please try again.");
            } finally {
                // Reset Button State
                dashboardRevealBtn.disabled = false;
                dashboardRevealBtn.classList.remove('loading');
                if (dashBtnText) dashBtnText.style.display = 'inline-block';
            }
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
        revealBtn.classList.add('loading');
        btnText.style.display = 'none';

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
                    revealBtn.classList.remove('loading');
                    btnText.style.display = 'inline-block';
                    return;
                }
            }

            // 2. Determine "Current" Location for Weather
            let currentLat = birthLocation ? birthLocation.lat : null;
            let currentLon = birthLocation ? birthLocation.lon : null;

            // Update request
            const requestData = {
                uid: localStorage.getItem('currentUser') ? JSON.parse(localStorage.getItem('currentUser')).uid : "guest",
                name: name,
                dob: dob,
                birth_time: (tobNaCheckbox && tobNaCheckbox.checked) ? "12:00" : (birthTimeInput && birthTimeInput.value ? birthTimeInput.value : "12:00"),
                birth_place_name: birthPlaceVal || null,
                birth_lat: birthLocation ? birthLocation.lat : null,
                birth_lon: birthLocation ? birthLocation.lon : null,
                current_lat: currentLat,
                current_lon: currentLon,
            };

            console.log("Sending Request:", requestData);

            // Fetch Luck and Forecast in parallel
            // We only fetch forecast if we have a valid birth location
            const luckPromise = api.calculateLuck(requestData);
            const forecastPromise = birthLocation
                ? api.getForecast(requestData).catch(e => {
                    console.error('Forecast API error:', e);
                    return null;
                })
                : Promise.resolve(null);

            const [response, forecastResponse] = await Promise.all([luckPromise, forecastPromise]);


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

            // Render Powerball Numbers
            renderPowerball(response.personal_powerball, response.daily_powerballs);

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
            revealBtn.classList.remove('loading');
            btnText.style.display = 'inline-block';
        }
    });

    // --- Text-to-Speech Logic ---
    const listenBtn = document.getElementById('listen-btn');
    const stopBtn = document.getElementById('stop-btn');
    let synth = window.speechSynthesis;
    let currentUtterance = null;

    if (listenBtn && stopBtn) {
        listenBtn.addEventListener('click', () => {
            const text = document.getElementById('fortune-text').innerText;
            if (!text) return;

            synth.cancel();

            currentUtterance = new SpeechSynthesisUtterance(text);
            currentUtterance.rate = 1.0;
            currentUtterance.pitch = 1.0;

            const voices = synth.getVoices();
            const preferredVoice = voices.find(v => v.name.includes("Samantha") || v.name.includes("Google US English"));
            if (preferredVoice) currentUtterance.voice = preferredVoice;

            currentUtterance.onend = () => {
                listenBtn.style.display = 'inline-block';
                stopBtn.style.display = 'none';
            };

            listenBtn.style.display = 'none';
            stopBtn.style.display = 'inline-block';

            synth.speak(currentUtterance);
        });

        stopBtn.addEventListener('click', () => {
            synth.cancel();
            listenBtn.style.display = 'inline-block';
            stopBtn.style.display = 'none';
        });
    }

    if (synth.onvoiceschanged !== undefined) {
        synth.onvoiceschanged = () => { };
    }


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
        const strategyBtn = document.getElementById('strategy-btn');
        const powerHoursBtn = document.getElementById('power-hours-btn');

        // Strategy Button
        if (!strategy) {
            strategyBtn.style.display = 'none';
        } else {
            strategyBtn.style.display = 'flex';
            document.getElementById('strategy-text').textContent = strategy;
        }

        // Power Hours Button
        const slotsList = document.getElementById('time-slots-list');
        slotsList.innerHTML = '';

        if (slots && slots.length > 0) {
            powerHoursBtn.style.display = 'flex';
            slots.forEach(slot => {
                const div = document.createElement('div');
                div.style.cssText = "background: white; border: 1.5px solid var(--accent-gold); color: var(--deep-purple); font-size: 0.9rem; font-weight: 500; padding: 14px; border-radius: 12px; line-height: 1.5;";
                div.textContent = slot;
                slotsList.appendChild(div);
            });
        } else {
            powerHoursBtn.style.display = 'none';
        }
    }

    // Modal Functions (Global)
    window.openModal = function (modalName) {
        const modal = document.getElementById(modalName + '-modal');
        if (modal) {
            modal.classList.add('active');
            document.body.style.overflow = 'hidden'; // Prevent background scroll

            // Special handling for Astro Insights modal - fetch natal chart
            if (modalName === 'astro-insights') {
                loadAstroInsights();
            }
        }
    };

    // Load Astro Insights (Natal Chart Data)
    async function loadAstroInsights() {
        const contentDiv = document.getElementById('kundali-report-content');
        contentDiv.innerHTML = '<p style="text-align: center; padding: 40px;">✨ Consulting the stars...</p>';

        try {
            // Get birth info from form inputs (same as luck calculation)
            const dobInput = document.getElementById('dob');
            const birthTimeInput = document.getElementById('birth-time');
            const birthPlaceInput = document.getElementById('birth-place');
            const tobNaCheckbox = document.getElementById('tob-na-checkbox');

            const dob = dobInput ? dobInput.value : '';
            const birthTime = (tobNaCheckbox && tobNaCheckbox.checked) ? '12:00' : (birthTimeInput ? birthTimeInput.value : '12:00');

            if (!dob) {
                contentDiv.innerHTML = '<p style="text-align: center; color: orange;">⚠️ Please enter your date of birth first.</p>';
                return;
            }

            // Get birth location (geocode if needed)
            let birthLat = 0, birthLon = 0;
            const birthPlace = birthPlaceInput ? birthPlaceInput.value : '';
            if (birthPlace) {
                try {
                    const geoUrl = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(birthPlace)}`;
                    const geoResponse = await fetch(geoUrl);
                    const geoData = await geoResponse.json();
                    if (geoData && geoData.length > 0) {
                        birthLat = parseFloat(geoData[0].lat);
                        birthLon = parseFloat(geoData[0].lon);
                    }
                } catch (e) { console.error('Geocoding error:', e); }
            }

            // Prepare birth info (matching backend BirthInfo schema)
            const birthInfo = {
                dob: dob,
                time: birthTime || '12:00',
                lat: birthLat,
                lon: birthLon,
                timezone: 'UTC'
            };

            // Fetch natal chart from API
            const response = await fetch(`${window.celestialAPI?.baseURL || 'https://omniluck.onrender.com'}/api/astrology/natal-chart`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(birthInfo)
            });

            if (!response.ok) throw new Error('Failed to fetch chart');

            const chart = await response.json();

            // Render the chart data
            let html = `
                <div style="margin-bottom: 20px; padding: 16px; background: rgba(192, 153, 240, 0.1); border-radius: 12px;">
                    <h4 style="color: var(--accent-purple); margin: 0 0 8px 0;">🌅 Your Rising Sign (Ascendant)</h4>
                    <p style="font-size: 1.1rem; font-weight: 600; color: var(--deep-purple); margin: 0 0 8px 0;">${chart.ascendant || 'Unknown'}</p>
                    <p style="font-size: 0.85rem; opacity: 0.8; margin: 0;">This sign represents your outer personality and how you interact with the world today.</p>
                </div>
                
                <h4 style="color: var(--deep-purple); margin: 0 0 12px 0;">🌟 Key Planetary Influences</h4>
            `;

            // Planet keywords
            const planetKeywords = {
                'Sun': 'vitality and purpose',
                'Moon': 'emotional depth',
                'Mars': 'action and drive',
                'Jupiter': 'expansion and luck',
                'Venus': 'love and harmony',
                'Mercury': 'communication',
                'Saturn': 'discipline'
            };

            const keyPlanets = ['Sun', 'Moon', 'Mars', 'Jupiter', 'Venus'];

            if (chart.planets) {
                keyPlanets.forEach(planet => {
                    if (chart.planets[planet]) {
                        html += `
                            <div style="display: flex; align-items: flex-start; gap: 10px; margin-bottom: 12px;">
                                <span style="color: var(--accent-gold);">•</span>
                                <div>
                                    <strong style="color: var(--deep-purple);">${planet} in ${chart.planets[planet].sign}</strong>
                                    <p style="font-size: 0.85rem; opacity: 0.7; margin: 4px 0 0 0;">Bringing ${planetKeywords[planet] || 'cosmic'} energy to your life.</p>
                                </div>
                            </div>
                        `;
                    }
                });
            }

            // Chart strength
            html += `
                <div style="margin-top: 20px; padding: 16px; background: rgba(255, 200, 100, 0.2); border-radius: 12px; text-align: center;">
                    <h4 style="color: var(--deep-purple); margin: 0 0 8px 0;">Chart Strength: ${chart.strength_score || 50}/100</h4>
                    <p style="font-size: 0.8rem; opacity: 0.7; margin: 0;">A higher score indicates stronger planetary support.</p>
                </div>
            `;

            contentDiv.innerHTML = html;

        } catch (error) {
            console.error('Astro Insights Error:', error);
            contentDiv.innerHTML = `
                <div style="text-align: center; padding: 40px;">
                    <span style="font-size: 3rem;">⚠️</span>
                    <h4 style="color: var(--deep-purple); margin: 16px 0 8px 0;">Insights Unavailable</h4>
                    <p style="font-size: 0.85rem; opacity: 0.7;">Please ensure you have entered your birth information and have an internet connection.</p>
                </div>
            `;
        }
    }

    window.closeModal = function (modalName) {
        const modal = document.getElementById(modalName + '-modal');
        if (modal) {
            modal.classList.remove('active');
            document.body.style.overflow = ''; // Restore scroll

            // Stop speech if modal closes
            if (window.speechSynthesis) window.speechSynthesis.cancel();
            const listenBtn = document.getElementById('listen-btn');
            const stopBtn = document.getElementById('stop-btn');
            if (listenBtn && stopBtn) {
                listenBtn.style.display = 'inline-block';
                stopBtn.style.display = 'none';
            }
        }
    };

    window.closeModalOnOverlay = function (event, modalName) {
        // Only close if clicking directly on overlay (not the card)
        if (event.target.classList.contains('modal-overlay')) {
            closeModal(modalName);
        }
    };

    // Close modal with Escape key
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            document.querySelectorAll('.modal-overlay.active').forEach(modal => {
                modal.classList.remove('active');
            });
            document.body.style.overflow = '';
        }
    });

    function renderPowerball(personalPB, dailyPBs) {
        // Store for QR Generation
        window.currentPowerballData = { personal: personalPB, daily: dailyPBs };

        const powerballBtn = document.getElementById('powerball-btn');

        // Only show if we have powerball data
        if (!personalPB && (!dailyPBs || dailyPBs.length === 0)) {
            powerballBtn.style.display = 'none';
            return;
        }

        powerballBtn.style.display = 'flex';

        // Helper function to create a ball element
        function createBall(number, isRed = false) {
            const ball = document.createElement('div');
            ball.style.cssText = `
                width: 40px;
                height: 40px;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-weight: 700;
                font-size: 0.95rem;
                ${isRed
                    ? 'background: linear-gradient(135deg, #dc2626, #991b1b); color: white; box-shadow: 0 4px 12px rgba(220, 38, 38, 0.4);'
                    : 'background: white; color: var(--deep-purple); border: 2px solid var(--accent-purple); box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);'
                }
            `;
            ball.textContent = number;
            return ball;
        }

        // Render Personal Powerball
        if (personalPB) {
            const personalDisplay = document.getElementById('personal-powerball-display');
            personalDisplay.innerHTML = '';

            // Add white balls
            personalPB.white_balls.forEach(num => {
                personalDisplay.appendChild(createBall(num, false));
            });

            // Add separator
            const separator = document.createElement('div');
            separator.style.cssText = 'width: 2px; height: 30px; background: var(--accent-gold); margin: 0 4px; opacity: 0.3;';
            personalDisplay.appendChild(separator);

            // Add powerball
            personalDisplay.appendChild(createBall(personalPB.powerball, true));
        }

        // Render Daily Powerballs
        if (dailyPBs && dailyPBs.length > 0) {
            const dailyList = document.getElementById('daily-powerballs-list');
            dailyList.innerHTML = '';

            dailyPBs.forEach((combo, idx) => {
                const comboDiv = document.createElement('div');
                comboDiv.style.cssText = 'margin-bottom: 12px; padding: 12px; background: rgba(192, 153, 240, 0.05); border-radius: 10px; border: 1px solid rgba(192, 153, 240, 0.1);';

                const header = document.createElement('div');
                header.style.cssText = 'font-size: 0.75rem; color: var(--deep-purple); opacity: 0.6; margin-bottom: 8px; font-weight: 600;';
                header.textContent = `Combination #${idx + 1}`;
                comboDiv.appendChild(header);

                const ballsContainer = document.createElement('div');
                ballsContainer.style.cssText = 'display: flex; gap: 6px; justify-content: center; flex-wrap: wrap;';

                // Add white balls (smaller)
                combo.white_balls.forEach(num => {
                    const ball = document.createElement('div');
                    ball.style.cssText = `
                        width: 32px;
                        height: 32px;
                        border-radius: 50%;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        font-weight: 600;
                        font-size: 0.85rem;
                        background: white;
                        color: var(--deep-purple);
                        border: 1.5px solid var(--accent-purple);
                        box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
                    `;
                    ball.textContent = num;
                    ballsContainer.appendChild(ball);
                });

                // Add separator
                const sep = document.createElement('div');
                sep.style.cssText = 'width: 1px; height: 24px; background: var(--accent-purple); margin: 0 4px; opacity: 0.2;';
                ballsContainer.appendChild(sep);

                // Add powerball (smaller)
                const powerball = document.createElement('div');
                powerball.style.cssText = `
                    width: 32px;
                    height: 32px;
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-weight: 600;
                    font-size: 0.85rem;
                    background: linear-gradient(135deg, #dc2626, #991b1b);
                    color: white;
                    box-shadow: 0 2px 8px rgba(220, 38, 38, 0.3);
                `;
                powerball.textContent = combo.powerball;
                ballsContainer.appendChild(powerball);

                comboDiv.appendChild(ballsContainer);

                // Add Scan Button Row
                const scanBtnRow = document.createElement('div');
                scanBtnRow.style.cssText = 'display:flex; justify-content:flex-end; margin-top:8px;';

                const dbScanBtn = document.createElement('button');
                dbScanBtn.innerHTML = '<span>📱</span> Scan';
                dbScanBtn.style.cssText = 'background:none; border:1px solid rgba(192, 153, 240, 0.4); border-radius:12px; padding:4px 10px; font-size:0.75rem; cursor:pointer; color:var(--deep-purple); display:flex; align-items:center; gap:4px; transition: background 0.2s;';
                dbScanBtn.onmouseover = () => dbScanBtn.style.background = 'rgba(192, 153, 240, 0.1)';
                dbScanBtn.onmouseout = () => dbScanBtn.style.background = 'none';

                dbScanBtn.onclick = (e) => {
                    e.stopPropagation();
                    if (window.generateQR) window.generateQR(combo, `Combination #${idx + 1}`);
                };

                scanBtnRow.appendChild(dbScanBtn);
                comboDiv.appendChild(scanBtnRow);
                dailyList.appendChild(comboDiv);
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
    // Guest Home Button Logic
    const guestHomeBtn = document.getElementById('guest-home-btn');
    if (guestHomeBtn) {
        guestHomeBtn.addEventListener('click', () => {
            window.location.href = 'index.html';
        });
    }

    // Powerball Manual Generation Logic
    const pbGenBtn = document.getElementById('pb-generate-btn');
    if (pbGenBtn) {
        pbGenBtn.addEventListener('click', async () => {
            const linesInput = document.getElementById('pb-lines-input');
            const count = parseInt(linesInput.value) || 5;

            // Validate count
            if (count < 1 || count > 50) {
                alert("Max 50 numbers can be generated.");
                return;
            }

            const btnOriginalText = pbGenBtn.textContent;
            pbGenBtn.textContent = "Generating...";
            pbGenBtn.disabled = true;

            try {
                // Construct request data from current inputs
                // Note: We access the DOM elements directly here to ensure freshness
                const nInput = document.getElementById('name');
                const dInput = document.getElementById('dob');
                const tInput = document.getElementById('birth-time');
                const pInput = document.getElementById('birth-place');
                const tCheck = document.getElementById('tob-na'); // Checkbox

                // Calculate current location (if available in global scope or re-fetch?)
                // For now use defaults or stored values if available
                let lat = null, lon = null;
                // Try to find cached location from previous run?
                // Alternatively, we can just omit current location as it's less critical for powerball strictly
                // Or we can try to re-use the 'birthLocation' variable if it's in scope.
                // 'birthLocation' is likely defined in the scope of 'revealBtn' listener, not here.
                // So we'll have to rely on what we can get.

                // Let's re-use the values from the input fields
                const requestData = {
                    uid: localStorage.getItem('currentUser') ? JSON.parse(localStorage.getItem('currentUser')).uid : "guest",
                    name: nInput ? nInput.value : "User",
                    dob: dInput ? dInput.value : new Date().toISOString().split('T')[0],
                    birth_time: (tCheck && tCheck.checked) ? "12:00" : (tInput ? tInput.value : "12:00"),
                    birth_place_name: pInput ? pInput.value : null,
                    // If we don't have lat/lon, the backend might approximate or skip
                    birth_lat: null,
                    birth_lon: null,
                    powerball_count: count
                };

                const response = await api.calculateLuck(requestData);

                // Update only the powerball list
                renderPowerball(response.personal_powerball, response.daily_powerballs);

            } catch (error) {
                console.error("Refresh Error:", error);
                alert("Failed to refresh numbers.");
            } finally {
                pbGenBtn.textContent = btnOriginalText;
                pbGenBtn.disabled = false;
            }
        });
    }

    // ============================================================================
    // RETAILER BRIDGE LOGIC
    // ============================================================================

    // 1. Age Verification Toggle
    const ageToggle = document.getElementById('age-verify-toggle');
    const scanBtn = document.getElementById('scan-pay-btn');
    const scanAllBtn = document.getElementById('scan-all-daily-btn');
    const qrContainer = document.getElementById('pb-qr-container');

    if (ageToggle && scanBtn) {
        ageToggle.addEventListener('change', (e) => {
            const btns = [scanBtn, scanAllBtn];
            if (e.target.checked) {
                btns.forEach(b => { if (b) { b.style.opacity = '1'; b.style.pointerEvents = 'auto'; } });
            } else {
                btns.forEach(b => { if (b) { b.style.opacity = '0.5'; b.style.pointerEvents = 'none'; } });
                if (qrContainer) qrContainer.style.display = 'none';
            }
        });
    }

    // 2. Scan & Pay (Generate QR)
    window.generateQR = function (targetData = null, labelText = "Personal Numbers") {
        const qrContainer = document.getElementById('pb-qr-container');
        const qrCodeDiv = document.getElementById('pb-qr-code');
        const seedDisplay = document.getElementById('qr-seed-hash');
        const labelDisplay = document.getElementById('qr-code-label');

        const ageToggle = document.getElementById('age-verify-toggle');
        if (ageToggle && !ageToggle.checked) {
            if (confirm("Confirm 18+ to view Digital Play Slip?")) {
                ageToggle.checked = true;
                ageToggle.dispatchEvent(new Event('change'));
            } else return;
        }

        if (qrContainer) {
            qrContainer.style.display = 'flex';
            if (qrContainer.style.display !== 'none') {
                qrContainer.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
        }
        if (qrCodeDiv) qrCodeDiv.innerHTML = '';
        if (labelDisplay) labelDisplay.textContent = labelText;

        // Default to Personal if no target provided
        if (!targetData) {
            const data = window.currentPowerballData;
            if (data && data.personal) targetData = data.personal;
        }

        if (!targetData) {
            if (qrCodeDiv) qrCodeDiv.textContent = "No data available.";
            return;
        }

        // Format: GAME:PB|W:01,02,03,04,05|P:06
        const wb = targetData.white_balls.join(',');
        const pb = targetData.powerball;
        const qrString = `GAME:PB|W:${wb}|P:${pb}`;

        try {
            new QRCode(qrCodeDiv, {
                text: qrString,
                width: 160,
                height: 160,
                colorDark: "#4a148c",
                colorLight: "#ffffff",
                correctLevel: QRCode.CorrectLevel.H
            });
            if (seedDisplay) seedDisplay.textContent = btoa(qrString).substring(0, 12).toUpperCase();
        } catch (e) {
            console.error(e);
            if (qrCodeDiv) qrCodeDiv.textContent = "Error.";
        }
    }

    if (scanBtn) {
        scanBtn.addEventListener('click', () => window.generateQR(null, "Personal Numbers"));
    }





    // Bulk Scan Daily Button
    if (scanAllBtn) {
        scanAllBtn.addEventListener('click', () => {
            const data = window.currentPowerballData;
            if (!data || !data.daily || data.daily.length === 0) {
                alert("No daily numbers to scan.");
                return;
            }

            // Build Bulk String: GAME:PB|COUNT:N|1:W..P..|2:W..P..
            let qrStr = `GAME:PB|COUNT:${data.daily.length}`;
            data.daily.forEach((set, i) => {
                qrStr += `|${i + 1}:W${set.white_balls.join(',')}P${set.powerball}`;
            });

            const qrContainer = document.getElementById('pb-qr-container');
            const qrCodeDiv = document.getElementById('pb-qr-code');
            const labelDisplay = document.getElementById('qr-code-label');
            const seedDisplay = document.getElementById('qr-seed-hash');

            if (qrContainer) {
                qrContainer.style.display = 'flex';
                qrContainer.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
            if (qrCodeDiv) qrCodeDiv.innerHTML = '';
            if (labelDisplay) labelDisplay.textContent = `Daily Play Slip (${data.daily.length} Lines)`;

            try {
                new QRCode(qrCodeDiv, {
                    text: qrStr,
                    width: 220,
                    height: 220,
                    colorDark: "#4a148c",
                    colorLight: "#ffffff",
                    correctLevel: QRCode.CorrectLevel.L // Low ECC for density
                });
                if (seedDisplay) seedDisplay.textContent = "BULK-" + btoa(qrStr).substring(0, 8);
            } catch (e) {
                console.error(e);
                if (qrCodeDiv) qrCodeDiv.textContent = "Data too large for QR.";
            }
        });
    }
    const saveQrBtn = document.getElementById('save-qr-btn');
    if (saveQrBtn) {
        saveQrBtn.addEventListener('click', () => {
            const img = document.querySelector('#pb-qr-code img');
            if (img) {
                const link = document.createElement('a');
                link.download = 'omniluck-powerball-qr.png';
                link.href = img.src;
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            } else {
                alert("Please generate a QR code first.");
            }
        });
    }

    // 4. Retailer Locator (Mocked for Demo)
    const findRetailersBtn = document.getElementById('find-retailers-btn');
    const retailerList = document.getElementById('retailer-list');

    if (findRetailersBtn && retailerList) {
        findRetailersBtn.addEventListener('click', () => {
            retailerList.innerHTML = '<p style="padding:16px;text-align:center;">Locating nearby stores...</p>';

            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition((pos) => {
                    const lat = pos.coords.latitude;
                    const lon = pos.coords.longitude;

                    // Specific Google Maps Search URL
                    // uses 'lottery retailer' query near user location
                    const mapsUrl = `https://www.google.com/maps/search/lottery+retailer/@${lat},${lon},14z`;

                    // Mock API latency
                    setTimeout(() => {
                        retailerList.innerHTML = '';

                        // Mock Data (In production, replace with Google Places API)
                        const stores = [
                            { name: "Quick Mart #101", dist: "0.3 mi" },
                            { name: "Shell Station", dist: "0.6 mi" },
                            { name: "7-Eleven", dist: "1.1 mi" }
                        ];

                        stores.forEach(store => {
                            const item = document.createElement('div');
                            item.className = 'retailer-item';
                            item.innerHTML = `
                                <div>
                                    <div style="font-weight:600; font-size:0.9rem; color:var(--deep-purple);">${store.name}</div>
                                    <div style="font-size:0.75rem; color:#666;">${store.dist} • Authorized</div>
                                </div>
                                <a href="${mapsUrl}" target="_blank" 
                                   style="background:var(--accent-purple); color:white; text-decoration:none; padding:6px 12px; border-radius:8px; font-size:0.75rem; font-weight:600;">
                                    Navigate
                                </a>
                            `;
                            retailerList.appendChild(item);
                        });
                    }, 1500);

                }, (err) => {
                    console.error("Geo Error:", err);
                    retailerList.innerHTML = '<p style="padding:16px;text-align:center;color:red;">Location access denied.</p>';
                });
            } else {
                retailerList.innerHTML = '<p style="padding:16px;text-align:center;">Geolocation not supported.</p>';
            }
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
