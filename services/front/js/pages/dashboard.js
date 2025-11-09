document.addEventListener('DOMContentLoaded', function() {
    // Dashboard functionality
    let currentPage = 1;
    const videosPerPage = 10;
    let allVideos = [];
    let filteredVideos = [];
    let userStats = {};

    // Elements
    const loadingElement = document.getElementById('loading');
    const videosContainer = document.getElementById('videos-container');
    const emptyState = document.getElementById('empty-state');
    const videosTableBody = document.getElementById('videos-table-body');
    const paginationContainer = document.getElementById('pagination-container');
    const statusFilter = document.getElementById('statusFilter');
    const logoutBtn = document.getElementById('logoutBtn');
    const usernameDisplay = document.getElementById('username');

    // Stats elements
    const totalVideosElement = document.getElementById('totalVideos');
    const totalVotesElement = document.getElementById('totalVotes');
    const rankingElement = document.getElementById('ranking');
    const avgScoreElement = document.getElementById('avgScore');

    // Modal elements
    const deleteModal = document.getElementById('delete-modal');
    const confirmDeleteBtn = document.getElementById('confirm-delete');
    let videoToDelete = null;

    // Initialize dashboard
    async function init() {
        // Check authentication
        const user = getCurrentUser();
        if (!user) {
            window.location.href = 'login.html';
            return;
        }

        // Display username
        usernameDisplay.textContent = user.firstName || user.email;

        // Load data
        await Promise.all([
            loadUserStats(),
            loadUserVideos()
        ]);
    }

    // Load user statistics
    async function loadUserStats() {
        try {
            const response = await apiClient.get('/api/user/stats');
            userStats = response;
            
            // Update stats display
            totalVideosElement.textContent = userStats.totalVideos || 0;
            totalVotesElement.textContent = userStats.totalVotes || 0;
            rankingElement.textContent = userStats.ranking ? `#${userStats.ranking}` : '-';
            avgScoreElement.textContent = (userStats.averageScore || 0).toFixed(1);
            
        } catch (error) {
            console.error('Error loading stats:', error);
        }
    }

    // Load user videos
    async function loadUserVideos() {
        try {
            loadingElement.classList.remove('hidden');
            videosContainer.classList.add('hidden');
            emptyState.classList.add('hidden');
            
            const response = await apiClient.get('/api/videos');
            allVideos = response.videos || response || [];
            
            applyFilters();
            
        } catch (error) {
            console.error('Error loading videos:', error);
            showToast('Error al cargar los videos', 'error');
            showEmptyState();
        } finally {
            loadingElement.classList.add('hidden');
        }
    }

    // Apply filters
    function applyFilters() {
        filteredVideos = allVideos.filter(video => {
            if (statusFilter.value && video.visibility !== statusFilter.value) {
                return false;
            }
            return true;
        });

        currentPage = 1;
        renderVideos();
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

        videosTableBody.innerHTML = '';
        
        videosToShow.forEach(video => {
            const row = createVideoRow(video);
            videosTableBody.appendChild(row);
        });

        // Show pagination
        renderPagination();
        
        videosContainer.classList.remove('hidden');
        emptyState.classList.add('hidden');
    }

    // Create video row
    function createVideoRow(video) {
        const row = document.createElement('tr');
        row.className = 'hover:bg-gray-50';
        
        const uploadDate = new Date(video.uploadDate || video.uploadedAt).toLocaleDateString('fr-FR');
        const statusClass = video.visibility === 'public' ? 'text-green-600 bg-green-100' : 'text-gray-600 bg-gray-100';
        const statusText = video.visibility === 'public' ? 'Publique' : 'Privée';

        row.innerHTML = `
            <td class="px-4 py-4">
                <div class="max-w-xs">
                    <div class="font-medium text-gray-900 truncate">${video.title}</div>
                    <div class="text-sm text-gray-500">${video.category || 'Non spécifiée'}</div>
                </div>
            </td>
            <td class="px-4 py-4">
                <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full ${statusClass}">
                    ${statusText}
                </span>
            </td>
            <td class="px-4 py-4 text-sm text-gray-900">
                ${uploadDate}
            </td>
            <td class="px-4 py-4 text-sm text-gray-900">
                <div class="flex items-center">
                    <i class="fas fa-thumbs-up text-green-500 mr-1"></i>
                    ${video.votes || 0}
                </div>
            </td>
            <td class="px-4 py-4 text-sm text-gray-900">
                <div class="flex items-center">
                    <i class="fas fa-star text-yellow-500 mr-1"></i>
                    ${(video.averageScore || 0).toFixed(1)}
                </div>
            </td>
            <td class="px-4 py-4 text-sm text-gray-500">
                <div class="flex items-center space-x-2">
                    ${video.status === 'processed' && !video.published 
                        ? `<button class="text-green-600 hover:text-green-900" onclick="publishVideo('${video.video_id}', event)">
                             <i class="fas fa-upload"></i>
                           </button>` 
                        : ''
                    }
                    <button class="text-blue-600 hover:text-blue-900" onclick="viewVideo('${video.video_id}')">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="text-red-600 hover:text-red-900" onclick="confirmDeleteVideo('${video.id}')">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </td>
        `;

        return row;
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

    // Global functions for button actions
    window.viewVideo = function(videoId) {
        window.location.href = `video-detail.html?id=${videoId}`;
    };

    window.confirmDeleteVideo = function(videoId) {
        videoToDelete = videoId;
        deleteModal.classList.add('show');
    };

    window.publishVideo = async function(videoId, evt) {
        // Prevenir múltiples clics
        if (evt) {
            evt.preventDefault();
            evt.stopPropagation();
        }
        
        const btn = evt ? evt.currentTarget : null;
        if (!btn || btn.disabled) return;
    
        btn.disabled = true;
        const originalHTML = btn.innerHTML;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
    
        try {
            await apiClient.post(`/videos/${videoId}/publish`, {});
            showToast('Video publicado exitosamente', 'success');
            
            // Refresh the video list
            await loadUserVideos();
            
        } catch (error) {
            console.error('Error publishing video:', error);
            showToast('Error al publicar', 'error');
        } finally {
            btn.disabled = false;
            btn.innerHTML = originalHTML;
        }
    };

    // Delete video
    async function deleteVideo(videoId) {
        try {
            await apiClient.delete(`/api/videos/${videoId}`);
            showToast('Video eliminado exitosamente', 'success');
            
            // Remove from arrays and refresh
            allVideos = allVideos.filter(v => v.id !== videoId);
            applyFilters();
            
            // Refresh stats
            await loadUserStats();
            
        } catch (error) {
            console.error('Error deleting video:', error);
            showToast('Error al eliminar', 'error');
        }
    }

    // Event listeners
    statusFilter.addEventListener('change', applyFilters);

    logoutBtn.addEventListener('click', (e) => {
        e.preventDefault();
        logout();
        window.location.href = 'login.html';
    });

    // Modal event listeners
    confirmDeleteBtn.addEventListener('click', async () => {
        if (videoToDelete) {
            await deleteVideo(videoToDelete);
            videoToDelete = null;
            deleteModal.classList.remove('show');
        }
    });

    // Close modal handlers
    deleteModal.querySelectorAll('.modal-close').forEach(btn => {
        btn.addEventListener('click', () => {
            deleteModal.classList.remove('show');
            videoToDelete = null;
        });
    });

    // Initialize dashboard
    init();
});
