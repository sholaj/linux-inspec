# Azure Container Instance for Oracle Database XE 21c
# Used for InSpec compliance testing

resource "azurerm_container_group" "oracle" {
  count               = var.deploy_oracle ? 1 : 0
  name                = "aci-oracle-inspec-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.aci.id]

  # Oracle Container Registry authentication
  image_registry_credential {
    server   = "container-registry.oracle.com"
    username = var.oracle_registry_username
    password = var.oracle_registry_password
  }

  container {
    name   = "oracle-xe"
    image  = "container-registry.oracle.com/database/express:21.3.0-xe"
    cpu    = "2"
    memory = "4"

    ports {
      port     = 1521
      protocol = "TCP"
    }

    environment_variables = {
      ORACLE_CHARACTERSET = "AL32UTF8"
    }

    secure_environment_variables = {
      ORACLE_PWD = var.oracle_password
    }

    # Ephemeral storage for database files
    volume {
      name       = "oracle-data"
      mount_path = "/opt/oracle/oradata"
      empty_dir  = true
    }
  }

  tags = merge(
    local.common_tags,
    {
      Database = "Oracle"
      Version  = "21c-XE"
    }
  )

  depends_on = [azurerm_subnet.aci]
}
