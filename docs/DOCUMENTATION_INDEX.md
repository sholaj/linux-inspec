# Documentation Index

## Core Documentation

### 1. **README.md** (Root Directory)
Main project overview and getting started guide.
Location: `/Users/shola/Documents/MyGoProject/linux-inspec/README.md`

### 2. **DATABASE_COMPLIANCE_SCANNING_DESIGN.md**
Overall system design and architecture.
- Architecture diagrams
- Execution flow
- Role structure
- Integration patterns

### 3. **DATABASE_COMPLIANCE_SCANNING_REQUIREMENTS.md**
Business and functional requirements.
- Functional requirements
- Non-functional requirements
- Success criteria
- Risk mitigation

### 4. **AAP_MESH_ARCHITECTURE_GUIDE.md**
Comparison of AAP Mesh vs Delegate Host architecture.
- When to use each approach
- Architecture patterns
- Migration path
- Recommendations

### 5. **ANSIBLE_VARIABLES_REFERENCE.md**
Complete Ansible variables reference guide.
- SSH authentication variables (Layer 1)
- Database credentials (Layer 2)
- Correct variable names
- Common mistakes and fixes
- AAP2 credential mapping

### 6. **SECURITY_PASSWORD_HANDLING.md**
Critical security implementation guide.
- Environment variable approach
- Before/after security fixes
- Verification procedures
- No password exposure in logs/processes

### 7. **INVENTORY_USAGE.md**
Inventory-based scanning approach.
- Flat file format
- Inventory structure
- Security best practices
- Troubleshooting

### 8. **MULTI_PLATFORM_IMPLEMENTATION.md**
Multi-platform scanning overview.
- MSSQL, Oracle, Sybase support
- Platform-specific features
- Hello World validation
- Production readiness

### 9. **LOCAL_TESTING_GUIDE.md**
Local testing with Docker setup.
- Docker infrastructure
- InSpec installation
- Testing procedures
- Cleanup procedures

### 10. **QUICK_START_GUIDE.md**
Step-by-step quick start guide.
- Prerequisites
- Configuration steps
- Running tests
- Common operations

---

## Test Files and Playbooks

### Test Playbooks (Location: test_playbooks/)

1. **test_delegate_execution_flow.yml**
   - Tests SSH delegation to delegate host
   - Validates fact gathering
   - Mimics actual scan execution flow
   - **Run this first to validate setup**

2. **test_delegate_connection.yml**
   - Tests different connection scenarios
   - Direct connection, jump server, delegate patterns
   - Environment variable loading validation
   - **Run to validate connection architecture**

3. **test_mssql_implementation.yml**
   - Comprehensive 7-test validation suite
   - Tests all layers (delegation, tools, connectivity, InSpec)
   - **Run to validate MSSQL implementation**

4. **run_compliance_scans.yml**
   - Multi-platform compliance scanning (production)
   - Supports MSSQL, Oracle, Sybase
   - Batch execution with configurable concurrency
   - **Primary production playbook**

5. **run_mssql_inspec.yml**
   - MSSQL-specific compliance scanning
   - Server-level scanning (all databases on server)
   - **Production MSSQL scanning**

6. **run_oracle_inspec.yml**
   - Oracle-specific compliance scanning
   - Database-level scanning
   - TNS/Service name support
   - **Production Oracle scanning**

7. **run_sybase_inspec.yml**
   - Sybase-specific compliance scanning
   - Database-level with SSH support
   - **Production Sybase scanning**

### Test Inventories (Location: test_playbooks/)

1. **test_inventory.yml**
   - General test inventory
   - Used with test_delegate_execution_flow.yml
   - Examples for all database platforms

2. **test_mssql_inventory.yml**
   - MSSQL-specific test inventory
   - Used with test_mssql_implementation.yml
   - Shows both SSH auth methods

3. **test_vault.yml**
   - Test vault file with database credentials
   - **Replace CHANGE_ME values before using**
   - **Encrypt with ansible-vault**

4. **azure_test_inventory.yml**
   - Azure-specific test configuration
   - Example for cloud deployments

---

## Inventory Converter (Location: inventory_converter/)

### Converter Playbooks

1. **convert_flatfile_to_inventory.yml**
   - Main converter playbook
   - Converts 6-field flat file to Ansible inventory
   - Generates vault file templates

2. **process_flatfile_line.yml**
   - Line processing logic
   - Platform-specific parsing (MSSQL, Oracle, Sybase)

### Converter Templates

3. **templates/vault_template.j2**
   - Vault file generation template
   - Platform-specific password placeholders

### Converter Documentation

4. **README.md**
   - Converter usage guide
   - Input/output formats
   - Integration examples

---

## Quick Reference

### For Initial Setup
1. Read: **QUICK_START_GUIDE.md** (step-by-step setup)
2. Review: **ANSIBLE_VARIABLES_REFERENCE.md** (correct variable names)
3. Configure inventory (SSH key or password)
4. Run: `test_playbooks/test_delegate_execution_flow.yml` (validate delegation)

### For Testing
1. Validate setup: `test_playbooks/test_delegate_execution_flow.yml`
2. Test connections: `test_playbooks/test_delegate_connection.yml`
3. Test MSSQL: `test_playbooks/test_mssql_implementation.yml`

### For Production Scanning
1. All platforms: `test_playbooks/run_compliance_scans.yml`
2. MSSQL only: `test_playbooks/run_mssql_inspec.yml`
3. Oracle only: `test_playbooks/run_oracle_inspec.yml`
4. Sybase only: `test_playbooks/run_sybase_inspec.yml`

### For Security Information
- Read: **SECURITY_PASSWORD_HANDLING.md**
- All passwords passed via environment variables
- No passwords in logs or command-line
- Unconditional `no_log: true` enforcement

### For Architecture Decisions
- Read: **AAP_MESH_ARCHITECTURE_GUIDE.md**
- Delegate host vs AAP Mesh comparison
- When to use each approach

---

## Directory Structure Reference

```
linux-inspec/
├── docs/                           # All documentation files
│   ├── AAP_MESH_ARCHITECTURE_GUIDE.md
│   ├── ANSIBLE_VARIABLES_REFERENCE.md
│   ├── DATABASE_COMPLIANCE_SCANNING_DESIGN.md
│   ├── DATABASE_COMPLIANCE_SCANNING_REQUIREMENTS.md
│   ├── DOCUMENTATION_INDEX.md
│   ├── INVENTORY_USAGE.md
│   ├── LOCAL_TESTING_GUIDE.md
│   ├── MULTI_PLATFORM_IMPLEMENTATION.md
│   ├── QUICK_START_GUIDE.md
│   └── SECURITY_PASSWORD_HANDLING.md
├── test_playbooks/                 # All test and production playbooks
│   ├── README.md
│   ├── run_compliance_scans.yml    # Primary production playbook
│   ├── run_mssql_inspec.yml
│   ├── run_oracle_inspec.yml
│   ├── run_sybase_inspec.yml
│   ├── test_delegate_connection.yml
│   ├── test_delegate_execution_flow.yml
│   ├── test_mssql_implementation.yml
│   ├── test_inventory.yml
│   ├── test_mssql_inventory.yml
│   ├── test_vault.yml
│   └── azure_test_inventory.yml
├── inventory_converter/            # Flat file conversion tools
│   ├── README.md
│   ├── convert_flatfile_to_inventory.yml
│   ├── process_flatfile_line.yml
│   └── templates/
│       └── vault_template.j2
├── roles/                          # Ansible roles
│   ├── mssql_inspec/
│   ├── oracle_inspec/
│   └── sybase_inspec/
├── inventories/                    # Environment inventories
│   ├── production/
│   └── staging/
├── scripts/                        # Utility scripts
│   ├── convert_flatfile_to_inventory.py
│   └── git-hooks/
├── ansible.cfg                     # Ansible configuration
├── README.md                       # Main project README
└── LICENSE

```

---

## Document Maintenance

### When to Update Each Doc

**DOCUMENTATION_INDEX.md** (This file)
- New documentation files added
- File structure changes
- Playbook locations change

**DATABASE_COMPLIANCE_SCANNING_DESIGN.md**
- Architecture changes
- New platforms added
- Role structure modifications
- Integration patterns change

**ANSIBLE_VARIABLES_REFERENCE.md**
- New authentication methods
- Variable naming changes
- Credential structure changes

**SECURITY_PASSWORD_HANDLING.md**
- Security implementation changes
- New password handling approaches
- Compliance updates

**QUICK_START_GUIDE.md**
- Setup procedure changes
- New prerequisites
- Updated file paths

### Version Control
All documentation is version controlled in Git.
Check git history for changes and rationale.

---

## Getting Help

1. **Start with**: QUICK_START_GUIDE.md
2. **Variable issues**: ANSIBLE_VARIABLES_REFERENCE.md
3. **Security questions**: SECURITY_PASSWORD_HANDLING.md
4. **Architecture decisions**: AAP_MESH_ARCHITECTURE_GUIDE.md
5. **Testing problems**: test_playbooks/README.md
6. **Inventory conversion**: inventory_converter/README.md

---

**Last Updated**: 2025-12-14
**Total Documentation Files**: 10 core docs + 1 index = 11 files
**Status**: Updated and Consolidated ✓
**Project Structure**: Aligned with test_playbooks/ directory
**Variables**: Using correct `ansible_password` (not deprecated `ansible_ssh_pass`)
