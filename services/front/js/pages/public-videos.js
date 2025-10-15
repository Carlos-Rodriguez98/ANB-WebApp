document.addEventListener('DOMContentLoaded', function() {
    // Public videos functionality
    let currentPage = 1;
    const videosPerPage = 9;
    let allVideos = [];
    let filteredVideos = [];

    // Elements
    const videosGrid = document.getElementById('videos-grid');
    const loadingElement = document.getElementById('loading');
    const emptyState = document.getElementById('empty-state');
    const videosContainer = document.getElementById('videos-container');
    const paginationContainer = document.getElementById('pagination-container');

    // Load public videos
    async function loadPublicVideos() {
        try {
            loadingElement.classList.remove('hidden');
            videosContainer.classList.add('hidden');
            emptyState.classList.add('hidden');
            
            const response = await apiClient.get('/public/videos');
            // La respuesta es directamente un array de videos
            allVideos = Array.isArray(response) ? response : [];
            filteredVideos = [...allVideos];
            
            renderVideos();
            
        } catch (error) {
            console.error('Error loading videos:', error);
            showToast('Error al cargar los videos', 'error');
            showEmptyState();
        } finally {
            loadingElement.classList.add('hidden');
        }
    }

    // Render videos
    function renderVideos() {
        if (filteredVideos.length === 0) {
            showEmptyState();
            return;
        }

        const startIndex = (currentPage - 1) * videosPerPage;
        const endIndex = startIndex + videosPerPage;
        const videosToShow = filteredVideos.slice(startIndex, endIndex);

        videosGrid.innerHTML = '';
        
        videosToShow.forEach(video => {
            const videoCard = createVideoCard(video);
            videosGrid.appendChild(videoCard);
        });

        // Show pagination
        renderPagination();
        
        videosContainer.classList.remove('hidden');
        emptyState.classList.add('hidden');
    }

    // Create video card
    function createVideoCard(video) {
        const card = document.createElement('div');
        card.className = 'bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow cursor-pointer';
        
        // Utiliser une image par défaut pour les thumbnails
        const thumbnail = video.thumbnail || 'https://via.placeholder.com/400x225/f97316/ffffff?text=Video';
        
        card.innerHTML = `
            <div class="relative">
                <img src="${thumbnail}" alt="${video.titulo}" class="w-full h-48 object-cover">
                <div class="absolute top-2 right-2">
                    <span class="bg-black bg-opacity-75 text-white text-xs px-2 py-1 rounded">
                        ${video.duration || '0:00'}
                    </span>
                </div>
                <div class="absolute top-2 left-2">
                    <span class="bg-green-600 bg-opacity-90 text-white text-xs px-2 py-1 rounded">
                        Público
                    </span>
                </div>
            </div>
            <div class="p-4">
                <h3 class="font-semibold text-lg mb-2">${video.titulo}</h3>
                <div class="flex items-center text-sm text-gray-600 mb-2">
                    <i class="fas fa-user mr-2"></i>
                    <span>Jugador #${video.jugador_id}</span>
                </div>
                <div class="flex items-center justify-between text-sm text-gray-500">
                    <div class="flex items-center space-x-4">
                        <span class="flex items-center">
                            <i class="fas fa-thumbs-up mr-1 text-green-500"></i>
                            ${video.votos || 0} votos
                        </span>
                        <span class="flex items-center">
                            <i class="fas fa-eye mr-1 text-blue-500"></i>
                            Ver video
                        </span>
                    </div>
                </div>
            </div>
        `;

        card.addEventListener('click', () => {
            // Navigate to video detail page
            window.location.href = `public-video-detail.html?id=${video.id}`;
        });

        return card;
    }

    // Render pagination
    function renderPagination() {
        const totalPages = Math.ceil(filteredVideos.length / videosPerPage);
        
        if (totalPages <= 1) {
            paginationContainer.innerHTML = '';
            return;
        }

        let paginationHTML = '<div class="flex justify-center items-center space-x-2">';
        
        // Previous button
        if (currentPage > 1) {
            paginationHTML += `<button class="px-3 py-2 bg-white border border-gray-300 rounded-md hover:bg-gray-50 transition-colors" data-page="${currentPage - 1}">
                <i class="fas fa-chevron-left"></i>
            </button>`;
        }

        // Page numbers
        for (let i = 1; i <= totalPages; i++) {
            if (i === currentPage) {
                paginationHTML += `<button class="px-3 py-2 bg-primary-500 text-white border border-primary-500 rounded-md">${i}</button>`;
            } else if (i === 1 || i === totalPages || (i >= currentPage - 2 && i <= currentPage + 2)) {
                paginationHTML += `<button class="px-3 py-2 bg-white border border-gray-300 rounded-md hover:bg-gray-50 transition-colors" data-page="${i}">${i}</button>`;
            } else if (i === currentPage - 3 || i === currentPage + 3) {
                paginationHTML += '<span class="px-2 text-gray-500">...</span>';
            }
        }

        // Next button
        if (currentPage < totalPages) {
            paginationHTML += `<button class="px-3 py-2 bg-white border border-gray-300 rounded-md hover:bg-gray-50 transition-colors" data-page="${currentPage + 1}">
                <i class="fas fa-chevron-right"></i>
            </button>`;
        }

        paginationHTML += '</div>';
        paginationContainer.innerHTML = paginationHTML;

        // Add event listeners to pagination buttons
        paginationContainer.querySelectorAll('[data-page]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                currentPage = parseInt(e.target.dataset.page);
                renderVideos();
                window.scrollTo({ top: 0, behavior: 'smooth' });
            });
        });
    }

    // Show empty state
    function showEmptyState() {
        videosContainer.classList.add('hidden');
        emptyState.classList.remove('hidden');
    }

    // Initialize
    loadPublicVideos();
});
