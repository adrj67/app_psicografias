import sqlite3
import csv
from pathlib import Path

# Ruta de tu archivo CSV (AJUSTA SI ES DIFERENTE)
CSV_FILE = r'C:\Users\adrj\Escritorio\Argentina Programa\Flutter\BSP\BD\psicografias_texto.csv'
DB_FILE = 'assets/database/psicografias.db'

def main():
    print("📖 Leyendo archivo CSV...")
    
    # Verificar que el archivo existe
    if not Path(CSV_FILE).exists():
        print(f"❌ ERROR: No se encuentra el archivo {CSV_FILE}")
        print("¿Exportaste el CSV desde MySQL Workbench?")
        return
    
    # Crear carpeta
    Path('assets/database').mkdir(parents=True, exist_ok=True)
    
    # Conectar a SQLite
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # Crear tabla (sin imágenes por ahora)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS psicografias (
            id INTEGER PRIMARY KEY,
            mensaje TEXT NOT NULL,
            url_referencia TEXT,
            notas TEXT,
            coleccion_id INTEGER
        )
    ''')
    
    # Leer CSV e insertar
    print("📥 Insertando registros...")
    contador = 0
    
    with open(CSV_FILE, 'r', encoding='utf-8-sig') as f:  # utf-8-sig maneja BOM
        lector = csv.reader(f)
        
        # Saltar cabecera
        cabecera = next(lector)
        print(f"   Columnas: {cabecera}")
        
        for fila in lector:
            if len(fila) >= 4:
                try:
                    cursor.execute('''
                        INSERT OR REPLACE INTO psicografias 
                        (id, mensaje, url_referencia, notas, coleccion_id)
                        VALUES (?, ?, ?, ?, ?)
                    ''', (
                        int(fila[0]) if fila[0] else None,
                        fila[1] if len(fila) > 1 else '',
                        fila[2] if len(fila) > 2 and fila[2] else None,
                        fila[3] if len(fila) > 3 and fila[3] else None,
                        int(fila[4]) if len(fila) > 4 and fila[4] else None
                    ))
                    contador += 1
                    
                    if contador % 100 == 0:
                        print(f"   Progreso: {contador} registros")
                        conn.commit()
                        
                except Exception as e:
                    print(f"   ⚠️ Error fila {contador+1}: {e}")
                    print(f"      Contenido: {fila[:5]}")
    
    # Guardar
    conn.commit()
    
    # Verificar
    cursor.execute('SELECT COUNT(*) FROM psicografias')
    total = cursor.fetchone()[0]
    
    # Obtener tamaño
    tamaño_mb = Path(DB_FILE).stat().st_size / (1024 * 1024)
    
    print(f"\n{'='*50}")
    print(f"✅ BASE DE DATOS CREADA")
    print(f"   Registros insertados: {contador}")
    print(f"   Total en BD: {total}")
    print(f"   Tamaño archivo: {tamaño_mb:.2f} MB")
    print(f"   Ubicación: {DB_FILE}")
    print(f"{'='*50}")
    
    # Mostrar una muestra
    print("\n📋 Muestra de datos:")
    cursor.execute('SELECT id, substr(mensaje, 1, 80) as preview FROM psicografias LIMIT 3')
    for row in cursor.fetchall():
        print(f"   ID {row[0]}: {row[1]}...")
    
    conn.close()

if __name__ == "__main__":
    main()