# Mods

## Modpack elegido

**EL MINE MAS INMERSIVO 2**, por Shyoshi — https://www.curseforge.com/minecraft/modpacks/el-mine-mas-inmersivo-2
(CurseForge project ID `1588070`, archivo `8355401` / "v1Fix", actualizado 2026-07-02)

- **Minecraft:** 1.21.1
- **Loader:** NeoForge (NO Forge clasico) — version `21.1.48` (ver `terraform/terraform.tfvars`)
- **Tamano del pack:** ~160 MB, **~270 mods** (dependencias "Required"/"Include" listadas en la
  pagina de CurseForge), categoria **"Extra Large"**
- El propio pack **no publica un "server pack" separado** (la pagina de archivos adicionales dice
  "This mod has no additional files") — hay que generarlo/instalarlo a mano, ver abajo.
- El autor **no publica una cifra oficial de RAM recomendada**. Con ~270 mods y categoria "Extra
  Large", la referencia general de la comunidad para modpacks de ese tamano (pocos jugadores) es
  **8-12 GiB de heap**; por eso el proyecto despliega en una VM de 16 GiB (`Standard_B4ms`) con
  `-Xms8G -Xmx8G` (ver `terraform/variables.tf` y `scripts/mc-setup.sh`).

## Como conseguir los mods (CurseForge no permite descarga automatica sin API key)

CurseForge protege la descarga directa de mods de terceros: no hay una URL publica que se pueda
`curl` sin autenticarse. Hay dos formas de conseguir los `.jar` para el servidor:

### Opcion A — CurseForge App (manual, mas simple)
1. Instala la [CurseForge App](https://www.curseforge.com/download/app) y busca/instala el modpack
   "EL MINE MAS INMERSIVO 2" como si fueras a jugar.
2. En la instancia del modpack: menu **"..."** -> **"Export Instance"** o **"Create Server Pack"**
   (segun version de la app) -> genera un zip con todos los mods server-side ya resueltos.
3. Copia el contenido de `mods/` de ese zip a esta carpeta.
4. Sube el resultado a la VM con `scripts/push-mods.ps1`.

### Opcion B — API oficial de CurseForge (automatizable, necesita API key)
1. Pide una key gratuita en https://console.curseforge.com/ (API oficial de terceros).
2. Usa el manifest del pack (`manifest.json`, dentro del zip del modpack — se puede descargar el
   zip desde la propia web de CurseForge con el boton "Install"/"Download" sin key) para obtener la
   lista de `{projectID, fileID}` de cada mod.
3. Para cada mod, pide la URL de descarga real a la API:
   `GET https://api.curseforge.com/v1/mods/{projectID}/files/{fileID}/download-url`
   (header `x-api-key: TU_KEY`) y descarga el jar con esa URL.
4. Guarda los `.jar` resultantes en esta carpeta (`server/mods/`).

Hay un script que automatiza los pasos 2-4: `scripts/fetch-modpack.ps1`. Necesita tu propia API key
de CurseForge (`$env:CF_API_KEY`, gratuita) y descarga los mods directamente a esta carpeta. Algunos
mods bloquean la redistribucion via API de terceros — el script avisa cuales y hay que bajarlos a
mano desde su pagina en CurseForge.

## Reglas importantes para un servidor NeoForge modded

- Todos los jugadores necesitan **exactamente los mismos mods y versiones** instalados en su
  cliente (salvo mods marcados como "client-side only" — p. ej. shaders, algunos mods de UI/sonido —
  que solo van en el cliente, nunca aqui).
- El servidor y el cliente deben usar la **misma version de Minecraft (1.21.1) y de NeoForge (21.1.48)**.
- Si un mod tiene una version "-server" o "-universal" distinta a la del cliente, usa la de servidor
  aqui.
- Recursos client-only del pack (resource pack "EMMI2 RESOURCES", shaders) **no hacen falta en el
  servidor**.
