// VideoPlayer component
function VideoPlayer({ src, poster = '', controls = true, className = '' }) {
    return `
    <div class="video-container ${className}">
        <video 
            src="${src}"
            ${poster ? `poster='${poster}'` : ''}
            ${controls ? 'controls' : ''}
            preload="metadata"
            class="w-full h-full rounded-lg"
        >
            Votre navigateur ne supporte pas la lecture vidéo.
        </video>
    </div>
    `;
}

window.VideoPlayer = VideoPlayer;
