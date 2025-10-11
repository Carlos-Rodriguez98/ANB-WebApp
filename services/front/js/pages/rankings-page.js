// Rankings Page - pour rankings.html
document.addEventListener('DOMContentLoaded', function() {
    const loadingElement = document.getElementById('loading');
    const rankingsContainer = document.getElementById('rankings-container');
    const emptyState = document.getElementById('empty-state');
    const tableBody = document.getElementById('rankings-table-body');
    const paginationContainer = document.getElementById('pagination-container');

    let currentPage = 1;
    let totalPages = 1;
    let currentFilter = '';

    // Éléments des filtres
    const periodFilter = document.getElementById('periodFilter');
    const categoryFilter = document.getElementById('categoryFilter');
    const positionFilter = document.getElementById('positionFilter');
    const resetButton = document.getElementById('resetFilters');

    // Fonction pour charger les rankings
    async function loadRankings(page = 1, filters = {}) {
        try {
            showLoading();
            
            // Appeler l'API rankings
            const response = await api.getRankings('', page, 20);
            
            if (response && response.rankings && response.rankings.length > 0) {
                displayRankings(response.rankings, page);
                updatePagination(response.currentPage || page, response.totalPages || 1);
                showRankingsTable();
            } else {
                showEmptyState();
            }
            
        } catch (error) {
            console.error('Erreur lors du chargement des rankings:', error);
            showEmptyState('Erreur lors du chargement des classifications');
        }
    }

    // Afficher l'état de chargement
    function showLoading() {
        loadingElement.classList.remove('hidden');
        rankingsContainer.classList.add('hidden');
        emptyState.classList.add('hidden');
    }

    // Afficher le tableau des rankings
    function showRankingsTable() {
        loadingElement.classList.add('hidden');
        rankingsContainer.classList.remove('hidden');
        emptyState.classList.add('hidden');
    }

    // Afficher l'état vide
    function showEmptyState(message = 'Ninguna clasificación disponible') {
        loadingElement.classList.add('hidden');
        rankingsContainer.classList.add('hidden');
        emptyState.classList.remove('hidden');
        emptyState.querySelector('.empty-state-title').textContent = message;
    }

    // Afficher les rankings dans le tableau
    function displayRankings(rankings, page) {
        tableBody.innerHTML = '';
        
        rankings.forEach((ranking, index) => {
            const position = ((page - 1) * 20) + index + 1;
            const row = document.createElement('tr');
            row.className = 'hover:bg-gray-50';
            
            row.innerHTML = `
                <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                        <span class="text-lg font-bold text-gray-900">
                            ${position <= 3 ? getMedal(position) : position}
                        </span>
                    </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                        <div class="h-10 w-10 rounded-full bg-primary-100 flex items-center justify-center">
                            <i class="fas fa-user text-primary-600"></i>
                        </div>
                        <div class="ml-4">
                            <div class="text-sm font-medium text-gray-900">
                                ${ranking.username || ranking.playerName || `Jugador ${ranking.jugador || 'N/A'}`}
                            </div>
                            <div class="text-sm text-gray-500">ID: ${ranking.jugador || 'N/A'}</div>
                        </div>
                    </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm text-gray-900">${calculateScore(ranking.votes)}</div>
                    <div class="text-sm text-gray-500">Puntos</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary-100 text-primary-800">
                        ${ranking.votes || ranking.votos_acumulados || 0} votos
                    </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <i class="fas fa-video mr-1"></i>
                    ${Math.floor((ranking.votes || 0) / 5) || 'N/A'}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    ${getTrend(position)}
                </td>
            `;
            
            tableBody.appendChild(row);
        });
    }

    // Obtenir le médaille pour les 3 premières positions
    function getMedal(position) {
        const medals = {
            1: '<i class="fas fa-medal text-yellow-500 text-xl"></i>',
            2: '<i class="fas fa-medal text-gray-400 text-xl"></i>',
            3: '<i class="fas fa-medal text-yellow-600 text-xl"></i>'
        };
        return medals[position] || position;
    }

    // Calculer le score basé sur les votes
    function calculateScore(votes) {
        return (votes || 0) * 10; // Score simplifié
    }

    // Obtenir la tendance (simulée)
    function getTrend(position) {
        const trends = [
            '<i class="fas fa-arrow-up text-green-500"></i>',
            '<i class="fas fa-arrow-down text-red-500"></i>',
            '<i class="fas fa-minus text-gray-500"></i>'
        ];
        return trends[position % 3];
    }

    // Mettre à jour la pagination
    function updatePagination(current, total) {
        currentPage = current;
        totalPages = total;
        
        if (total <= 1) {
            paginationContainer.innerHTML = '';
            return;
        }

        let paginationHTML = `
            <div class="flex items-center justify-between">
                <div class="text-sm text-gray-700">
                    Página ${current} de ${total}
                </div>
                <div class="flex space-x-2">
        `;

        // Bouton précédent
        if (current > 1) {
            paginationHTML += `
                <button onclick="changePage(${current - 1})" 
                        class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
                    Anterior
                </button>
            `;
        }

        // Pages
        for (let i = Math.max(1, current - 2); i <= Math.min(total, current + 2); i++) {
            const isActive = i === current;
            paginationHTML += `
                <button onclick="changePage(${i})" 
                        class="px-3 py-2 text-sm font-medium ${isActive ? 'text-white bg-primary-600' : 'text-gray-500 bg-white'} border border-gray-300 rounded-md hover:bg-gray-50">
                    ${i}
                </button>
            `;
        }

        // Bouton suivant
        if (current < total) {
            paginationHTML += `
                <button onclick="changePage(${current + 1})" 
                        class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
                    Siguiente
                </button>
            `;
        }

        paginationHTML += `
                </div>
            </div>
        `;

        paginationContainer.innerHTML = paginationHTML;
    }

    // Fonction globale pour changer de page
    window.changePage = function(page) {
        if (page >= 1 && page <= totalPages && page !== currentPage) {
            loadRankings(page);
        }
    };

    // Gestionnaires d'événements pour les filtres
    resetButton.addEventListener('click', function() {
        periodFilter.value = 'all';
        categoryFilter.value = '';
        positionFilter.value = '';
        loadRankings(1);
    });

    // Recharger quand les filtres changent (pour l'instant, les filtres ne sont pas implémentés côté backend)
    [periodFilter, categoryFilter, positionFilter].forEach(filter => {
        filter.addEventListener('change', function() {
            // Pour l'instant, on recharge simplement les données
            // Plus tard, on pourra implémenter un vrai filtrage
            loadRankings(1);
        });
    });

    // Actualisation automatique toutes les 30 secondes
    setInterval(() => {
        if (document.visibilityState === 'visible') {
            loadRankings(currentPage);
        }
    }, 30000);

    // Chargement initial
    loadRankings();
});
