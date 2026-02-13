# WinRM InSpec Prerequisites Guide

This guide covers the prerequisites and setup for running InSpec compliance scans against Windows SQL Server using WinRM transport.

## Architecture Overview

```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│ Linux Runner VM     │     │    Windows VM       │     │   SQL Server        │
│ (Delegate Host)     │     │    (10.0.1.x)       │     │   (localhost:1433)  │
│                     │     │                     │     │                     │
│  ┌───────────────┐  │     │  ┌───────────────┐  │     │  ┌───────────────┐  │
│  │   InSpec      │──┼─────┼─▶│    WinRM      │  │     │  │   Database    │  │
│  │   + train-    │  │5985 │  │   Service     │  │     │  │   Engine      │  │
│  │   winrm       │  │     │  └───────┬───────┘  │     │  └───────────────┘  │
│  └───────────────┘  │     │          │          │     │         ▲           │
│                     │     │  ┌───────▼───────┐  │     │         │           │
│                     │     │  │ mssql_session │──┼─────┼─────────┘           │
│                     │     │  │   (ADO.NET)   │  │1433 │                     │
│                     │     │  └───────────────┘  │     │                     │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
```

**Key Insight**: InSpec runs on the Linux runner (delegate host), connects to Windows via WinRM (port 5985), and the `mssql_session` resource executes on the Windows target using built-in ADO.NET drivers to connect to SQL Server.

## WinRM Username Format

**IMPORTANT:** For Active Directory authentication, the username MUST include domain context. A bare username (e.g., `svc_inspec`) will fail with `WinRM::WinRMAuthorizationError`.

| Format | Example | Notes |
|--------|---------|-------|
| **UPN (recommended)** | `svc_inspec@corp.example.com` | User Principal Name - most reliable |
| **Down-level** | `CORP\\svc_inspec` | Escape backslash in YAML with `\\` |

**Common Error:**
```
WinRM::WinRMAuthorizationError: WinRM authentication failed
```

**Cause:** Username missing domain context (e.g., `p882789` instead of `p882789@domain.com`)

**Solution:** Use UPN format: `username@domain.com`

---

## Inventory Pattern

This implementation uses the **delegate host pattern** within the existing `mssql_databases` inventory group. Windows SQL Server hosts are identified by `use_winrm: true`:

```yaml
mssql_databases:
  hosts:
    # Linux Container MSSQL (direct connection)
    mssql_test_01:
      mssql_server: 10.0.2.4
      use_winrm: false

    # Windows SQL Server (WinRM connection)
    mssql_windows_01:
      mssql_server: localhost
      use_winrm: true
      winrm_host: 10.0.1.5
      winrm_port: 5985
      # NOTE: Username MUST include domain - use UPN format (user@domain) or down-level (DOMAIN\\user)
      winrm_username: azureadmin@corp.example.com
      winrm_password: "{{ lookup('env', 'WINDOWS_ADMIN_PASSWORD') }}"
```

## Prerequisites Summary

| Component | Prerequisite | Why Needed |
|-----------|-------------|------------|
| Linux Runner | `train-winrm` gem | WinRM transport for InSpec |
| Linux Runner | InSpec 5.x | Compliance scanning engine |
| Windows VM | WinRM enabled (5985) | Remote command execution |
| Windows VM | SQL Server Express 2019 | Database target |
| Windows VM | Mixed Mode Auth | SA login for mssql_session |
| SQL Server | TCP/IP enabled on 1433 | Network connectivity |
| Azure NSG | Allow WinRM/SQL ports | Network traffic |

## Deployment Steps

### 1. Deploy Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Set required variables
export TF_VAR_deploy_windows_mssql=true
export TF_VAR_windows_admin_password='ComplexP@ss123!'
export TF_VAR_mssql_password='SqlP@ssw0rd123!'
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/inspec_azure.pub)"

# Review the plan
terraform plan

# Deploy resources
terraform apply

# Note the outputs
terraform output windows_mssql_public_ip   # For RDP
terraform output windows_mssql_private_ip  # For WinRM from runner
```

### 2. Wait for Setup Completion

The Windows VM runs a Custom Script Extension that:
1. Enables WinRM HTTP (port 5985)
2. Configures firewall rules
3. Downloads and installs SQL Server 2019 Express
4. Enables Mixed Mode Authentication
5. Configures TCP/IP on port 1433

This process takes approximately 15-20 minutes. You can monitor progress:

```bash
# RDP to Windows VM and check logs
# Or wait for setup-complete.txt marker
```

### 3. Verify WinRM Connectivity

SSH to the Linux runner and test WinRM:

```bash
# SSH to runner
ssh -i ~/.ssh/inspec_azure azureuser@$(terraform output -raw runner_public_ip)

# Test WinRM connectivity
WINDOWS_IP=$(terraform output -raw windows_mssql_private_ip)
inspec detect -t winrm://azureadmin@$WINDOWS_IP:5985 --ssl=false --password 'ComplexP@ss123!'
```

Expected output:
```
== Platform Details

Name:      windows
Families:  windows
Release:   10.0.20348
Arch:      x86_64
```

### 4. Run InSpec Compliance Scan

```bash
# Set environment variables
export WINDOWS_ADMIN_PASSWORD='ComplexP@ss123!'
export MSSQL_PASSWORD='SqlP@ssw0rd123!'
export WINDOWS_MSSQL_IP='<private_ip_from_terraform>'

# Run the playbook (targets only WinRM-enabled hosts in mssql_databases)
cd /home/azureuser/linux-inspec
ansible-playbook test_playbooks/run_mssql_inspec_winrm.yml -i inventories/hosts.yml

# Or target specific WinRM host
ansible-playbook test_playbooks/run_mssql_inspec_winrm.yml -i inventories/hosts.yml --limit mssql_windows_01

# Or use a remote delegate host
ansible-playbook test_playbooks/run_mssql_inspec_winrm.yml -i inventories/hosts.yml -e "inspec_delegate_host=inspec-runner"

# View results
cat /tmp/compliance_scans/mssql/winrm/*.json | jq '.statistics'
```

## Troubleshooting

### WinRM Connection Refused

**Symptom**: `Connection refused` or `Unable to connect`

**Causes & Solutions**:

1. **WinRM not enabled**
   ```powershell
   # On Windows VM
   winrm quickconfig -force
   winrm set winrm/config/service '@{AllowUnencrypted="true"}'
   winrm set winrm/config/service/auth '@{Basic="true"}'
   ```

2. **Firewall blocking port 5985**
   ```powershell
   New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
   ```

3. **NSG not allowing traffic**
   - Check Azure NSG rules allow port 5985 from the runner subnet

### SQL Server Connection Failed

**Symptom**: `Login failed for user 'sa'` or `Cannot connect`

**Causes & Solutions**:

1. **Mixed Mode Auth not enabled**
   ```powershell
   # Check SQL Server auth mode in registry
   Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQLServer" -Name LoginMode
   # Should be 2 (Mixed Mode)
   ```

2. **TCP/IP not enabled**
   ```powershell
   # Enable via SQL Server Configuration Manager
   # Or via PowerShell with SMO
   $wmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer
   $tcp = $wmi.ServerInstances['MSSQLSERVER'].ServerProtocols['Tcp']
   $tcp.IsEnabled = $true
   $tcp.Alter()
   Restart-Service MSSQLSERVER
   ```

3. **Wrong SA password**
   ```powershell
   # Reset SA password
   sqlcmd -S localhost -Q "ALTER LOGIN sa WITH PASSWORD = 'NewP@ssw0rd123!'"
   ```

### WinRM Authorization Error

**Symptom**: `WinRM::WinRMAuthorizationError` despite confirmed network connectivity and valid credentials

**Cause**: Username missing domain context. The WinRM Negotiate authentication requires domain-qualified usernames.

**Solution**: Use UPN format for the username:
```yaml
# Wrong - missing domain context
winrm_username: p882789

# Correct - UPN format (recommended)
winrm_username: p882789@corp.example.com

# Correct - Down-level format (escape backslash in YAML)
winrm_username: "CORP\\p882789"
```

---

### train-winrm Not Found

**Symptom**: `Could not load 'train-winrm'`

**Solution**:
```bash
# Check if already installed (correct method for both Enterprise and Community InSpec)
inspec plugin list | grep train-winrm

# Install on Linux runner if not found
inspec plugin install train-winrm

# Verify installation
inspec plugin list | grep train-winrm
# Expected output: train-winrm  0.2.13  gem (system)  train-1

# NOTE: Do NOT use 'gem list train-winrm' - Enterprise InSpec bundles
# train-winrm as a system plugin which won't appear in gem list output
```

### InSpec Profile Errors

**Symptom**: `Profile has errors` or `Control failures`

**Debugging**:
```bash
# Check profile syntax
inspec check roles/mssql_inspec/files/inspec_profile/

# Run with debug
inspec exec roles/mssql_inspec/files/inspec_profile/ \
  -t winrm://azureadmin@$WINDOWS_IP:5985 \
  --password 'ComplexP@ss123!' \
  --ssl=false \
  --log-level debug
```

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `WINDOWS_ADMIN_PASSWORD` | Windows VM admin password | `ComplexP@ss123!` |
| `MSSQL_PASSWORD` | SQL Server SA password | `SqlP@ssw0rd123!` |
| `WINDOWS_MSSQL_IP` | Windows VM private IP | `10.0.1.5` |
| `WINDOWS_ADMIN_USERNAME` | Windows admin user | `azureadmin` |

## Cost Considerations

| Resource | Monthly Cost |
|----------|--------------|
| Windows VM (B2s) | ~$42 |
| SQL Server Express | Free |
| Managed Disk (127GB) | ~$5 |
| **With Auto-Shutdown** | **~$30** |

The infrastructure includes auto-shutdown at 23:00 UTC to reduce costs during non-testing hours.

## Cleanup

```bash
# Destroy all resources
cd terraform
terraform destroy

# Or just destroy Windows VM
terraform destroy -target=azurerm_windows_virtual_machine.mssql
```

## Security Notes

1. **WinRM HTTP**: Uses unencrypted HTTP (port 5985) for simplicity. For production, configure HTTPS (port 5986) with certificates.

2. **Basic Auth**: Uses basic authentication with plaintext passwords. Consider using Kerberos or certificate-based auth for production.

3. **SA Account**: Uses SQL Server SA account. For production, create dedicated compliance scanning accounts with minimal required permissions.

4. **NSG Rules**: WinRM and SQL ports are restricted to the VM subnet. Review and tighten for production use.

## Related Documentation

- [InSpec WinRM Transport](https://docs.chef.io/inspec/transport/)
- [SQL Server 2019 Express](https://www.microsoft.com/en-us/sql-server/sql-server-2019)
- [Azure Windows VMs](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/)
- [mssql_session Resource](https://docs.chef.io/inspec/resources/mssql_session/)
