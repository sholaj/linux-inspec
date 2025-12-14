#!/usr/bin/env python3
"""
Convert flat-file database connection details to Ansible inventory format
Input format: PLATFORM SERVER_NAME DB_NAME SERVICE_NAME PORT VERSION
Example: MSSQL m02dsm3 m02dsm3 BIRS_Confidential 1733 2017

NOTE: Original script does NOT include credentials in flat file!
- Username comes from predefined service account (e.g., dbmaint)
- Password retrieved externally via pwEcho.exe/Cloakware system
"""

import sys
import yaml
import argparse
import os
from pathlib import Path


def parse_flatfile_line(line):
    """Parse a single line from the flat file"""
    parts = line.strip().split()
    if len(parts) != 6:
        return None

    parsed = {
        'platform': parts[0],
        'server': parts[1],
        'database': parts[2],
        'service': parts[3],
        'port': parts[4],
        'version': parts[5]
    }

    return parsed


def convert_to_inventory(input_file, output_format='yaml', default_username='nist_scan_user'):
    """Convert flat file to Ansible inventory format"""

    inventory = {
        'all': {
            'children': {
                'mssql_databases': {
                    'hosts': {}
                },
                'oracle_databases': {
                    'hosts': {}
                },
                'sybase_databases': {
                    'hosts': {}
                }
            }
        }
    }

    # Track passwords separately for vault
    passwords = {}

    # Read and parse input file
    with open(input_file, 'r') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()

            # Skip empty lines and comments
            if not line or line.startswith('#'):
                continue

            parsed = parse_flatfile_line(line)
            if not parsed:
                print(f"Warning: Skipping invalid line {line_num}: {line}", file=sys.stderr)
                continue

            # Create unique host identifier
            host_id = f"{parsed['server']}_{parsed['database']}_{parsed['port']}".replace('.', '_').replace('-', '_')

            # Create host vars WITHOUT password
            host_vars = {
                'mssql_server': parsed['server'],
                'mssql_port': int(parsed['port']),
                'mssql_database': parsed['database'],
                'mssql_service': parsed['service'] if parsed['service'] != 'null' else '',
                'mssql_version': parsed['version'],
                'mssql_username': default_username,
                'mssql_host_id': host_id  # Add host_id for password lookup
            }

            # Store password placeholder - DB team will provide actual passwords
            passwords[f"vault_{host_id}_password"] = "DB_TEAM_TO_PROVIDE"

            # Add to appropriate group
            if parsed['platform'].upper() == 'MSSQL':
                inventory['all']['children']['mssql_databases']['hosts'][host_id] = host_vars
            elif parsed['platform'].upper() == 'ORACLE':
                # Adjust keys for Oracle
                oracle_vars = {k.replace('mssql_', 'oracle_'): v for k, v in host_vars.items()}
                inventory['all']['children']['oracle_databases']['hosts'][host_id] = oracle_vars
            elif parsed['platform'].upper() == 'SYBASE':
                # Adjust keys for Sybase
                sybase_vars = {k.replace('mssql_', 'sybase_'): v for k, v in host_vars.items()}
                inventory['all']['children']['sybase_databases']['hosts'][host_id] = sybase_vars

    return inventory, passwords


def write_yaml_inventory(inventory_data, output_file):
    """Write inventory data to YAML file"""

    # Add global vars
    inventory_data['all']['vars'] = {
        'base_results_dir': '/tmp/compliance_scans',
        'ansible_connection': 'local',
        'inspec_debug_mode': False,
        'ansible_python_interpreter': '{{ ansible_playbook_python }}'
    }

    with open(output_file, 'w') as f:
        yaml.dump(inventory_data, f, default_flow_style=False, sort_keys=False)

    print(f"Inventory written to: {output_file}")


def generate_sample_flatfile(output_file):
    """Generate a sample flat file with example entries"""

    sample_content = """# Sample database inventory file
# Format: PLATFORM SERVER_NAME DB_NAME SERVICE_NAME PORT VERSION
# Lines starting with # are comments
# NO CREDENTIALS IN FLAT FILE - DB team provides passwords separately

# MSSQL Examples
MSSQL sqlserver01.example.com master default 1433 2019
MSSQL sqlserver02.example.com production_db null 1433 2018
MSSQL sqlserver03.example.com test_db SQLEXPRESS 1434 2016
MSSQL m02dsm3 m02dsm3 BIRS_Confidential 1733 2017

# Multiple databases on same server
MSSQL dbserver.example.com finance_db null 1433 2019
MSSQL dbserver.example.com hr_db null 1433 2019
MSSQL dbserver.example.com sales_db null 1433 2019

# Oracle Examples (for future use)
ORACLE oraserver01.example.com ORCL XE 1521 19c
ORACLE oraserver02.example.com PRODDB null 1521 12c

# Sybase Examples (for future use)
SYBASE sybserver01.example.com master SAP_ASE 5000 16.0
"""

    with open(output_file, 'w') as f:
        f.write(sample_content)

    print(f"Sample flat file written to: {output_file}")


def write_vault_file(passwords, vault_file):
    """Write passwords to vault file"""

    with open(vault_file, 'w') as f:
        f.write("---\n")
        f.write("# Ansible Vault file for database passwords\n")
        f.write("# This file will be encrypted. DO NOT commit unencrypted!\n\n")
        yaml.dump(passwords, f, default_flow_style=False, sort_keys=False)

    print(f"Vault file written to: {vault_file}")
    print(f"  Contains {len(passwords)} password variables")
    print(f"  Encrypt with: ansible-vault encrypt {vault_file} --vault-password-file .vaultpass")


def main():
    parser = argparse.ArgumentParser(
        description='Convert flat-file database inventory to Ansible format',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Convert flat file to YAML inventory
  %(prog)s -i databases.txt -o inventory.yml

  # Convert with vault template generation
  %(prog)s -i databases.txt -o inventory.yml --vault-template vault.yml

  # Generate sample flat file
  %(prog)s --generate-sample sample_databases.txt

  # Specify default username for entries without explicit username
  %(prog)s -i databases.txt -o inventory.yml -u default_scan_user

Usage with playbook:
  ansible-playbook -i inventory.yml run_mssql_inspec.yml
  ansible-playbook -i inventory.yml run_mssql_inspec.yml --ask-vault-pass
  ansible-playbook -i inventory.yml run_mssql_inspec.yml -e @vault.yml
        """
    )

    parser.add_argument('-i', '--input',
                        help='Input flat file with database details')
    parser.add_argument('-o', '--output',
                        help='Output inventory file (YAML format)')
    parser.add_argument('-u', '--username',
                        default='nist_scan_user',
                        help='Default username for entries without explicit username (default: nist_scan_user)')
    parser.add_argument('--vault-template',
                        metavar='FILE',
                        help='Generate Ansible Vault template file for passwords')
    parser.add_argument('--generate-sample',
                        metavar='FILE',
                        help='Generate a sample flat file')

    args = parser.parse_args()

    # Handle sample generation
    if args.generate_sample:
        generate_sample_flatfile(args.generate_sample)
        return 0

    # Validate input for conversion
    if not args.input or not args.output:
        parser.error("Both --input and --output are required for conversion")

    if not os.path.exists(args.input):
        print(f"Error: Input file '{args.input}' not found", file=sys.stderr)
        return 1

    # Convert the file
    try:
        inventory_data, passwords = convert_to_inventory(args.input, 'yaml', args.username)

        # Count hosts
        mssql_count = len(inventory_data['all']['children']['mssql_databases']['hosts'])
        oracle_count = len(inventory_data['all']['children']['oracle_databases']['hosts'])
        sybase_count = len(inventory_data['all']['children']['sybase_databases']['hosts'])
        total_count = mssql_count + oracle_count + sybase_count

        print(f"\nConversion Summary:")
        print(f"  Total database hosts: {total_count}")
        print(f"  MSSQL databases: {mssql_count}")
        print(f"  Oracle databases: {oracle_count}")
        print(f"  Sybase databases: {sybase_count}")
        print()

        # Write inventory
        write_yaml_inventory(inventory_data, args.output)

        # Write vault file if requested
        if args.vault_template:
            write_vault_file(passwords, args.vault_template)

        print(f"\nUsage:")
        print(f"  # For POC (with .vaultpass file):")
        print(f"  ansible-playbook -i {args.output} run_mssql_inspec.yml -e @{args.vault_template or 'vault.yml'} --vault-password-file .vaultpass")
        print(f"\n  # For AAP (Ansible Automation Platform):")
        print(f"  # Upload {args.output} as inventory")
        print(f"  # Add {args.vault_template or 'vault.yml'} as encrypted extra vars")
        print(f"  # Configure credential for vault password")

        return 0

    except Exception as e:
        print(f"Error during conversion: {e}", file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())