@echo off
REM Wrapper de arranque local para Windows. Comprueba el EULA y delega en run.bat (generado por el instalador de Forge).
cd /d "%~dp0"

findstr /C:"eula=true" eula.txt >nul 2>&1
if errorlevel 1 (
  echo Debes aceptar el EULA primero: edita eula.txt y pon eula=true.
  exit /b 1
)

findstr /C:"PLACEHOLDER" run.bat >nul 2>&1
if not errorlevel 1 (
  echo Todavia no se ha instalado Forge en esta carpeta ^(run.bat es un placeholder^). Ver instrucciones en run.sh.
  exit /b 1
)

call run.bat nogui
