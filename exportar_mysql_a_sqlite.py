import mysql.connector
import sqlite3
from pathlib import Path

# Configuración MySQL (AJUSTA SEGÚN TUS DATOS)
MYSQL_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'SanJuan@517',  # Tu contraseña de MySQL
    'database': 'psicografias',
    'port': 3306
}

# Configuración SQLite
SQLITE_FILE = 'assets/database/psicografias_con_imagenes.db'

def exportar():
    print("="*60)
    print("EXPORTANDO PSICOGRAFÍAS DESDE MySQL A SQLite")
    print("="*60)
    
    # Conectar a MySQL
    print("\n1. Conectando a MySQL...")
    try:
        mysql_conn = mysql.connector.connect(**MYSQL_CONFIG)
        mysql_cursor = mysql_conn.cursor(dictionary=True)
        print("   ✅ Conectado a MySQL")
    except Exception as e:
        print(f"   ❌ Error conectando a MySQL: {e}")
        return
    
    # Crear carpeta para SQLite
    Path('assets/database').mkdir(parents=True, exist_ok=True)
    
    # Conectar a SQLite
    print("\n2. Creando base de datos SQLite...")
    sqlite_conn = sqlite3.connect(SQLITE_FILE)
    sqlite_cursor = sqlite_conn.cursor()
    
    # Crear tabla en SQLite
    sqlite_cursor.execute('''
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
    print("   ✅ Tabla creada")
    
    # Consultar datos desde MySQL
    print("\n3. Leyendo datos desde MySQL...")
    mysql_cursor.execute("""
        SELECT 
            id, 
            mensaje, 
            url_referencia, 
            notas, 
            coleccion_id,
            imagen_principal,
            imagen_secundaria
        FROM psicografias
        ORDER BY id
    """)
    
    registros = mysql_cursor.fetchall()
    total = len(registros)
    print(f"   ✅ {total} registros encontrados")
    
    # Insertar en SQLite
    print("\n4. Insertando en SQLite...")
    insertados = 0
    errores = 0
    
    for registro in registros:
        try:
            sqlite_cursor.execute('''
                INSERT OR REPLACE INTO psicografias 
                (id, mensaje, url_referencia, notas, coleccion_id, imagen_principal, imagen_secundaria)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                registro['id'],
                registro['mensaje'],
                registro['url_referencia'],
                registro['notas'],
                registro['coleccion_id'],
                registro['imagen_principal'],  # MySQL BLOB directo
                registro['imagen_secundaria']   # MySQL BLOB directo
            ))
            insertados += 1
            
            if insertados % 100 == 0:
                print(f"   Progreso: {insertados}/{total}")
                sqlite_conn.commit()
                
        except Exception as e:
            errores += 1
            if errores <= 5:
                print(f"   ⚠️ Error ID {registro['id']}: {e}")
    
    # Guardar cambios
    sqlite_conn.commit()
    
    # Verificar resultado
    sqlite_cursor.execute('SELECT COUNT(*) FROM psicografias')
    total_sqlite = sqlite_cursor.fetchone()[0]
    
    # Verificar tamaño del archivo
    tamaño_mb = Path(SQLITE_FILE).stat().st_size / (1024 * 1024)
    
    print("\n" + "="*60)
    print("RESULTADO")
    print("="*60)
    print(f"✅ Registros insertados: {insertados}")
    print(f"❌ Errores: {errores}")
    print(f"📊 Total en BD SQLite: {total_sqlite}")
    print(f"💾 Tamaño archivo: {tamaño_mb:.2f} MB")
    print(f"📁 Ubicación: {SQLITE_FILE}")
    
    # Verificar que las imágenes se guardaron
    sqlite_cursor.execute('''
        SELECT 
            COUNT(*) as total,
            COUNT(imagen_principal) as con_principal,
            COUNT(imagen_secundaria) as con_secundaria
        FROM psicografias
    ''')
    stats = sqlite_cursor.fetchone()
    print(f"\n📸 Imágenes guardadas:")
    print(f"   Con imagen principal: {stats[1]}")
    print(f"   Con imagen secundaria: {stats[2]}")
    
    # Cerrar conexiones
    mysql_cursor.close()
    mysql_conn.close()
    sqlite_conn.close()
    
    print("\n🎉 ¡EXPORTACIÓN COMPLETADA!")

if __name__ == "__main__":
    exportar()