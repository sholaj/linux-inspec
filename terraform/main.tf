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
  cloud_init_script = <<-EOF
    #!/bin/bash
    set -ex

    # Log output
    exec > >(tee /var/log/cloud-init-custom.log)
    exec 2>&1

    echo "Starting cloud-init setup at $(date)"

    # Install base tools (no epel-release on RHEL)
    dnf install -y git python3-pip gcc make

    # Install Python 3.9 for Ansible compatibility
    dnf install -y python39

    # Install Ruby 3.1 via module stream
    dnf module reset ruby -y || true
    dnf module enable ruby:3.1 -y
    dnf module install ruby:3.1 -y
    dnf install -y ruby-devel redhat-rpm-config

    # Install InSpec 5.22.29 via gem
    gem install inspec-bin -v 5.22.29 --no-document

    # Accept InSpec license
    export CHEF_LICENSE=accept
    inspec --chef-license=accept || true

    # Verify InSpec installation
    inspec version

    # Install MSSQL tools 18 (sqlcmd)
    curl -fsSL https://packages.microsoft.com/config/rhel/8/prod.repo -o /etc/yum.repos.d/mssql-release.repo
    ACCEPT_EULA=Y dnf install -y mssql-tools18 unixODBC-devel

    # Add MSSQL tools to PATH
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /etc/profile.d/mssql.sh

    # Create sqlcmd wrapper with SSL trust (-C flag) for self-signed certs
    cat > /usr/local/bin/sqlcmd << 'SQLCMD_WRAPPER'
#!/bin/bash
/opt/mssql-tools18/bin/sqlcmd -C "$@"
SQLCMD_WRAPPER
    chmod +x /usr/local/bin/sqlcmd

    # Create results directory
    mkdir -p /tmp/compliance_scans
    chmod 777 /tmp/compliance_scans

    # Install Oracle Instant Client 21c
    echo "Installing Oracle Instant Client..."
    dnf install -y libaio

    # Download Oracle Instant Client (Basic + SQLPlus)
    cd /tmp
    curl -LO https://download.oracle.com/otn_software/linux/instantclient/2113000/oracle-instantclient-basic-21.13.0.0.0-1.el8.x86_64.rpm || echo "Oracle basic client download failed"
    curl -LO https://download.oracle.com/otn_software/linux/instantclient/2113000/oracle-instantclient-sqlplus-21.13.0.0.0-1.el8.x86_64.rpm || echo "Oracle sqlplus download failed"

    # Install Oracle RPMs if downloaded
    if [ -f oracle-instantclient-basic-21.13.0.0.0-1.el8.x86_64.rpm ]; then
      dnf install -y oracle-instantclient-basic-21.13.0.0.0-1.el8.x86_64.rpm
      dnf install -y oracle-instantclient-sqlplus-21.13.0.0.0-1.el8.x86_64.rpm || true

      # Set Oracle environment variables
      cat >> /etc/profile.d/oracle.sh << 'ORACLE_ENV'
export ORACLE_HOME=/usr/lib/oracle/21/client64
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME/bin:$PATH
ORACLE_ENV

      # Create sqlplus wrapper for easy access
      ln -sf /usr/lib/oracle/21/client64/bin/sqlplus /usr/local/bin/sqlplus 2>/dev/null || true
      echo "Oracle Instant Client installed successfully"

      # Create oracle_query wrapper (password via ORACLE_PWD env var)
      cat > /usr/local/bin/oracle_query << 'ORACLE_WRAPPER'
#!/bin/bash
# Oracle query wrapper - password via ORACLE_PWD environment variable
USER="$1"; HOST="$2"; PORT="$3"; SERVICE="$4"; shift 4; QUERY="$*"
[ -z "$ORACLE_PWD" ] && echo "ERROR: ORACLE_PWD not set" >&2 && exit 1
sqlplus -S "${USER}/${ORACLE_PWD}@${HOST}:${PORT}/${SERVICE}" << EOF
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 200
${QUERY};
EXIT;
EOF
ORACLE_WRAPPER
      chmod +x /usr/local/bin/oracle_query
      echo "oracle_query wrapper installed"
    else
      echo "Oracle Instant Client installation skipped (download failed)"
    fi

    # Create sybase_query wrapper (password via SYBASE_PWD env var)
    cat > /usr/local/bin/sybase_query << 'SYBASE_WRAPPER'
#!/bin/bash
# Sybase query wrapper - password via SYBASE_PWD environment variable
USER="$1"; SERVER="$2"; shift 2; QUERY="$*"
[ -z "$SYBASE_PWD" ] && echo "ERROR: SYBASE_PWD not set" >&2 && exit 1
isql -U"${USER}" -P"${SYBASE_PWD}" -S"${SERVER}" -w999 << EOF
${QUERY}
go
quit
EOF
SYBASE_WRAPPER
    chmod +x /usr/local/bin/sybase_query
    echo "sybase_query wrapper installed"

    # Signal completion
    touch /var/log/cloud-init-complete

    echo "Cloud-init setup completed at $(date)"
  EOF
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
