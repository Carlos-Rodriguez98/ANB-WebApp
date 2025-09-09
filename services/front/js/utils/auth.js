// Authentication utility
class Auth {
    static TOKEN_KEY = 'jwt_token';
    static USER_KEY = 'user_data';

    // Store JWT token and user data
    static login(token, userData) {
        localStorage.setItem(this.TOKEN_KEY, token);
        localStorage.setItem(this.USER_KEY, JSON.stringify(userData));
    }

    // Remove token and user data
    static logout() {
        localStorage.removeItem(this.TOKEN_KEY);
        localStorage.removeItem(this.USER_KEY);
    }

    // Check if user is authenticated
    static isAuthenticated() {
        const token = localStorage.getItem(this.TOKEN_KEY);
        if (!token) return false;

        // Check if token is expired (basic JWT parsing)
        try {
            const payload = JSON.parse(atob(token.split('.')[1]));
            const currentTime = Date.now() / 1000;
            
            if (payload.exp && payload.exp < currentTime) {
                // Token expired, clean up
                this.logout();
                return false;
            }
            
            return true;
        } catch (error) {
            // Invalid token format
            this.logout();
            return false;
        }
    }

    // Get current user data
    static getCurrentUser() {
        const userData = localStorage.getItem(this.USER_KEY);
        return userData ? JSON.parse(userData) : null;
    }

    // Get JWT token
    static getToken() {
        return localStorage.getItem(this.TOKEN_KEY);
    }

    // Require authentication for protected routes
    static requireAuth() {
        if (!this.isAuthenticated()) {
            Toast.show('Please login to access this page', 'warning');
            Router.navigate('/login');
            return false;
        }
        return true;
    }

    // Initialize auth state on page load
    static init() {
        // Check token validity on app start
        if (!this.isAuthenticated()) {
            this.logout(); // Clean up any invalid tokens
        }
    }
}

// Initialize auth on load
document.addEventListener('DOMContentLoaded', () => {
    Auth.init();
});
