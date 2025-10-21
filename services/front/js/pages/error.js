// Error Pages
function renderErrorPage(type = 500, message = '') {
    const app = document.getElementById('app');
    let icon = 'fa-exclamation-triangle', title = 'Error', desc = message || "Se produjo un error inesperado.";
    if (type === 401) {
        icon = 'fa-lock';
        title = 'No autorizado';
        desc = "Debe iniciar sesión para acceder a esta página.";
    } else if (type === 403) {
        icon = 'fa-ban';
        title = 'Acceso denegado';
        desc = "No tiene acceso a este recurso.";
    } else if (type === 404) {
        icon = 'fa-search';
        title = 'No encontrado';
        desc = "La página o recurso solicitado no existe.";
    }
    app.innerHTML = `
    <div class="min-h-[60vh] flex flex-col items-center justify-center fade-in">
      <i class="fas ${icon} text-6xl text-primary-500 mb-6"></i>
      <h2 class="text-3xl font-bold mb-2">${title}</h2>
      <p class="text-gray-600 mb-6">${desc}</p>
      <a href="/" onclick="Router.navigate('/'); return false;" class="btn-primary">Volver al inicio</a>
    </div>
    `;
}

window.renderErrorPage = renderErrorPage;
