# Sybase InSpec Ansible Role

Executes InSpec compliance checks against SAP ASE (Sybase) databases.

## Requirements

- Ansible 2.9+
- InSpec 5.22+ installed on the execution host
- Sybase client (isql from SAP ASE SDK or tsql from FreeTDS) installed on the execution host
- SSH access to Sybase server (for SSH transport mode)
- Network connectivity to target Sybase servers

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
sybase_server: ""               # Sybase server hostname/IP
sybase_port: 5000               # Sybase port
sybase_database: ""             # Target database name
sybase_service: ""              # Sybase server/service name (for interfaces file)
sybase_username: "nist_scan_user"  # Database username
sybase_password: ""             # Database password (use vault/AAP credential)
sybase_version: "16"            # Sybase version (15, 16)
```

### SSH Connection Variables (for SSH transport)

```yaml
sybase_use_ssh: true                    # Enable SSH transport (recommended)
sybase_ssh_user: "oracle"               # SSH username for Sybase server
sybase_ssh_password: ""                 # SSH password (use vault/AAP credential)
sybase_ssh_port: 22                     # SSH port
sybase_ssh_key_path: "/tmp/sybase_ssh_key"  # Path to SSH private key
```

### Optional Variables

```yaml
sybase_service_name: "SAP_ASE"           # Sybase service name
sybase_charset: "iso_1"                  # Character set
sybase_isql_bin: ""                      # isql binary path (auto-detected if empty)
sybase_home: ""                          # SYBASE home directory (uses env if empty)
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
sybase_environment_base:
  PATH: "/opt/sap/OCS-16_0/bin"
  LD_LIBRARY_PATH: "/opt/sap/OCS-16_0/lib"
  SYBASE: "/opt/sap"
  SYBASE_OCS: "OCS-16_0"
```

Override these in your inventory or playbook if Sybase SDK is installed in a different location.

## Supported Sybase Versions

- Sybase ASE 15.x
- Sybase ASE 16.x (SAP ASE)

## Directory Structure

```
sybase_inspec/
├── tasks/
│   ├── main.yml              # Entry point - determines execution mode
│   ├── validate.yml          # Parameter validation
│   ├── setup.yml             # Setup directories, interfaces file, SYBASE.sh
│   ├── execute.yml           # Run InSpec controls via SSH
│   ├── process_results.yml   # Save results to files
│   ├── cleanup.yml           # Generate reports, cleanup temp files
│   └── splunk_integration.yml # Optional Splunk integration
├── defaults/main.yml         # Default variables
├── vars/main.yml             # Role variables (tool paths, SSH settings)
├── files/
│   ├── SYBASE15_ruby/        # Sybase 15 controls
│   └── SYBASE16_ruby/        # Sybase 16 controls
│       └── libraries/
│           └── sybase_session_local.rb  # Custom InSpec resource
├── templates/
│   ├── interfaces.j2         # Sybase interfaces file template
│   ├── SYBASE.sh.j2          # Environment script template
│   └── sybase_summary_report.j2  # Summary report template
└── README.md
```

## Usage

### Basic Playbook (SSH Mode - Recommended)

```yaml
---
- name: Run Sybase Compliance Scan
  hosts: runner
  gather_facts: true

  vars:
    sybase_server: "sybase.example.com"
    sybase_port: 5000
    sybase_database: "master"
    sybase_service: "SYBASESVR"
    sybase_username: "scan_user"
    sybase_password: "{{ vault_sybase_password }}"
    sybase_version: "16"
    sybase_use_ssh: true
    sybase_ssh_user: "oracle"
    sybase_ssh_password: "{{ vault_ssh_password }}"
    inspec_delegate_host: ""

  roles:
    - sybase_inspec
```

### Direct Mode Playbook (No SSH)

```yaml
---
- name: Run Sybase Compliance Scan (Direct)
  hosts: runner
  gather_facts: true

  vars:
    sybase_server: "sybase.example.com"
    sybase_port: 5000
    sybase_database: "master"
    sybase_service: "SYBASESVR"
    sybase_username: "scan_user"
    sybase_password: "{{ vault_sybase_password }}"
    sybase_version: "16"
    sybase_use_ssh: false

  roles:
    - sybase_inspec
```

### Delegate Mode Playbook

```yaml
---
- name: Run Sybase Compliance Scan via Delegate
  hosts: sybase_databases
  gather_facts: true

  vars:
    inspec_delegate_host: "inspec-runner"

  roles:
    - sybase_inspec
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
    sybase_databases:
      hosts:
        SYBPROD01_5000:
          sybase_server: sybprod01.example.com
          sybase_port: 5000
          sybase_service: "SYBPROD01"
          sybase_database: "master"
          sybase_version: "16"
        SYBPROD02_5000:
          sybase_server: sybprod02.example.com
          sybase_port: 5000
          sybase_service: "SYBPROD02"
          sybase_database: "production"
          sybase_version: "16"
      vars:
        inspec_delegate_host: "inspec-runner"
        sybase_username: nist_scan_user
        sybase_use_ssh: true
        sybase_ssh_user: oracle
```

## Sybase Client Options

The role supports two Sybase clients:

### SAP ASE isql (Preferred)

The native SAP client provides full compatibility:

```bash
# Location (SAP ASE SDK)
/opt/sap/OCS-16_0/bin/isql

# Environment
export SYBASE=/opt/sap
export SYBASE_OCS=OCS-16_0
export PATH=$SYBASE/$SYBASE_OCS/bin:$PATH
export LD_LIBRARY_PATH=$SYBASE/$SYBASE_OCS/lib:$LD_LIBRARY_PATH
```

### FreeTDS tsql (Alternative)

Open-source alternative when SAP client is unavailable:

```bash
# Install
dnf install -y freetds

# Test
tsql -H sybase.host -p 5000 -U user -P password
```

The role's custom `sybase_session_local` InSpec resource auto-detects the available client and uses:
1. SAP isql (if available in SYBASE path)
2. FreeTDS tsql (fallback)

## Output

Results are saved as JSON files in `base_results_dir`:

- Individual control results: `SYBASE_NIST_<pid>_<server>_<database>_<version>_<timestamp>_<control>.json`
- Summary report: `sybase_summary_<timestamp>.txt`

### Result Structure

```json
{
  "controls": [{
    "id": "2.01",
    "status": "passed",
    "code_desc": "Verify audit trail is enabled"
  }],
  "statistics": {
    "duration": 0.234
  },
  "version": "5.22.29"
}
```

## Interfaces File

The role automatically generates a Sybase interfaces file for server connectivity:

```
# /opt/sap/interfaces (generated)
SYBASESVR
    master tcp ether sybase.example.com 5000
    query tcp ether sybase.example.com 5000
```

## Environment Setup

Verify Sybase client installation:

```bash
# Check Sybase environment
echo $SYBASE
echo $SYBASE_OCS
source $SYBASE/SYBASE.sh

# Test isql (SAP client)
isql -S SERVERNAME -U username -P password -D database

# Test tsql (FreeTDS)
tsql -H hostname -p 5000 -U username -P password
```

## Error Handling

The role handles:
- Missing InSpec or Sybase client binaries
- Sybase client not configured
- SSH connection failures (when using SSH transport)
- Database connection failures
- Invalid credentials
- Unsupported Sybase versions
- InSpec exit codes (0=passed, 100=failed, 101=skipped)

## Troubleshooting

### Sybase Client Not Found

```bash
# Check SAP ASE client installation
ls -la /opt/sap/OCS-16_0/bin/isql

# Or install FreeTDS
dnf install -y freetds
which tsql
```

### SSH Connection Failed

```bash
# Test SSH connectivity
ssh -o StrictHostKeyChecking=no user@sybase.host

# Check SSH key permissions
chmod 600 /path/to/key
```

### Database Connection Failed (isql)

```bash
# Source environment
source /opt/sap/SYBASE.sh

# Test isql connection
isql -S SERVERNAME -U user -P password -D database
```

### Database Connection Failed (tsql)

```bash
# Test tsql connection
echo "SELECT @@version\ngo" | tsql -H hostname -p 5000 -U user -P password
```

### Interfaces File Issues

```bash
# Check interfaces file
cat $SYBASE/interfaces

# Verify server entry exists
grep SERVERNAME $SYBASE/interfaces
```

### Debug Mode

Enable verbose output:

```yaml
inspec_debug_mode: true
```

## Custom InSpec Resource

The role includes a custom `sybase_session_local` InSpec resource that:

- Auto-detects SAP isql or FreeTDS tsql
- Handles local and remote execution properly
- Parses both isql and tsql output formats
- Manages temporary SQL files correctly

Located at: `files/SYBASE16_ruby/libraries/sybase_session_local.rb`

## License

Internal use only

## Author

DevOps Team
