# Servidor de Minecraft modded — EL MINE MAS INMERSIVO 2

Este proyecto es una **copia adaptada** de `Proyectis/Servidor de minecraft` (el servidor **PaperMC**
ya desplegado en Azure), como punto de partida para un servidor **modded**. Se ha modificado la
parte de instalación de Paper a un loader de mods; el resto de la infraestructura (VM apagada por
defecto, backups, alertas, auto-apagado) se mantiene igual.

## Modpack elegido

**EL MINE MAS INMERSIVO 2**, por Shyoshi — https://www.curseforge.com/minecraft/modpacks/el-mine-mas-inmersivo-2
(CurseForge project ID `1588070`, archivo `8355401` / "v1Fix", actualizado 2026-07-02)

- **Minecraft:** `1.21.1`
- **Loader:** **NeoForge** `21.1.48` — ⚠️ el modpack pide NeoForge, **no Forge clásico** (aunque el
  proyecto se llame "con mods forge"). Se adaptó toda la instalación en consecuencia (ver abajo).
- **~270 mods** (dependencias listadas en CurseForge), categoría **"Extra Large"**.
- El pack **no publica un server pack propio** ("This mod has no additional files" en su página) —
  hay que generar/instalar los mods a mano o vía API (ver `server/mods/README.md`).
- El autor **no publica una cifra oficial de RAM recomendada**. Se estimó a partir de guías
  generales de la comunidad para modpacks de este tamaño (ver sección de costes).

## Estructura

```
server/         Plantilla local del servidor: eula.txt, server.properties, mods/ (con instrucciones
                para bajar el modpack), scripts de arranque. NeoForge todavía NO está instalado aquí
                (ver server/run.sh para los pasos).
terraform/      IaC (copiado y adaptado de "Servidor de minecraft"): red, VM, storage, alertas,
                function de arranque. prefix="mcforge" (distinto a "mcserver") para poder convivir
                con el servidor Paper en la misma suscripción sin chocar nombres.
scripts/        Scripts de la VM (rcon, backup, monitor, idle-stop, mc-setup instalando NeoForge)
                y utilidades de PC (start.ps1, stop.ps1, pull-backups.ps1, push-mods.ps1,
                fetch-modpack.ps1 para bajar los mods vía API de CurseForge).
backups/        Destino local de los backups (vacío).
```

## Qué falta para dejarlo desplegable de verdad

1. ~~Elegir versión de Minecraft/loader~~ — ya resuelto: `1.21.1` + NeoForge `21.1.48`, en
   `terraform/terraform.tfvars`.
2. **Conseguir los mods del pack.** CurseForge no permite descargarlos con un simple `curl`; ver
   `server/mods/README.md` para las dos opciones (CurseForge App manual, o `scripts/fetch-modpack.ps1`
   con una API key gratuita). Colócalos en `server/mods/`.
3. **Probar localmente (opcional):** desde `server/`, descarga el instalador de NeoForge (ver
   comentarios en `server/run.sh`) y ejecuta `java -jar neoforge-installer.jar --installServer`. Eso
   genera `run.sh` / `run.bat` de verdad (los que hay ahora son solo placeholders). Pon `eula=true`
   en `eula.txt` y arranca con `./start.sh` (o `start.bat`).
4. **Desplegar en Azure:**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars   # ya tiene los valores del modpack precargados
   terraform init
   terraform plan
   terraform apply
   ```
   El primer arranque (cloud-init) descarga e instala NeoForge solo. Sube los mods después con
   `scripts/push-mods.ps1`.

## Coste / tamaño de VM

El proyecto Paper original usaba `Standard_B2s` (2 vCPU / 4 GiB), pensado para un servidor vanilla-ish
sin apenas mods. Este modpack tiene ~270 mods (categoría "Extra Large" en CurseForge); la guía
general de la comunidad para modpacks de ese tamaño con pocos jugadores es **8-12 GiB de heap**
(el autor no publica una cifra propia). Con eso:

- `Standard_B2s` (4 GiB total) y `Standard_B2ms` (8 GiB total) se quedan cortos o sin margen para el
  sistema operativo — descartados.
- **`Standard_B4ms`** (4 vCPU / 16 GiB) es el tamaño **burstable más barato** que cubre 8 GiB de heap
  dejando ~8 GiB de margen para SO/GC/metaspace. Es el que quedó configurado por defecto
  (`terraform/variables.tf`), con `-Xms8G -Xmx8G` (`scripts/mc-setup.sh`).
- **Precio aproximado** (Linux, pay-as-you-go, orientativo — varía por región/momento):
  `B2s` ≈ \$0.042/h, `B4ms` ≈ \$0.166/h (~4x, proporcional a los recursos). Con el patrón de "VM
  apagada por defecto, se enciende solo mientras se juega" que ya tenía el proyecto, el coste en
  reposo casi no cambia (es sobre todo el disco); el coste por hora jugada sube ~4x respecto al
  servidor Paper. Para una cifra exacta en tu región (`spaincentral`) usa la
  [calculadora de precios de Azure](https://azure.microsoft.com/pricing/calculator/).
- **Disco:** subido de 30 a 50 GiB (sigue en `Standard_LRS`/HDD, el tier más barato) — un modpack de
  este tamaño (mods + libraries + world) ocupa más que Paper vanilla.
- Todo lo demás que ya ahorraba costes sigue intacto: VM **deallocated por defecto**, **IP pública
  bajo demanda** (se borra sola al apagar), **auto-apagado** a los `idle_minutes` sin jugadores,
  backups con expiración automática. No se tocó nada de eso.

## Diferencias con el proyecto Paper original

- **Loader:** NeoForge (no Paper, y no Forge clásico tampoco — el modpack elegido lo requiere).
  `scripts/mc-setup.sh` soporta ambos (`mod_loader = "forge"` o `"neoforge"` en las variables de
  Terraform) y descarga el instalador correspondiente (`maven.neoforged.net` o
  `maven.minecraftforge.net`). No se instala Geyser/Floodgate (en NeoForge/Forge, Geyser es un mod,
  no un plugin de Spigot — si se quiere, va en `server/mods/`).
- **Arranque del servicio:** `minecraft.service` ejecuta `run.sh` (el script que genera el instalador
  del loader), no un `.jar` directo.
- **Tamaño de VM y disco:** ver sección de coste arriba.
- **`prefix` de recursos Azure:** `mcforge` en vez de `mcserver`, para no chocar con el servidor
  Paper si ambos se despliegan en la misma suscripción.
- **Sin secretos heredados:** `terraform.tfvars`, `terraform.tfstate(.backup)` y `start-url.txt` se
  reiniciaron a plantil