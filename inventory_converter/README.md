# Flat File to Inventory Converter

Converts database flat files to Ansible inventory format.

## Usage

```bash
ansible-playbook convert_flatfile_to_inventory.yml \
  -e "flatfile_input=databases.txt" \
  -e "inventory_output=inventory.yml"
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
```

## Output

Simple inventory with host metadata:

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
    oracle_databases:
      hosts:
        oraserver_db01_1521:
          oracle_server: oraserver
          oracle_database: db01
          oracle_service: db01_svc
          oracle_port: 1521
          oracle_version: "19"
          database_platform: oracle
    sybase_databases:
      hosts:
        sybserver_db01_5000:
          sybase_server: sybserver
          sybase_database: db01
          sybase_port: 5000
          sybase_version: "16"
          database_platform: sybase
```

## Notes

- MSSQL entries are deduplicated by `server:port` (server-level scanning)
- Oracle/Sybase entries are per-database
- Credentials are handled by AAP2, not in inventory
