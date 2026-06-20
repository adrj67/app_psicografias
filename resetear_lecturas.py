import sqlite3
import os

# Para ejecutar
# python resetear_lecturas.py

# Ruta de la base de datos (relativa al script)
# DB_PATH = 'assets/database/psicografias.db' # base de datos original, no se modifica

# Ruta de la base de datos (donde hace una copia de la bd que se usa despues)
DB_PATH = 'C:/Users/adrj/OneDrive/Documentos/psicografias.db'



def resetear_lecturas():
    """Elimina todos los registros del historial de lecturas"""
    
    # Verificar que el archivo existe
    if not os.path.exists(DB_PATH):
        print(f'❌ Error: No se encuentra la base de datos en {DB_PATH}')
        print('   Asegúrate de ejecutar el script desde la raíz del proyecto.')
        return
    
    try:
        # Conectar a la base de datos
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Contar registros antes de borrar
        cursor.execute('SELECT COUNT(*) FROM historial_lectura')
        antes = cursor.fetchone()[0]
        print(f'📊 Registros en historial antes de resetear: {antes}')
        
        # Confirmar antes de borrar
        if antes == 0:
            print('ℹ️  El historial ya está vacío. No se requiere acción.')
            conn.close()
            return
        
        print('⚠️  ¿Estás seguro de eliminar TODOS los registros de lecturas?')
        respuesta = input('   Escribe "si" para confirmar: ')
        
        if respuesta.lower() != 'si':
            print('❌ Operación cancelada.')
            conn.close()
            return
        
        # Borrar historial
        cursor.execute('DELETE FROM historial_lectura')
        conn.commit()
        
        # Verificar resultado
        cursor.execute('SELECT COUNT(*) FROM historial_lectura')
        despues = cursor.fetchone()[0]
        
        print(f'✅ Historial reseteado correctamente.')
        print(f'   Registros eliminados: {antes}')
        print(f'   Registros restantes: {despues}')
        
        conn.close()
        
    except sqlite3.Error as e:
        print(f'❌ Error en la base de datos: {e}')
    except Exception as e:
        print(f'❌ Error inesperado: {e}')

if __name__ == '__main__':
    resetear_lecturas()

    
# Para ejecutar
# python resetear_lecturas.py