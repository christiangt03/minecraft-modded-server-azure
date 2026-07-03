# Mods

## Estado: ya incluidos ✅

Los mods de este pack **ya están descargados en esta carpeta** (244 archivos `.jar`, ~724 MB),
copiados el 2026-07-03 desde una instalación local del modpack hecha con la **CurseForge App**
(carpeta `mods/` de la instancia instalada, no una API). No hace falta descargar nada más para
desplegar — solo instalar el binario del servidor (ver `server/run.sh`).

## Modpack

**EL MINE MAS INMERSIVO 2**, por Shyoshi — https://www.curseforge.com/minecraft/modpacks/el-mine-mas-inmersivo-2
(CurseForge project ID `1588070`, archivo `8355401` / "v1Fix", actualizado 2026-07-02)

- **Minecraft:** 1.21.1
- **Loader:** NeoForge (NO Forge clásico) — versión exacta **`21.1.225`**, confirmada dentro de la
  app de CurseForge (Profile Options → Current Modloader Versions). Corrige la estimación inicial
  (`21.1.48`, la build más reciente que se veía en el índice público del maven al investigar esto).
- **RAM recomendada por el autor: 12288 MB (12 GiB)** — visible en la app de CurseForge (Profile
  Options → Memory Settings → "Recommended by Author"). Esto reemplaza la estimación inicial basada
  en guías generales de la comunidad (8-12 GiB); ahora es un número real del autor del pack. Ver
  `terraform/variables.tf` y `scripts/mc-setup.sh` para cómo se aplicó (`-Xms12G -Xmx12G` en Azure).
- **270 dependencias** según CurseForge (244 quedan como `.jar` en esta carpeta; el resto son
  resource packs/shaders/utilidades client-only que no hacen falta en el servidor).
- El pack **no publica un "server pack" separado** — la app de CurseForge tampoco tiene ahora mismo
  una opción de "Export Instance"/"Create Server Pack" self-service, así que se copió directamente
  la carpeta `mods/` de la instancia instalada.

## Cómo se obtuvieron (por si hay que repetirlo)

1. Se abrió la CurseForge App (de escritorio), sección Minecraft.
2. Se buscó e instaló "EL MINE MAS INMERSIVO 2" (botón Install) — esto descarga los 270 elementos
   del pack a una instancia local.
3. Se abrió la carpeta de esa instancia (menú **⋮ → Open Folder**) y se copió el contenido de su
   subcarpeta `mods/` (244 `.jar`) a esta carpeta del proyecto.
4. No se vinculó ninguna cuenta de Microsoft ni se inició sesión en CurseForge — solo se usó la
   función de instalar/explorar mods, que no lo requiere.

Si el modpack se actualiza y hay que re-sincronizar los mods: repetir el mismo proceso (Update en la
app, volver a copiar `mods/`), o usar `scripts/fetch-modpack.ps1` si en el futuro se consigue una API
key de CurseForge (ver más abajo).

## Alternativa con API de CurseForge (no usada, documentada por si hace falta)

Conseguir una API key de CurseForge **no es instantáneo**: hay que rellenar un formulario de
solicitud (https://support.curseforge.com/en/support/solutions/articles/9000208346) y esperar
aprobación manual del equipo de Overwolf — no existe una consola de autoservicio para generarla al
momento (a pesar de lo que pueda sugerir `console.curseforge.com`, que es un portal distinto para
estudios de videojuegos). Si en algún momento se consigue una key:

```powershell
$env:CF_API_KEY = "tu-api-key"
.\scripts\fetch-modpack.ps1
```

Ese script re-descarga los mods vía la API oficial de CurseForge a esta misma carpeta.

## Reglas importantes para un servidor NeoForge modded

- Todos los jugadores necesitan **exactamente los mismos mods y versiones** instalados en su
  cliente (