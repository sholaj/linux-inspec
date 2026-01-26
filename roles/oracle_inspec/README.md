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
# TNS Configuration (enables auto-generated tnsnames.ora)
oracle_use_tns: false                    # Use TNS names for connection
oracle_tns_alias: ""                     # TNS alias name (defaults to oracle_service)
oracle_tns_admin: ""                     # TNS_ADMIN directory path (auto-creates if empty)
oracle_service_type: "service_name"      # Connection type: "service_name" or "sid"

# Execution Settings
inspec_delegate_host: "localhost"        # Execution host (empty = target host)
base_results_dir: "/tmp/compliance_scans"  # Results directory
inspec_debug_mode: false                 # Enable debug output
generate_summary_report: true            # Generate summary report
create_error_reports: true               # Create error reports on failure
continue_on_errors: true                 # Continue processing on errors

# Splunk Integration
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
│   ├── oracle_summary_report.j2  # Summary report template
│   ├── skip_report.j2            # Skip report template
│   └── tnsnames.ora.j2           # TNS names configuration template
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

When `oracle_use_tns: true` is set, the role automatically generates a `tnsnames.ora` file from the `tnsnames.ora.j2` template and sets the `TNS_ADMIN` environment variable.

```yaml
---
- name: Run Oracle Compliance Scan (TNS Mode)
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
    # TNS Configuration
    oracle_use_tns: true
    oracle_tns_alias: "ORCLPROD"  # Optional: defaults to oracle_service
    oracle_tns_admin: ""          # Optional: auto-creates in temp dir if empty

  roles:
    - oracle_inspec
```

### TNS Mode with Multiple Databases

```yaml
---
- name: Run Oracle Compliance Scan (Multiple DBs via TNS)
  hosts: runner
  gather_facts: true

  vars:
    oracle_use_tns: true
    oracle_databases:
      - name: "PROD1"
        host: "oracle-prod1.example.com"
        port: 1521
        service: "PROD1SVC"
        tns_alias: "PROD1"
      - name: "PROD2"
        host: "oracle-prod2.example.com"
        port: 1521
        service: "PROD2SVC"
        tns_alias: "PROD2"

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

## Understanding tnsnames.ora (For Junior Engineers)

### What is tnsnames.ora?

`tnsnames.ora` is Oracle's **network configuration file** that maps human-readable database aliases to full connection details. Think of it like a `/etc/hosts` file but for Oracle databases.

**Location:** `$TNS_ADMIN/tnsnames.ora` (typically `$ORACLE_HOME/network/admin/tnsnames.ora`)

### File Structure

```
# $TNS_ADMIN/tnsnames.ora
# Each entry is an alias that maps to connection details

ORCLCDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 10.0.2.6)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCLCDB)
    )
  )

# Multiple databases in the same file
PROD_DB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = prod-oracle.example.com)(PORT = 1521))
    (CONNECT_DATA =
      (SERVICE_NAME = PRODDB)
    )
  )

# RAC cluster with failover
CLUSTER_DB =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = node1.example.com)(PORT = 1521))
      (ADDRESS = (PROTOCOL = TCP)(HOST = node2.example.com)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = CLUSTERDB)
    )
  )
```

### Key Components Explained

| Component | Description | Example |
|-----------|-------------|---------|
| `ALIAS` | Name you use to connect | `ORCLCDB`, `PROD_DB` |
| `DESCRIPTION` | Container for connection details | - |
| `ADDRESS` | Protocol, host, and port | `(HOST = 10.0.2.6)(PORT = 1521)` |
| `CONNECT_DATA` | Database identifier | - |
| `SERVICE_NAME` | Modern way to identify database | `ORCLCDB` |
| `SID` | Legacy system identifier | `ORCL` (older databases) |

### Do You Need One for Every Database?

**No!** One file can contain **multiple database entries**. You have two options:

#### Option 1: tnsnames.ora (Traditional Method)

- Single file contains all database connection definitions
- Required for: RAC clusters, complex configurations, corporate environments
- Requires TNS_ADMIN environment variable to be set

```bash
# Set TNS_ADMIN
export TNS_ADMIN=/opt/oracle/network/admin

# Connect using alias
sqlplus system/OraclePass123@ORCLCDB
```

#### Option 2: Easy Connect (Recommended for Simple Cases)

- **No tnsnames.ora file needed**
- Connection details embedded in connection string
- Format: `//host:port/service_name`

```bash
# No tnsnames.ora required
sqlplus system/OraclePass123@//10.0.2.6:1521/ORCLCDB
```

### Which Method Does This Project Use?

**This project uses Easy Connect format** by default to avoid managing tnsnames.ora files:

```ruby
# InSpec connects using Easy Connect format
sql = oracledb_session(
  user: 'system',
  password: 'OraclePass123',
  host: '10.0.2.6',
  port: 1521,
  service: 'ORCLCDB'
)
# Translates to: sqlplus system/OraclePass123@//10.0.2.6:1521/ORCLCDB
```

### When to Use tnsnames.ora

| Scenario | Use tnsnames.ora? | Reason |
|----------|-------------------|--------|
| Simple single database | No | Easy Connect is simpler |
| Multiple databases | Optional | Easy Connect still works |
| RAC cluster with failover | **Yes** | Need ADDRESS_LIST for multiple nodes |
| Corporate environment | **Yes** | Central configuration management |
| Load balancing | **Yes** | Need LOAD_BALANCE parameter |
| SSL/TLS connections | **Yes** | Need SECURITY parameters |

### Auto-Generated tnsnames.ora (This Role)

When `oracle_use_tns: true` is set, this role **automatically generates** a `tnsnames.ora` file using the Jinja2 template at `templates/tnsnames.ora.j2`. This means:

1. **No manual file creation needed** - The role creates it for you
2. **Dynamic configuration** - Generated from your Ansible variables
3. **Temporary by default** - Created in a temp directory unless `oracle_tns_admin` is specified
4. **Cleaned up automatically** - Removed after the scan completes

**Generated tnsnames.ora example:**

```
# Auto-generated by Ansible oracle_inspec role
# Generated: 2026-01-26T10:00:00Z

ORCLCDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 10.0.2.6)(PORT = 1521))
    (CONNECT_DATA =
      (SERVICE_NAME = ORCLCDB)
    )
  )
```

**To use a pre-existing tnsnames.ora instead:**

```yaml
oracle_use_tns: true
oracle_tns_admin: "/opt/oracle/network/admin"  # Points to existing file
```

### Creating a tnsnames.ora File

If you need TNS-based connections:

```bash
# 1. Create the directory
sudo mkdir -p /opt/oracle/network/admin

# 2. Create tnsnames.ora
cat > /opt/oracle/network/admin/tnsnames.ora << 'EOF'
ORCLCDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 10.0.2.6)(PORT = 1521))
    (CONNECT_DATA =
      (SERVICE_NAME = ORCLCDB)
    )
  )
EOF

# 3. Set environment variable
export TNS_ADMIN=/opt/oracle/network/admin

# 4. Test the connection
sqlplus system/OraclePass123@ORCLCDB
```

### Troubleshooting TNS Issues

```bash
# Check TNS_ADMIN is set
echo $TNS_ADMIN

# Verify tnsnames.ora exists
cat $TNS_ADMIN/tnsnames.ora

# Test TNS resolution (if tnsping available)
tnsping ORCLCDB

# Common errors:
# ORA-12154: TNS:could not resolve the connect identifier
#   → Check spelling of alias, verify tnsnames.ora exists
# ORA-12541: TNS:no listener
#   → Oracle listener not running on target server
# ORA-12170: TNS:Connect timeout
#   → Network/firewall blocking port 1521
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
