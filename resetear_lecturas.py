import sqlite3
import os

# Para ejecutar:
# python resetear_lecturas.py

# Ruta de la base de datos (copia en Documentos que usa la app)
DB_PATH = 'C:/Users/adrj/OneDrive/Documentos/psicografias.db'

def resetear_datos():
    """Elimina historial de lecturas, colecciones, relaciones y notas"""
    
    if not os.path.exists(DB_PATH):
        print(f'❌ Error: No se encuentra la base de datos en {DB_PATH}')
        return
    
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Contar antes
        cursor.execute('SELECT COUNT(*) FROM historial_lectura')
        antes_lecturas = cursor.fetchone()[0]
        
        cursor.execute('SELECT COUNT(*) FROM colecciones')
        antes_colecciones = cursor.fetchone()[0]
        
        cursor.execute('SELECT COUNT(*) FROM psicografia_coleccion')
        antes_relaciones = cursor.fetchone()[0]
        
        print(f'📊 Estado actual:')
        print(f'   Lecturas: {antes_lecturas}')
        print(f'   Colecciones: {antes_colecciones}')
        print(f'   Relaciones: {antes_relaciones}')
        
        if antes_lecturas == 0 and antes_colecciones == 0 and antes_relaciones == 0:
            print('ℹ️  Todo ya está vacío.')
            conn.close()
            return
        
        print('\n⚠️  ¿Eliminar TODOS los datos?')
        print('   - Historial de lecturas')
        print('   - Colecciones y relaciones')
        print('   - Notas')
        respuesta = input('   Escribe "si" para confirmar: ')
        
        if respuesta.lower() != 'si':
            print('❌ Cancelado.')
            conn.close()
            return
        
        print('\n🗑️  Eliminando...')
        cursor.execute('DELETE FROM historial_lectura')
        print('   ✅ Lecturas')
        cursor.execute('DELETE FROM psicografia_coleccion')
        print('   ✅ Relaciones')
        cursor.execute('DELETE FROM colecciones')
        print('   ✅ Colecciones')
        cursor.execute('UPDATE psicografias SET notas = NULL')
        print('   ✅ Notas')
        conn.commit()
        
        # Verificar después
        cursor.execute('SELECT COUNT(*) FROM historial_lectura')
        despues_lecturas = cursor.fetchone()[0]
        cursor.execute('SELECT COUNT(*) FROM colecciones')
        despues_colecciones = cursor.fetchone()[0]
        cursor.execute('SELECT COUNT(*) FROM psicografia_coleccion')
        despues_relaciones = cursor.fetchone()[0]
        
        print('\n' + '='*50)
        print('✅ RESETEO COMPLETADO')
        print('='*50)
        print(f'   Lecturas: {antes_lecturas} → {despues_lecturas}')
        print(f'   Colecciones: {antes_colecciones} → {despues_colecciones}')
        print(f'   Relaciones: {antes_relaciones} → {despues_relaciones}')
        
        conn.close()
        
    except sqlite3.Error as e:
        print(f'❌ Error en BD: {e}')
    except Exception as e:
        print(f'❌ Error: {e}')

if __name__ == '__main__':
    resetear_datos()