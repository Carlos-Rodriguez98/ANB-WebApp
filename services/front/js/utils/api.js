// API utility functions
class API {
    constructor() {
        this.baseURL = '/api';
        this.defaultHeaders = {
            'Content-Type': 'application/json',
        };
    }

    // Get authorization header with JWT token
    getAuthHeaders() {
        const token = localStorage.getItem('jwt_token');
        return token 
            ? { ...this.defaultHeaders, 'Authorization': `Bearer ${token}` }
            : this.defaultHeaders;
    }

    // Generic request method
    async request(endpoint, options = {}) {
        const url = `${this.baseURL}${endpoint}`;
        const config = {
            headers: this.getAuthHeaders(),
            ...options,
        };

        try {
            const response = await fetch(url, config);
            
            // Handle different response status codes
            if (response.status === 401) {
                // Unauthorized - redirect to login
                Auth.logout();
                Router.navigate('/login');
                throw new Error('Session expired. Please login again.');
            }
            
            if (response.status === 403) {
                throw new Error('Access forbidden. You don\'t have permission to perform this action.');
            }
            
            if (response.status === 404) {
                throw new Error('Resource not found.');
            }
            
            if (!response.ok) {
                const errorData = await response.text();
                let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
                
                try {
                    const parsedError = JSON.parse(errorData);
                    errorMessage = parsedError.message || parsedError.error || errorMessage;
                } catch (e) {
                    if (errorData) errorMessage = errorData;
                }
                
                throw new Error(errorMessage);
            }

            // Handle empty responses
            const contentType = response.headers.get('content-type');
            if (contentType && contentType.includes('application/json')) {
                return await response.json();
            } else {
                return await response.text();
            }
            
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    }

    // GET request
    async get(endpoint) {
        return this.request(endpoint, { method: 'GET' });
    }

    // POST request
    async post(endpoint, data) {
        return this.request(endpoint, {
            method: 'POST',
            body: JSON.stringify(data),
        });
    }

    // POST request with file upload (FormData)
    async postFormData(endpoint, formData) {
        const token = localStorage.getItem('jwt_token');
        const headers = token ? { 'Authorization': `Bearer ${token}` } : {};
        
        return this.request(endpoint, {
            method: 'POST',
            headers,
            body: formData,
        });
    }

    // PUT request
    async put(endpoint, data) {
        return this.request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(data),
        });
    }

    // DELETE request
    async delete(endpoint) {
        return this.request(endpoint, { method: 'DELETE' });
    }

    // Auth endpoints
    async signup(userData) {
        return this.post('/auth/signup', userData);
    }

    async login(credentials) {
        return this.post('/auth/login', credentials);
    }

    // Video endpoints
    async uploadVideo(formData) {
        return this.postFormData('/videos/upload', formData);
    }

    async getMyVideos() {
        return this.get('/videos');
    }

    async getVideoById(id) {
        return this.get(`/videos/${id}`);
    }

    async deleteVideo(id) {
        return this.delete(`/videos/${id}`);
    }

    // Public endpoints
    async getPublicVideos(page = 1, limit = 12) {
        return this.get(`/public/videos?page=${page}&limit=${limit}`);
    }

    async getPublicVideoById(id) {
        return this.get(`/public/videos/${id}`);
    }

    async voteForVideo(id) {
        return this.post(`/public/videos/${id}/vote`, {});
    }

    async getRankings(city = '', page = 1, limit = 20) {
        const params = new URLSearchParams({ page, limit });
        if (city) params.append('city', city);
        return this.get(`/public/rankings?${params.toString()}`);
    }
}

// Create global API instance
window.api = new API();

// Alias for compatibility with new pages
window.apiClient = window.api;
