// Toast notification utility
class Toast {
    static container = null;

    // Initialize toast container
    static init() {
        this.container = document.getElementById('toast-container');
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.id = 'toast-container';
            this.container.className = 'fixed top-4 right-4 z-50 space-y-2';
            document.body.appendChild(this.container);
        }
    }

    // Show a toast notification
    static show(message, type = 'info', duration = 5000) {
        if (!this.container) this.init();

        const toast = this.createToast(message, type);
        this.container.appendChild(toast);

        // Auto remove after duration
        setTimeout(() => {
            this.remove(toast);
        }, duration);

        // Add click to dismiss
        toast.addEventListener('click', () => {
            this.remove(toast);
        });

        return toast;
    }

    // Create toast element
    static createToast(message, type) {
        const toast = document.createElement('div');
        toast.className = `toast ${type} px-4 py-3 rounded-lg shadow-lg text-white max-w-sm cursor-pointer transform translate-x-full`;
        
        const icons = {
            success: 'fas fa-check-circle',
            error: 'fas fa-times-circle',
            warning: 'fas fa-exclamation-triangle',
            info: 'fas fa-info-circle'
        };

        const colors = {
            success: 'bg-green-500',
            error: 'bg-red-500',
            warning: 'bg-yellow-500',
            info: 'bg-blue-500'
        };

        toast.classList.add(colors[type] || colors.info);

        toast.innerHTML = `
            <div class="flex items-center">
                <i class="${icons[type] || icons.info} mr-3"></i>
                <span class="flex-1">${message}</span>
                <button class="ml-3 text-white hover:text-gray-200 focus:outline-none">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        `;

        // Add close button functionality
        const closeBtn = toast.querySelector('button');
        closeBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            this.remove(toast);
        });

        // Animate in
        setTimeout(() => {
            toast.classList.remove('translate-x-full');
        }, 10);

        return toast;
    }

    // Remove toast with animation
    static remove(toast) {
        if (!toast || !toast.parentNode) return;

        toast.style.transform = 'translateX(100%)';
        toast.style.opacity = '0';
        
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 300);
    }

    // Convenience methods
    static success(message, duration) {
        return this.show(message, 'success', duration);
    }

    static error(message, duration) {
        return this.show(message, 'error', duration);
    }

    static warning(message, duration) {
        return this.show(message, 'warning', duration);
    }

    static info(message, duration) {
        return this.show(message, 'info', duration);
    }

    // Clear all toasts
    static clear() {
        if (this.container) {
            this.container.innerHTML = '';
        }
    }
}

// Initialize toast system when DOM loads
document.addEventListener('DOMContentLoaded', () => {
    Toast.init();
});
