# Flat File to Inventory Converter

Converts database flat files to Ansible inventory format.

## Usage

### Local Execution Mode (Default)
```bash
ansible-playbook convert_flatfile_to_inventory.yml \
  -e "flatfile_input=databases.txt" \
  -e "inventory_output=inventory.yml"
```

### With Remote Delegate Host
```bash
ansible-playbook convert_flatfile_to_inventory.yml \
  -e "flatfile_input=databases.txt" \
  -e "inventory_output=inventory.yml" \
  -e "inspec_delegate=inspec-runner" \
  -e "inspec_delegate_address=10.0.0.50" \
  -e "inspec_delegate_user=ansible_svc"
```

### All MSSQL Hosts Use WinRM (Default Mode)
```bash
# No need to add WINRM to every line - set default
ansible-playbook convert_flatfile_to_inventory.yml \
  -e "flatfile_input=databases.txt" \
  -e "inventory_output=inventory.yml" \
  -e "mssql_connection_mode=winrm"
```

### Mixed Environment (Override Default)
```bash
# Default to WinRM, but flat file can override per-host
ansible-playbook convert_flatfile_to_inventory.yml \
  -e "flatfile_input=databases.txt" \
  -e "mssql_connection_mode=winrm"
```
With flat file:
```
MSSQL winserver01 master svc1 1433 2019          # Uses default (winrm)
MSSQL winserver02 master svc1 1433 2019          # Uses default (winrm)
MSSQL linuxsql01 master svc1 1433 2019 DIRECT    # Override: direct connection
```

## Input Format

```
PLATFORM SERVER DATABASE SERVICE PORT VERSION [CONNECTION]
```

| Field | Required | Description |
|-------|----------|-------------|
| PLATFORM | Yes | Database type: MSSQL, ORACLE, SYBASE, POSTGRES |
| SERVER | Yes | Database server hostname |
| DATABASE | Yes | Database name (or `master` for MSSQL) |
| SERVICE | Yes | Service name (use `null` if N/A) |
| PORT | Yes | Database port number |
| VERSION | Yes | Database version |
| CONNECTION | No | Connection mode: `WINRM` or `DIRECT` (default: DIRECT) |

### Examples

Basic (direct connection):
```
MSSQL server01 master svc1 1433 2019
ORACLE oraserver db01 db01_svc 1521 19
SYBASE sybserver db01 dummy 5000 16
POSTGRES pgserver testdb null 5432 15
```

With WinRM (mixed environment):
```
# Windows SQL Servers using WinRM
MSSQL winserver01 master svc1 1433 2019 WINRM
MSSQL winserver02 master svc1 1433 2019 WINRM

# Linux SQL Server using direct connection
MSSQL linuxsql01 master svc1 1433 2019 DIRECT

# Other platforms (always direct)
ORACLE oraserver db01 db01_svc 1521 19
```

## Output

### Local Execution Mode (Default)
```yaml
all:
  children:
    mssql_databases:
      hosts:
        server01_1433:
          mssql_server: server01
          mssql_port: 1433
          mssql_version: "2019"
          database_platform: mssql
          use_winrm: false           # Direct connection
      vars:
        mssql_username: nist_scan_user
        # inspec_delegate_host defaults to "localhost"

    oracle_databases:
      hosts:
        oraserver_db01_1521:
          oracle_server: oraserver
          oracle_database: db01
          oracle_service: db01_svc
          oracle_port: 1521
          oracle_version: "19"
          database_platform: oracle
      vars:
        oracle_username: nist_scan_user

    sybase_databases:
      hosts:
        sybserver_db01_5000:
          sybase_server: sybserver
          sybase_database: db01
          sybase_port: 5000
          sybase_version: "16"
          database_platform: sybase
      vars:
        sybase_username: nist_scan_user
        sybase_use_ssh: true
        sybase_ssh_user: sybase_admin

    postgres_databases:
      hosts:
        pgserver_testdb_5432:
          postgres_server: pgserver
          postgres_database: testdb
          postgres_service: ""
          postgres_port: 5432
          postgres_version: "15"
          database_platform: postgres
      vars:
        postgres_username: nist_scan_user
```

### Mixed WinRM/Direct Environment
```yaml
all:
  children:
    mssql_databases:
      hosts:
        winserver01_1433:
          mssql_server: winserver01
          mssql_port: 1433
          mssql_version: "2019"
          database_platform: mssql
          use_winrm: true            # WinRM to Windows host
        linuxsql01_1433:
          mssql_server: linuxsql01
          mssql_port: 1433
          mssql_version: "2019"
          database_platform: mssql
          use_winrm: false           # Direct connection
      vars:
        mssql_username: nist_scan_user
        # WinRM credentials injected by AAP2 Custom Credential
```

### With Remote Delegate Host
```yaml
all:
  hosts:
    inspec-runner:
      ansible_host: 10.0.0.50
      ansible_connection: ssh
      ansible_user: ansible_svc

  children:
    mssql_databases:
      hosts:
        server01_1433:
          # ... host vars ...
      vars:
        mssql_username: nist_scan_user
        inspec_delegate_host: inspec-runner  # SSH to this host
```

## Connection Modes

### Execution Delegation (`inspec_delegate_host`)

| `inspec_delegate_host` | Execution Mode | Description |
|------------------------|----------------|-------------|
| `"localhost"` (default) | Local | InSpec runs on AAP2 execution node |
| `""` (empty) | Local | InSpec runs on AAP2 execution node |
| `"<hostname>"` | SSH | InSpec runs on specified host via SSH |

### Database Connection (`use_winrm`)

| `use_winrm` | Connection Mode | Use Case |
|-------------|-----------------|----------|
| `false` (default) | Direct | sqlcmd connects directly to database |
| `true` | WinRM | WinRM to Windows host, then local sqlcmd |

**WinRM Notes:**
- Only applicable to MSSQL on Windows hosts
- Requires `winrm_username` credential (injected by AAP2)
- See `docs/WINRM_PREREQUISITES.md` for Windows setup

## Supported Platforms

| Platform | Input Value | Deduplication | Notes |
|----------|-------------|---------------|-------|
| MSSQL | `MSSQL` | `server:port` | Server-level scanning |
| Oracle | `ORACLE` | `server:database:port` | Per-database scanning |
| Sybase | `SYBASE` | `server:database:port` | Per-database scanning |
| PostgreSQL | `POSTGRES` or `POSTGRESQL` | `server:database:port` | Per-database scanning |

## Notes

- MSSQL entries are deduplicated by `server:port` (server-level scanning)
- Oracle/Sybase/PostgreSQL entries are per-database
- Credentials (passwords) are handled by AAP2, not stored in inventory
- Group vars include default usernames for each platform
- Use `null` for the SERVICE field when not applicable (e.g., PostgreSQL)
- CONNECTION column is optional and backward compatible (defaults to DIRECT)
- Use `-e "mssql_connection_mode=winrm"` to default all MSSQL hosts to WinRM
- Per-line CONNECTION column overrides the default mode
- WinRM hosts require AAP2 Custom Credential for `winrm_username` injection
