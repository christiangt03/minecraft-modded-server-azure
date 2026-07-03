#!/usr/bin/env bash
# PLACEHOLDER. Este archivo lo genera/sobrescribe el INSTALADOR OFICIAL de NeoForge; el que hay aqui
# es solo un recordatorio de que falta ese paso. No se descarga ni ejecuta nada por ti todavia
# (a proposito, para no bajar el instalador sin confirmar version).
#
# Este proyecto usa el modpack "EL MINE MAS INMERSIVO 2" (Shyoshi), que pide:
#   Minecraft 1.21.1 + NeoForge 21.1.225 (version exacta confirmada en la app de CurseForge:
#   Profile Options > Current Modloader Versions)
#
# Los mods YA estan en mods/ (244 jars, copiados de una instalacion local con la CurseForge App).
# Falta solo instalar el server binario de NeoForge:
#   1) Desde esta carpeta (server/):
#        curl -o neoforge-installer.jar https://maven.neoforged.net/releases/net/neoforged/neoforge/21.1.225/neoforge-21.1.225-installer.jar
#        java -jar neoforge-installer.jar --installServer
#   2) Eso genera/reemplaza run.sh, run.bat,