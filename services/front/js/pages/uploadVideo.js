// Upload Video Page
async function renderUploadVideoPage() {
    if (!Auth.requireAuth()) return;
    const app = document.getElementById('app');
    app.innerHTML = `
    <section class="flex flex-col items-center justify-center min-h-[80vh] py-8 fade-in">
      <div class="w-full max-w-md bg-white rounded-lg shadow-lg p-8">
        <h2 class="text-2xl font-bold text-center text-primary-600 mb-6">Uploader une vidéo</h2>
        <form id="upload-form" autocomplete="off" enctype="multipart/form-data" novalidate>
          <div class="form-group">
            <label for="title" class="block text-gray-700">Título *</label>
            <input type="text" id="title" name="title" class="form-input" required maxlength="100">
            <div class="form-error" id="error-title"></div>
          </div>
          <div class="form-group">
            <label for="file" class="block text-gray-700">Video (MP4, máx 100MB) *</label>
            <input type="file" id="file" name="file" class="form-input" accept="video/mp4" required>
            <div class="form-error" id="error-file"></div>
          </div>
          <button type="submit" class="btn-primary w-full mt-4">Enviar</button>
        </form>
        <div class="text-center mt-4 text-sm">
          <a href="/dashboard" onclick="Router.navigate('/dashboard'); return false;" class="text-primary-500 hover:underline">Volver a mi espacio</a>
        </div>
      </div>
    </section>
    `;

    // Form validation and submit
    const form = document.getElementById('upload-form');
    form.onsubmit = async (e) => {
        e.preventDefault();
        form['error-title'].textContent = '';
        form['error-file'].textContent = '';
        const title = form.title.value.trim();
        const file = form.file.files[0];
        let hasError = false;
        if (!title) {
            form['error-title'].textContent = 'Título requerido.';
            hasError = true;
        }
        if (!file) {
            form['error-file'].textContent = 'Archivo requerido.';
            hasError = true;
        } else if (file.type !== 'video/mp4') {
            form['error-file'].textContent = 'Solo formato MP4.';
            hasError = true;
        } else if (file.size > 100 * 1024 * 1024) {
            form['error-file'].textContent = 'Archivo muy grande (máx 100MB).';
            hasError = true;
        }
        if (hasError) return;
        // API call
        try {
            const formData = new FormData();
            formData.append('title', title);
            formData.append('file', file);
            await api.uploadVideo(formData);
            Toast.success('Video subido exitosamente. Procesamiento en curso...');
            Router.navigate('/dashboard');
        } catch (err) {
            Toast.error(err.message || 'Error durante la subida');
        }
    };
}

window.renderUploadVideoPage = renderUploadVideoPage;