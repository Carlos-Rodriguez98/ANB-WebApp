// Pagination component
function Pagination({ currentPage, totalPages, onPageChange }) {
    if (totalPages <= 1) return '';
    let pages = [];
    for (let i = 1; i <= totalPages; i++) {
        if (i === 1 || i === totalPages || Math.abs(i - currentPage) <= 1) {
            pages.push(i);
        } else if (
            (i === currentPage - 2 && currentPage > 3) ||
            (i === currentPage + 2 && currentPage < totalPages - 2)
        ) {
            pages.push('...');
        }
    }
    // Remove duplicate '...'
    pages = pages.filter((v, i, a) => v !== '...' || a[i - 1] !== '...');

    return `
    <nav class="flex justify-center mt-6" aria-label="Pagination">
        <ul class="inline-flex items-center space-x-1">
            <li>
                <button class="px-3 py-1 rounded-l-lg ${currentPage === 1 ? 'bg-gray-200 text-gray-400 cursor-not-allowed' : 'bg-white hover:bg-primary-100 text-primary-600'}" ${currentPage === 1 ? 'disabled' : ''} onclick="${onPageChange}(${currentPage - 1})" aria-label="Página anterior">
                    <i class="fas fa-chevron-left"></i>
                </button>
            </li>
            ${pages.map(p =>
                p === '...'
                    ? `<li><span class="px-3 py-1 text-gray-400">...</span></li>`
                    : `<li><button class="px-3 py-1 rounded ${p === currentPage ? 'bg-primary-500 text-white' : 'bg-white hover:bg-primary-100 text-primary-600'}" onclick="${onPageChange}(${p})" aria-label="Página ${p}">${p}</button></li>`
            ).join('')}
            <li>
                <button class="px-3 py-1 rounded-r-lg ${currentPage === totalPages ? 'bg-gray-200 text-gray-400 cursor-not-allowed' : 'bg-white hover:bg-primary-100 text-primary-600'}" ${currentPage === totalPages ? 'disabled' : ''} onclick="${onPageChange}(${currentPage + 1})" aria-label="Página siguiente">
                    <i class="fas fa-chevron-right"></i>
                </button>
            </li>
        </ul>
    </nav>
    `;
}

window.Pagination = Pagination;
