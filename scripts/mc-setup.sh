#!/usr/bin/env bash
# Instala y configura un servidor de Minecraft modded. Lo ejecuta cloud-init en el primer arranque.
# Soporta Forge clasico (maven.minecraftforge.net) y NeoForge (maven.neoforged.net) segun MOD_LOADER.
# El modpack elegido para este proyecto (EL MINE MAS INMERSIVO 2) usa NeoForge, no Forge clasico.
# Los mods YA estan incluidos en server/mods/ (244 jars, copiados de una instalacion local hecha con
# la app de CurseForge). Sube esa carpeta a la VM con scripts/push-mods.ps1 (ver server/mods/README.md).
set -euo pipefail
set -a; source /etc/mc/env; set +a

MC_DIR=/opt/mc/server
MODS_DIR="$MC_DIR/mods"
UA="mc-azure-setup/1.0"
LOADER="${MOD_LOADER:-forge}"

id minecraft &>/dev/null || useradd -r -m -d /opt/mc -s /usr/sbin/nologin minecraft
mkdir -p "$MODS_DIR"

# --- Forge o NeoForge (instalador oficial) ---
if [ -z "${MC_VERSION:-}" ] || [ -z "${FORGE_VERSION:-}" ]; then
  echo "MC_VERSION o FORGE_VERSION vacias (rellena mc_version/forge_version en terraform.tfvars antes de desplegar). Se omite la instalacion del loader." | logger -t mc-setup
else
  if [ "$LOADER" = "neoforge" ]; then
    # NeoForge: version = FORGE_VERSION tal cual (ej. 21.1.225), maven propio.
    LOADER_BUILD="${FORGE_VERSION}"
    INSTALLER_URL="https://maven.neoforged.net/releases/net/neoforged/neoforge/${LOADER_BUILD}/neoforge-${LOADER_BUILD}-installer.jar"
  else
    # Forge clasico: version = <mc>-<forge> (ej. 1.20.1-47.3.0), maven de minecraftforge.
    LOADER_BUILD="${MC_VERSION}-${FORGE_VERSION}"
    INSTALLER_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${LOADER_BUILD}/forge-${LOADER_BUILD}-installer.jar"
  fi

  if curl -sfL -A "$UA" -o /tmp/loader-installer.jar "$INSTALLER_URL"; then
    (cd "$MC_DIR" && java -jar /tmp/loader-installer.jar --installServer)
    rm -f /tmp/loader-installer.jar
    echo "$LOADER $LOADER_BUILD instalado." | logger -t mc-setup
  else
    echo "No se pudo descargar el instalador de $LOADER para $LOADER_BUILD (revisa mc_version/forge_version/mod_loader). $INSTALLER_URL" | logger -t mc-setup
  fi
fi

# --- EULA ---
echo "eula=true" > "$MC_DIR/eula.txt"

# --- server.properties ---
cat > "$MC_DIR/server.properties" <<EOF
server-port=25565
enable-rcon=true
rcon.port=${RCON_PORT}
rcon.password=${RCON_PASSWORD}
broadcast-rcon-to-ops=false
max-players=${MAX_PLAYERS}
online-mode=true
motd=EL MINE MAS INMERSIVO 2 (servidor modded)
view-distance=8
simulation-distance=6
spawn-protection=0
enable-query=false
EOF

# --- Argumentos JVM (usados por run.sh que genera el instalador) ---
# 12G/12G: RAM recomendada por el propio autor del modpack (12288MB, visible en la app de CurseForge
# en Profile Options). Sobre una VM Standard_B4ms (16 GiB) deja ~4 GiB para SO/GC/metaspace: justo
# pero funcional para pocos jugadores. Si ves caidas/OOM, sube a Standard_B4ms -> Standard_B8ms (32 GiB).
cat > "$MC_DIR/user_jvm_args.txt" <<EOF
-Xms12G
-Xmx12G
EOF

# Los mods YA estan incluidos en server/mods/ (244 jars) — se suben con scripts/push-mods.ps1,
# no hace falta descargarlos de nuevo (ver server/mods/README.md).

chown -R minecraft:minecraft /opt/mc

systemctl daemon-reload
if [ -f "$MC_DIR/run.sh" ]; then
  systemctl enable --now minecraft.service
else
  echo "run.sh no existe todavia ($LOADER no se instalo): minecraft.service no se habilita. Una vez instalado, ejecuta: systemctl enable --now minecraft.service" | logger -t mc-setup
fi
systemctl enable --now mc-monitor.timer mc-idle-stop.timer mc-backup.timer
logger -t mc-setup "Setup completado."
