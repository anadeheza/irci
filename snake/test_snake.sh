#!/bin/bash
set -e

echo "=== Test Snake STX4 ==="
echo ""

docker rm -f rtm32-sim 2>/dev/null || true

echo "[1/4] Build imagen Docker..."
docker build --platform linux/amd64 -t rtm32 . >/dev/null

echo "[2/4] Levantando contenedor..."
docker run -d --platform linux/amd64 --name rtm32-sim -p 4444:4444 -p 5555:5555 rtm32 >/dev/null

echo "[3/4] Esperando boot + load snake (8s)..."
sleep 8

echo "[4/4] Leyendo UART..."
python3 - <<'PY'
import socket, time, select, re

s = socket.create_connection(("localhost", 5555), timeout=5)
time.sleep(1.5)
s.setblocking(False)
data = b""
end = time.time() + 2
while time.time() < end:
    r, _, _ = select.select([s], [], [], 0.2)
    if r:
        chunk = s.recv(8192)
        if not chunk:
            break
        data += chunk
s.close()

text = data.decode("ascii", errors="replace")
clean = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", text)
if "SERPIENTE STX4" in text:
    print("✅ EXITO: menú del snake recibido por UART")
    print("   Output:", repr(clean[:200]))
else:
    print("❌ FALLA: no se recibió el menú del snake")
    print("   Output:", repr(clean[:400]))
    raise SystemExit(1)
PY

docker rm -f rtm32-sim 2>/dev/null || true
echo ""
echo "=== Fin ==="
