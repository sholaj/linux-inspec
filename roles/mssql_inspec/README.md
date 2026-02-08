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

InSpec connects directly to SQL Server via WinRM using Windows/AD authentication.
A single AD account can scan multiple SQL Servers in the domain.

```yaml
use_winrm: true
mssql_server: "sqlserver.example.com"  # Target SQL Server
winrm_port: 5985
winrm_username: "DOMAIN\\svc_inspec"   # AD service account
winrm_password: "{{ vault_ad_password }}"
```

**Architecture:**
```
Delegate Host --[WinRM + AD Auth]--> SQL Server (Windows)
```

**Key Points:**
- `mssql_server` is the target SQL Server (no separate `winrm_host`)
- AD credentials authenticate both WinRM transport and SQL Server access
- One AD account can scan all SQL Servers it has access to

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
mssql_version: "2019"   # MSSQL version (2016, 2017, 2019)
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
winrm_port: 5985                         # WinRM HTTP port (5986 for HTTPS)
winrm_username: ""                       # AD username (DOMAIN\user or user@domain)
winrm_password: ""                       # AD password
winrm_ssl: false                         # Use HTTPS (port 5986)
winrm_ssl_verify: true                   # Verify SSL certificate
winrm_timeout: 60                        # Connection timeout (seconds)
```

**Note:** When `use_winrm: true`, InSpec connects directly to `mssql_server` using WinRM with AD credentials. No separate `winrm_host` is needed.

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

- MSSQL 2016
- MSSQL 2017
- MSSQL 2019

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
│   └── MSSQL2019_ruby/       # MSSQL 2019 controls
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
        winrm_username: "CORP\\svc_inspec"  # AD service account
        winrm_password: "{{ vault_ad_password }}"
        winrm_port: 5985
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

### Debug Mode

Enable verbose output:

```yaml
inspec_debug_mode: true
```

## License

Internal use only

## Author

DevOps Team
