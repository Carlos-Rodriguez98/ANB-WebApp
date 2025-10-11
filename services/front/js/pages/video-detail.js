document.addEventListener('DOMContentLoaded', function() {
    // Video detail functionality
    let currentVideo = null;

    // Elements
    const loadingElement = document.getElementById('loading');
    const videoDetailsElement = document.getElementById('video-details');
    const errorStateElement = document.getElementById('error-state');
    const usernameDisplay = document.getElementById('username');
    const logoutBtn = document.getElementById('logoutBtn');

    // Video elements
    const videoTitle = document.getElementById('video-title');
    const videoStatus = document.getElementById('video-status');
    const videoUploadDate = document.getElementById('video-upload-date');
    const videoProcessedDate = document.getElementById('video-processed-date');
    const processedDateContainer = document.getElementById('processed-date-container');
    const videoVotes = document.getElementById('video-votes').querySelector('span');
    const videoId = document.getElementById('video-id');
    const videoPlayer = document.getElementById('video-player');
    const videoSource = document.getElementById('video-source');

    // Action buttons
    const publishBtn = document.getElementById('publish-btn');
    const deleteBtn = document.getElementById('delete-btn');

    // Modal elements
    const deleteModal = document.getElementById('delete-modal');
    const confirmDeleteBtn = document.getElementById('confirm-delete');

    // Initialize
    async function init() {
        // Check authentication
        const user = Auth.getCurrentUser();
        if (!user) {
            window.location.href = 'login.html';
            return;
        }

        // Display username
        if (usernameDisplay) {
            usernameDisplay.textContent = user.firstName || user.email;
        }

        // Get video ID from URL
        const urlParams = new URLSearchParams(window.location.search);
        const videoIdParam = urlParams.get('id');

        if (!videoIdParam) {
            showErrorState();
            return;
        }

        // Load video details
        await loadVideoDetails(videoIdParam);
    }

    // Load video details
    async function loadVideoDetails(videoId) {
        try {
            loadingElement.classList.remove('hidden');
            videoDetailsElement.classList.add('hidden');
            errorStateElement.classList.add('hidden');

            const response = await apiClient.get(`/videos/${videoId}`);
            currentVideo = response;

            displayVideoDetails();

        } catch (error) {
            console.error('Error loading video details:', error);
            showErrorState();
        } finally {
            loadingElement.classList.add('hidden');
        }
    }

    // Display video details
    function displayVideoDetails() {
        if (!currentVideo) return;

        // Basic info
        videoTitle.textContent = currentVideo.title;
        videoId.textContent = currentVideo.video_id;

        // Upload date
        const uploadDate = new Date(currentVideo.uploaded_at);
        videoUploadDate.textContent = uploadDate.toLocaleDateString('fr-FR', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });

        // Processed date
        if (currentVideo.processed_at) {
            const processedDate = new Date(currentVideo.processed_at);
            videoProcessedDate.textContent = processedDate.toLocaleDateString('fr-FR', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
            processedDateContainer.classList.remove('hidden');
        } else {
            processedDateContainer.classList.add('hidden');
        }

        // Status
        updateStatusDisplay();

        // Votes
        videoVotes.textContent = currentVideo.votes || 0;

        // Video player
        if (currentVideo.processed_url && currentVideo.status === 'processed') {
            videoSource.src = currentVideo.processed_url;
            videoPlayer.load();
        } else if (currentVideo.original_url) {
            videoSource.src = currentVideo.original_url;
            videoPlayer.load();
        }

        // Action buttons
        updateActionButtons();

        videoDetailsElement.classList.remove('hidden');
    }

    // Update status display
    function updateStatusDisplay() {
        let statusClass = 'text-gray-600 bg-gray-100';
        let statusText = 'En traitement';

        if (currentVideo.status === 'processed') {
            statusClass = currentVideo.published ? 'text-green-600 bg-green-100' : 'text-blue-600 bg-blue-100';
            statusText = currentVideo.published ? 'Publié' : 'Traité';
        } else if (currentVideo.status === 'processing') {
            statusClass = 'text-yellow-600 bg-yellow-100';
            statusText = 'En traitement';
        } else if (currentVideo.status === 'error') {
            statusClass = 'text-red-600 bg-red-100';
            statusText = 'Erreur';
        }

        videoStatus.className = `px-2 py-1 text-xs font-semibold rounded-full ${statusClass}`;
        videoStatus.textContent = statusText;
    }

    // Update action buttons
    function updateActionButtons() {
        // Show publish button only if video is processed but not published
        if (currentVideo.status === 'processed' && !currentVideo.published) {
            publishBtn.classList.remove('hidden');
        } else {
            publishBtn.classList.add('hidden');
        }

        // Show delete button only if video is not published
        if (!currentVideo.published) {
            deleteBtn.classList.remove('hidden');
        } else {
            deleteBtn.classList.add('hidden');
        }
    }

    // Show error state
    function showErrorState() {
        loadingElement.classList.add('hidden');
        videoDetailsElement.classList.add('hidden');
        errorStateElement.classList.remove('hidden');
    }

    // Publish video
    async function publishVideo() {
        try {
            await apiClient.post(`/videos/${currentVideo.video_id}/publish`, {});
            Toast.show('Vidéo publiée avec succès', 'success');
            
            // Reload video details from API to get updated data
            await loadVideoDetails(currentVideo.video_id);
            
        } catch (error) {
            console.error('Error publishing video:', error);
            Toast.show('Erreur lors de la publication', 'error');
        }
    }

    // Delete video
    async function deleteVideo() {
        try {
            await apiClient.delete(`/videos/${currentVideo.video_id}`);
            Toast.show('Vidéo supprimée avec succès', 'success');
            
            // Redirect to dashboard after short delay
            setTimeout(() => {
                window.location.href = 'dashboard.html';
            }, 1500);
            
        } catch (error) {
            console.error('Error deleting video:', error);
            Toast.show('Erreur lors de la suppression', 'error');
        }
    }

    // Event listeners
    if (publishBtn) {
        publishBtn.addEventListener('click', publishVideo);
    }

    if (deleteBtn) {
        deleteBtn.addEventListener('click', () => {
            deleteModal.classList.add('show');
        });
    }

    if (confirmDeleteBtn) {
        confirmDeleteBtn.addEventListener('click', async () => {
            deleteModal.classList.remove('show');
            await deleteVideo();
        });
    }

    if (logoutBtn) {
        logoutBtn.addEventListener('click', (e) => {
            e.preventDefault();
            Auth.logout();
            window.location.href = 'login.html';
        });
    }

    // Modal close handlers
    deleteModal.querySelectorAll('.modal-close').forEach(btn => {
        btn.addEventListener('click', () => {
            deleteModal.classList.remove('show');
        });
    });

    // Initialize the page
    init();
});
