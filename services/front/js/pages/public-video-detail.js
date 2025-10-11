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

        // Basic info - adapter aux vrais champs retournés par le service voting
        videoTitle.textContent = currentVideo.titulo || currentVideo.title || 'Titre non disponible';
        videoPlayerName.textContent = currentVideo.playerName || `Joueur ${currentVideo.jugador_id}` || 'Joueur inconnu';
        videoCity.textContent = currentVideo.city || 'Ville inconnue';

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

        // Votes - adapter au vrai champ
        videoVotes.textContent = currentVideo.votos || currentVideo.votes || 0;

        // Video player - construire l'URL en utilisant le pattern du service vidéo
        let videoUrl = currentVideo.processed_url || 
                      currentVideo.processedUrl || 
                      currentVideo.url || 
                      currentVideo.video_url;
        
        if (!videoUrl && currentVideo.id && currentVideo.jugador_id) {
            // Construire l'URL basée sur le pattern: /static/processed/u{user_id}/{video_id}.mp4
            videoUrl = `http://localhost:8085/static/processed/u${currentVideo.jugador_id}/${currentVideo.id}.mp4`;
            console.log('URL construite à partir du pattern:', videoUrl);
        }
        
        if (!videoUrl) {
            // URL de vidéo de test en fallback
            videoUrl = 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4';
            console.warn('Aucune URL de vidéo trouvée, utilisation d\'une vidéo de test');
        }
        
        videoSource.src = videoUrl;
        videoPlayer.load();

        console.log('Détails de la vidéo:', currentVideo);
        console.log('URL finale de la vidéo:', videoUrl);

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

        // Vérifier si l'utilisateur est authentifié
        if (!Auth.isAuthenticated()) {
            showToast('Debes iniciar sesión para votar', 'warning');
            setTimeout(() => {
                window.location.href = 'login.html';
            }, 1500);
            return;
        }

        // Extraire l'ID utilisateur du token JWT
        const token = Auth.getToken();
        let userId;
        try {
            const payload = JSON.parse(atob(token.split('.')[1]));
            userId = payload.user_id || payload.sub || payload.id;
            
            console.log('JWT payload:', payload);
            console.log('Extracted userId:', userId);
            
            if (!userId) {
                showToast('Error: No se pudo obtener el ID de usuario', 'error');
                return;
            }
        } catch (error) {
            console.error('Error parsing JWT:', error);
            showToast('Error: Token inválido', 'error');
            return;
        }

        try {
            console.log('Sending vote with user_id:', parseInt(userId));
            await apiClient.post(`/public/videos/${currentVideo.id}/vote`, {
                user_id: parseInt(userId)
            });
            
            // Update vote count - adapter aux vrais champs
            if (currentVideo.votos !== undefined) {
                currentVideo.votos = (currentVideo.votos || 0) + 1;
                videoVotes.textContent = currentVideo.votos;
            } else {
                currentVideo.votes = (currentVideo.votes || 0) + 1;
                videoVotes.textContent = currentVideo.votes;
            }
            
            // Disable vote button
            voteBtn.disabled = true;
            voteBtn.innerHTML = '<i class="fas fa-check mr-2"></i>Voté !';
            voteBtn.classList.remove('btn-success');
            voteBtn.classList.add('btn-secondary');
            
            showToast('Vote enregistré avec succès !', 'success');
            
        } catch (error) {
            console.error('Error voting:', error);
            
            let errorMessage = 'Erreur lors du vote';
            if (error.message && error.message.includes('déjà voté')) {
                errorMessage = 'Vous avez déjà voté pour cette vidéo';
            } else if (error.message.includes('Session expired') || error.message.includes('401')) {
                showToast('Sesión expirada. Redirigiendo al login...', 'warning');
                setTimeout(() => {
                    window.location.href = 'login.html';
                }, 1500);
                return;
            }
            
            showToast(errorMessage, 'error');
        }
    }

    // Event listeners
    if (voteBtn) {
        voteBtn.addEventListener('click', voteForVideo);
    }

    // Initialize the page
    init();
});
