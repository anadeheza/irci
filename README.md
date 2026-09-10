# ROM e instrucciones en RTM32

Con el manual nuevo de la STX4 había que revisar cómo se arman las instrucciones
y dejar una ROM que bootee la máquina con un programa mínimo.

Lo primero que hice fue probar instrucciones sueltas en el debugger. Varias me
daban resultados raros o excepciones hasta que noté que estaba codificando el
opcode mal (lo estaba tratando como de 6 bits). Corregí eso, armé de nuevo los
hex y documenté cada caso en `casos_test.md`, con lo que seteaba antes, el
código que cargué y qué quedó en los registros después.

Después armé `boot_minimo.rom`: carga con `load`, calcula `(21 * 3) + 7` en R6
y termina en un salto a sí mismo para no seguir ejecutando basura. No es un
bootloader completo; es lo justo para mostrar que la imagen arranca y corre.

## Archivos

- `boot_minimo.rom` — ROM para el emulador
- `boot_minimo.hex` — el mismo programa en texto
- `casos_test.md` — detalle de las pruebas
- `encode.py` — script chico que usé para armar los opcodes sin equivocarme en los shifts

## Cómo probar la ROM

```
./rtm32 -d telnet -m 64K
```

```
telnet localhost 4444
load boot_minimo.rom exact
set PC 0
step 5
r
```

Si salió bien, R6 vale `0x46` y el PC queda en `0x14`.
