# Servidor de Minecraft con mods en Azure (NeoForge)

Variante con mods de [minecraft-server-azure](https://github.com/christiangt03/minecraft-server-azure),
el servidor PaperMC desplegado en Azure con Terraform. Se ha cambiado la instalación de Paper por el
loader de mods NeoForge y se ha redimensionado la VM; el resto de la infraestructura (VM apagada por
defecto, encendido bajo demanda, backups, alertas y auto-apagado por inactividad) es la misma.

## Estado

Los mods del modpack (244 `.jar` de servidor, unos 724 MB) se descargan aparte y no se incluyen en
el repositorio; en `server/mods/README.md` está explicado cómo obtenerlos. Falta instalar el binario
del servidor NeoForge para poder arrancarlo (ver "Pasos pendientes").

## Modpack elegido

**EL MINE MAS INMERSIVO 2**, por Shyoshi — https://www.curseforge.com/minecraft/modpacks/el-mine-mas-inmersivo-2
(CurseForge project ID `1588070`, archivo `8355401` / "v1Fix", actualizado 2026-07-02)

- **Minecraft:** `1.21.1`
- **Loader:** **NeoForge `21.1.225`** (versión exacta confirmada en la app de CurseForge — corrige la
  estimación inicial de `21.1.48`) — el modpack pide NeoForge, **no Forge clásico**. Se adaptó toda la instalación en consecuencia (ver abajo).
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

## Pasos pendientes

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
- **`Standard_B4s_v2`** (4 vCPU / 16 GiB) es el tamaño configurado por defecto
  (`terraform/variables.tf`): burstable, cubre los 12 GiB recomendados con `-Xms12G -Xmx12G` en el
  despliegue de Azure (`scripts/mc-setup.sh`).
  **Por qué Bsv2 y no `B4ms` (familia BS):** en esta suscripción de estudiante la cuota de la
  familia BS en `spaincentral` es de **solo 4 vCPU**, y el servidor Paper (`B2s`) ya consume 2.
  Un `B4ms` (4 vCPU BS) haría imposible tener **los dos servidores encendidos a la vez** (2+4 > 4).
  La familia Bsv2 tiene cuota propia de 10 vCPU sin usar, así que `B2s` (BS) + `B4s_v2` (Bsv2)
  conviven sin chocar. Ojo: la cuota **regional total** es 6 vCPU → con ambos encendidos (2+4=6)
  se queda justo al límite; no cabe nada más sin pedir ampliación de cuota.
  Ojo: con 12 GiB de heap sobre 16 GiB totales quedan solo ~4 GiB para SO/GC/metaspace — funciona para
  pocos jugadores, pero es más justo que lo ideal (los 30-40% de margen que se suelen recomendar).
  Si notas caídas o errores de memoria (OOM), el salto sería a **`Standard_B8s_v2`** (8 vCPU / 32 GiB,
  ~2x precio), pero requiere pedir ampliación de la cuota regional de 6 vCPU (con el Paper apagado
  también excedería: 8 > 6).
- **Precio aproximado** (Linux, pay-as-you-go, orientativo — varía por región/momento):
  `B2s` ≈ \$0.042/h, `B4s_v2` ≈ \$0.15-0.17/h (~4x), `B8s_v2` ≈ \$0.30-0.34/h (~8x). Con el patrón de "VM apagada
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
  reiniciaron a plantillas vacías al copiar el proyecto — los del proyecto Paper original apuntaban
  a *ese* despliegue.
- **Repo git:** se reinició por completo (`git init` nuevo) — ya no arrastra el historial del
  proyecto Paper.
- **Mods:** se consiguieron con la CurseForge App (instalación local + copia de su carpeta `mods/`),
  no con la API de terceros — conseguir una API key de CurseForge no es instantáneo (requiere
  solicitud y aprobación manual de Overwolf), así que se optó por la vía local. `scripts/fetch-modpack.ps1`
  queda documentado como alternativa si en el futuro se consigue una key.

## Lo demás (backups, alertas, encendido/apagado bajo demanda) funciona igual que en el proyecto
original — ver los scripts en `scripts/` y `terraform/` para el detalle; no se repite aquí.
