# Azure Container Instance for Sybase ASE
# Uses image from Azure Container Registry

resource "azurerm_container_group" "sybase" {
  count               = var.deploy_sybase ? 1 : 0
  name                = "aci-sybase-inspec-${var.environment}"
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
    name   = "sybase-ase"
    image  = "${azurerm_container_registry.main.login_server}/sybase:16.0"
    cpu    = "2"
    memory = "4"

    ports {
      port     = 5000
      protocol = "TCP"
    }

    environment_variables = {
      SYBASE_SERVER = "SYBASE"
    }

    secure_environment_variables = {
      SA_PASSWORD = var.sybase_password
    }
  }

  tags = merge(
    local.common_tags,
    {
      Database = "Sybase"
      Version  = "16"
    }
  )

  depends_on = [
    azurerm_subnet.aci,
    null_resource.import_sybase_image
  ]
}
