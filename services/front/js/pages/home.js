// Home (Landing) Page
async function renderHomePage() {
    const app = document.getElementById('app');
    app.innerHTML = `
    <section class="bg-gradient-to-br from-primary-50 to-dark-800 min-h-[80vh] flex flex-col justify-center items-center py-12 fade-in">
      <div class="max-w-2xl text-center">
        <img src="https://cdn-icons-png.flaticon.com/512/861/861512.png" alt="ANB Logo" class="mx-auto h-20 w-20 mb-4">
        <h1 class="text-4xl md:text-5xl font-extrabold text-primary-600 mb-4">ANB Rising Stars Showcase</h1>
        <p class="text-lg md:text-xl text-gray-700 mb-8">¡La plataforma oficial de la Asociación Nacional de Baloncesto para descubrir nuevos talentos aficionados!<br>¡Regístrate, comparte tus videos, vota por tus favoritos y escala en la clasificación!</p>
        <div class="flex flex-col md:flex-row justify-center gap-4 mb-6">
          <a href="/signup" onclick="event.preventDefault(); Router.navigate('/signup'); return false;" class="bg-primary-500 hover:bg-primary-600 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200 text-lg text-center">Registrarse</a>
          <a href="/login" onclick="event.preventDefault(); Router.navigate('/login'); return false;" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200 text-lg text-center">Iniciar Sesión</a>
          <a href="/public/videos" onclick="event.preventDefault(); Router.navigate('/public/videos'); return false;" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200 text-lg text-center">Videos Públicos</a>
          <a href="/public/rankings" onclick="event.preventDefault(); Router.navigate('/public/rankings'); return false;" class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200 text-lg text-center">Clasificación</a>
        </div>
      </div>
    </section>
    <section class="container mx-auto px-4 py-8 fade-in">
      <div class="grid md:grid-cols-2 gap-8">
        <div class="flex flex-col items-center">
          <i class="fas fa-basketball-ball text-5xl text-primary-500 mb-4"></i>
          <h2 class="text-2xl font-bold mb-2">Para los jugadores</h2>
          <p class="text-gray-600 mb-2">¡Crea una cuenta, sube tus videos de habilidades, sigue tus votos y escala en la clasificación nacional!</p>
        </div>
        <div class="flex flex-col items-center">
          <i class="fas fa-users text-5xl text-primary-500 mb-4"></i>
          <h2 class="text-2xl font-bold mb-2">Para los espectadores</h2>
          <p class="text-gray-600 mb-2">¡Descubre los talentos del mañana, mira los videos y vota por tus jugadores favoritos!</p>
        </div>
      </div>
    </section>
    `;
}

window.renderHomePage = renderHomePage;
