# MSSQL InSpec Ansible Role

Executes InSpec compliance checks against Microsoft SQL Server databases.

## Requirements

- Ansible 2.9+
- InSpec 5.22+ installed on the execution host
- sqlcmd (MSSQL Tools 18) installed on the execution host
- Network connectivity to target MSSQL servers

## Connection Modes

The role supports two connection modes controlled by `use_winrm`:

### Direct Mode (Default)

InSpec connects directly to SQL Server via TDS protocol (port 1433) using sqlcmd.

```yaml
use_winrm: false  # Default - use direct TDS connection
```

**Architecture:**
```
Delegate Host --[TDS 1433]--> SQL Server (Linux/Windows)
```

### WinRM Mode (Windows/AD Authentication)

InSpec connects to the Windows SQL Server via WinRM transport, then uses Windows
Authentication (Trusted Connection) for SQL Server access. This leverages the
[train-winrm](https://github.com/inspec/train-winrm) transport plugin.

```yaml
use_winrm: true
mssql_server: "sqlserver.example.com"  # Target SQL Server
# Username MUST include domain - use UPN format (recommended) or down-level
winrm_username: "svc_inspec@corp.example.com"  # AD service account
winrm_password: "{{ vault_ad_password }}"
```

**Architecture:**
```
┌─────────────┐     WinRM Transport      ┌──────────────────┐
│   Delegate  │ ──────────────────────→  │ Windows SQL      │
│   (Linux)   │   AD User credentials    │ Server           │
└─────────────┘                          └────────┬─────────┘
                                                  │
                                         InSpec runs HERE
                                                  │
                                         mssql_session()
                                         uses Windows Auth
                                         (no SQL credentials)
                                                  │
                                                  ▼
                                         SQL Server Database
```

**Key Points:**
- `mssql_server` is the target SQL Server (no separate `winrm_host`)
- AD credentials authenticate the WinRM transport layer
- SQL Server uses Windows Authentication (the AD user's identity)
- One AD account can scan all SQL Servers it has access to
- The AD user must have SQL Server login permissions via Windows Auth

**How Windows Authentication Works:**

Per [InSpec mssql_session documentation](https://docs.chef.io/inspec/resources/mssql_session/),
omitting the `user` and `password` parameters triggers Windows Authentication:

> "Omitting the username or password parameters results in the use of Windows
> authentication as the user Chef InSpec is executing as."

The InSpec profile automatically detects when credentials are not provided and
omits them from `mssql_session()`, triggering Windows Auth using the WinRM
user's Windows identity.

## Execution Modes

The role supports two execution modes controlled by `inspec_delegate_host`:

### Localhost Mode (Default)

InSpec runs on the inventory target host. Control files are copied from the Ansible controller.

```yaml
inspec_delegate_host: ""        # Empty string
inspec_delegate_host: "localhost"  # Explicit localhost
```

### Delegate Mode

InSpec runs on a remote bastion/jump server that has database connectivity.

```yaml
inspec_delegate_host: "inspec-runner"  # Inventory hostname of delegate
```

**Note:** Use the inventory hostname (not `ansible_host` value) for delegate mode.

## Role Variables

### Required Variables

```yaml
mssql_server: ""        # MSSQL server hostname/IP
mssql_port: 1433        # MSSQL port
mssql_database: "master"  # Target database
mssql_username: ""      # Database username
mssql_password: ""      # Database password (use vault/AAP credential)
mssql_version: "2019"   # MSSQL version (2016, 2017, 2018, 2019, 2022)
```

### Optional Variables

```yaml
mssql_service: ""                        # Named instance (if applicable)
inspec_delegate_host: ""                 # Execution host (empty = target host)
inspec_results_dir: "/tmp/inspec_mssql_results"  # Results directory
inspec_debug_mode: false                 # Enable debug output
generate_summary_report: true            # Generate summary report
cleanup_temp_files: true                 # Clean up temp control files
send_to_splunk: false                    # Send results to Splunk
splunk_hec_url: ""                       # Splunk HEC endpoint
splunk_hec_token: ""                     # Splunk HEC token
```

### WinRM Variables (Windows/AD Authentication)

```yaml
use_winrm: false                         # Enable WinRM/AD authentication mode
winrm_username: ""                       # AD username - MUST include domain
winrm_password: ""                       # AD password
```

**Important:** Username MUST include domain context for AD authentication:
- UPN format (recommended): `svc_inspec@corp.example.com`
- Down-level format: `CORP\\svc_inspec`

A bare username (e.g., `svc_inspec`) will fail with `WinRM::WinRMAuthorizationError`.

**Note:** When `use_winrm: true`, InSpec connects directly to `mssql_server` using WinRM (port 5985) with AD credentials. No separate `winrm_host` is needed.

**Command Format:**
```bash
inspec exec <profile> -t winrm://<server> --user '<user@domain.com>' --password '<password>'
```

### Batch Processing Variables

```yaml
batch_size: 0                            # Hosts per batch (0 = no batching)
batch_delay: 5                           # Seconds between batches
scan_timeout: 300                        # Per-host timeout (seconds)
continue_on_winrm_failure: true          # Continue if WinRM fails
max_retry_attempts: 2                    # Retry failed connections
retry_delay: 10                          # Seconds between retries
```

## Supported MSSQL Versions

- MSSQL 2016 (CIS Benchmark v1.3.0)
- MSSQL 2017 (CIS Benchmark v1.3.0)
- MSSQL 2018 (CIS Benchmark v1.3.0)
- MSSQL 2019 (CIS Benchmark v1.3.0)
- MSSQL 2022 (CIS Benchmark v1.0.0) - includes Ledger, Query Store, Contained AG controls

## Directory Structure

```
mssql_inspec/
├── tasks/
│   ├── main.yml              # Entry point - determines execution mode
│   ├── validate.yml          # Parameter validation
│   ├── preflight.yml         # Connection mode routing
│   ├── preflight_direct.yml  # Direct (sqlcmd) connectivity check
│   ├── preflight_winrm.yml   # WinRM connectivity check
│   ├── setup.yml             # Setup directories and copy controls
│   ├── execute.yml           # Execution mode routing
│   ├── execute_direct.yml    # Direct InSpec execution
│   ├── execute_winrm.yml     # WinRM-based InSpec execution
│   ├── process_results.yml   # Save results to files
│   ├── cleanup.yml           # Generate reports, cleanup
│   ├── error_handling.yml    # Error aggregation for batch scans
│   └── splunk_integration.yml # Optional Splunk integration
├── defaults/main.yml         # Default variables (includes WinRM)
├── vars/main.yml             # Role variables (tool paths)
├── files/
│   ├── MSSQL2016_ruby/       # MSSQL 2016 controls
│   ├── MSSQL2017_ruby/       # MSSQL 2017 controls
│   ├── MSSQL2018_ruby/       # MSSQL 2018 controls
│   ├── MSSQL2019_ruby/       # MSSQL 2019 controls
│   └── MSSQL2022_ruby/       # MSSQL 2022 controls
├── templates/
│   ├── summary_report.j2     # Summary report template
│   ├── skip_report.j2        # Skip report template
│   └── error_summary.j2      # Batch error summary template
└── README.md
```

## Usage

### Basic Playbook (Localhost Mode)

```yaml
---
- name: Run MSSQL Compliance Scan
  hosts: runner
  gather_facts: true

  vars:
    mssql_server: "sqlserver.example.com"
    mssql_port: 1433
    mssql_database: "master"
    mssql_username: "scan_user"
    mssql_password: "{{ vault_mssql_password }}"
    mssql_version: "2019"
    inspec_delegate_host: ""

  roles:
    - mssql_inspec
```

### Delegate Mode Playbook

```yaml
---
- name: Run MSSQL Compliance Scan via Delegate
  hosts: mssql_databases
  gather_facts: true

  vars:
    inspec_delegate_host: "inspec-runner"

  roles:
    - mssql_inspec
```

### Inventory Example (Delegate Mode)

```yaml
all:
  hosts:
    inspec-runner:
      ansible_host: jumphost.example.com
      ansible_connection: ssh
      ansible_user: ansible_svc

  children:
    mssql_databases:
      hosts:
        SQLPROD01_1433:
          mssql_server: sqlprod01.example.com
          mssql_port: 1433
          mssql_version: "2019"
      vars:
        inspec_delegate_host: "inspec-runner"
        mssql_username: scan_user
```

### WinRM Mode Playbook

```yaml
---
- name: Run MSSQL Compliance Scan via WinRM
  hosts: mssql_windows_databases
  gather_facts: true

  vars:
    use_winrm: true
    inspec_delegate_host: "inspec-runner"

  roles:
    - mssql_inspec
```

### WinRM/AD Authentication Inventory Example

```yaml
all:
  hosts:
    inspec-runner:
      ansible_host: linux-runner.example.com
      ansible_connection: ssh

  children:
    mssql_windows_databases:
      hosts:
        # Each host is a SQL Server to scan
        SQLPROD01:
          mssql_server: sqlprod01.example.com
          mssql_port: 1433
          mssql_database: master
          mssql_version: "2019"
        SQLPROD02:
          mssql_server: sqlprod02.example.com
          mssql_port: 1433
          mssql_database: master
          mssql_version: "2019"
      vars:
        # WinRM/AD settings apply to all SQL Servers
        use_winrm: true
        # Username MUST include domain (UPN format recommended)
        winrm_username: "svc_inspec@corp.example.com"
        winrm_password: "{{ vault_ad_password }}"
        inspec_delegate_host: "inspec-runner"
```

**Note:** With AD authentication, the same `winrm_username`/`winrm_password` can scan multiple SQL Servers.

## Output

Results are saved as JSON files in `inspec_results_dir`:

- Individual control results: `MSSQL_<server>_<database>_<version>_<timestamp>_<control>.json`
- Summary report: `summary_<timestamp>.txt`

### Result Structure

```json
{
  "controls": [{
    "id": "2.01",
    "status": "passed",
    "code_desc": "Ad Hoc Distributed Queries disabled"
  }],
  "statistics": {
    "duration": 0.123
  },
  "version": "5.22.29"
}
```

## Error Handling

The role handles:
- Missing InSpec or sqlcmd binaries
- Database connection failures
- Invalid credentials
- Unsupported MSSQL versions
- InSpec exit codes (0=passed, 100=failed, 101=skipped)

## Troubleshooting

### InSpec Not Found

```bash
# Check InSpec installation
inspec version

# Install via gem
gem install inspec-bin -v 5.22.29
```

### Database Connection Failed

```bash
# Test connectivity
sqlcmd -S server,port -U user -P password -Q "SELECT @@VERSION"
```

### WinRM Authorization Error

**Symptom:** `WinRM::WinRMAuthorizationError` despite valid credentials

**Cause:** Username missing domain context

**Solution:** Use UPN format for username:
```bash
# Wrong
--user 'svc_inspec'

# Correct
--user 'svc_inspec@corp.example.com'
```

### WinRM Connection Failed

```bash
# Test WinRM connectivity from delegate host
inspec detect -t winrm://sqlserver --user 'user@domain.com' --password 'pass'

# Common issues:
# - Firewall blocking port 5985/5986
# - WinRM service not running on target
# - AD user not in Remote Management Users group
# - Username missing domain (causes WinRMAuthorizationError)
```

**WinRM Server Configuration (on Windows SQL Server):**
```powershell
# Enable WinRM
Enable-PSRemoting -Force

# Allow connections from any host (or specific IPs)
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

# Verify WinRM is listening
winrm enumerate winrm/config/listener
```

### SQL Server Windows Auth Failed

When using WinRM mode, ensure the AD user has SQL Server access:

```sql
-- On SQL Server, verify the AD user has a login
SELECT name, type_desc FROM sys.server_principals
WHERE name LIKE '%svc_inspec%';

-- Grant access if needed
CREATE LOGIN [DOMAIN\svc_inspec] FROM WINDOWS;
ALTER SERVER ROLE [sysadmin] ADD MEMBER [DOMAIN\svc_inspec];
```

### Debug Mode

Enable verbose output:

```yaml
inspec_debug_mode: true
```

## License

Internal use only

## Author

DevOps Team
