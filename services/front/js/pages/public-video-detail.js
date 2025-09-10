document.addEventListener('DOMContentLoaded', function() {
    // Public video detail functionality
    let currentVideo = null;

    // Elements
    const loadingElement = document.getElementById('loading');
    const videoDetailsElement = document.getElementById('video-details');
    const errorStateElement = document.getElementById('error-state');

    // Video elements
    const videoTitle = document.getElementById('video-title');
    const videoPlayerName = document.getElementById('video-player-name');
    const videoCity = document.getElementById('video-city');
    const videoPublishedDate = document.getElementById('video-published-date');
    const videoVotes = document.getElementById('video-votes').querySelector('span');
    const videoPlayer = document.getElementById('video-player');
    const videoSource = document.getElementById('video-source');

    // Action elements
    const voteBtn = document.getElementById('vote-btn');
    const voteMessage = document.getElementById('vote-message');

    // Initialize
    async function init() {
        // Check if user is authenticated for voting
        const user = Auth.getCurrentUser();
        
        if (!user) {
            voteBtn.classList.add('hidden');
            voteMessage.classList.remove('hidden');
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

            const response = await apiClient.get(`/public/videos/${videoId}`);
            currentVideo = response;

            displayVideoDetails();

        } catch (error) {
            console.error('Error loading public video details:', error);
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
        videoPlayerName.textContent = currentVideo.playerName;
        videoCity.textContent = currentVideo.city;

        // Published date
        if (currentVideo.published_at) {
            const publishedDate = new Date(currentVideo.published_at);
            videoPublishedDate.textContent = publishedDate.toLocaleDateString('fr-FR', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        } else {
            videoPublishedDate.textContent = 'Date inconnue';
        }

        // Votes
        videoVotes.textContent = currentVideo.votes || 0;

        // Video player
        if (currentVideo.processed_url) {
            videoSource.src = currentVideo.processed_url;
            videoPlayer.load();
        }

        videoDetailsElement.classList.remove('hidden');
    }

    // Show error state
    function showErrorState() {
        loadingElement.classList.add('hidden');
        videoDetailsElement.classList.add('hidden');
        errorStateElement.classList.remove('hidden');
    }

    // Vote for video
    async function voteForVideo() {
        if (!currentVideo) return;

        try {
            await apiClient.post(`/public/videos/${currentVideo.id}/vote`, {});
            
            // Update vote count
            currentVideo.votes = (currentVideo.votes || 0) + 1;
            videoVotes.textContent = currentVideo.votes;
            
            // Disable vote button
            voteBtn.disabled = true;
            voteBtn.innerHTML = '<i class="fas fa-check mr-2"></i>Voté !';
            voteBtn.classList.remove('btn-success');
            voteBtn.classList.add('btn-secondary');
            
            Toast.show('Vote enregistré avec succès !', 'success');
            
        } catch (error) {
            console.error('Error voting:', error);
            
            let errorMessage = 'Erreur lors du vote';
            if (error.message && error.message.includes('déjà voté')) {
                errorMessage = 'Vous avez déjà voté pour cette vidéo';
            }
            
            Toast.show(errorMessage, 'error');
        }
    }

    // Event listeners
    if (voteBtn) {
        voteBtn.addEventListener('click', voteForVideo);
    }

    // Initialize the page
    init();
});
