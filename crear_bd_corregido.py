import sqlite3
import csv
from pathlib import Path

# Ruta de tu archivo CSV
CSV_FILE = r'C:\Users\adrj\Escritorio\Argentina Programa\Flutter\BSP\BD\psicografias_texto.csv'
DB_FILE = 'assets/database/psicografias.db'

def limpiar_valor(valor):
    """Convierte 'NULL' string a None y maneja tipos correctamente"""
    if not valor or valor == 'NULL' or valor == '':
        return None
    
    # Intentar convertir a número si es posible
    try:
        if valor.isdigit():
            return int(valor)
    except:
        pass
    
    return valor

def main():
    print("📖 Leyendo archivo CSV...")
    
    # Verificar que el archivo existe
    if not Path(CSV_FILE).exists():
        print(f"❌ ERROR: No se encuentra el archivo {CSV_FILE}")
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
    errores = 0
    
    with open(CSV_FILE, 'r', encoding='utf-8-sig') as f:
        lector = csv.reader(f)
        
        # Saltar cabecera
        cabecera = next(lector)
        print(f"   Columnas: {cabecera}")
        
        for fila in lector:
            try:
                if len(fila) >= 5:
                    # Limpiar cada valor
                    id_val = limpiar_valor(fila[0])
                    mensaje = limpiar_valor(fila[1])
                    url_referencia = limpiar_valor(fila[2])
                    notas = limpiar_valor(fila[3])
                    coleccion_id = limpiar_valor(fila[4])
                    
                    # Validar que tenemos datos mínimos
                    if id_val is not None and mensaje:
                        cursor.execute('''
                            INSERT OR REPLACE INTO psicografias 
                            (id, mensaje, url_referencia, notas, coleccion_id)
                            VALUES (?, ?, ?, ?, ?)
                        ''', (id_val, mensaje, url_referencia, notas, coleccion_id))
                        contador += 1
                        
                        if contador % 100 == 0:
                            print(f"   Progreso: {contador} registros")
                            conn.commit()
                    else:
                        errores += 1
                        
            except Exception as e:
                errores += 1
                if errores <= 3:  # Mostrar solo primeros 3 errores
                    print(f"   ⚠️ Error en fila {contador + errores}: {e}")
    
    # Guardar cambios finales
    conn.commit()
    
    # Verificar resultado
    cursor.execute('SELECT COUNT(*) FROM psicografias')
    total = cursor.fetchone()[0]
    
    # Obtener tamaño
    tamaño_mb = Path(DB_FILE).stat().st_size / (1024 * 1024)
    
    print(f"\n{'='*50}")
    print(f"✅ BASE DE DATOS CREADA")
    print(f"   Registros insertados: {contador}")
    print(f"   Errores: {errores}")
    print(f"   Total en BD: {total}")
    print(f"   Tamaño archivo: {tamaño_mb:.2f} MB")
    print(f"   Ubicación: {DB_FILE}")
    print(f"{'='*50}")
    
    # Mostrar una muestra
    if total > 0:
        print("\n📋 Muestra de datos:")
        cursor.execute('SELECT id, substr(mensaje, 1, 80) as preview FROM psicografias LIMIT 5')
        for row in cursor.fetchall():
            print(f"   ID {row[0]}: {row[1]}...")
    else:
        print("\n⚠️ No se insertaron registros. Verificando primeras líneas del CSV...")
        # Mostrar primeras líneas del CSV para debugging
        with open(CSV_FILE, 'r', encoding='utf-8-sig') as f:
            for i in range(3):
                linea = f.readline()
                print(f"   Línea {i+1}: {linea[:100]}...")
    
    conn.close()

if __name__ == "__main__":
    main()