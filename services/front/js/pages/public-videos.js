document.addEventListener('DOMContentLoaded', function() {
    // Public videos functionality
    let currentPage = 1;
    const videosPerPage = 9;
    let allVideos = [];
    let filteredVideos = [];
    
    // Cache pour les durées et miniatures
    const videoMetadataCache = new Map();

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
            // El voting-service devuelve array directo o objeto con propiedad videos
            allVideos = Array.isArray(response) ? response : (response.videos || []);
            filteredVideos = [...allVideos];
            
            // Précharger les métadonnées des vidéos
            await preloadVideoMetadata();
            
            renderVideos();
            
        } catch (error) {
            console.error('Error loading videos:', error);
            showToast('Error al cargar los videos', 'error');
            showEmptyState();
        } finally {
            loadingElement.classList.add('hidden');
        }
    }

    // Précharge les métadonnées des vidéos (durée et miniatures)
    async function preloadVideoMetadata() {
        const promises = allVideos.slice(0, videosPerPage * 2).map(async (video) => {
            if (video.processed_url || video.processedURL) {
                const videoUrl = video.processed_url || video.processedURL;
                
                try {
                    // Obtenir la durée réelle de la vidéo
                    const duration = await videoUtils.getVideoDuration(videoUrl);
                    
                    // Générer une miniature si elle n'existe pas
                    let thumbnail = videoUtils.getThumbnailUrl(video);
                    
                    // Si pas de miniature prédéfinie, essayer de la générer
                    if (thumbnail.includes('placeholder')) {
                        try {
                            thumbnail = await videoUtils.generateThumbnail(videoUrl);
                        } catch (thumbError) {
                            console.warn('Impossible de générer la miniature pour', video.id, thumbError);
                            // Garder l'image par défaut
                        }
                    }
                    
                    videoMetadataCache.set(video.id, {
                        duration: duration,
                        thumbnail: thumbnail
                    });
                    
                } catch (error) {
                    console.warn('Erreur lors du chargement des métadonnées pour la vidéo', video.id, error);
                }
            }
        });
        
        // Attendre quelques métadonnées sans bloquer le rendu
        await Promise.allSettled(promises.slice(0, 6));
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
        
        // Obtenir les métadonnées depuis le cache ou utiliser les valeurs par défaut
        const metadata = videoMetadataCache.get(video.id) || {};
        const thumbnail = metadata.thumbnail || videoUtils.getThumbnailUrl(video);
        const duration = metadata.duration ? videoUtils.formatDuration(metadata.duration) : (video.duration || '0:00');
        
        // Nom du joueur - utiliser différents champs possibles
        const playerName = video.playerName || video.player_name || `Jugador #${video.user_id || video.jugador_id}`;
        
        card.innerHTML = `
            <div class="relative">
                <img src="${thumbnail}" 
                     alt="${video.title || video.titulo}" 
                     class="w-full h-48 object-cover"
                     onerror="this.src='https://i.sstatic.net/l7kvp.jpg'"
                     loading="lazy">
                <div class="absolute top-2 right-2">
                    <span class="bg-black bg-opacity-75 text-white text-xs px-2 py-1 rounded">
                        ${duration}
                    </span>
                </div>
                <div class="absolute top-2 left-2">
                    <span class="bg-green-600 bg-opacity-90 text-white text-xs px-2 py-1 rounded">
                        Público
                    </span>
                </div>
                <div class="absolute inset-0 bg-black bg-opacity-0 hover:bg-opacity-10 transition-all duration-200 flex items-center justify-center">
                    <div class="opacity-0 hover:opacity-100 transition-opacity duration-200">
                        <i class="fas fa-play-circle text-white text-4xl"></i>
                    </div>
                </div>
            </div>
            <div class="p-4">
                <h3 class="font-semibold text-lg mb-2 line-clamp-2" title="${video.title || video.titulo}">
                    ${video.title || video.titulo}
                </h3>
                <div class="flex items-center text-sm text-gray-600 mb-2">
                    <i class="fas fa-user mr-2"></i>
                    <span class="truncate">${playerName}</span>
                </div>
                ${video.city ? `
                    <div class="flex items-center text-sm text-gray-500 mb-2">
                        <i class="fas fa-map-marker-alt mr-2"></i>
                        <span class="truncate">${video.city}</span>
                    </div>
                ` : ''}
                <div class="flex items-center justify-between text-sm text-gray-500">
                    <div class="flex items-center space-x-4">
                        <span class="flex items-center">
                            <i class="fas fa-thumbs-up mr-1 text-green-500"></i>
                            ${video.votes || video.votos || 0} votos
                        </span>
                        <span class="flex items-center">
                            <i class="fas fa-eye mr-1 text-blue-500"></i>
                            Ver video
                        </span>
                    </div>
                </div>
            </div>
        `;

        // Ajouter un indicateur de chargement pour les métadonnées si nécessaire
        if (!metadata.duration && (video.processed_url || video.processedURL)) {
            loadVideoMetadataAsync(video, card);
        }

        card.addEventListener('click', () => {
            // Navigate to video detail page
            window.location.href = `public-video-detail.html?id=${video.id}`;
        });

        return card;
    }

    // Charge les métadonnées d'une vidéo de manière asynchrone et met à jour la carte
    async function loadVideoMetadataAsync(video, cardElement) {
        if (videoMetadataCache.has(video.id)) return;
        
        const videoUrl = video.processed_url || video.processedURL;
        if (!videoUrl) return;
        
        try {
            const duration = await videoUtils.getVideoDuration(videoUrl);
            const formattedDuration = videoUtils.formatDuration(duration);
            
            // Mettre à jour l'affichage de la durée dans la carte
            const durationElement = cardElement.querySelector('.bg-black span');
            if (durationElement) {
                durationElement.textContent = formattedDuration;
            }
            
            // Essayer de générer une miniature si ce n'est pas déjà fait
            let thumbnail = videoUtils.getThumbnailUrl(video);
            if (thumbnail.includes('placeholder')) {
                try {
                    thumbnail = await videoUtils.generateThumbnail(videoUrl);
                    const imgElement = cardElement.querySelector('img');
                    if (imgElement) {
                        imgElement.src = thumbnail;
                    }
                } catch (thumbError) {
                    console.warn('Impossible de générer la miniature pour', video.id);
                }
            }
            
            // Mettre en cache les métadonnées
            videoMetadataCache.set(video.id, {
                duration: duration,
                thumbnail: thumbnail
            });
            
        } catch (error) {
            console.warn('Erreur lors du chargement des métadonnées pour', video.id, error);
        }
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
