// Rankings Page - Compatible con SPA y HTML tradicional
async function renderRankingsPage() {
    // Detectar modo: SPA (con #app) o HTML tradicional (con #rankings-table-body)
    const app = document.getElementById('app');
    const rankingsTableBody = document.getElementById('rankings-table-body');
    const isSPA = !!app && !rankingsTableBody;
    
    console.log('Rankings page initialized in', isSPA ? 'SPA' : 'Traditional HTML', 'mode');
    
    // Elementos para modo HTML tradicional
    const loadingElement = document.getElementById('loading');
    const rankingsContainer = document.getElementById('rankings-container');
    const emptyState = document.getElementById('empty-state');
    
    let page = 1;
    let totalPages = 1;
    let city = '';
    const limit = 20;
    let intervalId = null;

    // Función para renderizar en modo HTML tradicional
    function renderTraditional(rankings) {
        if (!rankingsTableBody) return;
        
        rankingsTableBody.innerHTML = '';
        
        rankings.forEach((player) => {
            const row = document.createElement('tr');
            row.className = 'hover:bg-gray-50';
            
            let rankBadge = '';
            if (player.position === 1) {
                rankBadge = '<span class="text-2xl">🥇</span>';
            } else if (player.position === 2) {
                rankBadge = '<span class="text-2xl">🥈</span>';
            } else if (player.position === 3) {
                rankBadge = '<span class="text-2xl">🥉</span>';
            } else {
                rankBadge = `<span class="text-lg font-bold text-gray-600">#${player.position}</span>`;
            }
            
            row.innerHTML = `
                <td class="px-6 py-4 whitespace-nowrap">${rankBadge}</td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                        <div class="flex-shrink-0 h-10 w-10 bg-primary-100 rounded-full flex items-center justify-center">
                            <i class="fas fa-user text-primary-600"></i>
                        </div>
                        <div class="ml-4">
                            <div class="text-sm font-medium text-gray-900">${player.username || '-'}</div>
                            <div class="text-sm text-gray-500">${player.city || '-'}</div>
                        </div>
                    </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm font-semibold text-primary-600">${player.votes * 10}</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                        ${player.votes} votos
                    </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">-</td>
                <td class="px-6 py-4 whitespace-nowrap"><i class="fas fa-arrow-up text-green-500"></i></td>
            `;
            
            rankingsTableBody.appendChild(row);
        });
        
        if (loadingElement) loadingElement.classList.add('hidden');
        if (rankingsContainer) rankingsContainer.classList.remove('hidden');
        if (emptyState) emptyState.classList.add('hidden');
    }
    
    // Función de carga principal
    async function load(pageNum, cityFilter) {
        try {
            // Show loading
            if (isSPA) {
                app.innerHTML = LoadingSpinner();
            } else {
                if (loadingElement) loadingElement.classList.remove('hidden');
                if (rankingsContainer) rankingsContainer.classList.add('hidden');
                if (emptyState) emptyState.classList.add('hidden');
            }
            
            // Fetch data
            const res = await api.getRankings(cityFilter, pageNum, limit);
            const rankings = Array.isArray(res) ? res : (res.rankings || res);
            
            console.log('Rankings loaded:', rankings.length, 'players');
            
            if (!rankings || rankings.length === 0) {
                if (isSPA) {
                    app.innerHTML = `
                        <div class='empty-state'>
                            <div class='empty-state-icon'><i class='fas fa-users-slash'></i></div>
                            <div class='empty-state-title'>Aucun résultat</div>
                            <div class='empty-state-description'>Aucun joueur trouvé.</div>
                        </div>`;
                } else {
                    if (loadingElement) loadingElement.classList.add('hidden');
                    if (rankingsContainer) rankingsContainer.classList.add('hidden');
                    if (emptyState) emptyState.classList.remove('hidden');
                }
                return;
            }
            
            totalPages = res.totalPages || Math.ceil((res.total || rankings.length) / limit) || 1;
            
            // Render based on mode
            if (isSPA) {
                // Modo SPA: renderizar todo dinámicamente
                app.innerHTML = `
                <section class="container mx-auto px-4 py-8 fade-in">
                  <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-6 gap-4">
                    <h2 class="text-2xl font-bold text-primary-600">Classement</h2>
                    <div class="flex items-center gap-2">
                      <input type="text" id="city-filter" class="form-input" placeholder="Filtrer par ville..." value="${cityFilter || ''}" style="max-width:180px;">
                      <button class="btn-secondary" onclick="applyCityFilter()"><i class="fas fa-search"></i></button>
                    </div>
                  </div>
                  <div class="overflow-x-auto">
                    <table class="table min-w-full">
                      <thead>
                        <tr>
                          <th>Position</th>
                          <th>Joueur</th>
                          <th>Ville</th>
                          <th>Votes</th>
                        </tr>
                      </thead>
                      <tbody>
                        ${rankings.map((r) => `
                          <tr>
                            <td class="font-bold">${r.position}</td>
                            <td>${r.username || '-'}</td>
                            <td>${r.city || '-'}</td>
                            <td><span class="badge badge-info">${r.votes ?? 0}</span></td>
                          </tr>
                        `).join('')}
                      </tbody>
                    </table>
                  </div>
                  ${Pagination({ currentPage: pageNum, totalPages, onPageChange: 'changeRankingsPage' })}
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
            } else {
                // Modo HTML tradicional: usar elementos existentes
                renderTraditional(rankings);
            }
            
        } catch (err) {
            console.error('Error loading rankings:', err);
            if (isSPA) {
                app.innerHTML = `<div class='empty-state'><div class='empty-state-title'>Erreur</div><div class='empty-state-description'>${err.message || 'Impossible de charger le classement.'}</div></div>`;
            } else {
                if (loadingElement) loadingElement.classList.add('hidden');
                if (emptyState) {
                    emptyState.classList.remove('hidden');
                    emptyState.innerHTML = `
                        <div class="empty-state-icon"><i class="fas fa-exclamation-triangle"></i></div>
                        <div class="empty-state-title">Error</div>
                        <div class="empty-state-description">${err.message || 'Error al cargar'}</div>
                    `;
                }
            }
        }
    }
    
    // Initial load
    load(page, city);
    
    // Live refresh every 5s (only in SPA mode)
    if (isSPA) {
        if (intervalId) clearInterval(intervalId);
        intervalId = setInterval(() => load(page, city), 5000);
        window.addEventListener('popstate', () => clearInterval(intervalId), { once: true });
    }
    
    // Setup reset button for traditional HTML
    if (!isSPA) {
        const resetBtn = document.getElementById('resetFilters');
        if (resetBtn) {
            resetBtn.addEventListener('click', () => load(page, city));
        }
    }
}

window.renderRankingsPage = renderRankingsPage;

// Auto-initialize if in traditional HTML mode
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
        if (document.getElementById('rankings-table-body')) {
            renderRankingsPage();
        }
    });
} else {
    if (document.getElementById('rankings-table-body')) {
        renderRankingsPage();
    }
}
