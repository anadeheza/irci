# Casos de prueba — RTM32 / STX4

Acá dejé los tests que corrí en el debugger. La idea fue cargar cada instrucción
con `set [dir] hex`, hacer `step` y mirar registros (y memoria cuando hacía falta).

Al principio armé varios hex como si el opcode tuviera 6 bits, y el emulador
ejecutaba otra cosa. En el manual el opcode son 5 bits (31..27). Después de
darme cuenta de eso regeneré todo con `encode.py` y volví a probar.

Para levantar la máquina:

```
./rtm32 -d telnet -m 64K
```

En otra terminal: `telnet localhost 4444`. Después de un `reset` el PC queda en
`0xF0000000`, así que para estas pruebas uso `set PC 0` y trabajo en RAM baja.

No metí TRAP ni CFS/CTS; preferí cubrir aritmética, lógica, saltos y acceso a
memoria primero.

---

# Caso 1
## Descripción
ADDI carga constante; ADD suma registros.

## Instrucciones
ADDI R7, R0, 12 — ADDI R8, R0, 30 — ADD R9, R7, R8

## Precondiciones
- `set PC 0`

## Code
```
set [0x0] 0x080E000C
set [0x4] 0x0810001E
set [0x8] 0x01D0901C
set [0xC] 0x00000000
step 3
r
```

## Postcondiciones
- R7=0xC, R8=0x1E, R9=0x2A, PC=0xC, CAUSE=0

## Conclusiones
Anduvo. Quedó 12+30=42 en R9 y no saltó ninguna excepción.

---

# Caso 2
## Descripción
SUB + SLT vs SLTU con 0xFFFFFFFF.

## Instrucciones
SUB R4,R2,R3 — SLT R5,R2,R3 — SLTU R6,R2,R3

## Precondiciones
- `set PC 0`
- `set R2 0xFFFFFFFF`
- `set R3 2`

## Code
```
set [0x0] 0x0086401D
set [0x4] 0x0086500C
set [0x8] 0x0086600D
step 3
r
```

## Postcondiciones
- R4=0xFFFFFFFD, R5=1, R6=0, CAUSE=0

## Conclusiones
Anduvo. SLT trata −1 < 2; SLTU no.

---

# Caso 3
## Descripción
JAL guarda link en R31; JR R31 vuelve.

## Instrucciones
JAL addr=3 — JR R31

## Precondiciones
- `set PC 0` — `set R31 0`

## Code
```
set [0x0]  0x18000003
set [0x4]  0x00000000
set [0x8]  0x00000000
set [0xC]  0x07C0000E
set [0x10] 0x00000000
step 1
r
step 1
r
```

## Postcondiciones
- Tras JAL: PC=0xC, R31=0x4
- Tras JR: PC=0x4

## Conclusiones
Anduvo. El link va a R31 (tabla A.1), no a R1.

---

# Caso 4
## Descripción
BEQ salta si iguales; BNE no salta si iguales.

## Instrucciones
BEQ R10,R11,2 — BNE R10,R11,2

## Precondiciones
- `set PC 0` — `set R10 0x55` — `set R11 0x55`

## Code
```
set [0x0]  0x82960002
set [0x4]  0x00000000
set [0x8]  0x00000000
set [0xC]  0x8A960002
set [0x10] 0x00000000
step 1
r
step 1
r
```

## Postcondiciones
- BEQ → PC=0xC; BNE → PC=0x10

## Conclusiones
Anduvo. Prefijos reales ~0x82 / 0x8A (opcodes 16 y 17), no 0x40 / 0x44.

---

# Caso 5
## Descripción
BLT y BGE con −5 y 2.

## Instrucciones
BLT R1,R2,2 — BGE R1,R2,2

## Precondiciones
- `set PC 0` — `set R1 0xFFFFFFFB` — `set R2 2`

## Code
```
set [0x0]  0x90440002
set [0x4]  0x00000000
set [0x8]  0x00000000
set [0xC]  0xA8440002
set [0x10] 0x00000000
step 1
r
step 1
r
```

## Postcondiciones
- BLT → PC=0xC, CAUSE=0
- BGE → PC=0x10, CAUSE=0

## Conclusiones
Anduvo. Los hex `0x48..`/`0x54..` del intento viejo eran SW/SH y fallaban.

---

# Caso 6
## Descripción
AND / OR / XOR bit a bit.

## Instrucciones
AND R12,R1,R2 — OR R13,R1,R2 — XOR R14,R1,R2

## Precondiciones
- `set PC 0` — `set R1 0x00FF00FF` — `set R2 0x0F0F0F0F`

## Code
```
set [0x0] 0x0044C008
set [0x4] 0x0044D009
set [0x8] 0x0044E00A
step 3
r
```

## Postcondiciones
- R12=0x000F000F, R13=0x0FFF0FFF, R14=0x0FF00FF0

## Conclusiones
Anduvo. Los tres resultados coinciden con lo que calcula a mano bit a bit.

---

# Caso 7
## Descripción
LUI + ORI arman 32 bits; XORI altera la parte baja.

## Instrucciones
LUI R1,0xABCD — ORI R1,R1,0x1234 — XORI R2,R1,0x00FF

## Precondiciones
- `set PC 0`

## Code
```
set [0x0] 0x3802ABCD
set [0x4] 0x28421234
set [0x8] 0x304400FF
step 3
r
```

## Postcondiciones
- R1=0xABCD1234, R2=0xABCD12CB, CAUSE=0

## Conclusiones
Anduvo. Con LUI y ORI armé 0xABCD1234 en R1; el XORI solo tocó la parte baja.

---

# Caso 8
## Descripción
SLL / SRL / SRA con aux=4 sobre 0xF00000F0.

## Instrucciones
SLL R3,R1,4 — SRL R4,R1,4 — SRA R5,R1,4

## Precondiciones
- `set PC 0` — `set R1 0xF00000F0`

## Code
```
set [0x0] 0x00023200
set [0x4] 0x00024201
set [0x8] 0x00025202
step 3
r
```

## Postcondiciones
- R3=0x00000F00, R4=0x0F00000F, R5=0xFF00000F

## Conclusiones
Anduvo. SRA desplaza `rt` (como SLL/SRL), no `rs`.

---

# Caso 9
## Descripción
SW escribe palabra; LW la recupera.

## Instrucciones
SW R2,0(R1) — LW R3,0(R1)

## Precondiciones
- `set PC 0` — `set R1 0x100` — `set R2 0xDEADBEEF` — `set R3 0`

## Code
```
set [0x0] 0x48440000
set [0x4] 0x40460000
step 2
examine 0x100 1
r
```

## Postcondiciones
- Mem[0x100]=0xDEADBEEF, R3=0xDEADBEEF, CAUSE=0

## Conclusiones
Anduvo. SW=opcode 9 (`0x48......`), LW=opcode 8 (`0x40......`).

---

# Caso 10
## Descripción
MUL / DIV / REST con 17 y 5.

## Instrucciones
MUL R4,R1,R2 — DIV R5,R1,R2 — REST R6,R1,R2

## Precondiciones
- `set PC 0` — `set R1 17` — `set R2 5`

## Code
```
set [0x0] 0x00444015
set [0x4] 0x00445018
set [0x8] 0x0044601A
step 3
r
```

## Postcondiciones
- R4=0x55, R5=3, R6=2

## Conclusiones
Anduvo. 17*5=85, 17/5=3 y el resto 2; todo encajó en R4/R5/R6.

---

# Caso 11 — ROM mínima
## Descripción
Probé la ROM pedida: un programa corto que multiplica, suma y se queda en loop.

## Instrucciones
ADDI / MUL / ADD / J dentro de `boot_minimo.rom`

## Precondiciones
- Emulador levantado con `./rtm32 -d telnet -m 64K`
- Conectado por telnet a localhost:4444

## Code
```
load boot_minimo.rom exact
set PC 0
step 5
r
```

Contenido del programa:
```
0x00  0x08040015   ADDI R2, R0, 21
0x04  0x08060003   ADDI R3, R0, 3
0x08  0x00864015   MUL  R4, R2, R3
0x0C  0x080A0007   ADDI R5, R0, 7
0x10  0x010A601C   ADD  R6, R4, R5
0x14  0x10000005   J    word 5
```

## Postcondiciones
- R2=0x15, R3=3, R4=0x3F, R5=7, R6=0x46
- PC=0x14; otro `step` deja el PC en el mismo lugar

## Conclusiones
Anduvo. La imagen carga, hace (21*3)+7=70 y no se desvía del loop.
