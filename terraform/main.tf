# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-inspec-${var.environment}-${random_string.suffix.result}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "InSpec-Database-Compliance"
    ManagedBy   = "Terraform"
    CostCenter  = "DevOps"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-inspec-${var.environment}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = azurerm_resource_group.main.tags
}

# Subnet for VMs
resource "azurerm_subnet" "vm" {
  name                 = "subnet-vm"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_vm_prefix]
}

# Subnet for Azure Container Instances (delegated)
resource "azurerm_subnet" "aci" {
  name                 = "subnet-aci"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_aci_prefix]

  delegation {
    name = "aci-delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Network Security Group for Runner VM
resource "azurerm_network_security_group" "runner" {
  name                = "nsg-runner-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowMSSQLOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowOracleOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1521"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowPostgresOutbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = azurerm_resource_group.main.tags
}

# Public IP for Runner VM
resource "azurerm_public_ip" "runner" {
  name                = "pip-runner-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Basic"

  tags = azurerm_resource_group.main.tags
}

# Network Interface for Runner VM
resource "azurerm_network_interface" "runner" {
  name                = "nic-runner-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.runner.id
  }

  tags = azurerm_resource_group.main.tags
}

# Associate NSG with Runner NIC
resource "azurerm_network_interface_security_group_association" "runner" {
  network_interface_id      = azurerm_network_interface.runner.id
  network_security_group_id = azurerm_network_security_group.runner.id
}

# Common tags for all resources
locals {
  common_tags = azurerm_resource_group.main.tags
}

# Cloud-init script for Runner VM
locals {
  cloud_init_script = <<-CLOUDINIT
#!/bin/bash
set -ex

# Log output to file
exec > >(tee /var/log/cloud-init-custom.log) 2>&1

echo "Starting cloud-init setup at $(date)"

# Install base tools
dnf install -y git python3-pip gcc make wget curl

# Install Python 3.9 for Ansible compatibility
dnf install -y python39

# Install Ruby 3.1 via module stream
dnf module reset ruby -y || true
dnf module enable ruby:3.1 -y
dnf module install ruby:3.1 -y
dnf install -y ruby-devel redhat-rpm-config

# Install InSpec 5.22.29 via gem (includes train-winrm for WinRM transport)
gem install inspec-bin -v 5.22.29 --no-document

# Accept InSpec license and verify
export CHEF_LICENSE=accept
/usr/local/bin/inspec --chef-license=accept || true
echo "InSpec version: $(/usr/local/bin/inspec version)"

# Add InSpec to PATH
echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/profile.d/inspec.sh

# ========================================
# MSSQL Client (sqlcmd)
# ========================================
echo "Installing MSSQL tools..."
curl -fsSL https://packages.microsoft.com/config/rhel/8/prod.repo -o /etc/yum.repos.d/mssql-release.repo
ACCEPT_EULA=Y dnf install -y mssql-tools18 unixODBC-devel

# Add MSSQL tools to PATH and create wrapper
cat > /etc/profile.d/mssql.sh << 'MSSQL_ENV'
export PATH="$PATH:/opt/mssql-tools18/bin"
MSSQL_ENV

# Create sqlcmd wrapper with SSL trust for self-signed certs
cat > /usr/local/bin/sqlcmd << 'SQLCMD_WRAPPER'
#!/bin/bash
/opt/mssql-tools18/bin/sqlcmd -C "$@"
SQLCMD_WRAPPER
chmod +x /usr/local/bin/sqlcmd
echo "MSSQL tools installed successfully"

# ========================================
# Oracle Instant Client (sqlplus)
# ========================================
echo "Installing Oracle Instant Client..."
dnf install -y libaio

cd /tmp
curl -LO https://download.oracle.com/otn_software/linux/instantclient/2113000/oracle-instantclient-basic-21.13.0.0.0-1.el8.x86_64.rpm || echo "Oracle basic download failed"
curl -LO https://download.oracle.com/otn_software/linux/instantclient/2113000/oracle-instantclient-sqlplus-21.13.0.0.0-1.el8.x86_64.rpm || echo "Oracle sqlplus download failed"

if [ -f oracle-instantclient-basic-21.13.0.0.0-1.el8.x86_64.rpm ]; then
  dnf install -y oracle-instantclient-basic-21.13.0.0.0-1.el8.x86_64.rpm
  dnf install -y oracle-instantclient-sqlplus-21.13.0.0.0-1.el8.x86_64.rpm || true

  cat > /etc/profile.d/oracle.sh << 'ORACLE_ENV'
export ORACLE_HOME=/usr/lib/oracle/21/client64
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME/bin:$PATH
ORACLE_ENV

  ln -sf /usr/lib/oracle/21/client64/bin/sqlplus /usr/local/bin/sqlplus 2>/dev/null || true
  echo "Oracle Instant Client installed successfully"
else
  echo "Oracle Instant Client installation skipped"
fi

# ========================================
# PostgreSQL Client (psql)
# ========================================
echo "Installing PostgreSQL client..."
dnf install -y postgresql

# Verify psql installation
psql --version || echo "psql installation check failed"
echo "PostgreSQL client installed successfully"

# ========================================
# Sybase environment (for InSpec sybase_session)
# ========================================
echo "Setting up Sybase environment for InSpec..."

# Install dependencies that may be needed by train-sybase plugin
dnf install -y libaio ncurses-libs

# Create SAP ASE directory structure (for production compatibility)
mkdir -p /opt/sap/OCS-16_0/bin
mkdir -p /opt/sap/OCS-16_0/lib
chown -R azureuser:azureuser /opt/sap

# Create SYBASE.sh environment script
cat > /opt/sap/SYBASE.sh << 'SYBASE_ENV'
#!/bin/bash
# SAP ASE Environment Variables
export SYBASE=/opt/sap
export SYBASE_OCS=OCS-16_0
export PATH=$SYBASE/$SYBASE_OCS/bin:$PATH
export LD_LIBRARY_PATH=$SYBASE/$SYBASE_OCS/lib:$LD_LIBRARY_PATH
SYBASE_ENV
chmod +x /opt/sap/SYBASE.sh

# Add to system-wide profile
cat > /etc/profile.d/sybase.sh << 'SYBASE_PROFILE'
# SAP ASE Environment
if [ -f /opt/sap/SYBASE.sh ]; then
  source /opt/sap/SYBASE.sh
fi
SYBASE_PROFILE

# Create interfaces file for Sybase server connections
cat > /opt/sap/interfaces << 'INTERFACES'
# SAP ASE Server Interfaces File
MYSYBASE
	query tcp ether 10.0.2.5 5000
	master tcp ether 10.0.2.5 5000
INTERFACES

echo "Sybase environment configured"
echo "Note: InSpec uses sybase_session resource for database connectivity"

# ========================================
# Create results directory
# ========================================
mkdir -p /tmp/compliance_scans
chmod 777 /tmp/compliance_scans

mkdir -p /tmp/inspec_profiles
chmod 777 /tmp/inspec_profiles

# Signal completion
touch /var/log/cloud-init-complete

echo "Cloud-init setup completed at $(date)"
echo "Installed tools:"
echo "  - InSpec: $(/usr/local/bin/inspec version 2>/dev/null || echo 'check manually')"
echo "  - sqlcmd (MSSQL): $(which sqlcmd 2>/dev/null || echo 'not in PATH yet')"
echo "  - sqlplus (Oracle): $(which sqlplus 2>/dev/null || echo 'not in PATH yet')"
echo "  - psql (PostgreSQL): $(which psql 2>/dev/null || echo 'not in PATH yet')"
echo "  - Sybase: Using InSpec sybase_session (interfaces file at /opt/sap/interfaces)"
CLOUDINIT
}

# Runner VM
resource "azurerm_linux_virtual_machine" "runner" {
  name                = "vm-runner-inspec-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.runner_vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.runner.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8-lvm-gen2"
    version   = "latest"
  }

  custom_data = base64encode(local.cloud_init_script)

  tags = azurerm_resource_group.main.tags
}

# Auto-shutdown schedule for cost savings
resource "azurerm_dev_test_global_vm_shutdown_schedule" "runner" {
  virtual_machine_id = azurerm_linux_virtual_machine.runner.id
  location           = azurerm_resource_group.main.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = azurerm_resource_group.main.tags
}
