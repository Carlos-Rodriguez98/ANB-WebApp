document.addEventListener('DOMContentLoaded', function() {
    // Upload video functionality
    let selectedFile = null;
    let uploadInProgress = false;

    // Elements
    const uploadForm = document.getElementById('upload-form');
    const dropZone = document.getElementById('drop-zone');
    const fileInput = document.getElementById('video-file');
    const filePreview = document.getElementById('file-preview');
    const fileName = document.getElementById('file-name');
    const fileSize = document.getElementById('file-size');
    const removeFileBtn = document.getElementById('remove-file');
    const uploadProgress = document.getElementById('upload-progress');
    const progressBar = document.getElementById('progress-bar');
    const progressText = document.getElementById('progress-text');
    const submitBtn = document.getElementById('submit-btn');
    const usernameDisplay = document.getElementById('username');
    const logoutBtn = document.getElementById('logoutBtn');

    // Form elements
    const titleInput = document.getElementById('title');
    const categorySelect = document.getElementById('category');
    const positionSelect = document.getElementById('position');
    const visibilitySelect = document.getElementById('visibility');
    const descriptionTextarea = document.getElementById('description');
    const tagsInput = document.getElementById('tags');
    const termsCheckbox = document.getElementById('terms');

    // Initialize
    function init() {
        // Check authentication
        const user = getCurrentUser();
        if (!user) {
            window.location.href = 'login.html';
            return;
        }

        // Display username
        usernameDisplay.textContent = user.firstName || user.email;

        // Setup event listeners
        setupEventListeners();
    }

    // Setup all event listeners
    function setupEventListeners() {
        // File drop and selection
        dropZone.addEventListener('click', () => fileInput.click());
        dropZone.addEventListener('dragover', handleDragOver);
        dropZone.addEventListener('dragleave', handleDragLeave);
        dropZone.addEventListener('drop', handleDrop);
        fileInput.addEventListener('change', handleFileSelect);
        removeFileBtn.addEventListener('click', removeFile);

        // Form submission
        uploadForm.addEventListener('submit', handleSubmit);

        // Logout
        logoutBtn.addEventListener('click', (e) => {
            e.preventDefault();
            logout();
            window.location.href = 'login.html';
        });

        // Auto-generate title from filename
        fileInput.addEventListener('change', () => {
            if (selectedFile && !titleInput.value) {
                const baseName = selectedFile.name.replace(/\.[^/.]+$/, "");
                titleInput.value = baseName;
            }
        });
    }

    // Drag and drop handlers
    function handleDragOver(e) {
        e.preventDefault();
        dropZone.classList.add('border-primary-400', 'bg-primary-50');
    }

    function handleDragLeave(e) {
        e.preventDefault();
        dropZone.classList.remove('border-primary-400', 'bg-primary-50');
    }

    function handleDrop(e) {
        e.preventDefault();
        dropZone.classList.remove('border-primary-400', 'bg-primary-50');
        
        const files = e.dataTransfer.files;
        if (files.length > 0) {
            handleFileSelect({ target: { files } });
        }
    }

    // Handle file selection
    function handleFileSelect(e) {
        const file = e.target.files[0];
        
        if (!file) return;

        // Validate file type
        if (!file.type.startsWith('video/')) {
            showToast('Por favor selecciona un archivo de video válido', 'error');
            return;
        }

        // Validate file size (100MB max)
        const maxSize = 100 * 1024 * 1024; // 100MB
        if (file.size > maxSize) {
            showToast('El archivo es demasiado grande. Tamaño máximo: 100MB', 'error');
            return;
        }

        selectedFile = file;
        showFilePreview();
    }

    // Show file preview
    function showFilePreview() {
        if (!selectedFile) return;

        fileName.textContent = selectedFile.name;
        fileSize.textContent = formatFileSize(selectedFile.size);
        
        filePreview.classList.remove('hidden');
        dropZone.style.display = 'none';
    }

    // Remove selected file
    function removeFile() {
        selectedFile = null;
        fileInput.value = '';
        filePreview.classList.add('hidden');
        dropZone.style.display = 'block';
        
        // Clear auto-generated title if it matches filename
        if (titleInput.value && selectedFile) {
            const baseName = selectedFile.name.replace(/\.[^/.]+$/, "");
            if (titleInput.value === baseName) {
                titleInput.value = '';
            }
        }
    }

    // Format file size
    function formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    // Handle form submission
    async function handleSubmit(e) {
        e.preventDefault();
        
        if (uploadInProgress) return;

        // Validate form
        if (!validateForm()) return;

        uploadInProgress = true;
        showUploadProgress();

        try {
            // Create FormData
            const formData = new FormData();
            formData.append('video', selectedFile);
            formData.append('title', titleInput.value.trim());
            formData.append('category', categorySelect.value);
            formData.append('position', positionSelect.value);
            formData.append('visibility', visibilitySelect.value);
            formData.append('description', descriptionTextarea.value.trim());
            formData.append('tags', tagsInput.value.trim());

            // Simulate upload progress
            await simulateUploadProgress();

            // Make API call
            const response = await apiClient.postFormData('/api/videos/upload', formData);
            
            showToast('¡Video subido exitosamente!', 'success');
            
            // Redirect to dashboard after short delay
            setTimeout(() => {
                window.location.href = 'dashboard.html';
            }, 2000);

        } catch (error) {
            console.error('Upload error:', error);
            showToast('Error al subir el video', 'error');
            hideUploadProgress();
            uploadInProgress = false;
        }
    }

    // Validate form
    function validateForm() {
        // Check file
        if (!selectedFile) {
            showToast('Veuillez sélectionner un fichier vidéo', 'error');
            return false;
        }

        // Check required fields
        if (!titleInput.value.trim()) {
            showToast('Le titre est requis', 'error');
            titleInput.focus();
            return false;
        }

        if (!categorySelect.value) {
            showToast('Veuillez sélectionner une catégorie', 'error');
            categorySelect.focus();
            return false;
        }

        if (!positionSelect.value) {
            showToast('Veuillez sélectionner votre poste', 'error');
            positionSelect.focus();
            return false;
        }

        if (!visibilitySelect.value) {
            showToast('Veuillez sélectionner la visibilité', 'error');
            visibilitySelect.focus();
            return false;
        }

        if (!termsCheckbox.checked) {
            showToast('Vous devez accepter les conditions d\'utilisation', 'error');
            termsCheckbox.focus();
            return false;
        }

        return true;
    }

    // Show upload progress
    function showUploadProgress() {
        uploadProgress.classList.remove('hidden');
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Upload en cours...';
        
        // Disable form fields
        const formElements = uploadForm.querySelectorAll('input, select, textarea, button');
        formElements.forEach(element => {
            if (element !== submitBtn) {
                element.disabled = true;
            }
        });
    }

    // Hide upload progress
    function hideUploadProgress() {
        uploadProgress.classList.add('hidden');
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<i class="fas fa-upload mr-2"></i>Uploader la vidéo';
        
        // Re-enable form fields
        const formElements = uploadForm.querySelectorAll('input, select, textarea, button');
        formElements.forEach(element => {
            element.disabled = false;
        });
    }

    // Simulate upload progress
    function simulateUploadProgress() {
        return new Promise((resolve) => {
            let progress = 0;
            const interval = setInterval(() => {
                progress += Math.random() * 15;
                if (progress >= 100) {
                    progress = 100;
                    clearInterval(interval);
                    setTimeout(resolve, 500);
                }
                
                progressBar.style.width = `${progress}%`;
                progressText.textContent = `${Math.round(progress)}%`;
            }, 200);
        });
    }

    // Initialize the page
    init();
});
