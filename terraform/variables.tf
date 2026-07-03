variable "subscription_id" {
  description = "ID de tu suscripcion de Azure. Obligatorio, sin valor por defecto a proposito: rellena el tuyo en terraform.tfvars (nunca lo pongas aqui ni lo subas a un repo publico). Consultalo con: az account show --query id -o tsv"
  type        = string
}

variable "prefix" {
  description = "Prefijo de nombres de recursos (distinto al del servidor Paper 'mcserver' para no chocar en la misma suscripcion)"
  type        = string
  default     = "mcforge"
}

variable "mc_version" {
  description = "Version de Minecraft. Elegida por el modpack (EL MINE MAS INMERSIVO 2): 1.21.1."
  type        = string
  default     = "1.21.1"
}

variable "mod_loader" {
  description = "Loader de mods: \"forge\" (maven.minecraftforge.net) o \"neoforge\" (maven.neoforged.net). El modpack elegido usa NeoForge, no Forge clasico."
  type        = string
  default     = "neoforge"
}

variable "forge_version" {
  description = "Version del loader (Forge o NeoForge, segun mod_loader) para esa version de Minecraft. Para este modpack (NeoForge en MC 1.21.1): 21.1.225 (version exacta, confirmada dentro de la app de CurseForge en Profile Options > Current Modloader Versions; corrige una estimacion inicial de 21.1.48 que solo era la build mas reciente visible en el indice publico del maven al investigar esto)."
  type        = string
  default     = "21.1.225"
}

variable "env" {
  description = "Entorno (dev/prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Region de Azure"
  type        = string
  default     = "spaincentral"
}

variable "vm_size" {
  description = "Tamano de la VM. Subido de B2s (4 GiB, el original para Paper vanilla) a B4ms (4 vCPU / 16 GiB): el autor del modpack recomienda 12288 MB (12 GiB) de heap (dato real de la app de CurseForge, no una estimacion) -> hace falta mas RAM total que la que da B2s (4 GiB) o B2ms (8 GiB, no dejaria margen para el sistema). B4ms es el tamano burstable mas barato que cubre 12 GiB de heap dejando ~4 GiB de margen; si hay caidas/OOM en produccion, sube a B8ms (8 vCPU / 32 GiB)."
  type        = string
  default     = "Standard_B4ms"
}

variable "use_spot" {
  description = "Usar VM Spot (mas barata, puede ser desalojada). Suele estar limitada en cuentas de estudiante."
  type        = bool
  default     = false
}

variable "admin_username" {
  description = "Usuario administrador de la VM"
  type        = string
  default     = "azuremc"
}

variable "ssh_public_key_path" {
  description = "Ruta a la clave publica SSH para acceder a la VM"
  type        = string
  default     = "~/.ssh/mcserver.pub"
}

variable "allowed_ssh_cidr" {
  description = "CIDR permitido para SSH (tu IP publica /32). Redetectar con: curl -s https://api.ipify.org"
  type        = string
}

variable "dns_label" {
  description = "Etiqueta DNS para la IP publica -> {label}.spaincentral.cloudapp.azure.com (unica en la region)"
  type        = st