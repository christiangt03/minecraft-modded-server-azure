# Sube los .jar de server/mods (local) a /opt/mc/server/mods en la VM, por SSH (scp).
# Ejecutalo despues de terraform apply y de que la VM este encendida.
#
# Uso manual:
#   .\push-mods.ps1
param(
  [string]$AdminUser = "azuremc",
  [string]$SshKey    = "$HOME\.ssh\mcserver",
  [string]$ModsDir   = "$PSScriptRoot\..\server\mods"
)

$ErrorActionPreference = "Stop"

$fqdn = terraform -chdir="$PSScriptRoot\..\terraform" output -raw server_address
if (-not $fqdn) { throw "No se pudo obtener server_address de 'terraform output'. ¿Esta desplegado el proyecto?" }

$jars = Get-ChildItem -Path $ModsDir -Filter *.jar -File -ErrorAction SilentlyContinue
if (-not $jars) {
  Write-Warning "No hay .jar en $ModsDir todavia. Añade tus mods ahi primero."
  exit 0
}

Write-Host "Subiendo $($jars.Count) mod(s) a ${AdminUser}@${fqdn}:/opt/mc/server/mods ..."
scp -i $SshKey $jars.FullName "${AdminUser}@${fqdn}:/opt/mc/server/mods/"

Write-Host "Hecho. Reinicia el servicio para que los cargue: ssh -i $SshKey ${AdminUser}@${fqdn} 'sudo systemctl restart minecraft'"
