# Sybase InSpec Ansible Role

Executes InSpec compliance checks against SAP ASE (Sybase) databases.

## Requirements

- Ansible 2.9+
- InSpec 5.22+ installed on the execution host
- Sybase client (isql from SAP ASE SDK or tsql from FreeTDS) installed on the execution host
- Network connectivity to target Sybase servers
- SSH key access to Sybase server (only if using legacy SSH transport mode)

## Connection Modes: Direct vs SSH

The role supports two database connection modes. **Direct mode is recommended.**

### Direct Mode (Default, Recommended)

```
AAP2 → SSH → Delegate Host → isql (network) → Sybase Database
              (Ansible)        (port 5000)
```

InSpec runs on the delegate host and `isql` connects to the database over the network. This is the same pattern used by the MSSQL and Oracle roles.

```yaml
sybase_use_ssh: false  # Default
```

### SSH Mode (Legacy)

```
AAP2 → SSH → Delegate Host → SSH → Sybase Server → isql → Database
              (Ansible)       (InSpec transport)     (local)
```

InSpec SSHs into the Sybase server itself and runs `isql` locally on the database host. This was the pattern used by the original `NISTv2.ksh` script.

```yaml
sybase_use_ssh: true
sybase_ssh_user: "oracle"
sybase_ssh_key_path: "~oracle/.ssh/id_rsa"
```

### Why Direct Mode is Better

| Factor | Direct Mode | SSH Mode |
|--------|-------------|----------|
| **Dependencies on DB server** | Network port only | SSH access + oracle user + isql |
| **SSH key management** | Not needed | Required on every DB server |
| **Consistency** | Same as MSSQL/Oracle roles | Unique pattern |
| **Onboarding complexity** | Firewall rule + DB credentials | SSH access per server |
| **Points of failure** | 2 layers | 3 layers |
| **Privilege escalation** | Not needed | oracle user access required |

Direct mode is simpler, has fewer moving parts, and aligns with how the other database roles work. SSH mode is retained for backward compatibility with environments that already have the SSH/oracle user pattern configured.

## Execution Modes

Orthogonal to the connection mode above, the role supports two execution modes controlled by `inspec_delegate_host`:

### Localhost Mode

InSpec runs on the inventory target host. Control files are copied from the Ansible controller.

```yaml
inspec_delegate_host: ""           # Empty string
inspec_delegate_host: "localhost"  # Explicit localhost
```

### Delegate Mode (Recommended for production)

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

### SSH Connection Variables (legacy mode only)

Only required when `sybase_use_ssh: true`. Not needed for direct mode (default).

```yaml
sybase_use_ssh: false                   # Direct mode (default, recommended)
sybase_ssh_user: "oracle"               # SSH username for Sybase server (SSH mode only)
sybase_ssh_port: 22                     # SSH port (SSH mode only)
sybase_ssh_key_path: "~oracle/.ssh/id_rsa"  # Path to SSH private key (SSH mode only)
```

### Optional Variables

```yaml
sybase_service_name: "SAP_ASE"           # Sybase service name
sybase_charset: "iso_1"                  # Character set
sybase_isql_bin: ""                      # isql binary path (auto-detected if empty)
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

### Client Tool Paths (EE vs Delegate Host)

The role maintains **two sets of Sybase client paths** and auto-selects based on execution mode.
The resolved paths are used to build `sybase_environment_base` at runtime.

| Variable | Default | Used When |
|----------|---------|-----------|
| `sybase_home_ee` | `/opt/sybase` | Localhost mode (AAP2 Execution Environment) |
| `sybase_ocs_ee` | `OCS_16_0` | Localhost mode |
| `sybase_home_delegate` | `/tools/ver/sybase` | Delegate mode (on-prem bastion) |
| `sybase_ocs_delegate` | `OCS_16_0` | Delegate mode |
| `sybase_home` | `""` (empty) | Direct override - bypasses auto-select |
| `sybase_ocs` | `""` (empty) | Direct override - bypasses auto-select |

**How auto-selection works:**

```
inspec_delegate_host: ""              → uses sybase_home_ee / sybase_ocs_ee
inspec_delegate_host: "inspec-runner" → uses sybase_home_delegate / sybase_ocs_delegate
sybase_home: "/custom/sybase"         → always uses this (overrides auto-select)
```

The role builds `sybase_environment_base` at runtime from the resolved paths:

```yaml
# Computed automatically in main.yml — do not set directly
sybase_environment_base:
  PATH: "<resolved_home>/<resolved_ocs>/bin"
  LD_LIBRARY_PATH: "<resolved_home>/<resolved_ocs>/lib"
  SYBASE: "<resolved_home>"
  SYBASE_OCS: "<resolved_ocs>"
```

**Customizing for your environment:**

```yaml
# Override EE path (if Sybase SDK is at a different location in the container)
sybase_home_ee: "/opt/sap/ase"

# Override delegate path (if the on-prem bastion differs from default)
sybase_home_delegate: "/opt/sybase"
sybase_ocs_delegate: "OCS_16_0"

# Force a specific path regardless of mode
sybase_home: "/custom/sybase"
sybase_ocs: "OCS_16_0"
```

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
│   │   └── libraries/
│   │       └── sybase_session_local.rb  # Custom InSpec resource
│   └── SYBASE16_ruby/        # Sybase 16 controls
│       └── libraries/
│           └── sybase_session_local.rb  # Custom InSpec resource
├── templates/
│   ├── interfaces.j2         # Sybase interfaces file template
│   ├── SYBASE.sh.j2          # Environment script template
│   └── sybase_summary_report.j2  # Summary report template
└── README.md
```

### InSpec Input Names

The role passes these inputs to InSpec controls, consistent across all platform roles:

| InSpec Input | Ansible Variable | Description |
|-------------|-----------------|-------------|
| `usernm` | `sybase_username` | Database username |
| `passwd` | `sybase_password` | Database password |
| `servicenm` | `sybase_service` | ASE server/service name |
| `database` | `sybase_database` | Target database name |

## Usage

### Direct Mode Playbook (Recommended)

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

  roles:
    - sybase_inspec
```

### SSH Mode Playbook (Legacy)

Only use this if your environment requires SSH into the Sybase server to run isql locally.

```yaml
---
- name: Run Sybase Compliance Scan (SSH Mode)
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
    sybase_ssh_key_path: "~oracle/.ssh/id_rsa"

  roles:
    - sybase_inspec
```

### Delegate Mode with Inventory (Production)

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
      ansible_host: [DELEGATE_HOST]
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
```

## Sybase Client Options

The role supports two Sybase clients:

### SAP ASE isql (Preferred)

The native SAP client provides full compatibility:

```bash
# Location varies by environment:
#   EE container:    /opt/sybase/OCS_16_0/bin/isql
#   Delegate host:   /tools/ver/sybase/OCS_16_0/bin/isql

# Environment (set automatically by the role via sybase_environment_base)
export SYBASE=/opt/sybase          # or sybase_home_delegate value
export SYBASE_OCS=OCS_16_0
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

## SSL/TLS Configuration

The role supports opt-in SSL/TLS for Sybase ASE servers that require encrypted connections. SSL is **disabled by default** and all existing non-SSL connections work unchanged.

### SSL Variables

```yaml
sybase_ssl_enabled: false                    # Enable SSL/TLS for this connection
sybase_ssl_port: 1063                        # SSL port (default: 1063)
sybase_ssl_tls_version: "TLS 1.2"           # TLS version
sybase_ssl_cipher_suites: "TLS_ECDHE_RSA_WITH_AES256_GCM_SHA384"  # Cipher suite
sybase_ssl_trusted_cert_file: ""             # Source path to trusted.txt on controller (required)
sybase_ssl_trusted_cert_dest: ""             # Override destination path (auto-selected if empty)
sybase_ssl_libtcl_cfg_path: ""               # Override libtcl.cfg path (auto-selected if empty)
```

### SSL Playbook Example

```yaml
---
- name: Run Sybase SSL Compliance Scan
  hosts: runner
  gather_facts: true

  vars:
    sybase_server: "sybase.example.com"
    sybase_port: 5000                      # Standard port (still needed for service definition)
    sybase_database: "master"
    sybase_service: "SYBASESVR"
    sybase_username: "scan_user"
    sybase_password: "{{ vault_sybase_password }}"
    sybase_version: "16"
    sybase_ssl_enabled: true
    sybase_ssl_port: 1063
    sybase_ssl_trusted_cert_file: "files/trusted.txt"

  roles:
    - sybase_inspec
```

### Mixed Inventory (SSL + Non-SSL)

```yaml
all:
  children:
    sybase_databases:
      hosts:
        SYBPROD01_5000:
          sybase_server: sybprod01.example.com
          sybase_port: 5000
          sybase_service: "SYBPROD01"
          sybase_database: "master"
          sybase_ssl_enabled: false
        SYBPROD01_1063:
          sybase_server: sybprod01.example.com
          sybase_port: 5000
          sybase_service: "SYBPROD01_SSL"
          sybase_database: "master"
          sybase_ssl_enabled: true
          sybase_ssl_port: 1063
          sybase_ssl_trusted_cert_file: "files/sybprod01_trusted.txt"
```

### How SSL Works

1. **Interfaces file**: Uses `ssl` protocol instead of `tcp` with the SSL port
2. **libtcl.cfg**: Tells the Open Client library to load `libsybssl64.so` with the configured cipher suite
3. **trusted.txt**: CA certificate file deployed to the delegate host for certificate validation
4. **isql -X flag**: Tells isql to use the SSL module for the connection
5. **SYBOCS_CFG**: Environment variable pointing to `libtcl.cfg` location

### SSL Troubleshooting

#### SSL Handshake Failed

```
Error: SSL_HANDSHAKE_FAILED
```

- Verify the Sybase server has SSL enabled on the configured port
- Check that the cipher suite matches the server's configuration
- Ensure the TLS version is compatible (TLS 1.2 required)

#### SSL Certificate Invalid

```
Error: SSL_CERT_INVALID
```

- Verify `sybase_ssl_trusted_cert_file` points to the correct CA certificate
- Ensure the certificate is valid and not expired
- Check that the certificate chain is complete

#### SSL on FreeTDS (Not Supported)

SSL is only supported with the SAP isql client. FreeTDS tsql does not support SAP ASE SSL natively. If SSL is enabled and only tsql is available, the role will log a warning.

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
# /opt/sybase/interfaces (generated)
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
# Check SAP ASE client installation at expected paths
ls -la /opt/sybase/OCS_16_0/bin/isql          # EE default
ls -la /tools/ver/sybase/OCS_16_0/bin/isql    # Delegate default

# Or install FreeTDS (test environments)
dnf install -y freetds
which tsql
```

**Fix:** Override the path for your execution mode:

```yaml
# If running in EE (localhost mode)
sybase_home_ee: "/opt/sybase"

# If running on delegate host
sybase_home_delegate: "/tools/ver/sybase"

# Or force a specific path regardless of mode
sybase_home: "/opt/sap/ase"
sybase_ocs: "OCS_16_0"
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
source /opt/sybase/SYBASE.sh

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

The role includes a custom `sybase_session_local` InSpec resource (in both SYBASE15 and SYBASE16 profiles) that:

- Auto-detects SAP isql or FreeTDS tsql
- Supports custom interfaces file path via `-I` flag (for on-prem where `/opt/sybase/interfaces` may not exist)
- Handles local and remote execution properly
- Parses both isql and tsql output formats
- Manages temporary SQL files correctly

Located at: `files/SYBASE{15,16}_ruby/libraries/sybase_session_local.rb`

## License

Internal use only

## Author

DevOps Team
