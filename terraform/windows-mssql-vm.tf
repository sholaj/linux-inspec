# Windows VM with SQL Server Express for WinRM-based InSpec Testing
# Deployed conditionally via var.deploy_windows_mssql
#
# Architecture:
# Linux Runner (10.0.1.4) --[WinRM 5985]--> Windows VM (10.0.1.x) --[ADO.NET]--> SQL Server (localhost:1433)

# ========================================
# Network Security Group
# ========================================
resource "azurerm_network_security_group" "windows_mssql" {
  count               = var.deploy_windows_mssql ? 1 : 0
  name                = "nsg-windows-mssql-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # WinRM HTTP (for InSpec from runner)
  security_rule {
    name                       = "AllowWinRM"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = var.subnet_vm_prefix
    destination_address_prefix = "*"
  }

  # RDP (for management access)
  security_rule {
    name                       = "AllowRDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SQL Server (for potential direct testing)
  security_rule {
    name                       = "AllowSQLServer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = var.subnet_vm_prefix
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.main.tags
}

# ========================================
# Public IP (for RDP access)
# ========================================
resource "azurerm_public_ip" "windows_mssql" {
  count               = var.deploy_windows_mssql ? 1 : 0
  name                = "pip-windows-mssql-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Basic"

  tags = azurerm_resource_group.main.tags
}

# ========================================
# Network Interface
# ========================================
resource "azurerm_network_interface" "windows_mssql" {
  count               = var.deploy_windows_mssql ? 1 : 0
  name                = "nic-windows-mssql-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.windows_mssql[0].id
  }

  tags = azurerm_resource_group.main.tags
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "windows_mssql" {
  count                     = var.deploy_windows_mssql ? 1 : 0
  network_interface_id      = azurerm_network_interface.windows_mssql[0].id
  network_security_group_id = azurerm_network_security_group.windows_mssql[0].id
}

# ========================================
# Windows Virtual Machine
# ========================================
resource "azurerm_windows_virtual_machine" "mssql" {
  count               = var.deploy_windows_mssql ? 1 : 0
  name                = "vm-win-mssql-${var.environment}"
  computer_name       = "winmssql${var.environment}"  # Max 15 chars
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.windows_vm_size
  admin_username      = var.windows_admin_username
  admin_password      = var.windows_admin_password

  network_interface_ids = [
    azurerm_network_interface.windows_mssql[0].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 127
  }

  # Windows Server 2022 Datacenter
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  # Enable WinRM for Custom Script Extension and remote management
  winrm_listener {
    protocol = "Http"
  }

  tags = azurerm_resource_group.main.tags
}

# ========================================
# Custom Script Extension - Setup WinRM & SQL Server
# ========================================
resource "azurerm_virtual_machine_extension" "winrm_setup" {
  count                      = var.deploy_windows_mssql ? 1 : 0
  name                       = "winrm-setup"
  virtual_machine_id         = azurerm_windows_virtual_machine.mssql[0].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  # Comprehensive WinRM + SQL Server setup
  protected_settings = jsonencode({
    commandToExecute = <<-EOT
powershell -ExecutionPolicy Unrestricted -Command "
$ErrorActionPreference = 'Continue'
$logFile = 'C:\\WindowsAzure\\setup.log'

function Log { param($msg) Add-Content $logFile \"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $msg\" }

Log 'Starting WinRM and SQL Server setup...'

# ============ WinRM Configuration ============
Log 'Configuring WinRM...'

# Enable WinRM service
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM

# Configure WinRM for remote access
winrm quickconfig -force 2>&1 | Out-Null

# Set WinRM service settings
winrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'
winrm set winrm/config/service/auth '@{Basic=\"true\"}'
winrm set winrm/config/service/auth '@{Negotiate=\"true\"}'
winrm set winrm/config/service/auth '@{CredSSP=\"true\"}'
winrm set winrm/config '@{MaxEnvelopeSizekb=\"8192\"}'
winrm set winrm/config/client '@{AllowUnencrypted=\"true\"}'
winrm set winrm/config/client/auth '@{Basic=\"true\"}'

# Set TrustedHosts to allow connections from any host
Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*' -Force

# Configure LocalAccountTokenFilterPolicy for remote admin access
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'LocalAccountTokenFilterPolicy' -Value 1 -PropertyType DWORD -Force -ErrorAction SilentlyContinue

# Restart WinRM to apply changes
Restart-Service WinRM

# Firewall rules
New-NetFirewallRule -DisplayName 'WinRM HTTP' -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'SQL Server' -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow -ErrorAction SilentlyContinue

Log 'WinRM configured successfully'

# ============ SQL Server Express Installation ============
Log 'Downloading SQL Server Express 2019...'

# Create temp directory
New-Item -ItemType Directory -Path 'C:\\SQLSetup' -Force | Out-Null

# Download SQL Server Express
\$sqlUrl = 'https://go.microsoft.com/fwlink/?linkid=866658'
\$sqlInstaller = 'C:\\SQLSetup\\SQL2019-SSEI-Expr.exe'

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri \$sqlUrl -OutFile \$sqlInstaller -UseBasicParsing
    Log 'SQL Server Express downloaded'
} catch {
    Log \"Download failed: \$_\"
}

# Run SQL Server Express installer (download media)
if (Test-Path \$sqlInstaller) {
    Log 'Extracting SQL Server media...'
    Start-Process -FilePath \$sqlInstaller -ArgumentList '/Action=Download', '/MediaPath=C:\\SQLSetup', '/MediaType=Core', '/Quiet' -Wait

    # Find and run setup
    \$setupExe = Get-ChildItem -Path 'C:\\SQLSetup' -Recurse -Filter 'setup.exe' | Select-Object -First 1
    if (\$setupExe) {
        Log 'Installing SQL Server Express...'
        \$installArgs = '/Q /ACTION=Install /FEATURES=SQLENGINE /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT=\"NT AUTHORITY\\SYSTEM\" /SQLSYSADMINACCOUNTS=\"BUILTIN\\Administrators\" /SECURITYMODE=SQL /SAPWD=\"${var.windows_admin_password}\" /TCPENABLED=1 /IACCEPTSQLSERVERLICENSETERMS'
        Start-Process -FilePath \$setupExe.FullName -ArgumentList \$installArgs -Wait
        Log 'SQL Server Express installed'
    }
}

# Enable SQL Server TCP/IP and set port
try {
    Import-Module SQLPS -DisableNameChecking -ErrorAction SilentlyContinue
    \$smo = 'Microsoft.SqlServer.Management.Smo.'
    \$wmi = New-Object (\$smo + 'Wmi.ManagedComputer') .
    \$tcp = \$wmi.ServerInstances['MSSQLSERVER'].ServerProtocols['Tcp']
    \$tcp.IsEnabled = \$true
    \$tcp.Alter()
    Restart-Service MSSQLSERVER -Force -ErrorAction SilentlyContinue
    Log 'SQL Server TCP/IP enabled'
} catch {
    Log \"SQL config warning: \$_\"
}

Log 'Setup complete!'
'Setup completed successfully' | Out-File 'C:\\WindowsAzure\\winrm-complete.txt'
"
EOT
  })

  tags = azurerm_resource_group.main.tags

  # Increase timeout for SQL Server installation
  timeouts {
    create = "60m"
  }

  depends_on = [azurerm_windows_virtual_machine.mssql]
}

# ========================================
# Auto-shutdown Schedule (cost savings)
# ========================================
resource "azurerm_dev_test_global_vm_shutdown_schedule" "windows_mssql" {
  count              = var.deploy_windows_mssql ? 1 : 0
  virtual_machine_id = azurerm_windows_virtual_machine.mssql[0].id
  location           = azurerm_resource_group.main.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = azurerm_resource_group.main.tags
}
