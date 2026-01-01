# Oracle InSpec Ansible Role

Executes InSpec compliance checks against Oracle databases.

## Requirements

- Ansible 2.9+
- InSpec 5.22+ installed on the execution host
- Oracle Instant Client (sqlplus) installed on the execution host
- Network connectivity to target Oracle servers

## Execution Modes

The role supports two execution modes controlled by `inspec_delegate_host`:

### Localhost Mode (Default)

InSpec runs on the inventory target host. Control files are copied from the Ansible controller.

```yaml
inspec_delegate_host: ""           # Empty string
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
oracle_server: ""           # Oracle server hostname/IP
oracle_port: 1521           # Oracle listener port
oracle_database: ""         # Database name (SID or service name)
oracle_service: ""          # Oracle service name (for connection string)
oracle_username: "nist_scan_user"  # Database username
oracle_password: ""         # Database password (use vault/AAP credential)
oracle_version: "19c"       # Oracle version (11g, 12c, 18c, 19c)
```

### Optional Variables

```yaml
oracle_use_tns: false                    # Use TNS names for connection
oracle_tns_admin: ""                     # TNS_ADMIN directory path
oracle_service_type: "service_name"      # Connection type: "service_name" or "sid"
inspec_delegate_host: "localhost"        # Execution host (empty = target host)
base_results_dir: "/tmp/compliance_scans"  # Results directory
inspec_debug_mode: false                 # Enable debug output
generate_summary_report: true            # Generate summary report
create_error_reports: true               # Create error reports on failure
continue_on_errors: true                 # Continue processing on errors
send_to_splunk: false                    # Send results to Splunk
splunk_hec_url: ""                       # Splunk HEC endpoint
splunk_hec_token: ""                     # Splunk HEC token
splunk_index: "compliance_scans"         # Splunk index name
```

### Environment Variables (vars/main.yml)

These are internal variables used by the role:

```yaml
oracle_environment_base:
  PATH: "/usr/local/oracle/NIST_FILES/mssql-tools/bin:/tools/ver/sybase/OCS-16_0/bin"
  LD_LIBRARY_PATH: "/tools/ver/oracle-19.16.0.0-64"
  ORACLE_HOME: "/tools/ver/oracle-19.16.0.0-64"
  TNS_ADMIN: "{{ oracle_tns_admin | default('/tools/ver/oracle-19.16.0.0-64/network/admin') }}"
  NLS_LANG: "AMERICAN_AMERICA.AL32UTF8"
```

Override these in your inventory or playbook if Oracle is installed in a different location.

## Supported Oracle Versions

- Oracle 11g
- Oracle 12c
- Oracle 18c
- Oracle 19c

## Directory Structure

```
oracle_inspec/
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
│   ├── ORACLE11g_ruby/       # Oracle 11g controls
│   ├── ORACLE12c_ruby/       # Oracle 12c controls
│   ├── ORACLE18c_ruby/       # Oracle 18c controls
│   └── ORACLE19c_ruby/       # Oracle 19c controls
├── templates/
│   └── oracle_summary_report.j2  # Summary report template
└── README.md
```

## Usage

### Basic Playbook (Localhost Mode)

```yaml
---
- name: Run Oracle Compliance Scan
  hosts: runner
  gather_facts: true

  vars:
    oracle_server: "oracledb.example.com"
    oracle_port: 1521
    oracle_database: "ORCL"
    oracle_service: "ORCL.example.com"
    oracle_username: "scan_user"
    oracle_password: "{{ vault_oracle_password }}"
    oracle_version: "19c"
    inspec_delegate_host: ""

  roles:
    - oracle_inspec
```

### TNS Connection Playbook

```yaml
---
- name: Run Oracle Compliance Scan (TNS)
  hosts: runner
  gather_facts: true

  vars:
    oracle_server: "oracledb.example.com"
    oracle_database: "ORCL"
    oracle_username: "scan_user"
    oracle_password: "{{ vault_oracle_password }}"
    oracle_version: "19c"
    oracle_use_tns: true
    oracle_tns_admin: "/opt/oracle/network/admin"

  roles:
    - oracle_inspec
```

### Delegate Mode Playbook

```yaml
---
- name: Run Oracle Compliance Scan via Delegate
  hosts: oracle_databases
  gather_facts: true

  vars:
    inspec_delegate_host: "inspec-runner"

  roles:
    - oracle_inspec
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
    oracle_databases:
      hosts:
        ORAPROD01_1521:
          oracle_server: oraprod01.example.com
          oracle_port: 1521
          oracle_service: "ORCLPRD"
          oracle_database: "ORCLPRD"
          oracle_version: "19c"
        ORAPROD02_1521:
          oracle_server: oraprod02.example.com
          oracle_port: 1521
          oracle_service: "ORCLPRD2"
          oracle_database: "ORCLPRD2"
          oracle_version: "12c"
      vars:
        inspec_delegate_host: "inspec-runner"
        oracle_username: nist_scan_user
```

## Connection String Formats

The role supports multiple Oracle connection formats:

### Service Name (Default)

```bash
sqlplus user/password@//host:port/service_name
```

### SID

```yaml
oracle_service_type: "sid"
```

```bash
sqlplus user/password@//host:port/SID
```

### TNS Names

```yaml
oracle_use_tns: true
oracle_tns_admin: "/path/to/tns"
```

```bash
sqlplus user/password@TNS_ALIAS
```

## Output

Results are saved as JSON files in `base_results_dir`:

- Individual control results: `ORACLE_NIST_<pid>_<server>_<database>_<version>_<timestamp>_<control>.json`
- Summary report: `oracle_summary_<timestamp>.txt`

### Result Structure

```json
{
  "controls": [{
    "id": "2.01",
    "status": "passed",
    "code_desc": "Verify audit trail is enabled"
  }],
  "statistics": {
    "duration": 0.456
  },
  "version": "5.22.29"
}
```

## Environment Setup

The role expects Oracle Instant Client to be installed. Verify the following:

```bash
# Check Oracle environment
echo $ORACLE_HOME
echo $LD_LIBRARY_PATH
echo $TNS_ADMIN

# Test sqlplus
sqlplus -V

# Test connectivity
echo "SELECT * FROM V\$VERSION;" | sqlplus -s user/password@//host:1521/service
```

## Error Handling

The role handles:
- Missing InSpec or sqlplus binaries
- Oracle client not configured
- Database connection failures
- Invalid credentials
- TNS resolution failures
- Unsupported Oracle versions
- InSpec exit codes (0=passed, 100=failed, 101=skipped)

## Troubleshooting

### Oracle Client Not Found

```bash
# Check Oracle Instant Client installation
ls -la /opt/oracle/instantclient_*

# Set environment
export ORACLE_HOME=/opt/oracle/instantclient_19_16
export LD_LIBRARY_PATH=$ORACLE_HOME:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME:$PATH
```

### TNS Resolution Failed

```bash
# Verify TNS_ADMIN
echo $TNS_ADMIN
cat $TNS_ADMIN/tnsnames.ora

# Test TNS connection
tnsping ALIAS_NAME
```

### Database Connection Failed

```bash
# Test connectivity
sqlplus user/password@//server:1521/service

# Check listener
lsnrctl status
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
