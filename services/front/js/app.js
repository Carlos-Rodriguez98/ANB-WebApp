// App entry point: register routes and start router

document.addEventListener('DOMContentLoaded', () => {
    // Wait a bit to ensure all scripts are loaded
    setTimeout(() => {
        console.log('Initializing ANB App...');
        
        // Check if all required functions are available
        const requiredFunctions = [
            'renderHomePage',
            'renderSignupPage', 
            'renderLoginPage',
            'renderDashboardPage',
            'renderUploadVideoPage',
            'renderVideoDetailPage',
            'renderPublicVideosPage',
            'renderPublicVideoDetailPage',
            'renderRankingsPage',
            'renderNavbar',
            'renderFooter'
        ];
        
        const missingFunctions = requiredFunctions.filter(func => typeof window[func] !== 'function');
        if (missingFunctions.length > 0) {
            console.error('Missing functions:', missingFunctions);
        }
        
        // Register routes
        Router.addRoute('/', renderHomePage);
        Router.addRoute('/signup', renderSignupPage);
        Router.addRoute('/login', renderLoginPage);
        Router.addRoute('/dashboard', renderDashboardPage, true);
        Router.addRoute('/videos/upload', renderUploadVideoPage, true);
        Router.addRoute('/videos/:id', renderVideoDetailPage, true);
        Router.addRoute('/public/videos', renderPublicVideosPage);
        Router.addRoute('/public/videos/:id', renderPublicVideoDetailPage);
        Router.addRoute('/public/rankings', renderRankingsPage);

        // Re-render navbar/footer on navigation
        window.addEventListener('popstate', () => {
            if (window.renderNavbar) renderNavbar();
            if (window.renderFooter) renderFooter();
        });

        // Initial render
        if (window.renderNavbar) renderNavbar();
        if (window.renderFooter) renderFooter();
        
        console.log('ANB App initialized successfully');
    }, 100);
});

// Expose navigation globally
window.navigate = (path) => Router.navigate(path);
