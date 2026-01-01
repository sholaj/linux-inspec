# Azure Container Instance for Oracle Database 19c
# Uses image from Azure Container Registry

resource "azurerm_container_group" "oracle" {
  count               = var.deploy_oracle ? 1 : 0
  name                = "aci-oracle-inspec-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.aci.id]

  # ACR credentials
  image_registry_credential {
    server   = azurerm_container_registry.main.login_server
    username = azurerm_container_registry.main.admin_username
    password = azurerm_container_registry.main.admin_password
  }

  container {
    name   = "oracle-19c"
    image  = "${azurerm_container_registry.main.login_server}/oracle:19c"
    cpu    = "2"
    memory = "8"

    ports {
      port     = 1521
      protocol = "TCP"
    }

    ports {
      port     = 5500
      protocol = "TCP"
    }

    environment_variables = {
      ORACLE_SID = "ORCLCDB"
      ORACLE_PDB = "ORCLPDB1"
    }

    secure_environment_variables = {
      ORACLE_PWD = var.oracle_password
    }
  }

  tags = merge(
    local.common_tags,
    {
      Database = "Oracle"
      Version  = "19c"
    }
  )

  depends_on = [
    azurerm_subnet.aci,
    null_resource.import_oracle_image
  ]
}
