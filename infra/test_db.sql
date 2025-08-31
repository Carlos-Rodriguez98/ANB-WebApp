-- test_db.sql: Script para crear y poblar la base de datos de prueba para ANB-WebApp

-- Crear tablas
CREATE TABLE "User" (
    user_id SERIAL PRIMARY KEY,
    firs_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    password VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50),
    Rol VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "Videos" (
    video_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES "User"(user_id),
    title VARCHAR(100),
    original_path VARCHAR(255),
    processed_path VARCHAR(255),
    status VARCHAR(20),
    uploaded_at TIMESTAMP,
    processed_at TIMESTAMP,
    published BOOLEAN DEFAULT FALSE
);

CREATE TABLE "Votes" (
    vote_id SERIAL PRIMARY KEY,
    video_id INT REFERENCES "Videos"(video_id),
    user_id INT REFERENCES "User"(user_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar usuarios de ejemplo
INSERT INTO "User" (firs_name, last_name, email, password, city, country, Rol) VALUES
('Ana', 'Gomez', 'ana@example.com', 'pass123', 'Bogotá', 'Colombia', 'jugador'),
('Luis', 'Martinez', 'luis@example.com', 'pass123', 'Medellín', 'Colombia', 'jugador'),
('Sofia', 'Lopez', 'sofia@example.com', 'pass123', 'Cali', 'Colombia', 'jugador'),
('Carlos', 'Perez', 'carlos@example.com', 'pass123', 'Barranquilla', 'Colombia', 'votante');

-- Insertar videos públicos de ejemplo
INSERT INTO "Videos" (user_id, title, original_path, processed_path, status, uploaded_at, processed_at, published) VALUES
(1, 'Video Ana 1', '/videos/ana1.mp4', '/videos/ana1_proc.mp4', 'aprobado', NOW(), NOW(), TRUE),
(2, 'Video Luis 1', '/videos/luis1.mp4', '/videos/luis1_proc.mp4', 'aprobado', NOW(), NOW(), TRUE),
(2, 'Video Luis 2', '/videos/luis2.mp4', '/videos/luis2_proc.mp4', 'aprobado', NOW(), NOW(), TRUE),
(3, 'Video Sofia 1', '/videos/sofia1.mp4', '/videos/sofia1_proc.mp4', 'aprobado', NOW(), NOW(), TRUE),
(1, 'Video Ana 2', '/videos/ana2.mp4', '/videos/ana2_proc.mp4', 'pendiente', NOW(), NULL, FALSE);

-- Insertar votos de ejemplo
INSERT INTO "Votes" (video_id, user_id) VALUES
(1, 4), -- Carlos vota por Video Ana 1
(2, 4), -- Carlos vota por Video Luis 1
(3, 4), -- Carlos vota por Video Luis 2
(4, 4); -- Carlos vota por Video Sofia 1

-- Puedes agregar más datos de prueba según sea necesario
