// Public Videos Gallery Page
async function renderPublicVideosPage() {
    const app = document.getElementById('app');
    let page = 1;
    let totalPages = 1;
    const limit = 12;

    async function load(pageNum) {
        app.innerHTML = LoadingSpinner();
        try {
            const res = await api.getPublicVideos(pageNum, limit);
            const videos = res.videos || res;
            totalPages = res.totalPages || Math.ceil((res.total || videos.length) / limit) || 1;
            app.innerHTML = `
            <section class="container mx-auto px-4 py-8 fade-in">
              <h2 class="text-2xl font-bold text-primary-600 mb-6">Videos Públicos</h2>
              ${(!videos || videos.length === 0) ? `
                <div class="empty-state">
                  <div class="empty-state-icon"><i class="fas fa-video-slash"></i></div>
                  <div class="empty-state-title">No hay videos disponibles</div>
                  <div class="empty-state-description">Aún no se han publicado videos.</div>
                </div>
              ` : `
                <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
                  ${videos.map(video => VideoCard({
                    id: video.id,
                    title: video.title,
                    playerName: video.playerName || video.username || '',
                    city: video.city,
                    thumbnailUrl: video.thumbnailUrl || '',
                    votes: video.votes,
                    onClick: `Router.navigate('/public/videos/${video.id}')`
                  })).join('')}
                </div>
                ${Pagination({ currentPage: pageNum, totalPages, onPageChange: 'changePublicVideosPage' })}
              `}
            </section>
            `;
            window.changePublicVideosPage = (p) => {
                if (p < 1 || p > totalPages) return;
                page = p;
                load(page);
            };
        } catch (err) {
            app.innerHTML = `<div class='empty-state'><div class='empty-state-title'>Error</div><div class='empty-state-description'>${err.message || 'No se pudieron cargar los videos.'}</div></div>`;
        }
    }
    load(page);
}

window.renderPublicVideosPage = renderPublicVideosPage;
