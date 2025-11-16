class API {
    constructor() {
        this.baseURL = '/api';
        this.defaultHeaders = {
            'Content-Type': 'application/json',
        };
    }

    getAuthHeaders() {
        const token = localStorage.getItem('jwt_token');
        return token
            ? { ...this.defaultHeaders, 'Authorization': `Bearer ${token}` }
            : { ...this.defaultHeaders };
    }

    // Generic request method (simplificada)
    async request(endpoint, options = {}) {
        const url = `${this.baseURL}${endpoint}`;
        const config = {
            headers: this.getAuthHeaders(),
            ...options,
        };

        try {
            const response = await fetch(url, config);

            // Intentar parsear JSON (si hay)
            let data = null;
            const contentType = response.headers.get('content-type') || '';
            if (contentType.includes('application/json')) {
                try {
                    data = await response.json();
                } catch (e) {
                    data = null;
                }
            } else {
                // si no es JSON, intentar leer texto (por si el backend responde texto)
                try {
                    const text = await response.text();
                    data = text ? { error: text } : null;
                } catch {
                    data = null;
                }
            }

            // Mensaje preferente del backend (primero error, luego message)
            const backendMessage = data?.error || data?.message || null;

            // 401: autenticación
            if (response.status === 401) {
                const message = backendMessage || 'Credenciales inválidas';

                const isLoginRequest = url.includes('/auth/login');

                if (!isLoginRequest) {
                    Auth.logout();
                    // usar window.Router solo si existe y tiene navigate
                    if (window.Router && typeof window.Router.navigate === 'function') {
                        window.Router.navigate('/login');
                    } else {
                        // fallback a redirect tradicional
                        window.location.href = '/login.html';
                    }
                }

                throw new Error(message);
            }

            // Otros errores HTTP (usar el mensaje backend si existe)
            if (!response.ok) {
                const message = backendMessage || `HTTP ${response.status} ${response.statusText}`;
                throw new Error(message);
            }

            // Éxito: retornamos el objeto JSON original (o texto envuelto en { result: text })
            return data;
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    }

    // Convenience wrappers (sin cambios importantes)
    async get(endpoint) {
        return this.request(endpoint, { method: 'GET' });
    }

    async post(endpoint, data) {
        return this.request(endpoint, {
            method: 'POST',
            body: JSON.stringify(data),
        });
    }

    async postFormData(endpoint, formData) {
        // Para FormData NO establezcas Content-Type: el navegador lo hace automáticamente.
        const token = localStorage.getItem('jwt_token');
        const headers = token ? { 'Authorization': `Bearer ${token}` } : {};
        return this.request(endpoint, {
            method: 'POST',
            headers,
            body: formData,
        });
    }

    async put(endpoint, data) {
        return this.request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(data),
        });
    }

    async delete(endpoint) {
        return this.request(endpoint, { method: 'DELETE' });
    }

    // endpoints (igual que antes)
    async signup(userData) { return this.post('/auth/signup', userData); }
    async login(credentials) { return this.post('/auth/login', credentials); }
    async uploadVideo(formData) { return this.postFormData('/videos/upload', formData); }
    async getMyVideos() { return this.get('/videos'); }
    async getVideoById(id) { return this.get(`/videos/${id}`); }
    async deleteVideo(id) { return this.delete(`/videos/${id}`); }
    async getPublicVideos(page = 1, limit = 12) { return this.get(`/public/videos?page=${page}&limit=${limit}`); }
    async getPublicVideoById(id) { return this.get(`/public/videos/${id}`); }
    async voteForVideo(id) { return this.post(`/public/videos/${id}/vote`, {}); }
    async getRankings(city = '', page = 1, limit = 20) {
        const params = new URLSearchParams({ page, limit });
        if (city) params.append('city', city);
        return this.get(`/public/rankings?${params.toString()}`);
    }
}

// Export global instance
window.api = new API();
window.apiClient = window.api;