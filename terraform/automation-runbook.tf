# =============================================================================
# Azure Automation Account & Runbook - Nightly Resource Shutdown
# =============================================================================
# Stops all running VMs and container instances in the resource group at 9 PM
# daily to minimize costs for this test/dev environment.
# =============================================================================

# --- Automation Account ---
resource "azurerm_automation_account" "main" {
  name                = "aa-inspec-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# --- Role Assignment: Allow Automation Account to manage resources ---
# Contributor on the resource group so the runbook can stop VMs and containers
resource "azurerm_role_assignment" "automation_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.main.identity[0].principal_id
}

# --- PowerShell Runbook: Stop all VMs and Containers ---
resource "azurerm_automation_runbook" "stop_resources" {
  name                    = "Stop-AllResources-Nightly"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  log_verbose             = false
  log_progress            = true
  runbook_type            = "PowerShell"
  description             = "Stops all running VMs and container instances in the InSpec test resource group to save costs overnight."

  content = <<-POWERSHELL
<#
  .SYNOPSIS
    Stops all running VMs and Azure Container Instances in the resource group.

  .DESCRIPTION
    Designed to run nightly at 9 PM via Azure Automation schedule.
    Uses the Automation Account's Managed Identity for authentication.
    Targets only resources within the InSpec test resource group.
#>

# Authenticate with the Automation Account's Managed Identity
try {
    Connect-AzAccount -Identity -ErrorAction Stop
    Write-Output "Successfully authenticated with Managed Identity."
}
catch {
    Write-Error "Failed to authenticate with Managed Identity: $_"
    throw $_
}

$resourceGroupName = "${azurerm_resource_group.main.name}"
Write-Output "Target Resource Group: $resourceGroupName"
Write-Output "Execution Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')"
Write-Output "=" * 60

# --- Stop Virtual Machines ---
Write-Output "`n--- Stopping Virtual Machines ---"
$vms = Get-AzVM -ResourceGroupName $resourceGroupName -Status -ErrorAction SilentlyContinue

if ($vms) {
    $runningVMs = $vms | Where-Object { $_.PowerState -eq "VM running" }

    if ($runningVMs) {
        Write-Output "Found $($runningVMs.Count) running VM(s)."
        foreach ($vm in $runningVMs) {
            Write-Output "Stopping VM: $($vm.Name) ..."
            try {
                Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vm.Name -Force -ErrorAction Stop
                Write-Output "  -> VM '$($vm.Name)' stopped successfully."
            }
            catch {
                Write-Warning "  -> Failed to stop VM '$($vm.Name)': $_"
            }
        }
    }
    else {
        Write-Output "No running VMs found. Nothing to stop."
    }
}
else {
    Write-Output "No VMs found in resource group."
}

# --- Stop Azure Container Instances ---
Write-Output "`n--- Stopping Container Instances ---"
$containers = Get-AzContainerGroup -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

if ($containers) {
    $runningContainers = $containers | Where-Object { $_.ProvisioningState -eq "Succeeded" -or $_.InstanceViewState -eq "Running" }

    if ($runningContainers) {
        Write-Output "Found $($runningContainers.Count) running container group(s)."
        foreach ($container in $runningContainers) {
            Write-Output "Stopping container group: $($container.Name) ..."
            try {
                Stop-AzContainerGroup -ResourceGroupName $resourceGroupName -Name $container.Name -ErrorAction Stop
                Write-Output "  -> Container group '$($container.Name)' stopped successfully."
            }
            catch {
                Write-Warning "  -> Failed to stop container group '$($container.Name)': $_"
            }
        }
    }
    else {
        Write-Output "No running container groups found. Nothing to stop."
    }
}
else {
    Write-Output "No container groups found in resource group."
}

# --- Summary ---
Write-Output "`n" + "=" * 60
Write-Output "Nightly shutdown complete at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')"
Write-Output "=" * 60
  POWERSHELL

  tags = local.common_tags
}

# --- Schedule: Every night at 9 PM ---
resource "azurerm_automation_schedule" "nightly_9pm" {
  name                    = "nightly-shutdown-9pm"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  frequency               = "Day"
  interval                = 1
  timezone                = var.runbook_timezone
  start_time              = timeadd(timestamp(), "24h")
  description             = "Triggers the stop-all-resources runbook every night at 9 PM"

  lifecycle {
    ignore_changes = [start_time]
  }
}

# --- Link Schedule to Runbook ---
resource "azurerm_automation_job_schedule" "nightly_stop" {
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name
  schedule_name           = azurerm_automation_schedule.nightly_9pm.name
  runbook_name            = azurerm_automation_runbook.stop_resources.name
}

# --- Required Az Modules for the Runbook ---
resource "azurerm_automation_module" "az_accounts" {
  name                    = "Az.Accounts"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Accounts"
  }
}

resource "azurerm_automation_module" "az_compute" {
  name                    = "Az.Compute"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Compute"
  }

  depends_on = [azurerm_automation_module.az_accounts]
}

resource "azurerm_automation_module" "az_containerinstance" {
  name                    = "Az.ContainerInstance"
  resource_group_name     = azurerm_resource_group.main.name
  automation_account_name = azurerm_automation_account.main.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.ContainerInstance"
  }

  depends_on = [azurerm_automation_module.az_accounts]
}
