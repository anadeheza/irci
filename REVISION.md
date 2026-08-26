# Qué revisar de tu trabajo en `instrucciones/`

## Veredicto corto

La **metodología** (casos con pre/code/post/conclusión) está bien y es lo que pide el
profesor. El problema grave es el **encoding**: casi todos los hex se armaron como
si el opcode tuviera **6 bits** (MIPS: `<< 26`). En STX4 el opcode tiene **5 bits**
(`<< 27`, bits 31..27). Por eso:

| Lo que creías probar | Qué veía en realidad la CPU | Tu conclusión |
|---|---|---|
| ADDI `0x04010005` | R-type basura (no escribe R1=5) | “Anduvo” — **falso** |
| J `0x08000002` | ADDI raro (escribe R0) | “Anduvo” — **falso** |
| ADD `0x0022181C` | ADD con registros mal parseados | a veces “anduvo” por casualidad |
| BLT/BGE/BLE `0x48../0x54..` | SW/SH → excepción CAUSE 5 | “No anduvo” — el opcode estaba mal |
| SW/LW `0x24../0x20..` | opcodes a la mitad | resultados poco confiables |

Las R-type “puras” (AND, OR, MUL…) a veces coincidían más porque el opcode 0
queda igual en ambos esquemas; igual los campos `rs/rt/rd` quedan corridos **un
bit** si partís de un encoding MIPS, así que hay que regenerarlos.

`deep.md` y `addysub.s` están a nivel ensamblador genérico (útil como idea), pero
**no** sustituyen los hex verificados en el debugger.

## Cómo codificar bien (receta)

1. Elegí formato (R / I / L / J) según el manual.
2. Poné el **opcode de 5 bits** en `[31:27]`.
3. Para R: `func` en los 6 bits bajos; `aux` en `[11:7]`; bit 6 = X (casi siempre 0).
4. Probá **una** instrucción con `step 1` + `r` (y `examine` si toca memoria).
5. Usá `entrega/encode.py` para no errarle a los shifts.

Ejemplo correcto:
- `ADDI R1, R0, 5` → `0x08020005` (no `0x04010005`)
- `ADD  R3, R1, R2` → `0x0044301C` (no `0x0022181C`)
- `J` a dirección 0x8 → word addr 2 → `0x10000002` (no `0x08000002`)

## ROM

Archivo: `entrega/boot_minimo.rom` (formato MDBG del propio `dump bin`).

```
../rtm32 -d telnet -m 64K
load entrega/boot_minimo.rom exact
set PC 0
step 5
r
```

Debe quedar `R6 = 0x46` (70) y `PC = 0x14` en loop.

También está `boot_minimo.bin` (solo las 6 palabras) y `boot_minimo.hex` (listado).

## Qué subir a GitHub

Subí **`casos_test.md`** (único, distinto al de compañeros) + la ROM.
No copies literal el texto de otro: cambiá valores, registros y narrativas.
