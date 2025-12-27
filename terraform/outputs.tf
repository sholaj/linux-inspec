output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "runner_public_ip" {
  description = "Public IP address of the runner VM"
  value       = azurerm_public_ip.runner.ip_address
}

output "runner_private_ip" {
  description = "Private IP address of the runner VM"
  value       = azurerm_network_interface.runner.private_ip_address
}

output "mssql_private_ip" {
  description = "Private IP address of the MSSQL container"
  value       = azurerm_container_group.mssql.ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the runner VM"
  value       = "ssh -i ~/.ssh/inspec_azure ${var.admin_username}@${azurerm_public_ip.runner.ip_address}"
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_vm_id" {
  description = "ID of the VM subnet"
  value       = azurerm_subnet.vm.id
}

output "subnet_aci_id" {
  description = "ID of the ACI subnet"
  value       = azurerm_subnet.aci.id
}

output "oracle_private_ip" {
  description = "Private IP address of the Oracle container"
  value       = var.deploy_oracle ? azurerm_container_group.oracle[0].ip_address : "Not deployed"
}

output "oracle_connection_string" {
  description = "Oracle connection string for sqlplus"
  value       = var.deploy_oracle ? "sqlplus system@${azurerm_container_group.oracle[0].ip_address}:1521/ORCLPDB1" : "Not deployed"
}

output "sybase_private_ip" {
  description = "Private IP address of the Sybase container"
  value       = var.deploy_sybase ? azurerm_container_group.sybase[0].ip_address : "Not deployed"
}

output "sybase_connection_info" {
  description = "Sybase connection information"
  value       = var.deploy_sybase ? "isql -S SYBASE -U sa -P <password>" : "Not deployed"
}

output "acr_login_server" {
  description = "Azure Container Registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "estimated_monthly_cost" {
  description = "Estimated monthly cost in USD"
  value       = var.deploy_oracle && var.deploy_sybase ? "VM B2s: ~$30/mo + MSSQL ACI: ~$10/mo + Oracle ACI: ~$15/mo + Sybase ACI: ~$10/mo + Storage: ~$2/mo = ~$67/mo total" : var.deploy_oracle ? "VM B2s: ~$30/mo + MSSQL ACI: ~$10/mo + Oracle ACI: ~$15/mo + Storage: ~$2/mo = ~$57/mo total" : var.deploy_sybase ? "VM B2s: ~$30/mo + MSSQL ACI: ~$10/mo + Sybase ACI: ~$10/mo + Storage: ~$2/mo = ~$52/mo total" : "VM B2s: ~$30/mo + MSSQL ACI: ~$10/mo + Storage: ~$2/mo = ~$42/mo total"
}
