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

    // Spinner component
    window.LoadingSpinner = function(message = 'Cargando...') {
        return `
            <div class="flex flex-col items-center justify-center py-12">
                <div class="spinner w-8 h-8 border-4 border-gray-200 border-t-primary-600 rounded-full animate-spin mb-4"></div>
                <p class="text-gray-600">${message}</p>
            </div>
        `;
    };

    // Pagination component
    window.Pagination = function({ currentPage, totalPages, onPageChange }) {
        if (totalPages <= 1) return '';
        
        let paginationHTML = `
            <div class="flex items-center justify-between">
                <div class="text-sm text-gray-700">
                    Página ${currentPage} de ${totalPages}
                </div>
                <div class="flex space-x-2">
        `;

        // Bouton précédent
        if (currentPage > 1) {
            paginationHTML += `
                <button onclick="${onPageChange}(${currentPage - 1})" 
                        class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
                    Anterior
                </button>
            `;
        }

        // Pages
        for (let i = Math.max(1, currentPage - 2); i <= Math.min(totalPages, currentPage + 2); i++) {
            const isActive = i === currentPage;
            paginationHTML += `
                <button onclick="${onPageChange}(${i})" 
                        class="px-3 py-2 text-sm font-medium ${isActive ? 'text-white bg-primary-600' : 'text-gray-500 bg-white'} border border-gray-300 rounded-md hover:bg-gray-50">
                    ${i}
                </button>
            `;
        }

        // Bouton suivant
        if (currentPage < totalPages) {
            paginationHTML += `
                <button onclick="${onPageChange}(${currentPage + 1})" 
                        class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
                    Siguiente
                </button>
            `;
        }

        paginationHTML += `
                </div>
            </div>
        `;

        return paginationHTML;
    };
});
