import json
import sqlite3
import base64
from pathlib import Path

# Configuración
JSON_FILE = r'C:\Users\adrj\Escritorio\Argentina Programa\Flutter\BSP\app_psicografias\psicografias_export.json'
DB_FILE = 'assets/database/psicografias.db'

def convertir_blob(datos_blob):
    """Convierte datos BLOB de MySQL a SQLite"""
    if datos_blob is None:
        return None
    # MySQL Workbench exporta BLOB como base64
    if isinstance(datos_blob, str):
        try:
            return base64.b64decode(datos_blob)
        except:
            return None
    return datos_blob

def main():
    print("📖 Leyendo archivo JSON...")
    with open(JSON_FILE, 'r', encoding='utf-8') as f:
        datos = json.load(f)
    
    print(f"✅ Encontrados {len(datos)} registros")
    
    # Crear base de datos SQLite
    print("🗄️ Creando base de datos SQLite...")
    Path('assets/database').mkdir(parents=True, exist_ok=True)
    
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # Crear tabla
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS psicografias (
            id INTEGER PRIMARY KEY,
            mensaje TEXT NOT NULL,
            url_referencia TEXT,
            notas TEXT,
            coleccion_id INTEGER,
            imagen_principal BLOB,
            imagen_secundaria BLOB
        )
    ''')
    
    # Crear índice
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_coleccion ON psicografias(coleccion_id)')
    
    # Insertar datos
    print("📥 Insertando registros...")
    insertados = 0
    for registro in datos:
        try:
            cursor.execute('''
                INSERT OR REPLACE INTO psicografias 
                (id, mensaje, url_referencia, notas, coleccion_id, imagen_principal, imagen_secundaria)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                registro.get('id'),
                registro.get('mensaje', ''),
                registro.get('url_referencia'),
                registro.get('notas'),
                registro.get('coleccion_id'),
                convertir_blob(registro.get('imagen_principal')),
                convertir_blob(registro.get('imagen_secundaria'))
            ))
            insertados += 1
            if insertados % 100 == 0:
                print(f"   Progreso: {insertados}/{len(datos)}")
        except Exception as e:
            print(f"⚠️ Error en registro {registro.get('id')}: {e}")
    
    conn.commit()
    
    # Verificar
    cursor.execute('SELECT COUNT(*) FROM psicografias')
    total = cursor.fetchone()[0]
    
    # Verificar tamaño del archivo
    tamaño_mb = Path(DB_FILE).stat().st_size / (1024 * 1024)
    
    print(f"\n✅ Conversión completada!")
    print(f"   Registros insertados: {total}")
    print(f"   Tamaño DB: {tamaño_mb:.2f} MB")
    print(f"   Ubicación: {DB_FILE}")
    
    conn.close()

if __name__ == "__main__":
    main()