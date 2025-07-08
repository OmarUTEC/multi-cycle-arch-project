import os
import glob

# Asegúrate de que 'print' no ha sido sobrescrito ni eliminado
assert callable(print), "'print' ha sido sobrescrito o eliminado"

def recopilar_archivos_v(carpeta="./", archivo_salida="archivos_v.txt"):

    
    # Buscar todos los archivos .v en la carpeta
    patron = os.path.join(carpeta, "*.v")
    archivos_v = glob.glob(patron)
    
    if not archivos_v:
        print(f"No se encontraron archivos .v en la carpeta: {carpeta}")
        return
    
    # Crear el archivo de salida
    with open(archivo_salida, 'w', encoding='utf-8') as archivo_txt:
        
        for archivo_v in sorted(archivos_v):
            try:
                # Escribir el nombre del archivo como encabezado
                nombre_archivo = os.path.basename(archivo_v)
                archivo_txt.write(f"ARCHIVO: {nombre_archivo}\n")
                
                # Leer y escribir el contenido del archivo
                with open(archivo_v, 'r', encoding='utf-8') as f:
                    contenido = f.read()
                    archivo_txt.write(contenido)
                    
                # Agregar separador entre archivos
                
                print(f"Procesado: {nombre_archivo}")
                
            except UnicodeDecodeError:
                # Intentar con otra codificación si falla UTF-8
                try:
                    with open(archivo_v, 'r', encoding='latin-1') as f:
                        contenido = f.read()
                        archivo_txt.write(contenido)
                    print(f"Procesado con codificación latin-1: {nombre_archivo}")
                except Exception as e:
                    error_msg = f"ERROR al leer {nombre_archivo}: {str(e)}\n"
                    archivo_txt.write(error_msg)
                    print(f"Error al procesar {nombre_archivo}: {e}")
            
            except Exception as e:
                error_msg = f"ERROR al leer {nombre_archivo}: {str(e)}\n"
                archivo_txt.write(error_msg)
                print(f"Error al procesar {nombre_archivo}: {e}")
    
    print(f"\nProceso completado. Archivo creado: {archivo_salida}")
    print(f"Total de archivos .v procesados: {len(archivos_v)}")

# Función para buscar recursivamente en subdirectorios
def recopilar_archivos_v_recursivo(carpeta=".", archivo_salida="contenido_archivos_v_recursivo.txt"):
    """
    Recopila el contenido de todos los archivos .v en una carpeta y sus subdirectorios.
    """
    
    patron = os.path.join(carpeta, "", "*.v")
    archivos_v = glob.glob(patron, recursive=True)
    
    if not archivos_v:
        print(f"No se encontraron archivos .v en la carpeta y subdirectorios: {carpeta}")
        return
    
    with open(archivo_salida, 'w', encoding='utf-8') as archivo_txt:
         
        for archivo_v in sorted(archivos_v):
            try:
                ruta_relativa = os.path.relpath(archivo_v, carpeta)
                archivo_txt.write(f"ARCHIVO: {ruta_relativa}\n")
                
                # Leer y escribir el contenido del archivo
                with open(archivo_v, 'r', encoding='utf-8') as f:
                    contenido = f.read()
                    archivo_txt.write(contenido)
                    
                print(f"Procesado: {ruta_relativa}")
                
            except Exception as e:
                error_msg = f"ERROR al leer {ruta_relativa}: {str(e)}\n"
                archivo_txt.write(error_msg)
                print(f"Error al procesar {ruta_relativa}: {e}")
    
    print(f"\nProceso completado. Archivo creado: {archivo_salida}")
    print(f"Total de archivos .v procesados: {len(archivos_v)}")


print("=== BÚSQUEDA EN CARPETA ACTUAL ===")
recopilar_archivos_v()
    