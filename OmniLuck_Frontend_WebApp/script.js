import CelestialAPI from './api-client.js?v=5';
import { initUserSession } from './user-session.js';
import { db } from './firebase-config.js';
import { doc, updateDoc } from "https://www.gstatic.com/firebasejs/11.0.2/firebase-firestore.js";

document.addEventListener('DOMContentLoaded', () => {
    // Initialize API Client
    const api = new CelestialAPI();
    window.celestialAPI = api;

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

    // Toggle Location Explainer
    const locationInfoBtn = document.getElementById('location-info-btn');
    const locationExplainer = document.getElementById('location-explainer');
    if (locationInfoBtn && locationExplainer) {
        locationInfoBtn.addEventListener('click', (e) => {
            e.preventDefault();
            locationExplainer.style.display = locationExplainer.style.display === 'none' ? 'block' : 'none';
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
    const resultView = document.getElementById('daily-luck-result-view');
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
            history.replaceState({ view: 'dashboard' }, 'Dashboard', '#dashboard');
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
        // Phone
        const dPhone = document.getElementById('dashboard-phone-display');
        if (dPhone && user.phoneNumber) dPhone.textContent = user.phoneNumber;

        // Current Location
        const dLocation = document.getElementById('dashboard-location-display');
        if (dLocation) {
            dLocation.textContent = user.current_location || user.birth_place || '--';
        }

        if (user.birth_time) {
            if (birthTimeInput) birthTimeInput.value = user.birth_time;
            if (dTime) {
                // Format 01:30 -> 01:30 AM
                try {
                    const [h, m] = user.birth_time.split(':');
                    const hour = parseInt(h);
                    const ampm = hour >= 12 ? 'PM' : 'AM';
                    const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
                    const formattedHour = displayHour.toString().padStart(2, '0');
                    dTime.textContent = `${formattedHour}:${m} ${ampm}`;
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
        history.replaceState({ view: 'guest' }, 'Guest', '#guest');

        // Clear any existing guest session data
        sessionStorage.removeItem('guestSession');

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

                // Use current location from profile if available, otherwise fall back to birth location
                let currentLat = user.current_lat || (birthLocation ? birthLocation.lat : null);
                let currentLon = user.current_lon || (birthLocation ? birthLocation.lon : null);

                const requestData = {
                    uid: user.uid || "guest",
                    name: user.name || name,
                    dob: user.dob || dob,
                    birth_time: user.birthTime || user.birth_time || "12:00",
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

                // Store score for lottery
                window.currentLuckScore = percentage;

                // renderPowerball(response.personal_powerball, response.daily_powerballs); // REMOVED

                // Switch Views
                // Switch Views
                document.querySelectorAll('.view').forEach(v => {
                    v.style.display = 'none';
                    v.classList.remove('active');
                });

                resultView.style.display = 'block';
                resultView.classList.add('active');
                history.pushState({ view: 'daily-luck-result' }, 'Daily Luck Result', '#daily-luck-result');

                const userMenuContainer = document.getElementById('user-menu-container');
                if (userMenuContainer) userMenuContainer.style.display = 'flex';

                // Show global back button
                const resultBackBtnContainer = document.getElementById('result-back-btn-container');
                if (resultBackBtnContainer) resultBackBtnContainer.style.display = 'block';

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

    if (tryAgainBtn) {
        tryAgainBtn.addEventListener('click', () => {
            const user = JSON.parse(localStorage.getItem('currentUser'));
            if (user && window.showDashboardView) {
                window.showDashboardView();
            } else if (user) {
                // Manual Dashboard Switch
                document.querySelectorAll('.view').forEach(v => {
                    v.style.display = 'none';
                    v.classList.remove('active');
                });
                const dl = document.getElementById('dashboard-view');
                if (dl) {
                    dl.style.display = 'block';
                    dl.classList.add('active');
                }
                const um = document.getElementById('user-menu-container');
                if (um) um.style.display = 'block';
            } else {
                window.location.reload();
            }
        });
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
        // Read directly from form inputs to ensure fresh values
        const currentName = document.getElementById('name').value.trim();
        const currentDob = document.getElementById('dob').value;
        const birthPlaceVal = document.getElementById('birth-place').value.trim();

        if (!currentName || !currentDob || !birthPlaceVal) {
            alert("Please enter your Name, Date of Birth, and Place of Birth to reveal your fortune!");
            return;
        }

        // Update the closure variables
        name = currentName;
        dob = currentDob;

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

            // 2. Geocode Current Location (for weather/cosmic signals)
            const currentLocationInput = document.getElementById('current-location');
            const currentLocationVal = currentLocationInput ? currentLocationInput.value.trim() : null;
            let currentLocation = null;

            if (currentLocationVal) {
                currentLocation = await geocodeCity(currentLocationVal);
                if (!currentLocation) {
                    alert("Could not find current location '" + currentLocationVal + "'. Please validate the city and country name (e.g. Dallas, USA).");
                    revealBtn.disabled = false;
                    revealBtn.classList.remove('loading');
                    btnText.style.display = 'inline-block';
                    return;
                }
            }

            // Use current location if provided, otherwise fall back to birth location
            let currentLat = currentLocation ? currentLocation.lat : (birthLocation ? birthLocation.lat : null);
            let currentLon = currentLocation ? currentLocation.lon : (birthLocation ? birthLocation.lon : null);

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

            // Store for Lottery View
            window.currentLuckScore = percentage;

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

            // Render Powerball Numbers (Moved to dedicated view)
            // renderPowerball(response.personal_powerball, response.daily_powerballs);

            // Switch Views
            inputView.classList.remove('active');
            if (dashboardView) dashboardView.classList.remove('active');
            resultView.classList.add('active');
            history.pushState({ view: 'guest-daily-luck-result' }, 'Guest Daily Luck Result', '#guest-daily-luck-result');

            // Hide User Menu on Guest Result Page
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

            // Special handling for Comparison modal - analyze combos against history
            if (modalName === 'comparison') {
                loadComparisonAnalysis();
            }
        }
    };

    // Load comparison analysis - fetch history and analyze all combos
    async function loadComparisonAnalysis() {
        const combosDiv = document.getElementById('comparison-all-combos');
        if (!combosDiv) return;

        combosDiv.innerHTML = '<div style="text-align: center; padding: 20px; color: #666;"><span style="font-size: 1.5rem;">⏳</span><p style="margin: 8px 0 0 0; font-size: 0.85rem;">Analyzing your numbers...</p></div>';

        try {
            // Fetch historical drawings from cached backend API (last 100 drawings)
            const response = await fetch(window.celestialAPI.baseURL + '/api/luck/lottery/history?limit=100');
            const result = await response.json();
            const historicalDrawings = result.drawings || [];

            // Get user's generated numbers
            const cachedData = localStorage.getItem('lastLotteryData');
            if (!cachedData) {
                combosDiv.innerHTML = '<div style="text-align: center; padding: 30px; color: #666;"><span style="font-size: 2rem;">🎲</span><p style="margin: 12px 0 0 0;">Generate your lucky numbers first!</p></div>';
                return;
            }

            const data = JSON.parse(cachedData);
            const allCombos = [];

            // Add personal numbers
            if (data.personal_powerball) {
                allCombos.push({
                    type: 'personal',
                    label: '✨ Personal Numbers',
                    white_balls: data.personal_powerball.white_balls,
                    powerball: data.personal_powerball.powerball
                });
            }

            // Add daily combos
            (data.daily_powerballs || []).forEach((combo, idx) => {
                allCombos.push({
                    type: 'daily',
                    label: `#${idx + 1} Daily Combo`,
                    white_balls: combo.white_balls,
                    powerball: combo.powerball
                });
            });

            if (allCombos.length === 0) {
                combosDiv.innerHTML = '<div style="text-align: center; padding: 30px; color: #666;"><span style="font-size: 2rem;">🎲</span><p style="margin: 12px 0 0 0;">No combinations generated yet.</p></div>';
                return;
            }

            // Analyze each combo against historical drawings
            let totalMatches = 0;
            let bestComboMatches = 0;
            let bestComboLabel = '';
            let combosWithMatches = 0;

            let html = '';

            allCombos.forEach(combo => {
                // Find all matches with historical drawings
                let comboTotalMatches = 0;
                let matchingDraws = [];

                // Track how many times each number matched
                const numberMatchCounts = {};
                combo.white_balls.forEach(n => numberMatchCounts[n] = 0);
                numberMatchCounts['pb_' + combo.powerball] = 0;

                historicalDrawings.forEach(draw => {
                    const whiteMatches = combo.white_balls.filter(n => draw.white_balls.includes(n));
                    const pbMatch = combo.powerball === draw.powerball;
                    const matchCount = whiteMatches.length + (pbMatch ? 1 : 0);

                    // Count individual number matches
                    whiteMatches.forEach(n => numberMatchCounts[n]++);
                    if (pbMatch) numberMatchCounts['pb_' + combo.powerball]++;

                    if (matchCount > 0) {
                        comboTotalMatches += matchCount;
                        matchingDraws.push({
                            date: draw.date,
                            matches: matchCount,
                            whiteMatches,
                            pbMatch
                        });
                    }
                });

                totalMatches += comboTotalMatches;
                if (comboTotalMatches > 0) combosWithMatches++;
                if (comboTotalMatches > bestComboMatches) {
                    bestComboMatches = comboTotalMatches;
                    bestComboLabel = combo.label;
                }

                // Build HTML for this combo
                const isPersonal = combo.type === 'personal';
                html += `
                    <div style="padding: 16px; border-bottom: 2px solid #eee; ${isPersonal ? 'background: rgba(99, 102, 241, 0.05);' : ''}">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                            <span style="font-weight: 700; font-size: 0.85rem; color: ${isPersonal ? '#6366f1' : 'var(--deep-purple)'};">${combo.label}</span>
                            <span style="background: ${comboTotalMatches >= 10 ? '#22c55e' : comboTotalMatches >= 5 ? '#fbbf24' : '#e5e7eb'}; color: ${comboTotalMatches >= 5 ? 'white' : '#666'}; padding: 4px 10px; border-radius: 12px; font-size: 0.7rem; font-weight: 600;">
                                ${comboTotalMatches} total hits
                            </span>
                        </div>
                        <div style="display: flex; gap: 6px; justify-content: center; flex-wrap: wrap; margin-bottom: 10px;">
                            ${combo.white_balls.map(num => {
                    const matchCount = numberMatchCounts[num];
                    const isHot = matchCount > 0;
                    return `<div style="display: flex; flex-direction: column; align-items: center; gap: 2px;">
                                    <span style="display: inline-flex; align-items: center; justify-content: center; width: 36px; height: 36px; background: ${isHot ? '#22c55e' : 'white'}; border: 2px solid ${isHot ? '#22c55e' : 'var(--deep-purple)'}; border-radius: 50%; font-weight: 700; font-size: 0.85rem; color: ${isHot ? 'white' : 'var(--deep-purple)'};">${num}</span>
                                    ${matchCount > 1 ? `<span style="font-size: 0.6rem; color: #22c55e; font-weight: 600;">×${matchCount}</span>` : matchCount === 1 ? `<span style="font-size: 0.6rem; color: #888;">×1</span>` : ''}
                                </div>`;
                }).join('')}
                            <div style="display: flex; flex-direction: column; align-items: center; gap: 2px;">
                                <span style="display: inline-flex; align-items: center; justify-content: center; width: 36px; height: 36px; background: ${numberMatchCounts['pb_' + combo.powerball] > 0 ? '#22c55e' : 'linear-gradient(135deg, #FF5252, #D32F2F)'}; border-radius: 50%; font-weight: 700; font-size: 0.85rem; color: white;">${combo.powerball}</span>
                                ${numberMatchCounts['pb_' + combo.powerball] > 1 ? `<span style="font-size: 0.6rem; color: #22c55e; font-weight: 600;">×${numberMatchCounts['pb_' + combo.powerball]}</span>` : numberMatchCounts['pb_' + combo.powerball] === 1 ? `<span style="font-size: 0.6rem; color: #888;">×1</span>` : ''}
                            </div>
                        </div>
                        ${matchingDraws.length > 0 ? `
                            <div style="font-size: 0.7rem; color: #666; text-align: center;">
                                Matched in ${matchingDraws.length} of 100 drawings
                            </div>
                        ` : '<div style="font-size: 0.7rem; color: #999; text-align: center;">No matches in 100 drawings</div>'}
                    </div>
                `;
            });

            combosDiv.innerHTML = html;

            // Update statistics card - hit rate = % of drawings with at least 1 match
            const drawingsWithAnyMatch = new Set();
            allCombos.forEach(combo => {
                historicalDrawings.forEach((draw, idx) => {
                    const hasMatch = combo.white_balls.some(n => draw.white_balls.includes(n)) || combo.powerball === draw.powerball;
                    if (hasMatch) drawingsWithAnyMatch.add(idx);
                });
            });
            const hitRate = historicalDrawings.length > 0 ? Math.round((drawingsWithAnyMatch.size / historicalDrawings.length) * 100) : 0;

            document.getElementById('stat-total-matches').textContent = totalMatches;
            document.getElementById('stat-best-line').textContent = bestComboMatches > 0 ? bestComboMatches : '--';
            document.getElementById('stat-match-rate').textContent = `${hitRate}%`;

            // Update trust badge
            const trustBadge = document.getElementById('trust-badge');
            if (hitRate >= 80) {
                trustBadge.textContent = '🔥 Strong Alignment';
                trustBadge.style.background = 'rgba(34, 197, 94, 0.4)';
            } else if (hitRate >= 50) {
                trustBadge.textContent = '✨ Good Patterns';
                trustBadge.style.background = 'rgba(251, 191, 36, 0.4)';
            } else {
                trustBadge.textContent = '📊 Analyzed';
                trustBadge.style.background = 'rgba(255,255,255,0.2)';
            }

        } catch (error) {
            console.error('Failed to load comparison analysis:', error);
            combosDiv.innerHTML = '<div style="text-align: center; padding: 20px; color: #dc2626;"><span style="font-size: 1.5rem;">⚠️</span><p style="margin: 8px 0 0 0; font-size: 0.85rem;">Failed to analyze. Try again.</p></div>';
        }
    }

    // Load Historical Powerball Drawings (Using Cached Backend API)
    window.loadHistoricalDrawings = async function () {
        const listDiv = document.getElementById('historical-drawings-list');
        if (!listDiv) return;

        listDiv.innerHTML = '<div style="text-align: center; padding: 20px; color: #666;"><span style="font-size: 1.5rem;">⏳</span><p style="margin: 8px 0 0 0; font-size: 0.85rem;">Loading recent drawings...</p></div>';

        try {
            // Fetch from our cached backend API (refreshes only after new drawings)
            const response = await fetch(window.celestialAPI.baseURL + '/api/luck/lottery/history?limit=20');
            const result = await response.json();
            const drawings = result.drawings || [];

            // Get user's personal numbers for comparison
            const cachedData = localStorage.getItem('lastLotteryData');
            let userNumbers = [];
            let userPowerball = null;

            if (cachedData) {
                const data = JSON.parse(cachedData);
                if (data.personal_powerball) {
                    userNumbers = data.personal_powerball.white_balls || [];
                    userPowerball = data.personal_powerball.powerball;
                }
            }

            let html = '';

            // Show cache status
            if (result.cached) {
                html += `<div style="padding: 8px 12px; background: rgba(99, 102, 241, 0.1); border-radius: 8px; margin-bottom: 12px; font-size: 0.75rem; color: #6366f1;">
                    💾 Using cached data • Next refresh: ${new Date(result.next_refresh).toLocaleString('en-US', { weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })}
                </div>`;
            }

            drawings.forEach(draw => {
                const dateStr = new Date(draw.date).toLocaleDateString('en-US', {
                    weekday: 'short', month: 'short', day: 'numeric', year: 'numeric'
                });
                const whiteBalls = draw.white_balls;
                const powerball = draw.powerball;

                // Count matches
                let matchCount = 0;
                const matchedBalls = whiteBalls.map(num => {
                    const isMatch = userNumbers.includes(num);
                    if (isMatch) matchCount++;
                    return { num, isMatch };
                });
                const pbMatch = powerball === userPowerball;
                if (pbMatch) matchCount++;

                html += `
                    <div style="padding: 12px; border-bottom: 1px solid #eee; ${matchCount > 0 ? 'background: rgba(34, 197, 94, 0.05);' : ''}">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                            <span style="font-size: 0.75rem; color: #666;">${dateStr}</span>
                            ${matchCount > 0 ? `<span style="background: #22c55e; color: white; padding: 2px 8px; border-radius: 10px; font-size: 0.7rem; font-weight: 600;">${matchCount} match${matchCount > 1 ? 'es' : ''}</span>` : ''}
                        </div>
                        <div style="display: flex; gap: 4px; align-items: center; flex-wrap: wrap;">
                            ${matchedBalls.map(b => `
                                <span style="display: inline-flex; align-items: center; justify-content: center; width: 26px; height: 26px; border-radius: 50%; font-weight: 600; font-size: 0.7rem; ${b.isMatch ? 'background: #22c55e; color: white;' : 'background: #f3f4f6; color: #374151;'}">${b.num}</span>
                            `).join('')}
                            <span style="display: inline-flex; align-items: center; justify-content: center; width: 26px; height: 26px; border-radius: 50%; font-weight: 600; font-size: 0.7rem; ${pbMatch ? 'background: #22c55e; color: white;' : 'background: linear-gradient(135deg, #FF5252, #D32F2F); color: white;'}">${powerball}</span>
                        </div>
                    </div>
                `;
            });

            listDiv.innerHTML = html || '<p style="text-align: center; color: #666;">No drawings found</p>';

            // Calculate and update smart statistics
            updateComparisonStats(drawings);

        } catch (error) {
            console.error('Failed to load historical drawings:', error);
            listDiv.innerHTML = '<div style="text-align: center; padding: 20px; color: #dc2626;"><span style="font-size: 1.5rem;">⚠️</span><p style="margin: 8px 0 0 0; font-size: 0.85rem;">Failed to load drawings. Try again.</p></div>';
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

        // Save to localStorage for comparison modal
        localStorage.setItem('lastLotteryData', JSON.stringify({
            personal_powerball: personalPB,
            daily_powerballs: dailyPBs,
            generated_at: new Date().toISOString()
        }));

        const powerballBtn = document.getElementById('powerball-btn');

        // Only show if we have powerball data
        if (!personalPB && (!dailyPBs || dailyPBs.length === 0)) {
            if (powerballBtn) powerballBtn.style.display = 'none';
            return;
        }

        if (powerballBtn) powerballBtn.style.display = 'flex';

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

                // Add Scan Button Row (DISABLED/BACKUP)
                /*
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
                */
                dailyList.appendChild(comboDiv);
            });
        }
    }
    window.renderPowerball = renderPowerball;

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
        // Populate Top Stats
        // User Request: Start from next day (Tomorrow).
        // Logic: Check if the first entry is Today (or past). If so, skip it. 
        // If the first entry is already Tomorrow, keep it.
        const todayStr = new Date().toISOString().split('T')[0];
        let forecastSubset = data.trajectory;

        if (data.trajectory.length > 0) {
            // If first item date is today or earlier, skip it to ensure we start from "Tomorrow"
            // Simple string comparison YYYY-MM-DD works well here
            if (data.trajectory[0].date <= todayStr) {
                forecastSubset = data.trajectory.slice(1);
            }
        }

        // Find best day in the remaining forecast
        let best = forecastSubset[0];
        forecastSubset.forEach(d => { if (d.luck_score > best.luck_score) best = d; });

        document.getElementById('forecast-trend').textContent = data.trend_direction;

        // Format date: YYYY-MM-DD -> Day, MMM DD
        const formatDate = (ds) => {
            const d = new Date(ds);
            // Include Weekday
            return d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', timeZone: 'UTC' });
        };

        document.getElementById('forecast-best').textContent = `${formatDate(best.date)} (${best.luck_score}%)`;

        // Render Bar Chart
        const list = document.getElementById('forecast-list');
        list.innerHTML = '';

        forecastSubset.forEach(day => {
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

    // === HISTORY API INTEGRATION ===

    // 1. Handle UI Restoration (Formerly goBack)
    function restoreDashboardUI() {
        resultView.classList.remove('active');

        const currentUser = localStorage.getItem('currentUser');
        if (currentUser && dashboardView) {
            dashboardView.classList.add('active');
            const userMenuContainer = document.getElementById('user-menu-container');
            if (userMenuContainer) userMenuContainer.style.display = 'block';
        } else {
            inputView.classList.add('active');
            const userMenuContainer = document.getElementById('user-menu-container');
            if (userMenuContainer) userMenuContainer.style.display = 'none';
        }

        const progressRing = document.querySelector('.progress-ring-fill');
        if (progressRing) {
            progressRing.style.strokeDashoffset = 565.48;
        }
        resultPercentage.textContent = '0';
    }

    // 2. Handle Browser Back/Forward
    window.addEventListener('popstate', (event) => {
        const hash = window.location.hash;

        // Hide all views first
        document.querySelectorAll('.view').forEach(v => {
            v.style.display = 'none';
            v.classList.remove('active');
        });

        // Show the correct view based on hash
        if (hash === '#daily-luck-result') {
            const dailyLuckView = document.getElementById('daily-luck-result-view');
            if (dailyLuckView) {
                dailyLuckView.style.display = 'block';
                dailyLuckView.classList.add('active');
            }
            const userMenuContainer = document.getElementById('user-menu-container');
            if (userMenuContainer) userMenuContainer.style.display = 'flex';
        } else if (hash === '#guest-daily-luck-result') {
            const dailyLuckView = document.getElementById('daily-luck-result-view');
            if (dailyLuckView) {
                dailyLuckView.style.display = 'block';
                dailyLuckView.classList.add('active');
            }
            // Guest result - no user menu
        } else if (hash === '#lucky-number-result') {
            const lotteryResultView = document.getElementById('lucky-number-result');
            if (lotteryResultView) {
                lotteryResultView.style.display = 'block';
                lotteryResultView.classList.add('active');
            }
            const userMenuContainer = document.getElementById('user-menu-container');
            if (userMenuContainer) userMenuContainer.style.display = 'flex';
        } else if (hash === '#guest') {
            const inputView = document.getElementById('input-view');
            if (inputView) {
                inputView.style.display = 'block';
                inputView.classList.add('active');
            }
            // Guest flow - no user menu
        } else {
            // Default to dashboard
            const dashboardView = document.getElementById('dashboard-view');
            if (dashboardView) {
                dashboardView.style.display = 'block';
                dashboardView.classList.add('active');
            }
            const userMenuContainer = document.getElementById('user-menu-container');
            if (userMenuContainer) userMenuContainer.style.display = 'flex';
        }
    });

    // 3. Update Back/TryAgain Buttons to use smart goBack
    const handleManualBack = () => {
        window.goBack();
    };

    if (backBtn) backBtn.addEventListener('click', handleManualBack);
    if (tryAgainBtn) tryAgainBtn.addEventListener('click', handleManualBack);

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
                // Force refresh to generate NEW numbers (bypass 1-hour cache)
                await window.fetchLotteryNumbers(count, true);
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

        if (qrCodeDiv) {
            qrCodeDiv.innerHTML = '';
            // Reset & Apply Screen Optimization (High Contrast)
            // Reset Basic Styles
            qrCodeDiv.style.background = '#ffffff';
            qrCodeDiv.style.padding = '20px';
            qrCodeDiv.style.borderRadius = '12px';

            // Apply Premium Gold Class for Personal Numbers
            // Logic: Personal = Gold Class, Daily = Standard
            if (labelText.toLowerCase().includes("personal")) {
                qrCodeDiv.classList.add('personal-qr-container');
                // Clean up inline styles that might conflict
                qrCodeDiv.style.border = '';
                qrCodeDiv.style.boxShadow = '';
            } else {
                qrCodeDiv.classList.remove('personal-qr-container');
                qrCodeDiv.style.border = '1px solid #eee';
                qrCodeDiv.style.boxShadow = 'none';
            }
        }

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

        // Format Verification: GAME:PB|SLIP:1|L1:01,02,03,04,05,06 (Last is PB)
        const wb = targetData.white_balls.map(n => n.toString().padStart(2, '0')).join(',');
        const pb = targetData.powerball.toString().padStart(2, '0');
        const qrString = `GAME:PB|SLIP:1|L1:${wb},${pb}`;

        try {
            new QRCode(qrCodeDiv, {
                text: qrString,
                width: 180,
                height: 180,
                colorDark: "#000000", // Pure black
                colorLight: "#ffffff", // Pure white
                correctLevel: QRCode.CorrectLevel.M
            });
            if (seedDisplay) seedDisplay.textContent = "Seed: " + btoa(qrString).substring(0, 12).toUpperCase();
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

            // Build Bulk String: GAME:PB|SLIP:1|L1:..|L2:..
            let qrStr = `GAME:PB|SLIP:1`;
            data.daily.forEach((set, i) => {
                const wb = set.white_balls.map(n => n.toString().padStart(2, '0')).join(',');
                const pb = set.powerball.toString().padStart(2, '0');
                qrStr += `|L${i + 1}:${wb},${pb}`;
            });

            const qrContainer = document.getElementById('pb-qr-container');
            const qrCodeDiv = document.getElementById('pb-qr-code');
            const labelDisplay = document.getElementById('qr-code-label');
            const seedDisplay = document.getElementById('qr-seed-hash');

            if (qrContainer) {
                qrContainer.style.display = 'flex';
                qrContainer.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
            if (qrCodeDiv) {
                qrCodeDiv.innerHTML = '';
                // Screen Optimization (High Contrast)
                qrCodeDiv.classList.remove('personal-qr-container'); // Ensure Gold Class removed
                qrCodeDiv.style.background = '#ffffff';
                qrCodeDiv.style.padding = '20px';
                qrCodeDiv.style.borderRadius = '12px';
                qrCodeDiv.style.border = '1px solid #7c3aed'; // Normal border for bulk
                qrCodeDiv.style.boxShadow = 'none';
            }

            if (labelDisplay) labelDisplay.textContent = `Daily Play Slip (${data.daily.length} Lines)`;

            try {
                new QRCode(qrCodeDiv, {
                    text: qrStr,
                    width: 220,
                    height: 220,
                    colorDark: "#000000",
                    colorLight: "#ffffff",
                    correctLevel: QRCode.CorrectLevel.M
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
    const zipInput = document.getElementById('retailer-zip');

    if (findRetailersBtn && retailerList && zipInput) {
        findRetailersBtn.addEventListener('click', () => {
            const zip = zipInput.value.trim();
            if (!zip || zip.length < 5) {
                alert("Please enter a valid Zip Code.");
                return;
            }
            // Inject Spinner Styles
            if (!document.getElementById('loader-style')) {
                const style = document.createElement('style');
                style.id = 'loader-style';
                style.innerHTML = `@keyframes spinner { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }`;
                document.head.appendChild(style);
            }

            retailerList.innerHTML = `
                <div style="padding:24px;text-align:center;color:var(--deep-purple);">
                    <div style="border: 4px solid #f3f3f3; border-top: 4px solid var(--accent-purple); border-radius: 50%; width: 24px; height: 24px; animation: spinner 1s linear infinite; margin: 0 auto 12px auto;"></div>
                    <p style="margin:0; font-weight:500;">Locating nearby stores...</p>
                </div>`;

            // Auto-scroll to loader so user sees feedback immediately
            retailerList.scrollIntoView({ behavior: 'smooth', block: 'nearest' });

            // 1. Geocode Zip (Nominatim)
            const geoUrl = `https://nominatim.openstreetmap.org/search?postalcode=${zip}&country=USA&format=json&limit=1`;

            fetch(geoUrl)
                .then(r => r.json())
                .then(geoData => {
                    if (!geoData || geoData.length === 0) {
                        retailerList.innerHTML = '<p style="padding:16px;text-align:center;color:red;">Zip Code not found.</p>';
                        return;
                    }
                    const lat = parseFloat(geoData[0].lat);
                    const lon = parseFloat(geoData[0].lon);

                    const mapsUrl = `https://www.google.com/maps/search/lottery+retailer/@${lat},${lon},14z`;

                    // 2. Fetch Retailers (Overpass API)
                    // Reduced radius to 5km and increased timeout to fix 504s via LZ4 mirror
                    const radius = 5000;
                    const query = `[out:json][timeout:45];(node["shop"="lottery"](around:${radius},${lat},${lon});node["shop"="convenience"](around:${radius},${lat},${lon});node["amenity"="fuel"](around:${radius},${lat},${lon}););out body 15;`;

                    const url = `https://lz4.overpass-api.de/api/interpreter?data=${encodeURIComponent(query)}`;

                    fetch(url)
                        .then(r => {
                            if (!r.ok) throw new Error(`Overpass Status ${r.status}`);
                            return r.json();
                        })
                        .then(data => {
                            retailerList.innerHTML = '';
                            let elements = data.elements || [];

                            if (elements.length === 0) {
                                retailerList.innerHTML = `
                                    <div style="text-align:center; padding:16px;">
                                        <p style="color:#666; margin-bottom:8px;">No verified retailers found via API.</p>
                                        <a href="${mapsUrl}" target="_blank" style="font-weight:600; color:var(--deep-purple);">
                                            Search on Google Maps &rarr;
                                        </a>
                                    </div>`;
                                return;
                            }

                            // Calculate distances and process
                            let realStores = elements.map(e => {
                                const distKm = getDistanceFromLatLonInKm(lat, lon, e.lat, e.lon);
                                let name = e.tags.name;
                                if (!name) {
                                    const type = e.tags.shop || "Retailer";
                                    name = type.charAt(0).toUpperCase() + type.slice(1);
                                }

                                return {
                                    name: name,
                                    lat: e.lat,
                                    lon: e.lon,
                                    distVal: distKm,
                                    distStr: (distKm * 0.621371).toFixed(2) + " mi",
                                    hours: e.tags.opening_hours ? formatHours(e.tags.opening_hours) : "Hours: Check Store",
                                    phone: e.tags["phone"] || e.tags["contact:phone"] || null
                                };
                            })
                                .filter(s => s.name)
                                .sort((a, b) => a.distVal - b.distVal)
                                .slice(0, 10);

                            // Render
                            realStores.forEach((store, idx) => {
                                const item = document.createElement('div');
                                item.className = 'retailer-item';

                                const navUrl = `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(store.name)}&destination_place_id=${store.lat},${store.lon}`;

                                const badge = (idx === 0) ?
                                    `<span style="background:#22c55e; color:white; font-size:0.6rem; padding:2px 6px; border-radius:4px; margin-left:6px;">Nearest & Open</span>` :
                                    (store.hours.includes("Check") ? "" : `<span style="color:#22c55e; font-size:0.7rem; margin-left:4px;">● Open</span>`);

                                item.innerHTML = `
                                    <div style="flex:1;">
                                        <div style="font-weight:600; font-size:0.9rem; color:var(--deep-purple); display:flex; align-items:center;">
                                            ${store.name} ${badge}
                                        </div>
                                        <div style="font-size:0.75rem; color:#666; margin-top:2px;">
                                            ${store.distStr} • <span style="font-weight:500;">${store.hours}</span>
                                        </div>

                                    </div>
                                    <a href="${navUrl}" target="_blank" 
                                       style="background:var(--accent-purple); color:white; text-decoration:none; padding:8px 12px; border-radius:8px; font-size:0.75rem; font-weight:600;">
                                        Navigate
                                    </a>
                                `;
                                retailerList.appendChild(item);
                            });

                            // Auto-scroll to results to show stores immediately
                            setTimeout(() => {
                                retailerList.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
                            }, 100);
                        })
                        .catch(err => {
                            console.error("Overpass API Error:", err);
                            retailerList.innerHTML = `<p style="padding:16px;text-align:center;color:red;">Error fetching live data. <a href="${mapsUrl}" target="_blank">Use Map Search</a></p>`;
                        });

                })
                .catch(err => {
                    console.error("Geocoding Error:", err);
                    retailerList.innerHTML = `<p style="padding:16px;text-align:center;color:red;">Error finding zip code location.</p>`;
                });

        });
    }
    // --- Edit Profile Logic ---
    const openEditBtn = document.getElementById('open-edit-profile-btn');
    const editModal = document.getElementById('edit-modal');
    const saveProfileBtn = document.getElementById('save-profile-btn');

    // Edit Modal Elements
    const editTobNaCheckbox = document.getElementById('edit-tob-na-checkbox');
    const editTimeContainer = document.getElementById('edit-time-container');
    const editTobNaMessage = document.getElementById('edit-tob-na-message');
    const editTimeInput = document.getElementById('edit-time');

    // Toggle Edit "Don't Know" Logic
    if (editTobNaCheckbox) {
        editTobNaCheckbox.addEventListener('change', (e) => {
            const isChecked = e.target.checked;
            if (isChecked) {
                editTimeContainer.style.display = 'none';
                editTobNaMessage.style.display = 'block';
                editTimeInput.value = '';
            } else {
                editTimeContainer.style.display = 'block';
                editTobNaMessage.style.display = 'none';
            }
        });
    }

    if (openEditBtn) {
        openEditBtn.addEventListener('click', () => {
            const userStr = localStorage.getItem('currentUser');
            if (!userStr) return;
            const user = JSON.parse(userStr);

            document.getElementById('edit-firstname').value = user.firstName || "";
            document.getElementById('edit-middlename').value = user.middleName || "";
            document.getElementById('edit-lastname').value = user.lastName || "";

            // Phone Populate
            const fullPhone = user.phoneNumber || "";
            const spaceIdx = fullPhone.indexOf(' ');
            const codeEl = document.getElementById('edit-country-code');
            const phoneEl = document.getElementById('edit-phone');

            if (spaceIdx > 0 && fullPhone.startsWith('+')) {
                if (codeEl) codeEl.value = fullPhone.substring(0, spaceIdx);
                if (phoneEl) phoneEl.value = fullPhone.substring(spaceIdx + 1);
            } else {
                if (phoneEl) phoneEl.value = fullPhone;
            }

            document.getElementById('edit-dob').value = user.dob || "";
            document.getElementById('edit-place').value = user.birth_place || "";

            // Smart Time Populate
            if (user.birth_time) {
                editTimeInput.value = user.birth_time;
                if (editTobNaCheckbox) editTobNaCheckbox.checked = false;
                if (editTimeContainer) editTimeContainer.style.display = 'block';
                if (editTobNaMessage) editTobNaMessage.style.display = 'none';
            } else {
                editTimeInput.value = '';
                if (editTobNaCheckbox) editTobNaCheckbox.checked = true;
                if (editTimeContainer) editTimeContainer.style.display = 'none';
                if (editTobNaMessage) editTobNaMessage.style.display = 'block';
            }

            // Current Location
            const editCurrentLocation = document.getElementById('edit-current-location');
            if (editCurrentLocation) {
                editCurrentLocation.value = user.current_location || user.birth_place || '';
            }

            if (editModal) editModal.style.display = 'flex';
        });
    }

    // Toggle Edit Location Info
    const editLocationInfoBtn = document.getElementById('edit-location-info-btn');
    const editLocationExplainer = document.getElementById('edit-location-explainer');
    if (editLocationInfoBtn && editLocationExplainer) {
        editLocationInfoBtn.addEventListener('click', (e) => {
            e.preventDefault();
            editLocationExplainer.style.display = editLocationExplainer.style.display === 'none' ? 'block' : 'none';
        });
    }

    if (saveProfileBtn) {
        saveProfileBtn.addEventListener('click', async () => {
            const userStr = localStorage.getItem('currentUser');
            if (!userStr) return;
            const currentUser = JSON.parse(userStr);

            const newFirst = document.getElementById('edit-firstname').value.trim();
            const newMiddle = document.getElementById('edit-middlename').value.trim();
            const newLast = document.getElementById('edit-lastname').value.trim();

            const phoneCode = document.getElementById('edit-country-code').value;
            const phoneNum = document.getElementById('edit-phone').value.trim();
            const newPhone = phoneNum ? `${phoneCode} ${phoneNum}` : "";

            const newDob = document.getElementById('edit-dob').value;
            let newTime = document.getElementById('edit-time').value;
            const newPlace = document.getElementById('edit-place').value.trim();
            const newCurrentLocation = document.getElementById('edit-current-location')?.value.trim() || '';

            // Respect Checkbox
            const isNa = document.getElementById('edit-tob-na-checkbox')?.checked;
            if (isNa) newTime = "";

            if (!newFirst || !newDob) {
                alert("First Name and Date of Birth are valid required fields.");
                return;
            }

            saveProfileBtn.textContent = "Saving...";
            saveProfileBtn.disabled = true;

            try {
                // Geocode Current Location if provided
                let currentCoords = null;
                if (newCurrentLocation) {
                    currentCoords = await geocodeCity(newCurrentLocation);
                    if (!currentCoords) {
                        alert("Could not find current location '" + newCurrentLocation + "'. Please validate the city and country name.");
                        saveProfileBtn.textContent = "Save Changes";
                        saveProfileBtn.disabled = false;
                        return;
                    }
                }

                // Update Firestore
                const userRef = doc(db, "users", currentUser.uid);
                const fullName = `${newFirst} ${newMiddle ? newMiddle + ' ' : ''}${newLast}`.trim();

                const updates = {
                    firstName: newFirst,
                    middleName: newMiddle,
                    lastName: newLast,
                    name: fullName,
                    phoneNumber: newPhone,
                    dob: newDob,
                    birth_time: newTime, // Note: Schema uses 'birth_time'
                    birth_place: newPlace, // Note: Schema uses 'birth_place'
                    current_location: newCurrentLocation,
                    current_lat: currentCoords ? currentCoords.lat : currentUser.current_lat,
                    current_lon: currentCoords ? currentCoords.lon : currentUser.current_lon
                };

                await updateDoc(userRef, updates);

                // Update Local Storage
                const updatedUser = { ...currentUser, ...updates };
                localStorage.setItem('currentUser', JSON.stringify(updatedUser));

                // Update Dashboard UI Immediately
                const dashName = document.getElementById('dashboard-name-display');
                const dashDob = document.getElementById('dashboard-dob-display');
                const dashTime = document.getElementById('dashboard-time-display');
                const dashPlace = document.getElementById('dashboard-place-display');
                const dashPhone = document.getElementById('dashboard-phone-display');
                const dashLocation = document.getElementById('dashboard-location-display');
                const dashUserHeader = document.getElementById('dashboard-user-name');
                const greeting = document.getElementById('user-greeting');

                if (dashName) dashName.textContent = fullName;
                if (dashPhone) dashPhone.textContent = newPhone;
                if (dashDob) dashDob.textContent = new Date(newDob).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
                if (dashTime) dashTime.textContent = newTime ? newTime : "--";
                if (dashPlace) dashPlace.textContent = newPlace;
                if (dashLocation) dashLocation.textContent = newCurrentLocation || "--";
                if (dashUserHeader) dashUserHeader.textContent = newFirst;
                if (greeting) greeting.textContent = "Hi, " + newFirst;

                alert("Profile Updated Successfully!");
                if (editModal) editModal.style.display = 'none';

            } catch (error) {
                console.error("Update failed:", error);
                alert("Failed to update profile: " + error.message);
            } finally {
                saveProfileBtn.textContent = "Save Changes";
                saveProfileBtn.disabled = false;
            }
        });
    }

});

// Helper: Haversine Distance (Km)
function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of earth in km
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

function deg2rad(deg) {
    return deg * (Math.PI / 180);
}

// Helper: Simple formatter for OSM opening_hours (often complex strings)
function formatHours(osmHours) {
    if (!osmHours) return "Hours: Check Store";
    // Try to simplify common formats
    if (osmHours.includes("24/7")) return "Open 24 Hours";
    if (osmHours.length > 20) return "See hours on map";
    return osmHours;
}


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

// --- Profile Card Collapse Logic ---
const profileHeader = document.getElementById('profile-card-header');
if (profileHeader) {
    profileHeader.addEventListener('click', (e) => {
        // Don't toggle if edit button was clicked
        if (e.target.closest('#open-edit-profile-btn')) return;

        const content = document.getElementById('profile-card-content');
        const arrow = document.getElementById('profile-card-arrow');

        if (content.style.display === 'none') {
            content.style.display = 'block';
            if (arrow) arrow.style.transform = 'rotate(0deg)';
        } else {
            content.style.display = 'none';
            if (arrow) arrow.style.transform = 'rotate(-90deg)';
        }
    });
}

// 4. Cosmic Countdown
function startCosmicCountdown() {
    const timerEl = document.getElementById('cosmic-countdown');
    if (!timerEl) return;

    function update() {
        const now = new Date();
        const tomorrow = new Date(now);
        tomorrow.setUTCHours(24, 0, 0, 0); // Next UTC Midnight

        const diff = tomorrow - now;
        if (diff <= 0) {
            timerEl.textContent = "00:00:00";
            return;
        }

        const h = Math.floor(diff / (1000 * 60 * 60));
        const m = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        const s = Math.floor((diff % (1000 * 60)) / 1000);

        const pad = (n) => n.toString().padStart(2, '0');
        timerEl.textContent = `${pad(h)}:${pad(m)}:${pad(s)}`;
    }

    update(); // Init
    setInterval(update, 1000);
}

// --- Lottery View Logic ---
// Cache duration: 1 hour (in milliseconds)
const LOTTERY_CACHE_DURATION = 60 * 60 * 1000; // 1 hour

window.fetchLotteryNumbers = async (count = 5, forceRefresh = false) => {
    const user = JSON.parse(localStorage.getItem('currentUser'));
    if (!user) {
        console.error("No user found for lottery fetch");
        return;
    }

    // Check if we have cached lottery data that's still valid (less than 1 hour old)
    const cachedData = localStorage.getItem('lastLotteryData');
    if (cachedData && !forceRefresh) {
        const data = JSON.parse(cachedData);
        const generatedAt = new Date(data.generated_at);
        const now = new Date();
        const ageMs = now - generatedAt;

        if (ageMs < LOTTERY_CACHE_DURATION && data.personal_powerball) {
            console.log(`📊 Using cached lottery numbers (${Math.round(ageMs / 60000)} min old)`);
            // Render cached data
            if (window.renderPowerball) window.renderPowerball(data.personal_powerball, data.daily_powerballs);
            return;
        } else {
            console.log(`🔄 Cache expired (${Math.round(ageMs / 60000)} min old), fetching new numbers...`);
        }
    }

    console.log("Fetching Lottery Numbers for:", user.name);
    // UI Loading
    const list = document.getElementById('daily-powerballs-list');
    if (list) list.innerHTML = '<div style="text-align:center; padding:20px; color:var(--deep-purple);">🔮 Decoding Cosmic Numbers...</div>';

    // Prepare Request
    const req = {
        name: user.name,
        dob: user.dob,
        birth_time: user.birth_time || "12:00",
        birth_place_name: user.birth_place || "Unknown",
        birth_lat: user.birth_lat,
        birth_lon: user.birth_lon,
        timezone: user.timezone || "UTC",
        uid: user.uid || "guest",
        date: new Date().toISOString().split('T')[0],
        provided_luck_score: window.currentLuckScore, // Ensure consistency
        powerball_count: count // Add count
    };

    try {
        const result = await window.celestialAPI.calculateLottery(req);
        if (window.renderPowerball) window.renderPowerball(result.personal_powerball, result.daily_powerballs);
    } catch (e) {
        console.error("Lottery Fetch Error:", e);
        if (list) list.innerHTML = '<div style="text-align:center; color:red; padding:20px;">Failed to decode numbers. Try again.</div>';
    }
};

// ============================================================================
// LUCKY NUMBERS CALCULATION (Numerology-based)
// ============================================================================

function calculateAndDisplayLuckyNumbers() {
    const user = JSON.parse(localStorage.getItem('currentUser'));
    if (!user) return;

    const dob = user.dob || '2000-01-01';
    const name = user.name || 'User';

    // Calculate permanent numbers (based on birth date & name)
    const lifePathNumber = calculateLifePathNumber(dob);
    const soulNumber = calculateSoulNumber(name);
    const destinyNumber = calculateDestinyNumber(name);
    const masterNumber = calculateMasterNumber(dob, name);

    // Calculate daily lucky numbers (changes each day)
    const dailyNumbers = calculateDailyLuckyNumbers(dob, name);

    // Update permanent numbers display
    const permanentDiv = document.getElementById('permanent-lucky-numbers');
    if (permanentDiv) {
        permanentDiv.innerHTML = `
            <div style="display: flex; flex-direction: column; align-items: center; gap: 4px;">
                <span style="width: 44px; height: 44px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #8b5cf6, #6366f1); border-radius: 50%; font-weight: 700; font-size: 1.1rem; color: white; box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3);">${lifePathNumber}</span>
                <span style="font-size: 0.6rem; color: #888;">Life Path</span>
            </div>
            <div style="display: flex; flex-direction: column; align-items: center; gap: 4px;">
                <span style="width: 44px; height: 44px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #8b5cf6, #6366f1); border-radius: 50%; font-weight: 700; font-size: 1.1rem; color: white; box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3);">${soulNumber}</span>
                <span style="font-size: 0.6rem; color: #888;">Soul</span>
            </div>
            <div style="display: flex; flex-direction: column; align-items: center; gap: 4px;">
                <span style="width: 44px; height: 44px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #8b5cf6, #6366f1); border-radius: 50%; font-weight: 700; font-size: 1.1rem; color: white; box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3);">${destinyNumber}</span>
                <span style="font-size: 0.6rem; color: #888;">Destiny</span>
            </div>
            <div style="display: flex; flex-direction: column; align-items: center; gap: 4px;">
                <span style="width: 44px; height: 44px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #8b5cf6, #6366f1); border-radius: 50%; font-weight: 700; font-size: 1.1rem; color: white; box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3);">${masterNumber}</span>
                <span style="font-size: 0.6rem; color: #888;">Master</span>
            </div>
        `;
    }

    // Update daily numbers display
    const dailyDiv = document.getElementById('daily-lucky-numbers');
    if (dailyDiv) {
        dailyDiv.innerHTML = dailyNumbers.map(num => `
            <span style="width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #fbbf24, #f59e0b); border-radius: 50%; font-weight: 700; font-size: 0.95rem; color: white; box-shadow: 0 3px 10px rgba(251, 191, 36, 0.3);">${num}</span>
        `).join('');
    }

    // Update date display
    const dateSpan = document.getElementById('lucky-numbers-date');
    if (dateSpan) {
        dateSpan.textContent = new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }
}

// Reduce number to single digit (except master numbers 11, 22, 33)
function reduceToSingleDigit(num, keepMaster = false) {
    while (num > 9) {
        if (keepMaster && (num === 11 || num === 22 || num === 33)) return num;
        num = String(num).split('').reduce((a, b) => a + parseInt(b), 0);
    }
    return num;
}

// Life Path Number: Sum of all birth date digits
function calculateLifePathNumber(dob) {
    const digits = dob.replace(/-/g, '').split('').map(Number);
    const sum = digits.reduce((a, b) => a + b, 0);
    return reduceToSingleDigit(sum, true);
}

// Soul Number: Sum of vowels in name
function calculateSoulNumber(name) {
    const vowels = 'aeiouAEIOU';
    const letterValues = { a: 1, e: 5, i: 9, o: 6, u: 3 };
    let sum = 0;
    for (const char of name) {
        if (vowels.includes(char)) {
            sum += letterValues[char.toLowerCase()] || 0;
        }
    }
    return reduceToSingleDigit(sum) || 1;
}

// Destiny Number: Sum of consonants in name
function calculateDestinyNumber(name) {
    const vowels = 'aeiouAEIOU';
    let sum = 0;
    for (const char of name) {
        if (/[a-zA-Z]/.test(char) && !vowels.includes(char)) {
            sum += (char.toLowerCase().charCodeAt(0) - 96) % 9 || 9;
        }
    }
    return reduceToSingleDigit(sum) || 1;
}

// Master Number: Special calculation combining birth and name energy
function calculateMasterNumber(dob, name) {
    const lifePathNum = calculateLifePathNumber(dob);
    const nameSum = name.split('').reduce((sum, char) => {
        if (/[a-zA-Z]/.test(char)) {
            return sum + ((char.toLowerCase().charCodeAt(0) - 96) % 9 || 9);
        }
        return sum;
    }, 0);
    const combined = lifePathNum + reduceToSingleDigit(nameSum);
    return reduceToSingleDigit(combined, true);
}

// Daily Lucky Numbers: 4 numbers based on today's date + user's birth energy
function calculateDailyLuckyNumbers(dob, name) {
    const today = new Date();
    const dayOfYear = Math.floor((today - new Date(today.getFullYear(), 0, 0)) / (1000 * 60 * 60 * 24));
    const lifePathNum = calculateLifePathNumber(dob);
    const nameValue = name.split('').reduce((sum, char) => sum + char.charCodeAt(0), 0);

    // Generate 4 unique numbers between 1-99 based on seed
    const seed = (dayOfYear * 1000 + lifePathNum * 100 + nameValue) % 10000;
    const numbers = [];
    let seedVal = seed;

    while (numbers.length < 4) {
        seedVal = (seedVal * 9301 + 49297) % 233280; // LCG for pseudo-random
        const num = (seedVal % 69) + 1; // 1-69 range for Powerball compatibility
        if (!numbers.includes(num)) {
            numbers.push(num);
        }
    }

    return numbers.sort((a, b) => a - b);
}

// Handler for Lottery Button Click (with Animation)
window.handleLotteryClick = async () => {
    const btn = document.getElementById('lottery-reveal-btn');
    const btnText = btn ? btn.querySelector('.btn-text') : null;

    if (btn) {
        btn.disabled = true;
        btn.classList.add('loading');
        if (btnText) btnText.style.display = 'none';
    }

    try {
        // Fetch lottery numbers
        await window.fetchLotteryNumbers();

        // Navigate to Lottery Result View
        document.querySelectorAll('.view').forEach(v => {
            v.style.display = 'none';
            v.classList.remove('active');
        });
        const lotteryResultView = document.getElementById('lucky-number-result');
        if (lotteryResultView) {
            lotteryResultView.style.display = 'block';
            lotteryResultView.classList.add('active');
        }
        history.pushState({ view: 'lucky-number-result' }, 'Lucky Number Result', '#lucky-number-result');

        // Calculate and display lucky numbers
        calculateAndDisplayLuckyNumbers();

        // Show user menu
        const userMenuContainer = document.getElementById('user-menu-container');
        if (userMenuContainer) userMenuContainer.style.display = 'flex';

        // Show global back button
        const resultBackBtnContainer = document.getElementById('result-back-btn-container');
        if (resultBackBtnContainer) resultBackBtnContainer.style.display = 'block';

    } catch (error) {
        console.error("Lottery Click Error:", error);
        alert("Failed to decode lucky numbers. Please try again.");
    } finally {
        if (btn) {
            btn.disabled = false;
            btn.classList.remove('loading');
            if (btnText) btnText.style.display = 'inline-block';
        }
    }
};

// Toggle Powerball Card
window.togglePowerballCard = () => {
    const content = document.getElementById('powerball-content');
    const arrow = document.getElementById('pb-card-arrow');
    if (content && arrow) {
        if (content.style.display === 'none') {
            content.style.display = 'block';
            arrow.textContent = '▲';
        } else {
            content.style.display = 'none';
            arrow.textContent = '▼';
        }
    }
};


// === Modal Listeners ===

// Generate Request Button - Event listener is already set in the DOMContentLoaded block above
// Removed duplicate listener to prevent double API calls

// Retailer Search Logic
const findRetailersBtn = document.getElementById('find-retailers-btn');
if (findRetailersBtn) {
    findRetailersBtn.addEventListener('click', () => {
        const zip = document.getElementById('retailer-zip').value;
        const list = document.getElementById('retailer-list');
        if (!list) return;

        if (!zip) {
            list.style.padding = '15px';
            list.innerHTML = '<span style="color:red; font-size:0.8rem;">Please enter a Zip Code</span>';
            return;
        }

        // Mock Data
        list.innerHTML = `
                <div style="padding: 15px; border-bottom: 1px solid #eee;">
                     <div style="display:flex; justify-content:space-between;">
                        <strong>Lucky Market</strong>
                        <span style="font-size: 0.8rem; color: #666;">1.2 mi</span>
                     </div>
                     <div style="font-size:0.75rem; color:#888;">123 Star Ave</div>
                </div>
                <div style="padding: 15px; border-bottom: 1px solid #eee;">
                     <div style="display:flex; justify-content:space-between;">
                        <strong>Corner Store</strong>
                        <span style="font-size: 0.8rem; color: #666;">2.5 mi</span>
                     </div>
                     <div style="font-size:0.75rem; color:#888;">456 Moon St</div>
                </div>
             `;
    });
}

// Lottery Home Button
const lotteryHomeBtn = document.getElementById('lottery-home-btn');
if (lotteryHomeBtn) {
    lotteryHomeBtn.addEventListener('click', () => {
        // Navigate back to dashboard
        document.querySelectorAll('.view').forEach(v => {
            v.style.display = 'none';
            v.classList.remove('active');
        });
        const dashboardView = document.getElementById('dashboard-view');
        if (dashboardView) {
            dashboardView.style.display = 'block';
            dashboardView.classList.add('active');
        }
        history.pushState({ view: 'dashboard' }, 'Dashboard', '#dashboard');
    });
}

// Animate Lottery Percentage (gold ring)
window.animateLotteryPercentage = (percentage) => {
    const ring = document.querySelector('.lottery-ring-fill');
    const percentEl = document.getElementById('lottery-result-percentage');
    if (!ring || !percentEl) return;

    const circumference = 2 * Math.PI * 90;
    ring.style.strokeDasharray = circumference;
    ring.style.strokeDashoffset = circumference;
    ring.style.stroke = '#f59e0b'; // Gold color

    // Animate ring
    setTimeout(() => {
        const offset = circumference - (percentage / 100) * circumference;
        ring.style.transition = 'stroke-dashoffset 1.5s ease-out';
        ring.style.strokeDashoffset = offset;
    }, 100);

    // Animate number
    let current = 0;
    const duration = 1500;
    const step = percentage / (duration / 16);
    const interval = setInterval(() => {
        current += step;
        if (current >= percentage) {
            current = percentage;
            clearInterval(interval);
        }
        percentEl.textContent = Math.round(current);
    }, 16);
};

startCosmicCountdown();

// Global Back Button Handler
const globalBackBtn = document.getElementById('global-back-btn');
if (globalBackBtn) {
    globalBackBtn.addEventListener('click', () => {
        history.back();
    });
}

// Global function to navigate to dashboard
window.goToDashboard = function () {
    // Hide all views
    document.querySelectorAll('.view').forEach(v => {
        v.style.display = 'none';
        v.classList.remove('active');
    });

    // Show dashboard
    const dashboardView = document.getElementById('dashboard-view');
    if (dashboardView) {
        dashboardView.style.display = 'block';
        dashboardView.classList.add('active');
    }

    // Show user menu
    const userMenuContainer = document.getElementById('user-menu-container');
    if (userMenuContainer) userMenuContainer.style.display = 'flex';

    // Update URL
    history.pushState({ view: 'dashboard' }, 'Dashboard', '#dashboard');
};

// Global function to navigate to guest input
window.goToGuestInput = function () {
    // Hide all views
    document.querySelectorAll('.view').forEach(v => {
        v.style.display = 'none';
        v.classList.remove('active');
    });

    // Show guest input view
    const inputView = document.getElementById('input-view');
    if (inputView) {
        inputView.style.display = 'block';
        inputView.classList.add('active');
    }

    // Clear guest session data and form fields
    sessionStorage.removeItem('guestSession');

    const nameInput = document.getElementById('name');
    const dobInput = document.getElementById('dob');
    const placeInput = document.getElementById('birth-place');
    const timeInput = document.getElementById('birth-time');
    const tobCheckbox = document.getElementById('tob-na-checkbox');
    const timeContainer = document.getElementById('time-inputs-container');
    const naMessage = document.getElementById('tob-na-message');

    if (nameInput) nameInput.value = '';
    if (dobInput) dobInput.value = '';
    if (placeInput) placeInput.value = '';
    if (timeInput) timeInput.value = '';
    if (tobCheckbox) tobCheckbox.checked = false;
    if (timeContainer) timeContainer.style.display = 'block';
    if (naMessage) naMessage.style.display = 'none';

    // Hide user menu (guest flow)
    const userMenuContainer = document.getElementById('user-menu-container');
    if (userMenuContainer) userMenuContainer.style.display = 'none';

    // Update URL
    history.pushState({ view: 'guest' }, 'Guest', '#guest');
};

// Smart back function - checks if guest or logged in
window.goBack = function () {
    const hash = window.location.hash;
    if (hash === '#guest-daily-luck-result') {
        window.goToGuestInput();
    } else {
        window.goToDashboard();
    }
};

// Show signup prompt for guest users trying to access lucky numbers
window.showSignupPrompt = function () {
    openModal('signup-prompt');
};
