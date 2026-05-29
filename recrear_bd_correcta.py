import sqlite3
import csv
from pathlib import Path

CSV_FILE = r'C:\Users\adrj\Escritorio\Argentina Programa\Flutter\BSP\BD\psicografias_texto.csv'
DB_FILE = 'assets/database/psicografias.db'

def limpiar_valor(valor):
    """Convierte 'NULL' string a None"""
    if valor is None or valor == '':
        return None
    if isinstance(valor, str):
        if valor.upper() == 'NULL' or valor.strip() == '':
            return None
        return valor.strip()
    return valor

def main():
    print("="*50)
    print("RECREANDO BASE DE DATOS")
    print("="*50)
    
    # Verificar CSV
    if not Path(CSV_FILE).exists():
        print(f"❌ ERROR: No se encuentra {CSV_FILE}")
        return
    
    # Contar líneas del CSV
    with open(CSV_FILE, 'r', encoding='utf-8-sig') as f:
        total_lineas = sum(1 for _ in f)
    print(f"📄 CSV tiene {total_lineas} líneas (incluyendo cabecera)")
    
    # Crear BD nueva (sobrescribir)
    Path('assets/database').mkdir(parents=True, exist_ok=True)
    if Path(DB_FILE).exists():
        Path(DB_FILE).unlink()
        print("🗑️  Base de datos anterior eliminada")
    
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # Crear tabla
    cursor.execute('''
        CREATE TABLE psicografias (
            id INTEGER PRIMARY KEY,
            mensaje TEXT NOT NULL,
            url_referencia TEXT,
            notas TEXT,
            coleccion_id INTEGER
        )
    ''')
    print("✅ Tabla creada")
    
    # Insertar datos
    print("📥 Insertando registros...")
    contador = 0
    errores = []
    
    with open(CSV_FILE, 'r', encoding='utf-8-sig') as f:
        lector = csv.reader(f)
        cabecera = next(lector)  # Saltar cabecera
        print(f"📋 Columnas: {cabecera}")
        
        for num_fila, fila in enumerate(lector, start=2):
            try:
                if len(fila) >= 5:
                    id_val = int(fila[0]) if fila[0] and fila[0].isdigit() else None
                    mensaje = limpiar_valor(fila[1])
                    url = limpiar_valor(fila[2])
                    notas = limpiar_valor(fila[3])
                    coleccion = int(fila[4]) if fila[4] and fila[4].isdigit() else None
                    
                    if id_val and mensaje:
                        cursor.execute('''
                            INSERT INTO psicografias (id, mensaje, url_referencia, notas, coleccion_id)
                            VALUES (?, ?, ?, ?, ?)
                        ''', (id_val, mensaje, url, notas, coleccion))
                        contador += 1
                        
                        if contador % 200 == 0:
                            print(f"   Progreso: {contador} registros")
                            conn.commit()
                    else:
                        errores.append(f"Fila {num_fila}: ID o mensaje vacío")
                        
            except Exception as e:
                errores.append(f"Fila {num_fila}: {e}")
    
    # Guardar cambios
    conn.commit()
    
    # Verificar resultado
    cursor.execute('SELECT COUNT(*) FROM psicografias')
    total = cursor.fetchone()[0]
    
    # Obtener tamaño
    tamaño_bytes = Path(DB_FILE).stat().st_size
    tamaño_mb = tamaño_bytes / (1024 * 1024)
    
    print("\n" + "="*50)
    print("RESULTADO FINAL")
    print("="*50)
    print(f"✅ Registros insertados: {contador}")
    print(f"❌ Errores: {len(errores)}")
    print(f"📊 Total en BD: {total}")
    print(f"💾 Tamaño archivo: {tamaño_mb:.2f} MB ({tamaño_bytes:,} bytes)")
    print(f"📁 Ubicación: {DB_FILE}")
    
    # Mostrar muestra
    if total > 0:
        print("\n📋 Verificando datos:")
        cursor.execute('SELECT id, substr(mensaje, 1, 60) as preview FROM psicografias LIMIT 3')
        for row in cursor.fetchall():
            print(f"   ID {row[0]}: {row[1]}...")
    
    if errores:
        print(f"\n⚠️ Primeros 5 errores:")
        for error in errores[:5]:
            print(f"   - {error}")
    
    conn.close()
    
    if total == 1313:
        print("\n🎉 ¡ÉXITO! Base de datos con 1313 registros")
    else:
        print(f"\n⚠️ ATENCIÓN: Se esperaban 1313 registros, pero hay {total}")

if __name__ == "__main__":
    main()