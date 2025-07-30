# multi-cycle-arch-project

<<<<<<< Updated upstream
## Uso básico
### Ensamblado de instrucciones

Para ensamblar un archivo de instrucciones y generar el archivo de memoria hexadecimal usamos un codigo python que se puede ejecutar de la siguiete manera:

```sh
python ASM_v2.py test.asm out.memfile
```

- `test.asm`: Archivo de entrada con las instrucciones en ensamblador, por ejemplo:
  ```
  SUB R4, R15, R15
  SUB R5, R15, R15
  ADD R2, R4, #5
  ADD R3, R5, #4
  UMUL R0, R2, R3
  ```
- `out.memfile`: Archivo de salida con las instrucciones codificadas.

### Simulación en VS Code con Icarus Verilog

1. Asegúrate de tener Icarus Verilog instalado.
2. En tu archivo de testbench, agrega lo siguiente dentro del bloque `initial` para habilitar el volcado de la simulación:
   ```verilog
   initial begin
     $dumpfile("dump.vcd");
     $dumpvars;
   end
   ```
3. Compila todos los archivos Verilog:
   ```sh
   iverilog -g2005-sv -Wall -o simulacion.vvp *.v
   ```
4. Ejecuta la simulación:
   ```sh
   vvp simulacion.vvp
   ```
5. Correr Generator Hexadecimal : Copiar al memfile.mem el contenido de out.memfile
   ```sh
   python3 script.py test.asm out.memfile
   ```

### Notas

- El archivo generado `dump.vcd` puede abrirse con un visualizador de ondas como GTKWave para analizar la simulación.
- El archivo de memoria (`memfile.mem`) debe estar en el mismo directorio que los archivos Verilog para que la memoria se inicialice correctamente.
=======
# Rama Harris

>>>>>>> Stashed changes
