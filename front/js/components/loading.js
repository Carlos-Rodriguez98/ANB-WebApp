// Loading spinner and skeletons
function LoadingSpinner({ className = '' } = {}) {
    return `<div class="flex justify-center items-center ${className}"><div class="spinner"></div></div>`;
}

function SkeletonText({ width = 'w-32', className = '' } = {}) {
    return `<div class="skeleton skeleton-text ${width} ${className}"></div>`;
}

function SkeletonCard() {
    return `
    <div class="card p-3 animate-pulse">
        <div class="aspect-w-16 aspect-h-9 bg-gray-200 rounded-lg mb-2"></div>
        <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
        <div class="h-3 bg-gray-200 rounded w-1/2"></div>
    </div>
    `;
}

window.LoadingSpinner = LoadingSpinner;
window.SkeletonText = SkeletonText;
window.SkeletonCard = SkeletonCard;
