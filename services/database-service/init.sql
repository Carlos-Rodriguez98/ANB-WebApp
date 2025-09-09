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
    original_path  TEXT NOT NULL,
    processed_path TEXT,
    status         VARCHAR(255) NOT NULL,
    uploaded_at    TIMESTAMPTZ DEFAULT now(),
    processed_at   TIMESTAMPTZ,
    published      BOOLEAN DEFAULT FALSE
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


INSERT INTO app.users (first_name, last_name, email, password, city, country) VALUES
('Carlos', 'Ramírez', 'carlos.ramirez@example.com', 'password123', 'Bogotá', 'Colombia'),
('Ana', 'Martínez', 'ana.martinez@example.com', 'password123', 'Medellín', 'Colombia'),
('John', 'Doe', 'john.doe@example.com', 'password123', 'New York', 'USA'),
('Laura', 'Smith', 'laura.smith@example.com', 'password123', 'Los Angeles', 'USA'),
('Pedro', 'Gómez', 'pedro.gomez@example.com', 'password123', 'Madrid', 'España');