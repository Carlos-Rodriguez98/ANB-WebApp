// Common JavaScript for all pages
document.addEventListener('DOMContentLoaded', function() {
    // Mobile menu toggle
    const mobileMenuBtn = document.getElementById('mobile-menu-btn');
    const mobileMenu = document.getElementById('mobile-menu');
    
    if (mobileMenuBtn && mobileMenu) {
        mobileMenuBtn.addEventListener('click', function() {
            mobileMenu.classList.toggle('active');
        });
    }

    // Initialize auth state
    Auth.init();

    // Update navigation based on auth state
    updateNavigation();

    // Check if user is authenticated and update UI accordingly
    function updateNavigation() {
        const isAuth = Auth.isAuthenticated();
        const user = Auth.getCurrentUser();

        // Update navigation for authenticated users
        if (isAuth && user) {
            // Replace login/signup buttons with user info and logout
            const authButtons = document.querySelectorAll('.auth-buttons');
            authButtons.forEach(container => {
                container.innerHTML = `
                    <span class="text-gray-200 mr-2">${user.firstName || 'Usuario'}</span>
                    <a href="dashboard.html" class="btn-secondary mr-2">Mi Espacio</a>
                    <button onclick="logout()" class="btn-danger">Cerrar Sesión</button>
                `;
            });

            // Add dashboard link to main navigation
            const mainNavs = document.querySelectorAll('.main-nav');
            mainNavs.forEach(nav => {
                const dashboardLink = document.createElement('a');
                dashboardLink.href = 'dashboard.html';
                dashboardLink.className = 'text-gray-100 hover:text-primary-400 transition';
                dashboardLink.textContent = 'Mi Espacio';
                nav.appendChild(dashboardLink);
            });
        }
    }

    // Global logout function
    window.logout = function() {
        Auth.logout();
        Toast.success('¡Sesión cerrada exitosamente!');
        setTimeout(() => {
            window.location.href = '../index.html';
        }, 1000);
    };

    // Global navigation helper
    window.navigate = function(url) {
        window.location.href = url;
    };

    // Form validation helper
    window.validateForm = function(form, rules) {
        let isValid = true;
        
        // Clear previous errors
        form.querySelectorAll('.form-error').forEach(error => {
            error.textContent = '';
        });

        for (const [fieldName, fieldRules] of Object.entries(rules)) {
            const field = form[fieldName];
            const errorElement = document.getElementById(`error-${fieldName}`);
            
            if (!field) continue;

            const value = field.value.trim();
            
            for (const rule of fieldRules) {
                if (!rule.validator(value)) {
                    if (errorElement) {
                        errorElement.textContent = rule.message;
                    }
                    isValid = false;
                    break;
                }
            }
        }

        return isValid;
    };

    // Common validation rules
    window.ValidationRules = {
        required: (value) => value.length > 0,
        email: (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value),
        minLength: (min) => (value) => value.length >= min,
        match: (otherValue) => (value) => value === otherValue
    };
});
