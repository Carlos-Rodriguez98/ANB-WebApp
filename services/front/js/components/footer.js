// Footer component
function renderFooter() {
    const footer = document.getElementById('footer');
    if (!footer) return;
    footer.innerHTML = `
    <footer class="bg-dark-900 text-gray-300 py-6 mt-12 shadow-inner">
      <div class="container mx-auto px-4 flex flex-col md:flex-row items-center justify-between">
        <div class="flex items-center space-x-2 mb-2 md:mb-0">
          <img src="https://cdn-icons-png.flaticon.com/512/861/861512.png" alt="ANB Logo" class="h-6 w-6">
          <span class="font-semibold text-primary-400">ANB Rising Stars Showcase</span>
        </div>
        <div class="text-sm">
          <a href="mailto:contact@anb.com" class="hover:text-primary-400 underline">Contacto</a>
          <span class="mx-2">|</span>
          <a href="#" class="hover:text-primary-400 underline">Aviso legal</a>
        </div>
        <div class="text-xs mt-2 md:mt-0">&copy; 2025 ANB. Todos los derechos reservados.</div>
      </div>
    </footer>
    `;
}

document.addEventListener('DOMContentLoaded', renderFooter);
window.renderFooter = renderFooter;
