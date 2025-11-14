// Public Video Detail Page
async function renderPublicVideoDetailPage(path) {
    const app = document.getElementById('app');
    const id = path.split('/').pop();
    app.innerHTML = LoadingSpinner();
    try {
        const video = await api.getPublicVideoById(id);
        if (!video) throw new Error('Vidéo introuvable');
        app.innerHTML = `
        <section class="container mx-auto px-4 py-8 fade-in">
          <div class="max-w-2xl mx-auto bg-white rounded-lg shadow-lg p-6">
            <h2 class="text-2xl font-bold text-primary-600 mb-4">${video.title}</h2>
            <div class="mb-4">
              <span class="badge badge-info mr-2"><i class="fas fa-user mr-1"></i>${video.playerName || video.username || 'Jugador desconocido'}</span>
              <span class="badge badge-info"><i class="fas fa-map-marker-alt mr-1"></i>${video.city || '-'}</span>
            </div>
            ${video.status === 'processed' && video.processedUrl ? VideoPlayer({ src: video.processedUrl }) : `<div class='empty-state'><div class='empty-state-description'>Video en procesamiento...</div></div>`}
            <div class="flex items-center justify-between mt-6">
              <span class="badge badge-info"><i class="fas fa-thumbs-up mr-1"></i>${video.votes ?? 0} voto${video.votes === 1 ? '' : 's'}</span>
              <button id="vote-btn" class="btn-primary ${!Auth.isAuthenticated() ? 'opacity-60 cursor-not-allowed' : ''}" ${!Auth.isAuthenticated() ? 'disabled' : ''}>Votar</button>
            </div>
            <div id="vote-error" class="form-error mt-2"></div>
            <div class="mt-4">
              <a href="/public/videos" onclick="Router.navigate('/public/videos'); return false;" class="btn-secondary">Volver a la galería</a>
            </div>
          </div>
        </section>
        `;
        // Vote handler
        const voteBtn = document.getElementById('vote-btn');
        if (voteBtn) {
            voteBtn.onclick = async () => {
                if (!Auth.isAuthenticated()) {
                    Router.navigate('/login');
                    return;
                }
                voteBtn.disabled = true;
                voteBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Votando...';
                try {
                    await api.voteForVideo(id);
                    Toast.success('¡Su voto ha sido registrado!');
                    renderPublicVideoDetailPage(`/public/videos/${id}`);
                } catch (err) {
                    document.getElementById('vote-error').textContent = err.message || 'Error al votar.';
                    if (err.message && err.message.toLowerCase().includes('déjà voté')) {
                        Toast.warning('Ya ha votado por este video.');
                    } else if (err.message && err.message.includes('401')) {
                        Router.navigate('/login');
                    } else if (err.message && err.message.includes('404')) {
                        app.innerHTML = `<div class='empty-state'><div class='empty-state-title'>Video no encontrado</div><div class='empty-state-description'>El video solicitado no existe.</div></div>`;
                    } else {
                        Toast.error(err.message || 'Error al votar.');
                    }
                } finally {
                    voteBtn.disabled = false;
                    voteBtn.textContent = 'Votar';
                }
            };
        }
    } catch (err) {
        if (err.message.includes('404') || err.message.includes('introuvable')) {
            app.innerHTML = `<div class='empty-state'><div class='empty-state-title'>Video no encontrado</div><div class='empty-state-description'>El video solicitado no existe.</div></div>`;
        } else {
            app.innerHTML = `<div class='empty-state'><div class='empty-state-title'>Error</div><div class='empty-state-description'>${err.message || 'Error inesperado.'}</div></div>`;
        }
    }
}

window.renderPublicVideoDetailPage = renderPublicVideoDetailPage;
