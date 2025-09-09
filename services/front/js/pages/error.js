// Error Pages
function renderErrorPage(type = 500, message = '') {
    const app = document.getElementById('app');
    let icon = 'fa-exclamation-triangle', title = 'Erreur', desc = message || "Une erreur inattendue s'est produite.";
    if (type === 401) {
        icon = 'fa-lock';
        title = 'Non autorisé';
        desc = "Vous devez être connecté pour accéder à cette page.";
    } else if (type === 403) {
        icon = 'fa-ban';
        title = 'Accès refusé';
        desc = "Vous n'avez pas accès à cette ressource.";
    } else if (type === 404) {
        icon = 'fa-search';
        title = 'Introuvable';
        desc = "La page ou la ressource demandée n'existe pas.";
    }
    app.innerHTML = `
    <div class="min-h-[60vh] flex flex-col items-center justify-center fade-in">
      <i class="fas ${icon} text-6xl text-primary-500 mb-6"></i>
      <h2 class="text-3xl font-bold mb-2">${title}</h2>
      <p class="text-gray-600 mb-6">${desc}</p>
      <a href="/" onclick="Router.navigate('/'); return false;" class="btn-primary">Retour à l'accueil</a>
    </div>
    `;
}

window.renderErrorPage = renderErrorPage;
