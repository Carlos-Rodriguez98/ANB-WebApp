-- Crear esquema y configurar search_path
CREATE SCHEMA IF NOT EXISTS app;
SET search_path = app, public;

-- 1) Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    user_id    BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name  VARCHAR(100) NOT NULL,
    email      VARCHAR(255) NOT NULL UNIQUE,
    password   VARCHAR(255) NOT NULL,
    city       VARCHAR(100) NOT NULL,
    country    VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2) Tabla de videos
CREATE TABLE IF NOT EXISTS videos (
    video_id       BIGSERIAL PRIMARY KEY,
    user_id        BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    title          VARCHAR(255) NOT NULL,
    original_path  TEXT,
    processed_path TEXT,
    status         VARCHAR(255) NOT NULL,    -- uploaded | processed | deleted
    uploaded_at    TIMESTAMPTZ DEFAULT now(),
    processed_at   TIMESTAMPTZ,
    published      BOOLEAN DEFAULT FALSE,
    published_at   TIMESTAMPTZ
);

-- 3) Tabla de votos
CREATE TABLE IF NOT EXISTS votes (
    vote_id    BIGSERIAL PRIMARY KEY,
    video_id   BIGINT NOT NULL REFERENCES videos(video_id) ON DELETE CASCADE,
    user_id    BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    -- Evita que un mismo usuario vote varias veces el mismo video
    UNIQUE(video_id, user_id)
);

-- Usuarios de prueba
-- NOTA: Todos los usuarios tienen el mismo password hash
-- Hash: $2a$12$uNdyCUr0n31df29OGWxOc.m94lMkiJyVdLYUUHcnMxROZ6jbwngRW
-- Password en texto plano: "password123" (sin comillas)
-- Para login use: email del usuario + password: password123

INSERT INTO app.users (user_id, first_name, last_name, email, password, city, country) VALUES
(1, 'Carlos', 'Ramírez', 'carlos.ramirez@example.com', '$2a$12$uNdyCUr0n31df29OGWxOc.m94lMkiJyVdLYUUHcnMxROZ6jbwngRW', 'Bogotá', 'Colombia'),
(2, 'Ana', 'Martínez', 'ana.martinez@example.com', '$2a$12$uNdyCUr0n31df29OGWxOc.m94lMkiJyVdLYUUHcnMxROZ6jbwngRW', 'Medellín', 'Colombia'),
(3, 'John', 'Doe', 'john.doe@example.com', '$2a$12$uNdyCUr0n31df29OGWxOc.m94lMkiJyVdLYUUHcnMxROZ6jbwngRW', 'New York', 'USA'),
(4, 'Laura', 'Smith', 'laura.smith@example.com', '$2a$12$uNdyCUr0n31df29OGWxOc.m94lMkiJyVdLYUUHcnMxROZ6jbwngRW', 'Los Angeles', 'USA'),
(5, 'Pedro', 'Gómez', 'pedro.gomez@example.com', '$2a$12$uNdyCUr0n31df29OGWxOc.m94lMkiJyVdLYUUHcnMxROZ6jbwngRW', 'Madrid', 'España');

-- Videos de prueba
INSERT INTO app.videos (video_id, user_id, title, original_path, processed_path, status, uploaded_at, processed_at, published) VALUES
(101, 1, 'Video Carlos (procesado y publicado)', '/static/original/u7/carlos1.mp4', '/static/processed/u7/carlos1.mp4', 'processed', NOW() - interval '2 hours', NOW() - interval '1 hour', TRUE),
(102, 2, 'Video Ana (procesado y publicado)', '/static/original/u7/ana1.mp4', '/static/processed/u7/ana1.mp4', 'processed', NOW() - interval '3 hours', NOW() - interval '2 hours', TRUE),
(103, 3, 'Video John (procesado y no publicado)', '/static/original/u7/john1.mp4', '/static/processed/u7/john1.mp4', 'processed', NOW() - interval '4 hours', NOW() - interval '3 hours', FALSE),
(104, 4, 'Video Laura (solo subido, no procesado)', '/static/original/u7/laura1.mp4', NULL, 'uploaded', NOW() - interval '1 hour', NULL, FALSE),
(105, 5, 'Video Pedro (procesado y no publicado)', '/static/original/u7/pedro1.mp4', '/static/processed/u7/pedro1.mp4', 'processed', NOW() - interval '5 hours', NOW() - interval '4 hours', FALSE);

-- Votos de prueba
INSERT INTO app.votes (video_id, user_id) VALUES (102, 1), (103, 1); -- Carlos vota por Ana y John
INSERT INTO app.votes (video_id, user_id) VALUES (101, 2), (105, 2); -- Ana vota por Carlos y Pedro
INSERT INTO app.votes (video_id, user_id) VALUES (101, 3);           -- John vota por Carlos
INSERT INTO app.votes (video_id, user_id) VALUES (102, 4), (105, 4); -- Laura vota por Ana y Pedro
INSERT INTO app.votes (video_id, user_id) VALUES (101, 5), (102, 5); -- Pedro vota por Carlos y Ana

-- Resincronizar secuencias para evitar conflictos en futuros INSERT
SELECT setval('users_user_id_seq', (SELECT COALESCE(MAX(user_id), 1) FROM app.users) + 1);
SELECT setval('videos_video_id_seq', (SELECT COALESCE(MAX(video_id), 1) FROM app.videos) + 1);
SELECT setval('votes_vote_id_seq', (SELECT COALESCE(MAX(vote_id), 1) FROM app.votes) + 1);