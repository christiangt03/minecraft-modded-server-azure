# Descarga los mods del modpack "EL MINE MAS INMERSIVO 2" (CurseForge) usando la API oficial de
# CurseForge, y los deja en server/mods/. Necesita una API key gratuita (https://console.curseforge.com/).
#
# Uso:
#   $env:CF_API_KEY = "tu-api-key"
#   .\fetch-modpack.ps1
#
# Que hace:
#   1) Descarga el zip del modpack (el archivo principal, publico, no necesita key).
#   2) Lee manifest.json dentro del zip para sacar la lista {projectID, fileID} de cada mod.
#   3) Para cada mod, pide a la API la URL de descarga real y baja el .jar a server/mods/.
#
# Nota: algunos mods bloquean la distribucion via API de terceros (los marca el propio manifest.json
# con "isServerPack"/"downloadUrl": null en la respuesta) — si eso pasa, el script avisa y hay que
# bajarlos a mano desde la pagina del mod en CurseForge.

param(
  [string]$CfApiKey   = $env:CF_API_KEY,
  [string]$ModpackZipUrl = "https://www.curseforge.com/api/v1/mods/1588070/files/8355401/download",
  [string]$Destination = "$PSScriptRoot\..\server\mods",
  [string]$WorkDir      = "$env:TEMP\emmi2-modpack"
)

$ErrorActionPreference = "Stop"

if (-not $CfApiKey) {
  Write-Error "Falta CF_API_KEY. Pide una key gratuita en https://console.curseforge.com/ y ponla en `$env:CF_API_KEY."
  exit 1
}

New-Item -ItemType Directory -Force -Path $WorkDir, $Destination | Out-Null
$zipPath = Join-Path $WorkDir "modpack.zip"

Write-Host "Descargando el modpack (EL MINE MAS INMERSIVO 2, file 8355401)..."
Invoke-WebRequest -Uri $ModpackZipUrl -OutFile $zipPath -UserAgent "mc-modpack-fetch/1.0"

Write-Host "Extrayendo manifest.json..."
Expand-Archive -Path $zipPath -DestinationPath $WorkDir -Force
$manifestPath = Join-Path $WorkDir "manifest.json"
if (-not (Test-Path $manifestPath)) {
  Write-Error "No se encontro manifest.json en el zip descargado. Revisa $ModpackZipUrl a mano."
  exit 1
}
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

Write-Host "Mods en el manifest: $($manifest.files.Count)"
$headers = @{ "x-api-key" = $CfApiKey; "Accept" = "application/json" }
$failed = @()

foreach ($mod in $manifest.files) {
  $projectId = $mod.projectID
  $fileId    = $mod.fileID
  try {
    $resp = Invoke-RestMethod -Uri "https://api.curseforge.com/v1/mods/$projectId/files/$fileId/download-url" -Headers $headers
    $url = $resp.data
    if (-not $url) { throw "sin downloadUrl (mod con distribucion via API deshabilitada)" }
    $fileInfo = Invoke-RestMethod -Uri "https://api.curseforge.com/v1/mods/$projectId/files/$fileId" -Headers $headers
    $fileName = $fileInfo.data.fileName
    Invoke-WebRequest -Uri $url -OutFile (Join-Path $Destination $fileName) -UserAgent "mc-modpack-fetch/1.0"
    Write-Host "OK: $fileName"
  } catch {
    Write-Warning "Fallo mod projectID=$projectId fileID=$fileId : $_"
    $failed += "$projectId/$fileId"
  }
}

if ($failed.Count -gt 0) {
  Write-Warning "$($failed.Count) mod(s) no se pudieron descargar via API (distribucion bloqueada por el autor). Bajalos a mano desde CurseForge y sueltalos en $Destination :"
  $failed | ForEach-Object { Write-Warning " - https://www.curseforge.com/minecraft/mc-mods/... (projectID $_)" }
}

Write-Host "Hecho. Mods en: $Destination"
Write-Host "Recuerda: los archivos de 'overrides' del modpack (configs, etc.) tambien puede que quieras copiarlos a server\ a mano desde $WorkDir\overrides"
