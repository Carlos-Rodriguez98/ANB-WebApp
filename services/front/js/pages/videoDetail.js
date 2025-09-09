// Video Detail Page (My Video)
async function renderVideoDetailPage(path) {
    if (!Auth.requireAuth()) return;
    const app = document.getElementById('app');
    const id = path.split('/').pop();
    app.innerHTML = LoadingSpinner();
    try {
        const video = await api.getVideoById(id);
        if (!video) throw new Error('Vidéo introuvable');
        app.innerHTML = `
        <section class="container mx-auto px-4 py-8 fade-in">
          <div class="max-w-2xl mx-auto bg-white rounded-lg shadow-lg p-6">
            <h2 class="text-2xl font-bold text-primary-600 mb-4">Détail de la vidéo</h2>
            <div class="mb-4">
              <strong>Titre :</strong> ${video.title}<br>
              <strong>Statut :</strong> <span class="badge ${video.status === 'processed' ? 'badge-success' : 'badge-info'}">${video.status === 'processed' ? 'Traité' : 'En cours'}</span><br>
              <strong>Date upload :</strong> ${video.uploadedAt ? new Date(video.uploadedAt).toLocaleString() : '-'}<br>
              <strong>Date traitement :</strong> ${video.processedAt ? new Date(video.processedAt).toLocaleString() : '-'}<br>
              <strong>Votes :</strong> ${video.votes ?? 0}<br>
            </div>
            ${video.status === 'processed' && video.processedUrl ? VideoPlayer({ src: video.processedUrl }) : `<div class='empty-state'><div class='empty-state-description'>Vidéo en cours de traitement...</div></div>`}
            <div class="flex items-center justify-between mt-6">
              <a href="/dashboard" onclick="Router.navigate('/dashboard'); return false;" class="btn-secondary">Retour</a>
              <div class="flex space-x-2">
                ${video.status === 'processed' && video.processedUrl ? `<a href="${video.processedUrl}" download class="btn-secondary"><i class="fas fa-download mr-1"></i>Télécharger</a>` : ''}
                ${video.status !== 'processed' ? `<button class="btn-danger" onclick="deleteVideo('${video.id}')">Supprimer</button>` : ''}
              </div>
            </div>
          </div>
        </section>
        `;
        window.deleteVideo = async (id) => {
            Modal.danger('Supprimer la vidéo', 'Êtes-vous sûr de vouloir supprimer cette vidéo ? Cette action est irréversible.', async () => {
                try {
                    await api.deleteVideo(id);
                    Toast.success('Vidéo supprimée');
                    Router.navigate('/dashboard');
                } catch (err) {
                    Toast.error(err.message || 'Erreur lors de la suppression');
                }
            });
        };
    } catch (err) {
        if (err.message.includes('401')) {
            Router.navigate('/login');
        } else if (err.message.includes('403')) {
            app.innerHTML = `<div class='empty-state'><div class='empty-state-title'>Accès refusé</div><div class='empty-state-description'>Vous n'avez pas accès à cette vidéo.</div></div>`;
        } else if (err.message.includes('404') || err.message.includes('introuvable')) {
            app.innerHTML = `<div class='empty-state'><div class='empty-state-title'>Vidéo introuvable</div><div class='empty-state-description'>La vidéo demandée n'existe pas.</div></div>`;
        } else {
            app.innerHTML = `<div class='empty-state'><div class='empty-state-title'>Erreur</div><div class='empty-state-description'>${err.message || 'Erreur inattendue.'}</div></div>`;
        }
    }
}

window.renderVideoDetailPage = renderVideoDetailPage;
