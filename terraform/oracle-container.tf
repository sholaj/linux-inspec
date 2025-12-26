# Azure Container Instance for Oracle Database 19c
# Uses doctorkirk/oracle-19c from Docker Hub

resource "azurerm_container_group" "oracle" {
  count               = var.deploy_oracle ? 1 : 0
  name                = "aci-oracle-inspec-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.aci.id]

  # Docker Hub credentials for authenticated pulls
  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_password
  }

  container {
    name   = "oracle-19c"
    image  = "doctorkirk/oracle-19c"
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

  depends_on = [azurerm_subnet.aci]
}
