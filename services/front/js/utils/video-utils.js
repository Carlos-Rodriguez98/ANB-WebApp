// Utilitaires pour la gestion des vidéos
const videoUtils = {
    /**
     * Formate la durée en secondes en format MM:SS ou HH:MM:SS
     */
    formatDuration(seconds) {
        if (!seconds || isNaN(seconds)) return '0:00';
        
        const totalSeconds = Math.floor(seconds);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const secs = totalSeconds % 60;

        if (hours > 0) {
            return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        } else {
            return `${minutes}:${secs.toString().padStart(2, '0')}`;
        }
    },

    /**
     * Génère l'URL de la miniature pour une vidéo
     */
    getThumbnailUrl(video) {
        if (video.thumbnail_url) {
            return video.thumbnail_url;
        }
        
        // Si on a l'URL de la vidéo processée, on peut générer une miniature
        if (video.processed_url || video.processedURL) {
            const videoUrl = video.processed_url || video.processedURL;
            // Remplacer l'extension .mp4 par .jpg pour la miniature
            return videoUrl.replace(/\.mp4$/i, '_thumbnail.jpg');
        }
        
        // Image par défaut
        return 'https://via.placeholder.com/400x225/f97316/ffffff?text=Video';
    },

    /**
     * Obtient la durée d'une vidéo en utilisant l'élément video HTML5
     */
    async getVideoDuration(videoUrl) {
        return new Promise((resolve, reject) => {
            const video = document.createElement('video');
            video.preload = 'metadata';
            
            video.onloadedmetadata = () => {
                resolve(video.duration);
            };
            
            video.onerror = () => {
                reject(new Error('Impossible de charger les métadonnées de la vidéo'));
            };
            
            // Timeout après 10 secondes
            setTimeout(() => {
                reject(new Error('Timeout lors du chargement des métadonnées'));
            }, 10000);
            
            video.src = videoUrl;
        });
    },

    /**
     * Génère une miniature à partir d'une vidéo (première seconde)
     */
    async generateThumbnail(videoUrl, time = 1) {
        return new Promise((resolve, reject) => {
            const video = document.createElement('video');
            video.crossOrigin = 'anonymous';
            video.currentTime = time;
            
            video.onloadeddata = () => {
                const canvas = document.createElement('canvas');
                const ctx = canvas.getContext('2d');
                
                canvas.width = video.videoWidth;
                canvas.height = video.videoHeight;
                
                ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
                
                canvas.toBlob((blob) => {
                    if (blob) {
                        resolve(URL.createObjectURL(blob));
                    } else {
                        reject(new Error('Impossible de générer la miniature'));
                    }
                }, 'image/jpeg', 0.8);
            };
            
            video.onerror = () => {
                reject(new Error('Erreur lors du chargement de la vidéo'));
            };
            
            video.src = videoUrl;
        });
    }
};
