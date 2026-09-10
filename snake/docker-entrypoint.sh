#!/bin/bash
# Arranca el simulador STX4, puente UART en 5555, y carga snake.mdbg solo.
# No usa inject_rom.py ni rom.bin: el debugger queda ocupado por el loader
# (cerrar esa conexión mata rtm32).

echo "[BOOT] Iniciando simulador STX4..."
/rtm32 -d telnet -m 64K &>/tmp/rtm32.log &
SIM_PID=$!

sleep 2

if ! kill -0 $SIM_PID 2>/dev/null; then
  echo "[BOOT] ERROR: el simulador no levantó. Últimas líneas del log:"
  tail -5 /tmp/rtm32.log 2>/dev/null || echo "(log vacío o no existe)"
  echo "[BOOT] Manteniendo contenedor vivo para inspección..."
  tail -f /dev/null
  exit 1
fi

PTY=""
for i in $(seq 1 20); do
  PTY=$(grep 'UART available on' /tmp/rtm32.log 2>/dev/null | grep -o '/dev/pts/[0-9]*' | tail -1)
  if [ -n "$PTY" ] && [ -c "$PTY" ]; then
    break
  fi
  sleep 1
done

if [ -z "$PTY" ] || [ ! -c "$PTY" ]; then
  echo "[BOOT] ERROR: no se encontró PTY de UART"
  cat /tmp/rtm32.log 2>/dev/null || true
  kill $SIM_PID 2>/dev/null || true
  tail -f /dev/null
  exit 1
fi

echo "[BOOT] UART PTY: $PTY"
stty -F "$PTY" raw -echo -echoe -echok -echoctl -echoke

socat "$PTY" TCP-LISTEN:5555,reuseaddr,fork &
SOCAT_PID=$!
echo "[BOOT] socat UART→5555 activo (PID $SOCAT_PID)"

sleep 2

# Carga snake.mdbg y deja el socket del debugger abierto (si se cierra, muere rtm32).
python3 - <<'PY' &
import socket, time, select

IAC, DONT, DO, WONT, WILL = 255, 254, 253, 252, 251

def negotiate(sock, data):
    out = bytearray()
    i = 0
    while i < len(data):
        if data[i] == IAC and i + 1 < len(data):
            cmd = data[i + 1]
            if cmd in (DO, DONT, WILL, WONT) and i + 2 < len(data):
                opt = data[i + 2]
                if cmd == DO:
                    sock.send(bytes([IAC, WONT, opt]))
                elif cmd == WILL:
                    sock.send(bytes([IAC, DONT, opt]))
                i += 3
                continue
            if cmd == IAC:
                out.append(IAC)
                i += 2
                continue
            i += 2
            continue
        out.append(data[i])
        i += 1
    return bytes(out)

def recv_clean(sock, timeout=1.0):
    sock.settimeout(timeout)
    buf = b""
    end = time.time() + timeout
    while time.time() < end:
        try:
            chunk = sock.recv(4096)
            if not chunk:
                break
            buf += negotiate(sock, chunk)
            time.sleep(0.05)
            try:
                more = sock.recv(4096)
                if more:
                    buf += negotiate(sock, more)
            except socket.timeout:
                pass
            break
        except socket.timeout:
            break
    return buf

for attempt in range(30):
    try:
        dbg = socket.create_connection(("127.0.0.1", 4444), timeout=2)
        break
    except OSError:
        time.sleep(0.2)
else:
    raise SystemExit("no se pudo conectar al debugger")

time.sleep(0.4)
recv_clean(dbg, 0.5)
dbg.send(b"\r\n")
recv_clean(dbg, 0.5)
dbg.send(b"\r\n")
recv_clean(dbg, 0.5)
dbg.send(b"load /snake.mdbg exact\r\n")
time.sleep(0.6)
print("[BOOT] load:", recv_clean(dbg, 1).decode("ascii", "replace").strip(), flush=True)
dbg.send(b"continue\r\n")
time.sleep(0.2)
print("[BOOT] continue:", recv_clean(dbg, 0.5).decode("ascii", "replace").strip(), flush=True)
print("[BOOT] Snake cargado. Conexión debugger retenida.", flush=True)

# Mantener el socket vivo; drenar lo que llegue para no llenar buffers.
while True:
    r, _, _ = select.select([dbg], [], [], 60)
    if r:
        data = dbg.recv(4096)
        if not data:
            break
        negotiate(dbg, data)
PY
LOAD_PID=$!
sleep 2
if ! kill -0 $LOAD_PID 2>/dev/null; then
  echo "[BOOT] WARNING: falló la carga automática de snake.mdbg"
else
  echo "[BOOT] Loader snake activo (PID $LOAD_PID)"
fi

echo "[BOOT] Sistema listo."
echo "       UART del juego:  telnet/nc <host> 5555"
echo "       Controles:       W A S D  (usar: stty raw -echo; nc localhost 5555; stty sane)"
echo ""

wait $SIM_PID
