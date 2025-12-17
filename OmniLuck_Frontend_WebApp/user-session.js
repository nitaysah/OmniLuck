export function initUserSession() {
    const storedUser = localStorage.getItem('currentUser');
    const currentPath = window.location.pathname;

    // Normalize path check (handle / vs /index.html)
    const isPublicPage = currentPath.endsWith('index.html') || currentPath.endsWith('signup.html') || currentPath === '/' || currentPath.endsWith('/OmniLuck_Frontend_WebApp/');

    // Auth Check
    if (!storedUser) {
        if (!isPublicPage) {
            console.warn("No session found, redirecting to login.");
            window.location.href = 'index.html';
            return null;
        }
        return null;
    }

    let user;
    try {
        user = JSON.parse(storedUser);
    } catch (e) {
        console.error("Invalid user data", e);
        if (!isPublicPage) window.location.href = 'index.html';
        return null;
    }

    // Update Greeting
    const userGreeting = document.getElementById('user-greeting');
    const userMenuContainer = document.getElementById('user-menu-container');

    if (userGreeting && user) {
        // Use first name
        const firstName = user.name.split(' ')[0];
        userGreeting.textContent = `Hi, ${firstName}`;
    }

    if (userMenuContainer) {
        userMenuContainer.style.display = 'block';
    }

    // Toggle Dropdown
    const menuBtn = document.getElementById('user-menu-btn');
    const dropdown = document.getElementById('user-dropdown');

    if (menuBtn && dropdown) {
        // Remove existing listeners to avoid duplicates if calling init multiple times (though we shouldn't)
        const newBtn = menuBtn.cloneNode(true);
        menuBtn.parentNode.replaceChild(newBtn, menuBtn);

        newBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            dropdown.classList.toggle('show');
        });

        // Close when clicking outside
        window.addEventListener('click', (e) => {
            if (!document.getElementById('user-menu-container').contains(e.target)) {
                dropdown.classList.remove('show');
            }
        });
    }

    // Logout Logic
    const logoutBtn = document.getElementById('menu-logout-btn');
    if (logoutBtn) {
        // Clone to clear listeners
        const newLogout = logoutBtn.cloneNode(true);
        logoutBtn.parentNode.replaceChild(newLogout, logoutBtn);

        newLogout.addEventListener('click', () => {
            if (confirm('Are you sure you want to sign out?')) {
                localStorage.removeItem('currentUser');
                window.location.href = 'index.html';
            }
        });
    }

    return user;
}
