# Azure Container Registry for database container images
# This avoids Docker Hub rate limiting issues

resource "azurerm_container_registry" "main" {
  name                = "acrinspec${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = local.common_tags
}

# Import Sybase image from Docker Hub to ACR
resource "null_resource" "import_sybase_image" {
  count = var.deploy_sybase ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      az acr import \
        --name ${azurerm_container_registry.main.name} \
        --source docker.io/datagrip/sybase:16.0 \
        --image sybase:16.0 \
        --force 2>/dev/null || true
    EOT
  }

  triggers = {
    acr_id = azurerm_container_registry.main.id
  }

  depends_on = [azurerm_container_registry.main]
}

# Import Oracle image from Docker Hub to ACR
resource "null_resource" "import_oracle_image" {
  count = var.deploy_oracle ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      az acr import \
        --name ${azurerm_container_registry.main.name} \
        --source docker.io/doctorkirk/oracle-19c \
        --image oracle:19c \
        --force 2>/dev/null || true
    EOT
  }

  triggers = {
    acr_id = azurerm_container_registry.main.id
  }

  depends_on = [azurerm_container_registry.main]
}
