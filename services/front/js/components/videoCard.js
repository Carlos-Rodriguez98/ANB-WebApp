// VideoCard component
function VideoCard({
    id, title, playerName, city, thumbnailUrl, votes, onClick, showVotes = true, showCity = true
}) {
    return `
    <div class="card card-hover p-3 flex flex-col h-full cursor-pointer" tabindex="0" aria-label="Ver el video ${title}" onclick="${onClick ? onClick : `Router.navigate('/public/videos/${id}')`}">
        <div class="aspect-w-16 aspect-h-9 bg-gray-200 rounded-lg overflow-hidden mb-2 flex items-center justify-center">
            <img src="${thumbnailUrl || 'https://placehold.co/320x180?text=Video'}" alt="Miniatura de video" class="object-cover w-full h-full">
        </div>
        <div class="flex-1 flex flex-col justify-between">
            <div>
                <h3 class="font-semibold text-gray-900 text-base truncate">${title}</h3>
                ${showCity && city ? `<div class="text-xs text-gray-500 mt-1"><i class='fas fa-map-marker-alt mr-1'></i>${city}</div>` : ''}
            </div>
            <div class="flex items-center justify-between mt-2">
                ${showVotes ? `<span class="badge badge-info"><i class="fas fa-thumbs-up mr-1"></i>${votes ?? 0} voto${votes === 1 ? '' : 's'}</span>` : ''}
                ${playerName ? `<span class="text-xs text-gray-700 font-medium">${playerName}</span>` : ''}
            </div>
        </div>
    </div>
    `;
}

window.VideoCard = VideoCard;
