# AAP2 Controller VM Configuration
# Ansible Automation Platform 2 - Self-hosted on Azure

# Network Security Group for AAP2
resource "azurerm_network_security_group" "aap2" {
  count               = var.deploy_aap2 ? 1 : 0
  name                = "nsg-aap2-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # HTTPS for AAP2 Web UI
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SSH for management
  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Receptor mesh (AAP2 internal communication)
  security_rule {
    name                       = "AllowReceptor"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "27199"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # HTTP for initial setup (redirect to HTTPS)
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow outbound to database containers
  security_rule {
    name                       = "AllowDatabaseOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433-5432"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = azurerm_resource_group.main.tags
}

# Public IP for AAP2
resource "azurerm_public_ip" "aap2" {
  count               = var.deploy_aap2 ? 1 : 0
  name                = "pip-aap2-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Basic"

  tags = azurerm_resource_group.main.tags
}

# Network Interface for AAP2
resource "azurerm_network_interface" "aap2" {
  count               = var.deploy_aap2 ? 1 : 0
  name                = "nic-aap2-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.aap2[0].id
  }

  tags = azurerm_resource_group.main.tags
}

# Associate NSG with AAP2 NIC
resource "azurerm_network_interface_security_group_association" "aap2" {
  count                     = var.deploy_aap2 ? 1 : 0
  network_interface_id      = azurerm_network_interface.aap2[0].id
  network_security_group_id = azurerm_network_security_group.aap2[0].id
}

# Cloud-init script for AAP2 VM
locals {
  aap2_cloud_init_script = <<-CLOUDINIT
#!/bin/bash
# AAP2 Controller Preparation Script
# Note: Full AAP2 installation requires Red Hat subscription and manual setup

set -ex
exec > >(tee /var/log/aap2-cloud-init.log) 2>&1

echo "Starting AAP2 preparation at $(date)"

# Update system
dnf update -y

# Install prerequisites
dnf install -y \
  podman \
  git \
  python3-pip \
  ansible-core \
  wget \
  curl \
  unzip \
  tar \
  jq

# Install ansible-builder and ansible-navigator for EE management
pip3 install ansible-builder ansible-navigator

# Create directories for AAP2
mkdir -p /opt/aap2
mkdir -p /opt/aap2/execution-environments
mkdir -p /var/lib/awx/projects
mkdir -p /tmp/compliance_scans
chmod 755 /opt/aap2
chmod 777 /tmp/compliance_scans

# Install Azure CLI for ACR authentication
rpm --import https://packages.microsoft.com/keys/microsoft.asc
dnf install -y https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm || true
dnf install -y azure-cli || echo "Azure CLI installation skipped"

# Clone the compliance scanning repository
cd /opt/aap2
git clone https://github.com/sholaj/linux-inspec.git || echo "Git clone skipped - repo may not exist"
if [ -d linux-inspec ]; then
  cd linux-inspec
  git checkout feat/infraTest || true
fi

# Create AAP2 installation instructions file
cat > /opt/aap2/INSTALL_INSTRUCTIONS.md << 'INSTRUCTIONS'
# AAP2 Installation Instructions

## Prerequisites
1. Red Hat subscription with AAP entitlement
2. This VM is prepared with podman, ansible-builder, ansible-navigator

## Installation Steps

### Option 1: Containerized AAP (Recommended for Dev/Test)
1. Register with Red Hat:
   subscription-manager register --username YOUR_USERNAME --password YOUR_PASSWORD
   subscription-manager attach --pool=YOUR_AAP_POOL_ID

2. Install AAP2 Containerized:
   dnf install -y ansible-automation-platform-containerized-setup
   ansible-playbook -i inventory containerized_install.yml

### Option 2: Traditional AAP Installation
1. Download AAP2 bundle from access.redhat.com
2. Extract and run setup.sh

## Post-Installation
1. Access AAP2 at https://<this-vm-ip>
2. Default admin user: admin
3. Import credential types from /opt/aap2/linux-inspec/aap2-config/credential-types/
4. Create project pointing to /opt/aap2/linux-inspec
5. Build and push Execution Environment:
   cd /opt/aap2/linux-inspec/execution-environment
   ansible-builder build --tag acrinspecwzrr.azurecr.io/db-compliance-ee:1.0.0
   az acr login --name acrinspecwzrr
   podman push acrinspecwzrr.azurecr.io/db-compliance-ee:1.0.0

INSTRUCTIONS

# Create systemd service placeholder for AAP2
cat > /etc/systemd/system/aap2-ready.service << 'SERVICE'
[Unit]
Description=AAP2 Preparation Complete Marker
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable aap2-ready.service

# Signal completion
touch /var/log/aap2-cloud-init-complete

echo "AAP2 preparation complete at $(date)"
echo ""
echo "=========================================="
echo "AAP2 VM Preparation Complete"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. SSH to this VM: ssh ${var.admin_username}@<public-ip>"
echo "2. Register with Red Hat subscription"
echo "3. Install AAP2 following /opt/aap2/INSTALL_INSTRUCTIONS.md"
echo "4. Access AAP2 at https://<public-ip>"
echo ""
echo "Tools installed:"
echo "  - podman: $(podman --version 2>/dev/null || echo 'check manually')"
echo "  - ansible-builder: $(ansible-builder --version 2>/dev/null || echo 'check manually')"
echo "  - ansible-navigator: $(ansible-navigator --version 2>/dev/null || echo 'check manually')"
echo ""
CLOUDINIT
}

# AAP2 Controller VM
resource "azurerm_linux_virtual_machine" "aap2" {
  count               = var.deploy_aap2 ? 1 : 0
  name                = "vm-aap2-inspec-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.aap2_vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.aap2[0].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9-lvm-gen2"
    version   = "latest"
  }

  custom_data = base64encode(local.aap2_cloud_init_script)

  tags = azurerm_resource_group.main.tags
}

# Auto-shutdown schedule for AAP2 (cost savings)
resource "azurerm_dev_test_global_vm_shutdown_schedule" "aap2" {
  count              = var.deploy_aap2 ? 1 : 0
  virtual_machine_id = azurerm_linux_virtual_machine.aap2[0].id
  location           = azurerm_resource_group.main.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = azurerm_resource_group.main.tags
}
