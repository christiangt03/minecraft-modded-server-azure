#!/usr/bin/env bash
# Wrapper de arranque local. Comprueba el EULA y delega en run.sh (generado por el instalador de Forge).
set -euo pipefail
cd "$(dirname "$0")"

if ! grep -q "^eula=true" eula.txt 2>/dev/null; then
  echo "Debes aceptar el EULA primero: edita eula.txt y pon eula=true (tras leer https://aka.ms/MinecraftEULA)."
  exit 1
fi

if [ ! -f run.sh ] || grep -q "PLACEHOLDER" run.sh 2>/dev/null; then
  echo "Todavia no se ha instalado Forge en esta carpeta (run.sh es un placeholder). Ver instrucciones en run.sh."
  exit 1
fi

exec ./run.sh nogui
