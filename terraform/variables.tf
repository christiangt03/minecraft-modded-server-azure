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
  description = "Tamano de la VM. Subido de B2s (4 GiB, el original para Paper vanilla) a 4 vCPU / 16 GiB: el autor del modpack recomienda 12288 MB (12 GiB) de heap (dato real de la app de CurseForge, no una estimacion) -> hace falta mas RAM total que la que da B2s (4 GiB) o B2ms (8 GiB, no dejaria margen para el sistema). Se usa B4s_v2 (familia Bsv2, cuota 10 vCPU libre en esta sub) y NO B4ms (familia BS, cuota de solo 4 vCPU de la que el servidor Paper B2s ya consume 2): con B4ms los dos servidores no podrian estar encendidos a la vez. Ojo: la cuota regional total es 6 vCPU, asi que con ambos encendidos (2+4) se queda justo al limite; no se puede subir a B8s_v2 sin pedir mas cuota."
  type        = string
  default     = "Standard_B4s_v2"
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
  type        = string
}

variable "alert_email" {
  description = "Email para las alertas de Azure"
  type        = string
}

variable "discord_webhook_url" {
  description = "Webhook de Discord para alertas de CPU/RAM/disco/crash (opcional). Vacio = desactivado."
  type        = string
  default     = ""
  sensitive   = true
}

variable "mc_max_players" {
  description = "Maximo de jugadores"
  type        = number
  default     = 10
}

variable "idle_minutes" {
  description = "Minutos sin jugadores antes de auto-apagar la VM (10 para ahorrar; el arranque bajo demanda hace barato volver a encender)"
  type        = number
  default     = 10
}

variable "backup_retention_days" {
  description = "Dias que se conservan los backups en el blob"
  type        = number
  default     = 30
}

variable "enable_start_function" {
  description = "Crear la Azure Function con boton web para que los amigos enciendan la VM bajo demanda"
  type        = bool
  default     = false
}

variable "function_location" {
  description = "Region para la Function de arranque. Y1 Linux no existe en spaincentral y la politica de la sub de estudiante solo permite: switzerlandnorth, francecentral, spaincentral, italynorth, norwayeast."
  type        = string
  default     = "francecentral"
}

variable "cpu_threshold" {
  description = "Umbral de alerta de CPU (%)"
  type        = number
  default     = 90
}

variable "ram_threshold" {
  description = "Umbral de alerta de RAM (%)"
  type        = number
  default     = 90
}

variable "disk_threshold" {
  description = "Umbral de alerta de disco (%)"
  type        = number
  default     = 85
}
