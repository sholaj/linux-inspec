# Azure Container Instance for PostgreSQL 15
resource "azurerm_container_group" "postgres" {
  count               = var.deploy_postgres ? 1 : 0
  name                = "aci-postgres-inspec-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.aci.id]

  container {
    name   = "postgres-server"
    image  = "postgres:15"
    cpu    = "1"
    memory = "1.5"

    ports {
      port     = 5432
      protocol = "TCP"
    }

    environment_variables = {
      POSTGRES_USER = "postgres"
      POSTGRES_DB   = "testdb"
    }

    secure_environment_variables = {
      POSTGRES_PASSWORD = var.postgres_password
    }

    volume {
      name       = "postgres-data"
      mount_path = "/var/lib/postgresql/data"
      empty_dir  = true
    }
  }

  tags = merge(
    azurerm_resource_group.main.tags,
    {
      Database = "PostgreSQL"
      Version  = "15"
    }
  )

  # Ensure subnet delegation is complete before creating container
  depends_on = [azurerm_subnet.aci]
}
