# Azure Container Instance for MSSQL Server 2019
resource "azurerm_container_group" "mssql" {
  name                = "aci-mssql-inspec-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.aci.id]

  container {
    name   = "mssql-server"
    image  = "mcr.microsoft.com/mssql/server:2019-latest"
    cpu    = "2"
    memory = "2"

    ports {
      port     = 1433
      protocol = "TCP"
    }

    environment_variables = {
      ACCEPT_EULA = "Y"
      MSSQL_PID   = "Developer"
    }

    secure_environment_variables = {
      MSSQL_SA_PASSWORD = var.mssql_password
    }

    volume {
      name       = "mssql-data"
      mount_path = "/var/opt/mssql"
      empty_dir  = true
    }
  }

  tags = merge(
    azurerm_resource_group.main.tags,
    {
      Database = "MSSQL"
      Version  = "2019"
    }
  )

  # Ensure subnet delegation is complete before creating container
  depends_on = [azurerm_subnet.aci]
}
