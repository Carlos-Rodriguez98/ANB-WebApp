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
            <h2 class="text-2xl font-bold text-primary-600 mb-4">Detalle del video</h2>
            <div class="mb-4">
              <strong>Título:</strong> ${video.title}<br>
              <strong>Estado:</strong> <span class="badge ${video.status === 'processed' ? 'badge-success' : 'badge-info'}">${video.status === 'processed' ? 'Procesado' : 'En proceso'}</span><br>
              <strong>Fecha de subida:</strong> ${video.uploadedAt ? new Date(video.uploadedAt).toLocaleString() : '-'}<br>
              <strong>Fecha de procesamiento:</strong> ${video.processedAt ? new Date(video.processedAt).toLocaleString() : '-'}<br>
              <strong>Votos:</strong> ${video.votes ?? 0}<br>
            </div>
            ${video.status === 'processed' && video.processedUrl ? VideoPlayer({ src: video.processedUrl }) : `<div class='empty-state'><div class='empty-state-description'>Video en procesamiento...</div></div>`}
            <div class="flex items-center justify-between mt-6">
              <a href="/dashboard" onclick="Router.navigate('/dashboard'); return false;" class="btn-secondary">Volver</a>
              <div class="flex space-x-2">
                ${video.status === 'processed' && video.processedUrl ? `<a href="${video.processedUrl}" download class="btn-secondary"><i class="fas fa-download mr-1"></i>Descargar</a>` : ''}
                ${video.status !== 'processed' ? `<button class="btn-danger" onclick="deleteVideo('${video.id}')">Eliminar</button>` : ''}
              </div>
            </div>
          </div>
        </section>
        `;
        window.deleteVideo = async (id) => {
            Modal.danger('Eliminar video', '¿Está seguro de que desea eliminar este video? Esta acción es irreversible.', async () => {
                try {
                    await api.deleteVideo(id);
                    Toast.success('Video eliminado');
                    Router.navigate('/dashboard');
                } catch (err) {
                    Toast.error(err.message || 'Error durante la eliminación');
                }
            });
        };
    } catch (err) {
        if (err.message.includes('401')) {
            Router.navigate('/login');
        } else if (err.message.includes('403')) {
            app.innerHTML = `<div class='empty-state'><div class='empty-state-title'>Acceso denegado</div><div class='empty-state-description'>No tienes acceso a este video.</div></div>`;
        } else if (err.message.includes('404') || err.message.includes('introuvable')) {
            app.innerHTML = `<div class='empty-state'><div class='empty-state-title'>Video no encontrado</div><div class='empty-state-description'>El video solicitado no existe.</div></div>`;
        } else {
            app.innerHTML = `<div class='empty-state'><div class='empty-state-title'>Error</div><div class='empty-state-description'>${err.message || 'Error inesperado.'}</div></div>`;
        }
    }
}

window.renderVideoDetailPage = renderVideoDetailPage;
