# Servidor de Minecraft modded — EL MINE MAS INMERSIVO 2

Este proyecto es una **copia adaptada** de `Proyectis/Servidor de minecraft` (el servidor **PaperMC**
ya desplegado en Azure), como punto de partida para un servidor **modded**. Se ha modificado la
parte de instalación de Paper a un loader de mods; el resto de la infraestructura (VM apagada por
defecto, backups, alertas, auto-apagado) se mantiene igual.

## Estado: mods ya incluidos ✅

Los 244 `.jar` del modpack ya están descargados en `server/mods/` (~724 MB) — se copiaron el
2026-07-03 desde una instalación local hecha con la CurseForge App (ver `server/mods/README.md` para
el detalle). Solo falta instalar el binario del servidor NeoForge para poder arrancarlo.

## Modpack elegido

**EL MINE MAS INMERSIVO 2**, por Shyoshi — https://www.curseforge.com/minecraft/modpacks/el-mine-mas-inmersivo-2
(CurseForge project ID `1588070`, archivo `8355401` / "v1Fix", actualizado 2026-07-02)

- **Minecraft:** `1.21.1`
- **Loader:** **NeoForge `21.1.225`** (versión exacta confirmada en la app de CurseForge — corrige la
  estimación inicial de `21.1.48`) — ⚠️ el modpack pide NeoForge, **no Forge clásico** (aunque el
  proyecto se llame "con mods forge"). Se adaptó toda la instalación en consecuencia (ver abajo).
- **270 dependencias** según CurseForge (244 quedaron como `.jar` de servidor en `server/mods/`; el
  resto son resource packs/shaders client-only), categoría **"Extra Large"**.
- **RAM recomendada por el autor: 12288 MB (12 GiB)** — dato real, visible en la app de CurseForge
  (Profile Options → Memory Settings), no una estimación de la comunidad como se pensó al principio.
- El pack no publica un "server pack" descargable aparte; los mods se obtuvieron copiando la carpeta
  `mods/` de una instalación local del pack (ver `server/mods/README.md`).

## Estructura

```
server/         Servidor local: eula.txt, server.properties, mods/ (244 jars, YA incluidos),
                scripts de arranque. Falta instalar el binario de NeoForge (ver server/run.sh).
terraform/      IaC (copiado y adaptado de "Servidor de minecraft"): red, VM, storage, alertas,
                function de arranque. prefix="mcforge" (distinto a "mcserver") para poder convivir
                con el servidor Paper en la misma suscripción sin chocar nombres.
scripts/        Scripts de la VM (rcon, backup, monitor, idle-stop, mc-setup instalando NeoForge)
                y utilidades de PC (start.ps1, stop.ps1, pull-backups.ps1, push-mods.ps1,
                fetch-modpack.ps1 — alternativa vía API de CurseForge, no usada, ver mods/README.md).
backups/        Destino local de los backups (vacío).
```

## Qué falta para dejarlo desplegable de verdad

1. ~~Elegir versión de Minecraft/loader~~ — resuelto: `1.21.1` + NeoForge `21.1.225`.
2. ~~Conseguir los mods del pack~~ — resuelto: ya están en `server/mods/` (244 jars).
3. **Instalar el binario de NeoForge** (esto sí falta): desde `server/`, descarga el instalador
   (ver comentarios en `server/run.sh`) y ejecuta `java -jar neoforge-installer.jar --installServer`.
   Eso genera `run.sh` / `run.bat` de verdad (los que hay ahora son placeholders) y puede resetear
   `user_jvm_args.txt` — si lo hace, vuelve a poner `-Xms6G -Xmx12G` (o los valores que uses). Pon
   `eula=true` en `eula.txt` (los mods ya están listos) y arranca con `./start.sh`.
4. **Desplegar en Azure:**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars   # ya tiene los valores del modpack precargados
   terraform init
   terraform plan
   terraform apply
   ```
   El primer arranque (cloud-init) instala NeoForge solo. Sube los mods con `scripts/push-mods.ps1`
   (ya están listos localmente, solo falta subirlos a la VM tras el primer despliegue).

## Coste / tamaño de VM

El proyecto Paper original usaba `Standard_B2s` (2 vCPU / 4 GiB), pensado para un servidor vanilla-ish
sin apenas mods. Este modpack (270 dependencias, categoría "Extra Large") **el propio autor recomienda
12 GiB de heap** (dato real de la app de CurseForge, no una estimación):

- `Standard_B2s` (4 GiB total) y `Standard_B2ms` (8 GiB total) no llegan ni de lejos a 12 GiB de
  heap — descartados.
- **`Standard_B4ms`** (4 vCPU / 16 GiB) es el tamaño **burstable más barato** que cubre los 12 GiB
  recomendados, con `-Xms12G -Xmx12G` en el despliegue de Azure (`scripts/mc-setup.sh`). Es el que
  quedó configurado por defecto (`terraform/variables.tf`).
  ⚠️ Con 12 GiB de heap sobre 16 GiB totales quedan solo ~4 GiB para SO/GC/metaspace — funciona para
  pocos jugadores, pero es más justo que lo ideal (los 30-40% de margen que se suelen recomendar).
  Si notas caídas o errores de memoria (OOM), sube a **`Standard_B8ms`** (8 vCPU / 32 GiB, ~2x precio)
  para tener margen cómodo; se deja documentado aquí en vez de subirlo por defecto para no
  sobredimensionar sin necesidad.
- **Precio aproximado** (Linux, pay-as-you-go, orientativo — varía por región/momento):
  `B2s` ≈ \$0.042/h, `B4ms` ≈ \$0.166/h (~4x), `B8ms` ≈ \$0.33/h (~8x). Con el patrón de "VM apagada
  por defecto, se enciende solo mientras se juega" que ya tenía el proyecto, el coste en reposo casi
  no cambia (es sobre todo el disco); el coste por hora jugada sube en proporción al tamaño elegido.
  Para una cifra exacta en tu región (`spaincentral`) usa la
  [calculadora de precios de Azure](https://azure.microsoft.com/pricing/calculator/).
- **Disco:** subido de 30 a 50 GiB (sigue en `Standard_LRS`/HDD, el tier más barato) — un modpack de
  este tamaño (244 mods + libraries + world) ocupa más que Paper vanilla.
- Todo lo demás que ya ahorraba costes sigue intacto: VM **deallocated por defecto**, **IP pública
  bajo demanda** (se borra sola al apagar), **auto-apagado** a los `idle_minutes` sin jugadores,
  backups con expiración automática. No se tocó nada de eso.

## Diferencias con el proyecto Paper original

- **Loader:** NeoForge (no Paper, y no Forge clásico tampoco — el modpack eleg