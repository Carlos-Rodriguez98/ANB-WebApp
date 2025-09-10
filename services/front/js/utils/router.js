// Simple SPA Router
class Router {
    constructor() {
        this.routes = new Map();
        this.currentRoute = null;
        this.init();
    }

    // Initialize router
    init() {
        // Handle browser back/forward buttons
        window.addEventListener('popstate', () => {
            this.handleRoute();
        });

        // Handle initial page load
        this.handleRoute();
    }

    // Register a route
    addRoute(path, handler, requiresAuth = false) {
        this.routes.set(path, { handler, requiresAuth });
    }

    // Navigate to a route
    navigate(path, replace = false) {
        if (replace) {
            history.replaceState(null, '', path);
        } else {
            history.pushState(null, '', path);
        }
        this.handleRoute();
    }

    // Handle current route
    async handleRoute() {
        const path = window.location.pathname;
        const route = this.findRoute(path);

        if (!route) {
            this.render404();
            return;
        }

        // Check authentication if required
        if (route.requiresAuth && !Auth.isAuthenticated()) {
            Toast.show('Please login to access this page', 'warning');
            this.navigate('/login', true);
            return;
        }

        this.currentRoute = path;
        
        try {
            // Check if handler function exists
            if (typeof route.handler !== 'function') {
                console.error('Route handler is not a function:', route.handler);
                this.render500();
                return;
            }
            
            await route.handler(path);
            
            // Re-render navbar after page change
            if (window.renderNavbar) {
                renderNavbar();
            }
        } catch (error) {
            console.error('Route handler error:', error);
            this.render500();
        }
    }

    // Find matching route (supports dynamic segments)
    findRoute(path) {
        // Exact match first
        if (this.routes.has(path)) {
            return this.routes.get(path);
        }

        // Dynamic route matching
        for (const [routePath, routeData] of this.routes) {
            const match = this.matchRoute(routePath, path);
            if (match) {
                return { ...routeData, params: match.params };
            }
        }

        return null;
    }

    // Match route with dynamic segments (:id)
    matchRoute(routePath, currentPath) {
        const routeSegments = routePath.split('/');
        const pathSegments = currentPath.split('/');

        if (routeSegments.length !== pathSegments.length) {
            return null;
        }

        const params = {};

        for (let i = 0; i < routeSegments.length; i++) {
            const routeSegment = routeSegments[i];
            const pathSegment = pathSegments[i];

            if (routeSegment.startsWith(':')) {
                // Dynamic segment
                const paramName = routeSegment.slice(1);
                params[paramName] = pathSegment;
            } else if (routeSegment !== pathSegment) {
                // Static segment doesn't match
                return null;
            }
        }

        return { params };
    }

    // Render 404 page
    render404() {
        const app = document.getElementById('app');
        app.innerHTML = `
            <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
                <div class="max-w-md w-full space-y-8 text-center">
                    <div>
                        <i class="fas fa-basketball-ball text-6xl text-primary-500 mb-8"></i>
                        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
                            Page Not Found
                        </h2>
                        <p class="mt-2 text-center text-sm text-gray-600">
                            The page you're looking for doesn't exist.
                        </p>
                    </div>
                    <div>
                        <button 
                            onclick="Router.navigate('/')" 
                            class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                        >
                            <i class="fas fa-home mr-2"></i>
                            Go Home
                        </button>
                    </div>
                </div>
            </div>
        `;
    }

    // Render 500 error page
    render500() {
        const app = document.getElementById('app');
        app.innerHTML = `
            <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
                <div class="max-w-md w-full space-y-8 text-center">
                    <div>
                        <i class="fas fa-exclamation-triangle text-6xl text-red-500 mb-8"></i>
                        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
                            Server Error
                        </h2>
                        <p class="mt-2 text-center text-sm text-gray-600">
                            Something went wrong. Please try again later.
                        </p>
                    </div>
                    <div>
                        <button 
                            onclick="Router.navigate('/')" 
                            class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                        >
                            <i class="fas fa-home mr-2"></i>
                            Go Home
                        </button>
                    </div>
                </div>
            </div>
        `;
    }

    // Get current route parameters
    getParams() {
        const route = this.findRoute(this.currentRoute);
        return route?.params || {};
    }
}

// Create global router instance
window.Router = new Router();
