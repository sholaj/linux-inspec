# MSSQL InSpec Ansible Role

Executes InSpec compliance checks against Microsoft SQL Server databases.

## Requirements

- Ansible 2.9+
- InSpec 5.22+ installed on the execution host
- sqlcmd (MSSQL Tools 18) installed on the execution host
- Network connectivity to target MSSQL servers

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
│   ├── setup.yml             # Setup directories and copy controls
│   ├── execute.yml           # Run InSpec controls
│   ├── process_results.yml   # Save results to files
│   ├── cleanup.yml           # Generate reports, cleanup
│   └── splunk_integration.yml # Optional Splunk integration
├── defaults/main.yml         # Default variables
├── vars/main.yml             # Role variables (tool paths)
├── files/
│   ├── MSSQL2016_ruby/       # MSSQL 2016 controls
│   ├── MSSQL2017_ruby/       # MSSQL 2017 controls
│   └── MSSQL2019_ruby/       # MSSQL 2019 controls
├── templates/
│   └── summary_report.j2     # Summary report template
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
