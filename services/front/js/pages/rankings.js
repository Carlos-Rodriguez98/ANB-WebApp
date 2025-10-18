// Rankings Page
async function renderRankingsPage() {
    const app = document.getElementById('app');
    let page = 1;
    let totalPages = 1;
    let city = '';
    const limit = 20;
    let intervalId = null;

    async function load(pageNum, cityFilter) {
        app.innerHTML = LoadingSpinner();
        try {
            const res = await api.getRankings(cityFilter, pageNum, limit);
            const rankings = res.rankings || res;
            totalPages = res.totalPages || Math.ceil((res.total || rankings.length) / limit) || 1;
            app.innerHTML = `
            <section class="container mx-auto px-4 py-8 fade-in">
              <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-6 gap-4">
                                <h2 class="text-xl font-semibold text-gray-900 mb-4">Clasificación</h2>
                <div class="flex items-center gap-2">
                  <input type="text" id="city-filter" class="form-input" placeholder="Filtrar por ciudad..." value="${cityFilter || ''}" style="max-width:180px;">
                  <button class="btn-secondary" onclick="applyCityFilter()"><i class="fas fa-search"></i></button>
                </div>
              </div>
              ${(!rankings || rankings.length === 0) ? `
                <div class="empty-state">
                  <div class="empty-state-icon"><i class="fas fa-users-slash"></i></div>
                  <div class="empty-state-title">Sin resultados</div>
                  <div class="empty-state-description">No se encontraron jugadores para este filtro.</div>
                </div>
              ` : `
                <div class="overflow-x-auto">
                  <table class="table min-w-full">
                    <thead>
                      <tr>
                        <th>Position</th>
                        <th>Jugador</th>
                                                                                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Votos</th>
                        <th>Votos</th>
                      </tr>
                    </thead>
                    <tbody>
                      ${rankings.map((r, i) => `
                        <tr>
                          <td class="font-bold">${(pageNum - 1) * limit + i + 1}</td>
                          <td>${r.username || r.playerName || '-'}</td>
                          <td>${r.city || '-'}</td>
                          <td><span class="badge badge-info">${r.votes ?? 0}</span></td>
                        </tr>
                      `).join('')}
                    </tbody>
                  </table>
                </div>
                ${Pagination({ currentPage: pageNum, totalPages, onPageChange: 'changeRankingsPage' })}
              `}
            </section>
            `;
            window.changeRankingsPage = (p) => {
                if (p < 1 || p > totalPages) return;
                page = p;
                load(page, city);
            };
            window.applyCityFilter = () => {
                city = document.getElementById('city-filter').value.trim();
                page = 1;
                load(page, city);
            };
        } catch (err) {
            app.innerHTML = `<div class='empty-state'><div class='empty-state-title'>Error</div><div class='empty-state-description'>${err.message || 'No se pudo cargar la clasificación.'}</div></div>`;
        }
    }
    load(page, city);
    // Live refresh every 5s
    if (intervalId) clearInterval(intervalId);
    intervalId = setInterval(() => load(page, city), 5000);
    // Clear interval on navigation
    window.addEventListener('popstate', () => clearInterval(intervalId), { once: true });
}

window.renderRankingsPage = renderRankingsPage;
