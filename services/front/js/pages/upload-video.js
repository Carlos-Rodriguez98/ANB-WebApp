document.addEventListener('DOMContentLoaded', function() {
    // Upload video functionality
    let selectedFile = null;
    let uploadInProgress = false;

    // Elements
    const uploadForm = document.getElementById('upload-form');
    const dropZone = document.getElementById('drop-zone');
    const selectVideoBtn = document.getElementById('select-video-btn');
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
    // Removed unnecessary form fields - video service only needs title

    // Initialize
    function init() {
        // Check authentication
        const user = Auth.getCurrentUser();
        if (!user) {
            window.location.href = 'login.html';
            return;
        }

        // Display username
        if (usernameDisplay) {
            usernameDisplay.textContent = user.firstName || user.email;
        }

        // Wait a bit for DOM to be fully ready
        setTimeout(() => {
            // Debug: Log elements to check if they exist
            console.log('Upload form elements found:', {
                dropZone: !!dropZone,
                selectVideoBtn: !!selectVideoBtn,
                fileInput: !!fileInput,
                uploadForm: !!uploadForm,
                titleInput: !!titleInput
            });

            // Log the actual elements for debugging
            console.log('Elements:', {
                dropZone,
                selectVideoBtn,
                fileInput,
                uploadForm
            });

            // Verify file input is properly configured
            if (fileInput) {
                console.log('File input configured successfully');
            }

            // Setup event listeners
            setupEventListeners();
        }, 100);
    }

    // Setup all event listeners
    function setupEventListeners() {
        // File drop and selection
        if (dropZone) {
            console.log('Setting up dropZone listeners');
            dropZone.addEventListener('click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                console.log('Drop zone clicked, triggering file input');
                if (fileInput) {
                    try {
                        fileInput.click();
                    } catch (error) {
                        console.error('Error triggering file input click:', error);
                        triggerFileInputAlternative();
                    }
                } else {
                    console.error('File input not found when drop zone clicked');
                }
            });
            dropZone.addEventListener('dragover', handleDragOver);
            dropZone.addEventListener('dragleave', handleDragLeave);
            dropZone.addEventListener('drop', handleDrop);
        } else {
            console.error('Drop zone element not found');
        }
        
        if (selectVideoBtn) {
            selectVideoBtn.addEventListener('click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                if (fileInput) {
                    try {
                        fileInput.click();
                    } catch (error) {
                        console.error('Error with fileInput.click():', error);
                        triggerFileInputAlternative();
                    }
                } else {
                    console.error('File input not found when button clicked');
                }
            });
        } else {
            console.error('Select video button not found');
        }
        
        if (fileInput) {
            fileInput.addEventListener('change', handleFileSelect);
        } else {
            console.error('File input element not found');
        }
        
        if (removeFileBtn) {
            removeFileBtn.addEventListener('click', removeFile);
        }

        // Form submission
        if (uploadForm) {
            uploadForm.addEventListener('submit', handleSubmit);
        }

        // Logout
        if (logoutBtn) {
            logoutBtn.addEventListener('click', (e) => {
                e.preventDefault();
                Auth.logout();
                window.location.href = 'login.html';
            });
        }

        // Auto-generate title from filename
        if (fileInput && titleInput) {
            fileInput.addEventListener('change', () => {
                if (selectedFile && !titleInput.value) {
                    const baseName = selectedFile.name.replace(/\.[^/.]+$/, "");
                    titleInput.value = baseName;
                }
            });
        }
    }

    // Alternative method to trigger file input
    function triggerFileInputAlternative() {
        console.log('Using alternative method to trigger file input');
        
        // Method 1: Dispatch mouse event
        try {
            const event = new MouseEvent('click', {
                bubbles: true,
                cancelable: true,
                view: window
            });
            fileInput.dispatchEvent(event);
            console.log('Alternative method 1 (MouseEvent) executed');
        } catch (error) {
            console.error('Alternative method 1 failed:', error);
            
            // Method 2: Focus and programmatic trigger
            try {
                fileInput.style.position = 'static';
                fileInput.style.opacity = '1';
                fileInput.style.width = '1px';
                fileInput.style.height = '1px';
                fileInput.focus();
                setTimeout(() => {
                    fileInput.click();
                    fileInput.style.position = 'absolute';
                    fileInput.style.left = '-9999px';
                    fileInput.style.opacity = '0';
                    fileInput.style.width = 'auto';
                    fileInput.style.height = 'auto';
                }, 100);
                console.log('Alternative method 2 (focus) executed');
            } catch (error2) {
                console.error('Alternative method 2 failed:', error2);
            }
        }
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
            Toast.show('Por favor selecciona un archivo de video válido', 'error');
            return;
        }

        // Validate file size (100MB max)
        const maxSize = 100 * 1024 * 1024; // 100MB
        if (file.size > maxSize) {
            Toast.show('El archivo es demasiado grande. Tamaño máximo: 100MB', 'error');
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
        const oldSelectedFile = selectedFile;
        selectedFile = null;
        fileInput.value = '';
        filePreview.classList.add('hidden');
        dropZone.style.display = 'block';
        
        // Clear auto-generated title if it matches filename
        if (titleInput.value && oldSelectedFile) {
            const baseName = oldSelectedFile.name.replace(/\.[^/.]+$/, "");
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
            // Create FormData - Only send what the video service expects
            const formData = new FormData();
            formData.append('video_file', selectedFile);  // video service expects 'video_file'
            formData.append('title', titleInput.value.trim());

            // Simulate upload progress
            await simulateUploadProgress();

            // Make API call to video service
            const response = await apiClient.postFormData('/videos/upload', formData);
            
            console.log('Upload response:', response);
            
            // Le service vidéo retourne { message, task_id }
            if (response.message) {
                Toast.show(response.message, 'success');
            } else {
                Toast.show('¡Video subido exitosamente!', 'success');
            }
            
            // Redirect to dashboard after short delay
            setTimeout(() => {
                window.location.href = 'dashboard.html';
            }, 2000);

        } catch (error) {
            console.error('Upload error:', error);
            let errorMessage = 'Error al subir el video';
            
            // Try to extract error message from response
            if (error.message) {
                errorMessage = error.message;
            }
            
            Toast.show(errorMessage, 'error');
            hideUploadProgress();
            uploadInProgress = false;
        }
    }

    // Validate form
    function validateForm() {
        // Check file
        if (!selectedFile) {
            Toast.show('Veuillez sélectionner un fichier vidéo', 'error');
            return false;
        }

        // Check required fields - only title is required by video service
        if (!titleInput.value.trim()) {
            Toast.show('El título es requerido', 'error');
            titleInput.focus();
            return false;
        }

        return true;
    }

    // Show upload progress
    function showUploadProgress() {
        uploadProgress.classList.remove('hidden');
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Subida en curso...';
        
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