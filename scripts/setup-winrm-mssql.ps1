# PowerShell script to set up WinRM and SQL Server Express on Windows Server 2022
# This script is executed via Azure Custom Script Extension
#
# Prerequisites:
# - Windows Server 2022
# - Run as Administrator
# - Internet connectivity for SQL Server download
#
# Parameters passed via Terraform:
# - $MssqlPassword: SA password for SQL Server

param(
    [Parameter(Mandatory=$true)]
    [string]$MssqlPassword
)

$ErrorActionPreference = "Stop"
$LogFile = "C:\WindowsAzure\Logs\setup-winrm-mssql.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Add-Content -Path $LogFile -Value $logMessage
    Write-Host $logMessage
}

try {
    Write-Log "Starting WinRM and SQL Server setup..."

    # ========================================
    # 1. Configure WinRM for HTTP (port 5985)
    # ========================================
    Write-Log "Configuring WinRM..."

    # Enable WinRM service
    Set-Service -Name WinRM -StartupType Automatic
    Start-Service -Name WinRM

    # Configure WinRM for HTTP listener
    winrm quickconfig -force

    # Configure WinRM settings for InSpec compatibility
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/client '@{AllowUnencrypted="true"}'
    winrm set winrm/config/client/auth '@{Basic="true"}'

    # Increase max envelope size for large responses
    winrm set winrm/config '@{MaxEnvelopeSizekb="8192"}'

    # Set max timeout (in ms) - 3 minutes
    winrm set winrm/config '@{MaxTimeoutms="180000"}'

    Write-Log "WinRM configured successfully"

    # ========================================
    # 2. Configure Windows Firewall
    # ========================================
    Write-Log "Configuring firewall rules..."

    # Allow WinRM HTTP (5985)
    New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow -ErrorAction SilentlyContinue

    # Allow SQL Server (1433)
    New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow -ErrorAction SilentlyContinue

    # Allow RDP (3389) - should already be enabled but ensure it
    New-NetFirewallRule -DisplayName "RDP" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow -ErrorAction SilentlyContinue

    Write-Log "Firewall rules configured"

    # ========================================
    # 3. Download SQL Server 2019 Express
    # ========================================
    Write-Log "Downloading SQL Server 2019 Express..."

    $sqlInstallerPath = "C:\SQLSetup"
    $sqlInstallerExe = "$sqlInstallerPath\SQL2019-SSEI-Expr.exe"
    $sqlMediaPath = "$sqlInstallerPath\SQLMedia"

    # Create directory
    New-Item -ItemType Directory -Path $sqlInstallerPath -Force | Out-Null

    # Download SQL Server Express installer
    $sqlDownloadUrl = "https://go.microsoft.com/fwlink/?linkid=866658"

    Write-Log "Downloading SQL Server installer from $sqlDownloadUrl..."
    Invoke-WebRequest -Uri $sqlDownloadUrl -OutFile $sqlInstallerExe -UseBasicParsing

    Write-Log "SQL Server installer downloaded"

    # ========================================
    # 4. Extract SQL Server Media
    # ========================================
    Write-Log "Extracting SQL Server installation media..."

    # Extract the media files
    Start-Process -FilePath $sqlInstallerExe -ArgumentList "/MediaPath=$sqlMediaPath", "/MediaType=Core", "/Quiet", "/Action=Download" -Wait -NoNewWindow

    Write-Log "SQL Server media extracted"

    # ========================================
    # 5. Install SQL Server Express
    # ========================================
    Write-Log "Installing SQL Server 2019 Express..."

    $setupPath = Get-ChildItem -Path $sqlMediaPath -Recurse -Filter "setup.exe" | Select-Object -First 1

    if (-not $setupPath) {
        throw "SQL Server setup.exe not found in $sqlMediaPath"
    }

    # Install SQL Server with Mixed Mode Authentication
    $installArgs = @(
        "/Q"
        "/IACCEPTSQLSERVERLICENSETERMS"
        "/ACTION=Install"
        "/FEATURES=SQLENGINE"
        "/INSTANCENAME=MSSQLSERVER"
        "/SQLSYSADMINACCOUNTS=BUILTIN\Administrators"
        "/SECURITYMODE=SQL"
        "/SAPWD=$MssqlPassword"
        "/TCPENABLED=1"
        "/NPENABLED=0"
        "/UpdateEnabled=0"
    )

    Write-Log "Running SQL Server setup with arguments: $($installArgs -join ' ')"

    $process = Start-Process -FilePath $setupPath.FullName -ArgumentList $installArgs -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010) {
        throw "SQL Server installation failed with exit code: $($process.ExitCode)"
    }

    Write-Log "SQL Server installed successfully (exit code: $($process.ExitCode))"

    # ========================================
    # 6. Configure SQL Server TCP/IP
    # ========================================
    Write-Log "Configuring SQL Server TCP/IP settings..."

    # Load SQL Server SMO assemblies
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement') | Out-Null

    # Wait for SQL Server service to start
    Start-Sleep -Seconds 10
    Start-Service -Name MSSQLSERVER -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 10

    # Enable TCP/IP protocol
    $wmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer
    $tcpProtocol = $wmi.ServerInstances['MSSQLSERVER'].ServerProtocols['Tcp']
    $tcpProtocol.IsEnabled = $true
    $tcpProtocol.Alter()

    # Configure TCP/IP to listen on port 1433
    $ipAll = $tcpProtocol.IPAddresses | Where-Object { $_.Name -eq 'IPAll' }
    $ipAll.IPAddressProperties['TcpPort'].Value = '1433'
    $ipAll.IPAddressProperties['TcpDynamicPorts'].Value = ''
    $tcpProtocol.Alter()

    Write-Log "TCP/IP protocol enabled on port 1433"

    # ========================================
    # 7. Restart SQL Server
    # ========================================
    Write-Log "Restarting SQL Server service..."

    Restart-Service -Name MSSQLSERVER -Force
    Start-Sleep -Seconds 10

    # Verify service is running
    $sqlService = Get-Service -Name MSSQLSERVER
    Write-Log "SQL Server service status: $($sqlService.Status)"

    # ========================================
    # 8. Configure SQL Server Browser (optional)
    # ========================================
    Write-Log "Configuring SQL Server Browser service..."

    Set-Service -Name SQLBrowser -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name SQLBrowser -ErrorAction SilentlyContinue

    # ========================================
    # 9. Verify Setup
    # ========================================
    Write-Log "Verifying setup..."

    # Verify WinRM
    $winrmService = Get-Service -Name WinRM
    Write-Log "WinRM service status: $($winrmService.Status)"

    # Verify WinRM listener
    $listener = Get-ChildItem WSMan:\localhost\Listener | Where-Object { $_.Keys -contains 'Transport=HTTP' }
    if ($listener) {
        Write-Log "WinRM HTTP listener is active"
    } else {
        Write-Log "WARNING: WinRM HTTP listener not found"
    }

    # Verify SQL Server connection
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = "Server=localhost;Database=master;User Id=sa;Password=$MssqlPassword;"
        $connection.Open()

        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT @@VERSION"
        $version = $command.ExecuteScalar()

        $connection.Close()
        Write-Log "SQL Server connection verified: $($version.Substring(0, 50))..."
    } catch {
        Write-Log "WARNING: SQL Server connection test failed: $_"
    }

    # ========================================
    # 10. Create completion marker
    # ========================================
    $completionMarker = "C:\WindowsAzure\setup-complete.txt"
    @"
Setup completed successfully at $(Get-Date)

Components installed:
- WinRM HTTP (port 5985)
- SQL Server 2019 Express (port 1433)
- Mixed Mode Authentication enabled
- SA account configured

Test commands:
- Test WinRM: winrm identify -r:http://localhost:5985
- Test SQL: sqlcmd -S localhost -U sa -P '<password>' -Q "SELECT @@VERSION"
"@ | Out-File -FilePath $completionMarker

    Write-Log "Setup completed successfully!"
    Write-Log "Completion marker created at: $completionMarker"

} catch {
    Write-Log "ERROR: Setup failed - $_"
    Write-Log "Stack trace: $($_.ScriptStackTrace)"
    throw
}
