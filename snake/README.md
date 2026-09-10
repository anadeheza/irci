# Serpiente STX4 (RTM32)

Snake en ensamblador para la CPU **STX4**, corriendo en el simulador `rtm32` dentro de Docker.

## Contenido

| Archivo | Qué es |
| --- | --- |
| `rtm32` | Simulador STX4 (ELF x86-64) |
| `Dockerfile` / `docker-entrypoint.sh` | Imagen: sim + UART en 5555 + carga automática de `snake.mdbg` |
| `rtm32.asm-1.1.0/snake.rtm` | Código fuente del juego |
| `rtm32.asm-1.1.0/snake.mdbg` | Binario ensamblado (formato snapshot) |
| `rtm32.asm-1.1.0/x86_64-linux-musl-rtm32.asm` | Ensamblador (Linux x86_64) |
| `test_snake.sh` | Smoke test: build + menú por UART |

## Requisitos

- Docker (en Mac ARM usar siempre `--platform linux/amd64`)

## Jugar

```bash
docker rm -f rtm32-sim 2>/dev/null
docker build --platform linux/amd64 -t rtm32 .
docker run -d --platform linux/amd64 --name rtm32-sim -p 4444:4444 -p 5555:5555 rtm32
```

Esperá ~5–8 s (boot + `load /snake.mdbg exact` + `continue`).

Consola del juego (modo raw; `telnet` no sirve bien para jugar):

```bash
stty raw -echo; nc localhost 5555; stty sane
```

- Cualquier tecla → empezar / reiniciar
- `w` `a` `s` `d` → mover
- Cabeza `@`, cuerpo `O`, comida `$`

Parar:

```bash
docker rm -f rtm32-sim
```

## Reensamblar

Si tocás `snake.rtm`:

```bash
cd rtm32.asm-1.1.0
./x86_64-linux-musl-rtm32.asm snake.rtm -o snake.mdbg
```

Rebuild de la imagen para meter el `.mdbg` nuevo.

## Test automático

```bash
./test_snake.sh
```

## Notas

- El entrypoint deja abierta la sesión del debugger (puerto 4444). Cerrarla mata el simulador; para jugar solo hace falta el puerto **5555**.
- No hace falta `rom.bin` ni `inject_rom.py`: el juego se carga con `load ... exact`.
