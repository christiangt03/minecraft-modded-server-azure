#!/usr/bin/env bash
# PLACEHOLDER. Este archivo lo genera/sobrescribe el INSTALADOR OFICIAL de NeoForge; el que hay aqui
# es solo un recordatorio de que falta ese paso. No se descarga ni ejecuta nada por ti todavia
# (a proposito, para no bajar el instalador sin confirmar version).
#
# Este proyecto usa el modpack "EL MINE MAS INMERSIVO 2" (Shyoshi), que pide:
#   Minecraft 1.21.1 + NeoForge 21.1.48 (revisa si hay una build 21.1.x mas nueva antes de instalar:
#   https://maven.neoforged.net/releases/net/neoforged/neoforge/)
#
# Para dejarlo funcional:
#   1) Desde esta carpeta (server/):
#        curl -o neoforge-installer.jar https://maven.neoforged.net/releases/net/neoforged/neoforge/21.1.48/neoforge-21.1.48-installer.jar
#        java -jar neoforge-installer.jar --installServer
#   2) Eso genera/reemplaza run.sh, run.bat, la carpeta libraries/ y user_jvm_args.txt.
#   3) Vuelve a poner eula=true en eula.txt y coloca los mo