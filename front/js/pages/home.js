// Home (Landing) Page
async function renderHomePage() {
    const app = document.getElementById('app');
    app.innerHTML = `
    <section class="bg-gradient-to-br from-primary-50 to-dark-800 min-h-[80vh] flex flex-col justify-center items-center py-12 fade-in">
      <div class="max-w-2xl text-center">
        <img src="https://cdn-icons-png.flaticon.com/512/861/861512.png" alt="ANB Logo" class="mx-auto h-20 w-20 mb-4">
        <h1 class="text-4xl md:text-5xl font-extrabold text-primary-600 mb-4">ANB Rising Stars Showcase</h1>
        <p class="text-lg md:text-xl text-gray-700 mb-8">La plateforme officielle de l'Association Nationale de Basketball pour révéler les nouveaux talents amateurs !<br>Inscrivez-vous, partagez vos vidéos, votez pour vos favoris et grimpez dans le classement !</p>
        <div class="flex flex-col md:flex-row justify-center gap-4 mb-6">
          <a href="/signup" onclick="event.preventDefault(); Router.navigate('/signup'); return false;" class="bg-primary-500 hover:bg-primary-600 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200 text-lg text-center">Inscription</a>
          <a href="/login" onclick="event.preventDefault(); Router.navigate('/login'); return false;" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200 text-lg text-center">Connexion</a>
          <a href="/public/videos" onclick="event.preventDefault(); Router.navigate('/public/videos'); return false;" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200 text-lg text-center">Vidéos publiques</a>
          <a href="/public/rankings" onclick="event.preventDefault(); Router.navigate('/public/rankings'); return false;" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200 text-lg text-center">Classement</a>
        </div>
      </div>
    </section>
    <section class="container mx-auto px-4 py-8 fade-in">
      <div class="grid md:grid-cols-2 gap-8">
        <div class="flex flex-col items-center">
          <i class="fas fa-basketball-ball text-5xl text-primary-500 mb-4"></i>
          <h2 class="text-2xl font-bold mb-2">Pour les joueurs</h2>
          <p class="text-gray-600 mb-2">Créez un compte, uploadez vos vidéos de skills, suivez vos votes et grimpez dans le classement national !</p>
        </div>
        <div class="flex flex-col items-center">
          <i class="fas fa-users text-5xl text-primary-500 mb-4"></i>
          <h2 class="text-2xl font-bold mb-2">Pour le public</h2>
          <p class="text-gray-600 mb-2">Découvrez les talents de demain, regardez les vidéos et votez pour vos joueurs préférés !</p>
        </div>
      </div>
    </section>
    `;
}

window.renderHomePage = renderHomePage;
