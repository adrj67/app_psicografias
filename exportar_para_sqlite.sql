-- ============================================
-- CONVERSIÓN DE MySQL A SQLite
-- ============================================

-- 1. Crear tabla psicografias
CREATE TABLE psicografias (
    id INTEGER PRIMARY KEY,
    mensaje TEXT NOT NULL,
    url_referencia TEXT,
    notas TEXT,
    coleccion_id INTEGER,
    imagen_principal BLOB,
    imagen_secundaria BLOB
);

-- 2. Crear índices
CREATE INDEX idx_coleccion ON psicografias(coleccion_id);