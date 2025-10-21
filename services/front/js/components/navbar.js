// Navbar component
function renderNavbar() {
    const user = Auth.getCurrentUser();
    const isAuth = Auth.isAuthenticated();
    const nav = document.getElementById('navbar');
    if (!nav) return;

    nav.innerHTML = `
    <header class="bg-dark-900 shadow-md sticky top-0 z-40">
      <nav class="container mx-auto flex items-center justify-between px-4 py-3">
        <div class="flex items-center space-x-3">
          <a href="/" onclick="event.preventDefault(); Router.navigate('/'); return false;" class="flex items-center">
            <img src="https://cdn-icons-png.flaticon.com/512/861/861512.png" alt="ANB Logo" class="h-8 w-8 mr-2">
            <span class="text-xl font-bold text-primary-400 tracking-wide">ANB Rising Stars</span>
          </a>
        </div>
        <div class="hidden md:flex items-center space-x-6">
          <a href="/" onclick="event.preventDefault(); Router.navigate('/'); return false;" class="text-gray-100 hover:text-primary-400 transition">Inicio</a>
          <a href="/public/videos" onclick="event.preventDefault(); Router.navigate('/public/videos'); return false;" class="text-gray-100 hover:text-primary-400 transition">Videos Públicos</a>
          <a href="/public/rankings" onclick="event.preventDefault(); Router.navigate('/public/rankings'); return false;" class="text-gray-100 hover:text-primary-400 transition">Clasificación</a>
          ${isAuth ? `<a href="/dashboard" onclick="event.preventDefault(); Router.navigate('/dashboard'); return false;" class="text-gray-100 hover:text-primary-400 transition">Mi Espacio</a>` : ''}
        </div>
        <div class="hidden md:flex items-center space-x-2">
          ${isAuth ? `
            <span class="text-gray-200 mr-2">${user?.firstName || 'Usuario'}</span>
            <button onclick="Auth.logout(); Router.navigate('/login'); Toast.success('Cierre de sesión exitoso');" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200">Cerrar Sesión</button>
          ` : `
            <a href="/login" onclick="event.preventDefault(); Router.navigate('/login'); return false;" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200 mr-2">Iniciar Sesión</a>
            <a href="/signup" onclick="event.preventDefault(); Router.navigate('/signup'); return false;" class="bg-primary-500 hover:bg-primary-600 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200">Registrarse</a>
          `}
        </div>
        <!-- Mobile menu button -->
        <button id="mobile-menu-btn" class="md:hidden text-gray-100 focus:outline-none">
          <i class="fas fa-bars text-2xl"></i>
        </button>
      </nav>
      <!-- Mobile menu -->
      <div id="mobile-menu" class="mobile-menu md:hidden bg-dark-800 px-4 pb-4">
        <a href="/" onclick="event.preventDefault(); Router.navigate('/'); return false;" class="block py-2 text-gray-100 hover:text-primary-400">Inicio</a>
        <a href="/public/videos" onclick="event.preventDefault(); Router.navigate('/public/videos'); return false;" class="block py-2 text-gray-100 hover:text-primary-400">Videos Públicos</a>
        <a href="/public/rankings" onclick="event.preventDefault(); Router.navigate('/public/rankings'); return false;" class="block py-2 text-gray-100 hover:text-primary-400">Clasificación</a>
        ${isAuth ? `<a href="/dashboard" onclick="event.preventDefault(); Router.navigate('/dashboard'); return false;" class="block py-2 text-gray-100 hover:text-primary-400">Mi Espacio</a>` : ''}
        <div class="mt-2">
          ${isAuth ? `
            <span class="text-gray-200 mr-2">${user?.firstName || 'Usuario'}</span>
            <button onclick="Auth.logout(); Router.navigate('/login'); Toast.success('Cierre de sesión exitoso');" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200 w-full mt-2">Cerrar Sesión</button>
          ` : `
            <a href="/login" onclick="event.preventDefault(); Router.navigate('/login'); return false;" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200 w-full mb-2 block text-center">Iniciar Sesión</a>
            <a href="/signup" onclick="event.preventDefault(); Router.navigate('/signup'); return false;" class="bg-primary-500 hover:bg-primary-600 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200 w-full block text-center">Registrarse</a>
          `}
        </div>
      </div>
    </header>
    `;

    // Mobile menu toggle
    const btn = document.getElementById('mobile-menu-btn');
    const menu = document.getElementById('mobile-menu');
    if (btn && menu) {
        btn.onclick = () => {
            menu.classList.toggle('active');
        };
    }
}

document.addEventListener('DOMContentLoaded', renderNavbar);
window.renderNavbar = renderNavbar;
