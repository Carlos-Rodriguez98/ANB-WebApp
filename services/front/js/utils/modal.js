// Modal utility
class Modal {
    static container = null;
    static activeModals = [];

    // Initialize modal container
    static init() {
        this.container = document.getElementById('modal-container');
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.id = 'modal-container';
            document.body.appendChild(this.container);
        }
    }

    // Show a modal
    static show(title, content, buttons = [], options = {}) {
        if (!this.container) this.init();

        const modal = this.createModal(title, content, buttons, options);
        this.container.appendChild(modal);
        this.activeModals.push(modal);

        // Lock body scroll
        document.body.style.overflow = 'hidden';

        // Focus trap
        this.trapFocus(modal);

        return modal;
    }

    // Create modal element
    static createModal(title, content, buttons, options) {
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4';
        
        const defaultButtons = buttons.length === 0 ? [
            { text: 'OK', action: () => this.close(modal), primary: true }
        ] : buttons;

        modal.innerHTML = `
            <div class="bg-white rounded-lg max-w-md w-full max-h-96 overflow-y-auto" role="dialog" aria-modal="true" aria-labelledby="modal-title">
                <div class="p-6">
                    ${title ? `<h3 id="modal-title" class="text-lg font-semibold text-gray-900 mb-4">${title}</h3>` : ''}
                    <div class="text-gray-600 mb-6">
                        ${content}
                    </div>
                    <div class="flex justify-end space-x-3">
                        ${defaultButtons.map(button => `
                            <button 
                                data-modal-action="${button.action ? 'custom' : 'close'}"
                                class="${button.primary 
                                    ? 'bg-primary-500 hover:bg-primary-600 text-white' 
                                    : button.danger 
                                        ? 'bg-red-500 hover:bg-red-600 text-white'
                                        : 'bg-gray-200 hover:bg-gray-300 text-gray-800'
                                } font-medium py-2 px-4 rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 ${button.primary 
                                    ? 'focus:ring-primary-500' 
                                    : button.danger 
                                        ? 'focus:ring-red-500'
                                        : 'focus:ring-gray-500'
                                } focus:ring-opacity-50"
                            >
                                ${button.text}
                            </button>
                        `).join('')}
                    </div>
                </div>
            </div>
        `;

        // Add button event listeners
        const actionButtons = modal.querySelectorAll('[data-modal-action]');
        actionButtons.forEach((button, index) => {
            button.addEventListener('click', () => {
                const buttonConfig = defaultButtons[index];
                if (buttonConfig.action) {
                    buttonConfig.action();
                } else {
                    this.close(modal);
                }
            });
        });

        // Close on backdrop click
        if (!options.disableBackdropClick) {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    this.close(modal);
                }
            });
        }

        // Close on Escape key
        if (!options.disableEscapeKey) {
            const handleEscape = (e) => {
                if (e.key === 'Escape') {
                    this.close(modal);
                    document.removeEventListener('keydown', handleEscape);
                }
            };
            document.addEventListener('keydown', handleEscape);
        }

        return modal;
    }

    // Close modal
    static close(modal) {
        if (!modal || !modal.parentNode) return;

        // Remove from active modals
        const index = this.activeModals.indexOf(modal);
        if (index > -1) {
            this.activeModals.splice(index, 1);
        }

        // Animate out
        modal.style.opacity = '0';
        
        setTimeout(() => {
            if (modal.parentNode) {
                modal.parentNode.removeChild(modal);
            }
            
            // Unlock body scroll if no more modals
            if (this.activeModals.length === 0) {
                document.body.style.overflow = '';
            }
        }, 200);
    }

    // Close all modals
    static closeAll() {
        this.activeModals.forEach(modal => this.close(modal));
    }

    // Trap focus within modal
    static trapFocus(modal) {
        const focusableElements = modal.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        
        if (focusableElements.length === 0) return;

        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];

        // Focus first element
        firstElement.focus();

        const handleTabKey = (e) => {
            if (e.key === 'Tab') {
                if (e.shiftKey) {
                    if (document.activeElement === firstElement) {
                        lastElement.focus();
                        e.preventDefault();
                    }
                } else {
                    if (document.activeElement === lastElement) {
                        firstElement.focus();
                        e.preventDefault();
                    }
                }
            }
        };

        modal.addEventListener('keydown', handleTabKey);
    }

    // Convenience methods
    static confirm(title, message, onConfirm, onCancel) {
        return this.show(title, message, [
            { 
                text: 'Cancel', 
                action: () => {
                    this.close(this.activeModals[this.activeModals.length - 1]);
                    if (onCancel) onCancel();
                }
            },
            { 
                text: 'Confirm', 
                action: () => {
                    this.close(this.activeModals[this.activeModals.length - 1]);
                    if (onConfirm) onConfirm();
                },
                primary: true 
            }
        ]);
    }

    static alert(title, message, onOk) {
        return this.show(title, message, [
            { 
                text: 'OK', 
                action: () => {
                    this.close(this.activeModals[this.activeModals.length - 1]);
                    if (onOk) onOk();
                },
                primary: true 
            }
        ]);
    }

    static danger(title, message, onConfirm, onCancel) {
        return this.show(title, message, [
            { 
                text: 'Cancel', 
                action: () => {
                    this.close(this.activeModals[this.activeModals.length - 1]);
                    if (onCancel) onCancel();
                }
            },
            { 
                text: 'Delete', 
                action: () => {
                    this.close(this.activeModals[this.activeModals.length - 1]);
                    if (onConfirm) onConfirm();
                },
                danger: true 
            }
        ]);
    }
}

// Initialize modal system when DOM loads
document.addEventListener('DOMContentLoaded', () => {
    Modal.init();
});
