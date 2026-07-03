#!/usr/bin/env bash
# Instala y configura un servidor de Minecraft modded. Lo ejecuta cloud-init en el primer arranque.
# Soporta Forge clasico (maven.minecraftforge.net) y NeoForge (maven.neoforged.net) segun MOD_LOADER.
# El modpack elegido para este proyecto (EL MINE MAS INMERSIVO 2) usa NeoForge, no Forge clasico.
# A diferencia del proyecto Paper original, aqui NO se instalan mods automaticamente: CurseForge no
# permite descargarlos sin API key. Sube los .jar con scripts/push-mods.ps1 despues (ver server/mods/README.md).
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
    # NeoForge: version = FORGE_VERSION tal cual (ej. 21.1.48), maven propio.
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
motd=EL MINE MAS INM