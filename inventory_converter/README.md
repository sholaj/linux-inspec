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

## Input Format

```
PLATFORM SERVER DATABASE SERVICE PORT VERSION
```

Example:
```
MSSQL server01 master svc1 1433 2019
ORACLE oraserver db01 db01_svc 1521 19
SYBASE sybserver db01 dummy 5000 16
POSTGRES pgserver testdb null 5432 15
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

| `inspec_delegate_host` | Execution Mode | Description |
|------------------------|----------------|-------------|
| `"localhost"` (default) | Local | InSpec runs on AAP2 execution node |
| `""` (empty) | Local | InSpec runs on AAP2 execution node |
| `"<hostname>"` | SSH | InSpec runs on specified host via SSH |

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
