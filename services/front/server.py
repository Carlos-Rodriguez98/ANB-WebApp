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
import urllib.request
import urllib.parse
from urllib.parse import urlparse, parse_qs
import cgi
import tempfile
import requests

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """
    Handler personnalisé pour servir l'application SPA
    Et rediriger les endpoints auth vers le service auth réel
    """
    
    # Configuration des services via variables d'environnement
    AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://localhost:8080")
    VIDEO_SERVICE_URL = os.getenv("VIDEO_SERVICE_URL", "http://localhost:8081")
    VOTING_SERVICE_URL = os.getenv("VOTING_SERVICE_URL", "http://localhost:8082")
    RANKING_SERVICE_URL = os.getenv("RANKING_SERVICE_URL", "http://localhost:8083")
    
    def end_headers(self):
        # Ajouter l'encodage UTF-8 pour tous les fichiers HTML
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        super().end_headers()
        
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
    
    def proxy_to_auth_service(self, endpoint, method='POST', data=None):
        """Fait une requête vers le service auth réel"""
        url = f"{self.AUTH_SERVICE_URL}/api/auth/{endpoint}"
        
        try:
            if method == 'POST' and data:
                # Préparer la requête POST
                json_data = json.dumps(data).encode('utf-8')
                req = urllib.request.Request(
                    url, 
                    data=json_data,
                    headers={'Content-Type': 'application/json'}
                )
            else:
                req = urllib.request.Request(url)
            
            # Faire la requête
            with urllib.request.urlopen(req) as response:
                response_data = response.read().decode('utf-8')
                return json.loads(response_data), response.status
                
        except urllib.error.HTTPError as e:
            error_data = e.read().decode('utf-8')
            try:
                return json.loads(error_data), e.code
            except:
                return {"error": f"Auth service error: {e.reason}"}, e.code
        except Exception as e:
            return {"error": f"Connection error: {str(e)}"}, 500

    def proxy_to_video_service(self, endpoint, method='GET', data=None, headers=None, form_data=None):
        """Fait une requête vers le service vidéo réel"""
        url = f"{self.VIDEO_SERVICE_URL}/api{endpoint}"
        
        try:
            req_headers = headers or {}
            req_data = None
            
            if form_data:
                # Pour les uploads de fichiers multipart/form-data
                req_data = form_data
            elif method in ['POST', 'PUT'] and data:
                # Pour les requêtes JSON
                req_data = json.dumps(data).encode('utf-8')
                req_headers['Content-Type'] = 'application/json'
            
            req = urllib.request.Request(url, data=req_data, headers=req_headers, method=method)
            
            # Faire la requête
            with urllib.request.urlopen(req) as response:
                response_data = response.read().decode('utf-8')
                try:
                    return json.loads(response_data), response.status
                except:
                    return {"data": response_data}, response.status
                
        except urllib.error.HTTPError as e:
            error_data = e.read().decode('utf-8')
            try:
                return json.loads(error_data), e.code
            except:
                return {"error": f"Video service error: {e.reason}"}, e.code
        except Exception as e:
            return {"error": f"Connection error: {str(e)}"}, 500
    
    def proxy_to_voting_service(self, endpoint, method='GET', data=None, headers=None):
        """Fait une requête vers le service voting réel"""
        url = f"{self.VOTING_SERVICE_URL}/api{endpoint}"
        
        try:
            req_headers = headers or {}
            req_data = None
            
            if method in ['POST', 'PUT'] and data:
                # Pour les requêtes JSON
                req_data = json.dumps(data).encode('utf-8')
                req_headers['Content-Type'] = 'application/json'
            
            req = urllib.request.Request(url, data=req_data, headers=req_headers, method=method)
            
            # Faire la requête
            with urllib.request.urlopen(req) as response:
                response_data = response.read().decode('utf-8')
                try:
                    return json.loads(response_data), response.status
                except:
                    return {"data": response_data}, response.status
                
        except urllib.error.HTTPError as e:
            error_data = e.read().decode('utf-8')
            try:
                return json.loads(error_data), e.code
            except:
                return {"error": f"Voting service error: {e.reason}"}, e.code
        except Exception as e:
            return {"error": f"Connection error: {str(e)}"}, 500
    
    def proxy_to_ranking_service(self, endpoint, method='GET', data=None, headers=None):
        """Fait une requête vers le service ranking réel"""
        url = f"{self.RANKING_SERVICE_URL}/api{endpoint}"
        
        try:
            req_headers = headers or {}
            req_data = None
            
            if method in ['POST', 'PUT'] and data:
                # Pour les requêtes JSON
                req_data = json.dumps(data).encode('utf-8')
                req_headers['Content-Type'] = 'application/json'
            
            req = urllib.request.Request(url, data=req_data, headers=req_headers, method=method)
            
            # Faire la requête
            with urllib.request.urlopen(req) as response:
                response_data = response.read().decode('utf-8')
                try:
                    return json.loads(response_data), response.status
                except:
                    return {"data": response_data}, response.status
                
        except urllib.error.HTTPError as e:
            error_data = e.read().decode('utf-8')
            try:
                return json.loads(error_data), e.code
            except:
                return {"error": f"Ranking service error: {e.reason}"}, e.code
        except Exception as e:
            return {"error": f"Connection error: {str(e)}"}, 500
    
    def get_auth_token_from_request(self):
        """Extrait le token d'autorisation de la requête"""
        auth_header = self.headers.get('Authorization', '')
        if auth_header.startswith('Bearer '):
            return auth_header
        return None

    def handle_auth_signup(self):
        """Redirige POST /api/auth/signup vers le service auth réel"""
        data = self.get_request_data()
        
        # Transformer les données du front vers le format attendu par le service auth
        auth_data = {
            "first_name": data.get('firstName', ''),
            "last_name": data.get('lastName', ''),
            "email": data.get('email', ''),
            "password1": data.get('password', ''),
            "password2": data.get('password', ''),  # Même mot de passe pour confirmation
            "city": data.get('city', ''),
            "country": data.get('country', '')
        }
        
        # Appeler le service auth
        response_data, status_code = self.proxy_to_auth_service('signup', 'POST', auth_data)
        
        if status_code == 200:
            # Succès - transformer la réponse pour le front
            self.send_json_response({
                "message": response_data.get('message', 'Utilisateur créé avec succès'),
                "success": True
            })
        else:
            # Erreur - renvoyer l'erreur du service auth
            self.send_json_response(response_data, status_code)
    
    def handle_auth_login(self):
        """Redirige POST /api/auth/login vers le service auth réel"""
        data = self.get_request_data()
        
        # Les données sont déjà dans le bon format pour le service auth
        auth_data = {
            "email": data.get('email', ''),
            "password": data.get('password', '')
        }
        
        # Appeler le service auth
        response_data, status_code = self.proxy_to_auth_service('login', 'POST', auth_data)
        
        if status_code == 200:
            # Succès - transformer la réponse pour le front
            token = response_data.get('access_token')
            self.send_json_response({
                "access_token": token,
                "token_type": "Bearer",
                "message": "Connexion réussie"
            })
        else:
            # Erreur - renvoyer l'erreur du service auth
            self.send_json_response(response_data, status_code)
    
    def get_auth_token_from_request(self):
        """Extrait le token d'autorisation de la requête"""
        auth_header = self.headers.get('Authorization', '')
        if auth_header.startswith('Bearer '):
            return auth_header
        return None

    def handle_videos_upload(self):
        """Proxy POST /api/videos/upload vers le service vidéo"""
        auth_token = self.get_auth_token_from_request()
        if not auth_token:
            self.send_json_response({"error": "Token d'autorisation requis"}, 401)
            return
        
        try:
            # Parse le multipart/form-data
            content_type = self.headers.get('Content-Type', '')
            if not content_type.startswith('multipart/form-data'):
                self.send_json_response({"error": "Content-Type multipart/form-data requis"}, 400)
                return
                
            # Parse le form data
            form = cgi.FieldStorage(
                fp=self.rfile,
                headers=self.headers,
                environ={'REQUEST_METHOD': 'POST'}
            )
            
            # Vérifier que nous avons les champs requis
            if 'video_file' not in form or 'title' not in form:
                self.send_json_response({"error": "video_file et title sont requis"}, 400)
                return
            
            video_file = form['video_file']
            title = form['title'].value
            
            if not hasattr(video_file, 'file') or not hasattr(video_file, 'filename'):
                self.send_json_response({"error": "Fichier vidéo invalide"}, 400)
                return
            
            # Créer une nouvelle requête multipart pour le service vidéo
            try:
                import requests
            except ImportError:
                # Fallback si requests n'est pas installé
                self.send_json_response({"error": "Module requests requis pour l'upload. Installez avec: pip install requests"}, 500)
                return
            
            # Préparer les fichiers et données pour le service vidéo
            files = {
                'video_file': (
                    video_file.filename,
                    video_file.file,
                    video_file.type if hasattr(video_file, 'type') else 'video/mp4'
                )
            }
            data = {'title': title}
            headers = {'Authorization': auth_token}
            
            # Faire la requête vers le service vidéo
            video_service_url = f"{self.VIDEO_SERVICE_URL}/api/videos/upload"
            response = requests.post(
                video_service_url,
                files=files,
                data=data,
                headers=headers,
                timeout=300  # 5 minutes timeout pour les gros fichiers
            )
            
            # Retourner la réponse du service vidéo
            if response.headers.get('Content-Type', '').startswith('application/json'):
                response_data = response.json()
            else:
                response_data = {"message": response.text}
                
            self.send_json_response(response_data, response.status_code)
            
        except Exception as e:
            print(f"Error in upload proxy: {e}")
            import traceback
            traceback.print_exc()
            self.send_json_response({"error": f"Erreur lors du proxy upload: {str(e)}"}, 500)

    def handle_get_my_videos(self):
        """Proxy GET /api/videos vers le service vidéo"""
        auth_token = self.get_auth_token_from_request()
        if not auth_token:
            self.send_json_response({"error": "Token d'autorisation requis"}, 401)
            return
        
        try:
            # Faire la requête vers le service vidéo
            response_data, status_code = self.proxy_to_video_service(
                '/videos', 
                'GET', 
                headers={'Authorization': auth_token}
            )
            self.send_json_response(response_data, status_code)
            
        except Exception as e:
            print(f"Error in get_my_videos: {e}")
            self.send_json_response({"error": "Erreur lors du chargement des vidéos"}, 500)

    def handle_get_video_by_id(self, video_id):
        """Proxy GET /api/videos/:id vers le service vidéo"""
        auth_token = self.get_auth_token_from_request()
        if not auth_token:
            self.send_json_response({"error": "Token d'autorisation requis"}, 401)
            return
        
        try:
            # Faire la requête vers le service vidéo
            response_data, status_code = self.proxy_to_video_service(
                f'/videos/{video_id}', 
                'GET', 
                headers={'Authorization': auth_token}
            )
            self.send_json_response(response_data, status_code)
            
        except Exception as e:
            print(f"Error in get_video_by_id: {e}")
            self.send_json_response({"error": "Erreur lors du chargement de la vidéo"}, 500)

    def handle_delete_video(self, video_id):
        """Proxy DELETE /api/videos/:id vers le service vidéo"""
        auth_token = self.get_auth_token_from_request()
        if not auth_token:
            self.send_json_response({"error": "Token d'autorisation requis"}, 401)
            return
        
        try:
            # Faire la requête vers le service vidéo
            response_data, status_code = self.proxy_to_video_service(
                f'/videos/{video_id}', 
                'DELETE', 
                headers={'Authorization': auth_token}
            )
            self.send_json_response(response_data, status_code)
            
        except Exception as e:
            print(f"Error in delete_video: {e}")
            self.send_json_response({"error": "Erreur lors de la suppression de la vidéo"}, 500)

    def proxy_static_files(self, path):
        """Servir archivos estáticos directamente desde el NFS compartido"""
        try:
            # El NFS está montado en STORAGE_BASE_PATH (ej: /mnt/nfs/shared)
            # Las rutas en el JSON son como: /static/processed/07/video_101.mp4
            # Necesitamos mapear /static/ -> STORAGE_BASE_PATH/static/
            
            storage_base = os.getenv('STORAGE_BASE_PATH', '/mnt/nfs/shared')
            
            # La ruta ya incluye /static/, solo necesitamos agregar el base path
            # path = "/static/processed/07/video_101.mp4"
            # full_path = "/mnt/nfs/shared/static/processed/07/video_101.mp4"
            nfs_path = os.path.join(storage_base, path.lstrip('/'))
            
            print(f"📁 Serving static file: {path} -> {nfs_path}")
            print(f"   STORAGE_BASE_PATH: {storage_base}")
            
            # Verificar si el archivo existe
            if not os.path.exists(nfs_path):
                print(f"❌ File not found: {nfs_path}")
                self.send_response(404)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(b'File not found')
                return
            
            # Determinar el content-type
            import mimetypes
            content_type, _ = mimetypes.guess_type(nfs_path)
            if content_type is None:
                content_type = 'application/octet-stream'
            
            # Enviar el archivo
            self.send_response(200)
            self.send_header('Content-type', content_type)
            self.send_header('Content-Length', str(os.path.getsize(nfs_path)))
            self.send_header('Accept-Ranges', 'bytes')
            self.end_headers()
            
            # Leer y enviar el archivo en chunks
            with open(nfs_path, 'rb') as f:
                while True:
                    chunk = f.read(8192)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
            
            print(f"✓ File served successfully: {nfs_path}")
                    
        except Exception as e:
            print(f"❌ Error serving static file {path}: {e}")
            self.send_response(500)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b'<h1>500 - Internal Server Error</h1>')

    def handle_publish_video(self, video_id):
        """Redirige POST /api/videos/:id/publish vers le video-service"""
        """Proxy POST /api/videos/:id/publish al video-service"""
        auth_token = self.get_auth_token_from_request()
        if not auth_token:
            self.send_json_response({"error": "Token d'autorisation requis"}, 401)
            return
        
        try:
            # Rediriger vers le video-service
            url = f"{self.VIDEO_SERVICE_URL}/api/videos/{video_id}/publish"
            headers = {
                'Authorization': auth_token,  # auth_token contient déjà "Bearer "
                'Content-Type': 'application/json'
            }
            
            response = requests.post(url, headers=headers)
            
            if response.status_code == 200:
                self.send_json_response(response.json())
            else:
                self.send_json_response(response.json(), response.status_code)
            # Hacer proxy al video-service real (auth_token ya incluye "Bearer ")
            headers = {'Authorization': auth_token}
            data, status = self.proxy_to_video_service(f'/videos/{video_id}/publish', method='POST', headers=headers, data={})
            self.send_json_response(data, status)
            
        except Exception as e:
            print(f"Error in publish_video: {e}")
            self.send_json_response({"error": "Erreur lors de la publication"}, 500)

    def handle_get_user_stats(self):
        """Simule GET /api/user/stats - pour le moment, retourne des statistiques simulées"""
        auth_token = self.get_auth_token_from_request()
        if not auth_token:
            self.send_json_response({"error": "Token d'autorisation requis"}, 401)
            return
        
        # Pour le moment, nous simulons les stats utilisateur
        # Dans le futur, cela pourrait venir d'un service de statistiques dédié
        stats = {
            "totalVideos": 3,
            "totalVotes": 25,
            "ranking": 8,
            "averageScore": 4.2
        }
        self.send_json_response(stats)
    
    def handle_get_public_videos(self, query_params):
        """Appel vers le vrai endpoint /api/public/videos sur le service voting (port 8082)"""
        try:
            # Faire appel au vrai service voting sur le port 8082
            voting_service_url = f"{self.VOTING_SERVICE_URL}/api/public/videos"
            
            print(f"Appel vers: {voting_service_url}")
            response = requests.get(voting_service_url)
            
            if response.status_code == 200:
                # L'endpoint retourne directement un tableau de vidéos
                videos_data = response.json()
                print(f"Vidéos reçues: {videos_data}")
                
                # Retourner directement le tableau, car le JS s'attend maintenant à cela
                self.send_json_response(videos_data)
            else:
                print(f"Erreur du service voting: {response.status_code} - {response.text}")
                self.send_json_response({"error": "Service indisponible"}, 502)
            
        except requests.exceptions.RequestException as e:
            print(f"Erreur de connexion au service voting: {e}")
            # En cas d'erreur, retourner des données par défaut
            fallback_videos = [
                {"id": 1, "jugador_id": 1, "titulo": "Video par défaut", "votos": 0, "published": True}
            ]
            self.send_json_response(fallback_videos)
        except Exception as e:
            print(f"Error in get_public_videos: {e}")
            self.send_json_response({"error": "Erreur lors du chargement des vidéos publiques"}, 500)
    
    def handle_get_public_video_by_id(self, video_id):
        """Récupère une vidéo publique par son ID et enrichit avec les données du service vidéo"""
        try:
            # Récupérer d'abord la liste des vidéos publiques
            voting_service_url = f"{self.VOTING_SERVICE_URL}/api/public/videos"
            
            print(f"Récupération de la liste des vidéos pour trouver: {video_id}")
            response = requests.get(voting_service_url)
            
            if response.status_code == 200:
                videos_list = response.json()
                print(f"Liste récupérée, recherche de l'ID: {video_id}")
                
                # Chercher la vidéo avec l'ID correspondant
                video_found = None
                for video in videos_list:
                    # L'ID peut être dans différents champs selon la structure
                    if (str(video.get('id')) == str(video_id) or 
                        str(video.get('video_id')) == str(video_id) or
                        str(video.get('ID')) == str(video_id)):
                        video_found = video
                        break
                
                if video_found:
                    print(f"Vidéo trouvée dans le service voting: {video_found}")
                    
                    # Maintenant récupérer les détails depuis le service vidéo
                    try:
                        video_service_url = f"{self.VIDEO_SERVICE_URL}/api/videos/{video_id}"
                        print(f"Appel au service vidéo: {video_service_url}")
                        
                        video_response = requests.get(video_service_url)
                        
                        if video_response.status_code == 200:
                            video_details = video_response.json()
                            print(f"Détails de la vidéo récupérés: {video_details}")
                            
                            # Fusionner les données des deux services
                            enriched_video = {
                                **video_found,  # Données du service voting (votes, published, etc.)
                                **video_details,  # Données du service vidéo (URL, titre complet, etc.)
                                # Garder les votes du service voting
                                'votos': video_found.get('votos', 0),
                                'votes': video_found.get('votos', 0),  # Pour compatibilité
                            }
                            
                            self.send_json_response(enriched_video)
                        else:
                            print(f"Erreur du service vidéo: {video_response.status_code}")
                            # Si on ne peut pas récupérer les détails, retourner au moins les données du voting
                            self.send_json_response(video_found)
                            
                    except requests.exceptions.RequestException as e:
                        print(f"Erreur de connexion au service vidéo: {e}")
                        # Si on ne peut pas récupérer les détails, retourner au moins les données du voting
                        self.send_json_response(video_found)
                else:
                    print(f"Vidéo avec ID {video_id} non trouvée dans la liste")
                    self.send_json_response({"error": "Vidéo publique non trouvée"}, 404)
            else:
                print(f"Erreur du service voting: {response.status_code} - {response.text}")
                self.send_json_response({"error": "Service indisponible"}, 502)
            
        except requests.exceptions.RequestException as e:
            print(f"Erreur de connexion au service voting: {e}")
            self.send_json_response({"error": "Service indisponible"}, 503)
        except Exception as e:
            print(f"Error in get_public_video_by_id: {e}")
            self.send_json_response({"error": "Erreur lors du chargement de la vidéo"}, 500)
    
    def handle_vote_for_video(self, video_id):
        """Appel vers le vrai endpoint /api/public/videos/:id/vote sur le service voting (port 8082)"""
        try:
            # Récupérer les données du body de la requête
            data = self.get_request_data()
            user_id = data.get('user_id')
            
            if not user_id:
                self.send_json_response({"error": "user_id requis"}, 400)
                return
            
            # Faire appel au vrai service voting sur le port 8082
            voting_service_url = f"{self.VOTING_SERVICE_URL}/api/public/videos/{video_id}/vote"
            headers = {'Content-Type': 'application/json'}
            payload = {'user_id': user_id}
            
            print(f"Appel vote vers: {voting_service_url} avec user_id: {user_id}")
            response = requests.post(voting_service_url, headers=headers, json=payload)
            
            if response.status_code == 200:
                vote_data = response.json()
                print(f"Vote enregistré: {vote_data}")
                self.send_json_response(vote_data)
            elif response.status_code == 400 or response.status_code == 409:
                # L'utilisateur a déjà voté ou autre erreur business
                error_data = response.json()
                self.send_json_response(error_data, response.status_code)
            elif response.status_code == 404:
                self.send_json_response({"error": "Vidéo non trouvée"}, 404)
            elif response.status_code == 403:
                self.send_json_response({"error": "Vidéo non disponible pour le vote"}, 403)
            else:
                print(f"Erreur du service voting: {response.status_code} - {response.text}")
                self.send_json_response({"error": "Service indisponible"}, 502)
            
        except requests.exceptions.RequestException as e:
            print(f"Erreur de connexion au service voting: {e}")
            self.send_json_response({"error": "Service indisponible"}, 503)
        except Exception as e:
            print(f"Error in vote_for_video: {e}")
            self.send_json_response({"error": "Erreur lors du vote"}, 500)
    
    def handle_get_rankings(self, query_params):
        """Proxy vers le service ranking réel"""
        try:
            # Appel au service ranking réel
            response = requests.get(f"{self.RANKING_SERVICE_URL}/api/public/ranking", timeout=10)
            
            if response.status_code == 200:
                rankings_data = response.json()
                
                # Adapter le format pour le front-end
                # Le service ranking retourne: [{"jugador": 1, "votos_acumulados": 100}, ...]
                # Le front-end s'attend à: {"rankings": [...], "total": x, "totalPages": y}
                
                adapted_rankings = []
                for item in rankings_data:
                    adapted_rankings.append({
                        "username": f"Jugador {item['jugador']}",  # Nom générique car le service ne retourne que l'ID
                        "playerName": f"Jugador {item['jugador']}",
                        "votes": item['votos_acumulados'],
                        "city": "N/A"  # Information non disponible dans le service ranking
                    })
                
                # Pagination côté front-end
                page = int(query_params.get('page', [1])[0])
                limit = int(query_params.get('limit', [20])[0])
                city_filter = query_params.get('city', [''])[0]
                
                # Filtrer par ville si spécifié (même si pas vraiment applicable ici)
                if city_filter and city_filter.lower() != "n/a":
                    adapted_rankings = [r for r in adapted_rankings if city_filter.lower() in r['city'].lower()]
                
                total = len(adapted_rankings)
                start = (page - 1) * limit
                end = start + limit
                
                self.send_json_response({
                    "rankings": adapted_rankings[start:end],
                    "total": total,
                    "totalPages": (total + limit - 1) // limit if total > 0 else 1,
                    "currentPage": page
                })
            else:
                self.send_json_response({"error": "Service ranking indisponible"}, 503)
                
        except requests.exceptions.RequestException as e:
            print(f"Erreur de connexion au service ranking: {e}")
            self.send_json_response({"error": "Service ranking indisponible"}, 503)
        except Exception as e:
            print(f"Erreur dans handle_get_rankings: {e}")
            self.send_json_response({"error": "Erreur lors de la récupération du classement"}, 500)
    
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
        elif path.startswith('/api/videos/') and path.endswith('/publish'):
            video_id = path.split('/')[-2]
            return self.handle_publish_video(video_id)
        elif path.startswith('/api/public/videos/') and path.endswith('/vote'):
            video_id = path.split('/')[-2]
            return self.handle_vote_for_video(video_id)
        elif path.startswith('/api/voting/public/videos/') and path.endswith('/vote'):
            video_id = path.split('/')[-2]
            return self.handle_vote_for_video(video_id)
            # Proxy hacia voting-service
            auth_header = self.headers.get('Authorization', '')
            headers = {'Authorization': auth_header} if auth_header else {}
            data, status = self.proxy_to_voting_service(path.replace('/api', ''), method='POST', headers=headers, data={})
            return self.send_json_response(data, status)
        
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
            elif path == '/api/user/stats':
                return self.handle_get_user_stats()
            elif path.startswith('/api/videos/') and len(path.split('/')) == 4:
                video_id = path.split('/')[-1]
                return self.handle_get_video_by_id(video_id)
            elif path == '/api/public/videos':
                return self.handle_get_public_videos(query_params)
            elif path == '/api/voting/public/videos':
                return self.handle_get_public_videos(query_params)
                # Proxy hacia voting-service
                auth_header = self.headers.get('Authorization', '')
                headers = {'Authorization': auth_header} if auth_header else {}
                endpoint = path.replace('/api', '') + ('?' + parsed_path.query if parsed_path.query else '')
                data, status = self.proxy_to_voting_service(endpoint, method='GET', headers=headers)
                return self.send_json_response(data, status)
            elif path.startswith('/api/public/videos/') and len(path.split('/')) == 5:
                # Proxy hacia voting-service para video individual
                auth_header = self.headers.get('Authorization', '')
                headers = {'Authorization': auth_header} if auth_header else {}
                endpoint = path.replace('/api', '')
                data, status = self.proxy_to_voting_service(endpoint, method='GET', headers=headers)
                return self.send_json_response(data, status)
            elif path == '/api/public/rankings':
                # Proxy hacia ranking-service
                endpoint = path.replace('/api', '') + ('?' + parsed_path.query if parsed_path.query else '')
                data, status = self.proxy_to_ranking_service(endpoint, method='GET')
                return self.send_json_response(data, status)
            else:
                self.send_json_response({"error": "Endpoint non trouvé"}, 404)
                return
        
        # Si c'est un fichier statique existant, le servir normalement
        if path.startswith('/css/') or path.startswith('/js/') or path.startswith('/assets/') or path.startswith('/pages/') or path.endswith(('.css', '.js', '.png', '.jpg', '.jpeg', '.gif', '.ico', '.svg', '.html')):
            return super().do_GET()
        
        # Proxy pour les fichiers statiques vidéo (vers le service vidéo)
        if path.startswith('/static/'):
            return self.proxy_static_files(path)
        
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
        # Écouter sur toutes les interfaces (0.0.0.0) pour Docker
        with socketserver.TCPServer(("0.0.0.0", port), handler) as httpd:
            print(f"\n🚀 Serveur ANB Rising Stars démarré!")
            print(f"📍 URL: http://0.0.0.0:{port}")
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
    # Permettre de spécifier le port en argument ou via variable d'environnement
    port = int(os.getenv("SERVER_PORT", 8000))
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"❌ Port invalide. Utilisation du port par défaut {port}")
    
    run_server(port)
