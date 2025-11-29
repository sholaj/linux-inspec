# MSSQL InSpec Ansible Role

This Ansible role executes InSpec compliance checks against Microsoft SQL Server databases, refactored from the original `NIST_for_db.ksh` Bash script.

## Purpose

The `mssql_inspec` role performs NIST compliance scanning on MSSQL databases using InSpec controls. It provides:
- Modular, version-specific compliance checks
- Secure credential management
- Comprehensive error handling
- JSON-formatted compliance results

## Requirements

- Ansible 2.9+
- InSpec installed on the target system (`/usr/bin/inspec`)
- Network connectivity to target MSSQL servers
- Valid MSSQL credentials with appropriate permissions

## Role Variables

### Required Variables
```yaml
mssql_server: ""          # MSSQL server hostname/IP
mssql_port: 1433         # MSSQL port (default: 1433)
mssql_database: ""       # Target database name
mssql_username: ""       # Database username
mssql_password: ""       # Database password
mssql_version: ""        # MSSQL version (2008/2012/2014/2016/2018/2019)
```

### Optional Variables
```yaml
mssql_service: ""                    # Named instance (if applicable)
inspec_debug_mode: false            # Enable debug output
inspec_results_dir: "/tmp/inspec_mssql_results_{{ ansible_date_time.epoch }}"
generate_summary_report: true       # Generate summary report
cleanup_temp_files: true           # Clean up temporary files
use_vault: false                   # Use Ansible Vault for credentials
```

## Supported MSSQL Versions

- MSSQL 2008
- MSSQL 2012
- MSSQL 2014
- MSSQL 2016
- MSSQL 2018
- MSSQL 2019

## Directory Structure

```
mssql_inspec/
├── tasks/
│   ├── main.yml              # Main task file
│   └── process_results.yml   # Result processing tasks
├── defaults/main.yml         # Default variables
├── vars/main.yml             # Role variables
├── files/
│   ├── MSSQL2008_ruby/      # MSSQL 2008 controls
│   ├── MSSQL2012_ruby/      # MSSQL 2012 controls
│   ├── MSSQL2014_ruby/      # MSSQL 2014 controls
│   ├── MSSQL2016_ruby/      # MSSQL 2016 controls
│   ├── MSSQL2018_ruby/      # MSSQL 2018 controls
│   └── MSSQL2019_ruby/      # MSSQL 2019 controls
├── templates/
│   └── summary_report.j2    # Summary report template
└── README.md                # This file
```

## Usage

### Basic Usage

1. Include the role in your playbook:

```yaml
---
- name: Run MSSQL InSpec Compliance Checks
  hosts: localhost
  roles:
    - role: mssql_inspec
      vars:
        mssql_server: "sql-server.example.com"
        mssql_port: 1433
        mssql_database: "production_db"
        mssql_username: "nist_scan_user"
        mssql_password: "{{ vault_mssql_password }}"
        mssql_version: "2019"
```

### Using with Ansible Vault

For secure credential management:

```bash
# Create encrypted variable file
ansible-vault create group_vars/mssql/vault.yml

# Run playbook with vault
ansible-playbook -i inventory run_mssql_inspec.yml --ask-vault-pass
```

### Multiple Database Scanning

```yaml
---
- name: Scan Multiple MSSQL Databases
  hosts: localhost
  tasks:
    - name: Run compliance checks on multiple databases
      include_role:
        name: mssql_inspec
      vars:
        mssql_server: "{{ item.server }}"
        mssql_port: "{{ item.port }}"
        mssql_database: "{{ item.database }}"
        mssql_username: "{{ item.username }}"
        mssql_password: "{{ item.password }}"
        mssql_version: "{{ item.version }}"
      loop: "{{ mssql_databases }}"
```

## Output

The role generates JSON-formatted compliance results in the specified results directory:
- Individual control results: `MSSQL_<server>_<database>_<version>_<timestamp>_<control>.json`
- Error reports for failed connections
- Optional summary report

### Result Structure

```json
{
  "controls": [{
    "timestamp": "2024-01-15T10:30:00",
    "hostname": "sql-server.example.com",
    "database": "production_db",
    "port": "1433",
    "DBVersion": "2019",
    "id": "2.01",
    "status": "passed",
    "code_desc": "Ad Hoc Distributed Queries disabled",
    "statistics": {
      "duration": 0.123
    }
  }]
}
```

## Error Handling

The role handles various error conditions:
- Missing or invalid InSpec installation
- Connection failures to MSSQL server
- Invalid credentials
- Unsupported MSSQL versions
- Missing required parameters

## Security Considerations

1. **Credential Management**: Use Ansible Vault or external secret management systems
2. **Network Security**: Ensure secure network connections to MSSQL servers
3. **Audit Logging**: Results are stored locally; implement appropriate log retention
4. **Minimal Permissions**: Use dedicated scanning accounts with read-only permissions

## Troubleshooting

### InSpec Not Found
```bash
# Verify InSpec installation
which inspec
# Install if missing
gem install inspec
```

### Connection Failures
- Verify network connectivity: `telnet <server> <port>`
- Check firewall rules
- Verify MSSQL service is running
- Confirm credentials are valid

### Debug Mode
Enable debug mode for detailed output:
```yaml
inspec_debug_mode: true
```

## License

Internal use only

## Author

DevOps Team

## Support

For issues or questions, contact the DevOps team or raise an issue in the project repository.