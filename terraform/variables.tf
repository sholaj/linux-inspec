variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "mssql_password" {
  description = "Password for MSSQL SA account (must meet complexity requirements)"
  type        = string
  sensitive   = true
}

variable "admin_ssh_public_key" {
  description = "SSH public key for VM admin user"
  type        = string
}

variable "runner_vm_size" {
  description = "VM size for InSpec runner"
  type        = string
  default     = "Standard_B2s"
}

variable "auto_shutdown_time" {
  description = "Auto-shutdown time in HHMM format (UTC)"
  type        = string
  default     = "2300"
}

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_vm_prefix" {
  description = "Subnet prefix for VMs"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_aci_prefix" {
  description = "Subnet prefix for Azure Container Instances"
  type        = string
  default     = "10.0.2.0/24"
}

variable "admin_username" {
  description = "Admin username for VM"
  type        = string
  default     = "azureuser"
}

# Oracle Database Variables
variable "oracle_password" {
  description = "Password for Oracle SYS/SYSTEM accounts"
  type        = string
  sensitive   = true
  default     = ""
}

variable "deploy_oracle" {
  description = "Whether to deploy Oracle container"
  type        = bool
  default     = false
}

# Sybase Database Variables
variable "sybase_password" {
  description = "Password for Sybase SA account"
  type        = string
  sensitive   = true
  default     = ""
}

variable "deploy_sybase" {
  description = "Whether to deploy Sybase container"
  type        = bool
  default     = false
}

# PostgreSQL Database Variables
variable "postgres_password" {
  description = "Password for PostgreSQL postgres account"
  type        = string
  sensitive   = true
  default     = ""
}

variable "deploy_postgres" {
  description = "Whether to deploy PostgreSQL container"
  type        = bool
  default     = false
}

# Docker Hub Variables
variable "dockerhub_username" {
  description = "Docker Hub username for authenticated pulls"
  type        = string
  default     = ""
}

variable "dockerhub_password" {
  description = "Docker Hub password/token for authenticated pulls"
  type        = string
  sensitive   = true
  default     = ""
}

# AAP2 (Ansible Automation Platform 2) Variables
variable "deploy_aap2" {
  description = "Whether to deploy AAP2 Controller VM"
  type        = bool
  default     = false
}

variable "aap2_vm_size" {
  description = "VM size for AAP2 Controller (minimum 4 vCPU, 16GB RAM recommended)"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "aap2_admin_password" {
  description = "Admin password for AAP2 web UI (set during AAP2 installation)"
  type        = string
  sensitive   = true
  default     = ""
}

# Windows MSSQL VM Variables
variable "deploy_windows_mssql" {
  description = "Whether to deploy Windows VM with SQL Server Express"
  type        = bool
  default     = false
}

variable "windows_admin_username" {
  description = "Admin username for Windows VM"
  type        = string
  default     = "azureadmin"
}

variable "windows_admin_password" {
  description = "Admin password for Windows VM (must meet complexity requirements: 12+ chars, upper, lower, number, special)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "windows_vm_size" {
  description = "VM size for Windows MSSQL VM"
  type        = string
  default     = "Standard_B2s"
}
