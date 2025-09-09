#!/usr/bin/env python3
"""
Serveur statique simple pour tester l'application ANB Rising Stars Showcase
Avec simulation des endpoints API backend
"""
import http.server
import socketserver
import os
import sys
import json
import time
from urllib.parse import urlparse, parse_qs

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """
    Handler personnalisé pour servir l'application SPA
    Et simuler les endpoints API backend
    """
    
    def end_headers(self):
        # Ajouter l'encodage UTF-8 pour tous les fichiers HTML
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        super().end_headers()
    
    # Données simulées
    users = [
        {"id": "1", "firstName": "Jean", "lastName": "Dupont", "email": "jean@test.com", "city": "Paris", "country": "France"}
    ]
    videos = [
        {
            "id": "1", 
            "title": "Mi dribleo increíble", 
            "status": "processed", 
            "uploadedAt": "2025-08-25T10:00:00Z",
            "processedAt": "2025-08-25T10:05:00Z",
            "votes": 15,
            "processedUrl": "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
            "playerName": "Jean Dupont",
            "city": "Paris",
            "userId": "1"
        },
        {
            "id": "2", 
            "title": "Tir à 3 points", 
            "status": "processed", 
            "uploadedAt": "2025-08-24T14:30:00Z",
            "processedAt": "2025-08-24T14:35:00Z",
            "votes": 8,
            "processedUrl": "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4",
            "playerName": "Marie Martin",
            "city": "Lyon",
            "userId": "2"
        }
    ]
    votes = {}  # {"videoId": ["userId1", "userId2"]}
    current_user_id = None
    
    def send_json_response(self, data, status=200):
        """Envoie une réponse JSON"""
        self.send_response(status)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def get_request_data(self):
        """Récupère les données JSON de la requête"""
        content_length = int(self.headers.get('Content-Length', 0))
        if content_length > 0:
            post_data = self.rfile.read(content_length)
            return json.loads(post_data.decode())
        return {}
    
    def handle_auth_signup(self):
        """Simule POST /api/auth/signup"""
        data = self.get_request_data()
        # Validation basique
        if not data.get('email') or not data.get('password'):
            self.send_json_response({"error": "Email et mot de passe requis"}, 400)
            return
        
        # Créer un nouvel utilisateur
        new_user = {
            "id": str(len(self.users) + 1),
            "firstName": data.get('firstName', ''),
            "lastName": data.get('lastName', ''),
            "email": data['email'],
            "city": data.get('city', ''),
            "country": data.get('country', '')
        }
        self.users.append(new_user)
        
        # Générer un token simple
        token = f"fake-jwt-token-{new_user['id']}-{int(time.time())}"
        self.send_json_response({
            "token": token,
            "user": new_user
        })
    
    def handle_auth_login(self):
        """Simule POST /api/auth/login"""
        data = self.get_request_data()
        email = data.get('email')
        
        # Trouver l'utilisateur (mot de passe non vérifié pour la démo)
        user = next((u for u in self.users if u['email'] == email), None)
        if not user:
            self.send_json_response({"error": "Utilisateur non trouvé"}, 401)
            return
        
        token = f"fake-jwt-token-{user['id']}-{int(time.time())}"
        self.current_user_id = user['id']
        self.send_json_response({
            "token": token,
            "user": user
        })
    
    def handle_videos_upload(self):
        """Simule POST /api/videos/upload"""
        # Simuler l'upload (normalement multipart/form-data)
        new_video = {
            "id": str(len(self.videos) + 1),
            "title": "Nouvelle vidéo uploadée",
            "status": "processing",
            "uploadedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "processedAt": None,
            "votes": 0,
            "userId": self.current_user_id or "1"
        }
        self.videos.append(new_video)
        self.send_json_response({"message": "Vidéo uploadée avec succès", "video": new_video})
    
    def handle_get_my_videos(self):
        """Simule GET /api/videos"""
        user_videos = [v for v in self.videos if v.get('userId') == (self.current_user_id or "1")]
        self.send_json_response(user_videos)
    
    def handle_get_video_by_id(self, video_id):
        """Simule GET /api/videos/:id"""
        video = next((v for v in self.videos if v['id'] == video_id), None)
        if not video:
            self.send_json_response({"error": "Vidéo non trouvée"}, 404)
            return
        self.send_json_response(video)
    
    def handle_delete_video(self, video_id):
        """Simule DELETE /api/videos/:id"""
        video = next((v for v in self.videos if v['id'] == video_id), None)
        if not video:
            self.send_json_response({"error": "Vidéo non trouvée"}, 404)
            return
        
        self.videos.remove(video)
        self.send_json_response({"message": "Vidéo supprimée"})
    
    def handle_get_public_videos(self, query_params):
        """Simule GET /api/public/videos"""
        page = int(query_params.get('page', [1])[0])
        limit = int(query_params.get('limit', [12])[0])
        
        processed_videos = [v for v in self.videos if v['status'] == 'processed']
        total = len(processed_videos)
        start = (page - 1) * limit
        end = start + limit
        
        self.send_json_response({
            "videos": processed_videos[start:end],
            "total": total,
            "totalPages": (total + limit - 1) // limit,
            "currentPage": page
        })
    
    def handle_get_public_video_by_id(self, video_id):
        """Simule GET /api/public/videos/:id"""
        video = next((v for v in self.videos if v['id'] == video_id and v['status'] == 'processed'), None)
        if not video:
            self.send_json_response({"error": "Vidéo non trouvée"}, 404)
            return
        self.send_json_response(video)
    
    def handle_vote_for_video(self, video_id):
        """Simule POST /api/public/videos/:id/vote"""
        if not self.current_user_id:
            self.send_json_response({"error": "Non autorisé"}, 401)
            return
        
        video = next((v for v in self.videos if v['id'] == video_id), None)
        if not video:
            self.send_json_response({"error": "Vidéo non trouvée"}, 404)
            return
        
        # Vérifier si l'utilisateur a déjà voté
        if video_id not in self.votes:
            self.votes[video_id] = []
        
        if self.current_user_id in self.votes[video_id]:
            self.send_json_response({"error": "Vous avez déjà voté pour cette vidéo"}, 400)
            return
        
        self.votes[video_id].append(self.current_user_id)
        video['votes'] = len(self.votes[video_id])
        
        self.send_json_response({"message": "Vote enregistré"})
    
    def handle_get_rankings(self, query_params):
        """Simule GET /api/public/rankings"""
        city_filter = query_params.get('city', [''])[0]
        page = int(query_params.get('page', [1])[0])
        limit = int(query_params.get('limit', [20])[0])
        
        # Créer des classements basés sur les votes
        rankings = []
        user_votes = {}
        
        for video in self.videos:
            user_id = video.get('userId')
            if user_id:
                user = next((u for u in self.users if u['id'] == user_id), None)
                if user:
                    key = user['id']
                    if key not in user_votes:
                        user_votes[key] = {
                            "username": f"{user['firstName']} {user['lastName']}",
                            "city": user['city'],
                            "votes": 0
                        }
                    user_votes[key]['votes'] += video.get('votes', 0)
        
        rankings = list(user_votes.values())
        
        # Filtrer par ville si spécifié
        if city_filter:
            rankings = [r for r in rankings if city_filter.lower() in r['city'].lower()]
        
        # Trier par votes décroissants
        rankings.sort(key=lambda x: x['votes'], reverse=True)
        
        total = len(rankings)
        start = (page - 1) * limit
        end = start + limit
        
        self.send_json_response({
            "rankings": rankings[start:end],
            "total": total,
            "totalPages": (total + limit - 1) // limit if total > 0 else 1,
            "currentPage": page
        })
    
    def end_headers(self):
        # Ajouter les headers CORS pour le développement
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        super().end_headers()
    
    def do_OPTIONS(self):
        """Gère les requêtes CORS preflight"""
        self.send_response(200)
        self.end_headers()
    
    def do_POST(self):
        """Gère les requêtes POST pour les endpoints API"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        # Endpoints d'authentification
        if path == '/api/auth/signup':
            return self.handle_auth_signup()
        elif path == '/api/auth/login':
            return self.handle_auth_login()
        elif path == '/api/videos/upload':
            return self.handle_videos_upload()
        elif path.startswith('/api/public/videos/') and path.endswith('/vote'):
            video_id = path.split('/')[-2]
            return self.handle_vote_for_video(video_id)
        
        # Si ce n'est pas un endpoint API, erreur 404
        self.send_json_response({"error": "Endpoint non trouvé"}, 404)
    
    def do_DELETE(self):
        """Gère les requêtes DELETE"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        if path.startswith('/api/videos/') and len(path.split('/')) == 4:
            video_id = path.split('/')[-1]
            return self.handle_delete_video(video_id)
        
        self.send_json_response({"error": "Endpoint non trouvé"}, 404)
    
    def do_GET(self):
        # Parse l'URL
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        query_params = parse_qs(parsed_path.query)
        
        # Endpoints API
        if path.startswith('/api/'):
            if path == '/api/videos':
                return self.handle_get_my_videos()
            elif path.startswith('/api/videos/') and len(path.split('/')) == 4:
                video_id = path.split('/')[-1]
                return self.handle_get_video_by_id(video_id)
            elif path == '/api/public/videos':
                return self.handle_get_public_videos(query_params)
            elif path.startswith('/api/public/videos/') and len(path.split('/')) == 5:
                video_id = path.split('/')[-1]
                return self.handle_get_public_video_by_id(video_id)
            elif path == '/api/public/rankings':
                return self.handle_get_rankings(query_params)
            else:
                self.send_json_response({"error": "Endpoint non trouvé"}, 404)
                return
        
        # Si c'est un fichier statique existant, le servir normalement
        if path.startswith('/css/') or path.startswith('/js/') or path.startswith('/assets/') or path.startswith('/pages/') or path.endswith(('.css', '.js', '.png', '.jpg', '.jpeg', '.gif', '.ico', '.svg', '.html')):
            return super().do_GET()
        
        # Redirection vers index.html pour la racine
        if path == '/' or path == '':
            self.path = '/index.html'
            return super().do_GET()
        
        # Toutes les autres routes non trouvées
        self.send_response(404)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b'<h1>404 - Page Not Found</h1>')
        return

def run_server(port=8000):
    """
    Lance le serveur statique sur le port spécifié
    """
    # Changer vers le répertoire du front
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    handler = CustomHTTPRequestHandler
    
    try:
        with socketserver.TCPServer(("", port), handler) as httpd:
            print(f"\n🚀 Serveur ANB Rising Stars démarré!")
            print(f"📍 URL: http://localhost:{port}")
            print(f"📁 Répertoire: {os.getcwd()}")
            print("🛑 Appuyez sur Ctrl+C pour arrêter\n")
            
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n\n🛑 Serveur arrêté par l'utilisateur")
        sys.exit(0)
    except OSError as e:
        if "Address already in use" in str(e):
            print(f"❌ Le port {port} est déjà utilisé. Essayez un autre port:")
            print(f"   python3 server.py {port + 1}")
        else:
            print(f"❌ Erreur lors du démarrage du serveur: {e}")
        sys.exit(1)

if __name__ == "__main__":
    # Permettre de spécifier le port en argument
    port = 8000
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print("❌ Port invalide. Utilisation du port par défaut 8000")
    
    run_server(port)
