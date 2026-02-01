# Database Compliance Scanning Workshop

**Workshop Duration:** 2-3 hours
**Level:** Intermediate to Advanced
**Author:** Platform Engineering / DevOps
**Version:** 1.0
**Date:** 2026-01-30

---

## Workshop Overview

This workshop provides a hands-on walkthrough of the Database Compliance Scanning Framework, which automates NIST compliance scanning across enterprise database platforms using Ansible Automation Platform 2 (AAP2) and InSpec.

### Learning Objectives

By the end of this workshop, participants will:

1. Understand the delegate host architecture pattern for enterprise environments
2. Configure and deploy multi-platform database compliance scans
3. Implement secure credential management using industry best practices
4. Troubleshoot common connectivity and execution challenges
5. Integrate the framework with AAP2 for enterprise-scale deployment

### Prerequisites

- Basic knowledge of Ansible playbooks and YAML
- Familiarity with database administration concepts
- Access to a Linux environment with Ansible installed
- Understanding of SSH and network connectivity concepts

---

## Part 1: Architecture and Design Patterns

### 1.1 The Challenge: Enterprise Network Constraints

In enterprise banking environments, direct connectivity from automation platforms to databases is rarely possible due to:

- **Network Segmentation**: Databases reside in isolated network zones
- **Firewall Restrictions**: Opening new firewall rules requires lengthy approval processes
- **Compliance Requirements**: All access must be auditable and controlled
- **Bastion/Jump Server Architecture**: Access is routed through designated intermediaries

### 1.2 Solution: The Delegate Host Pattern

The delegate host pattern solves these challenges by leveraging existing infrastructure:

```
                                    ENTERPRISE NETWORK
    +--------------------------------------------------------------------------------+
    |                                                                                |
    |   +------------------+                              +------------------+       |
    |   |                  |         SSH (Port 22)       |                  |       |
    |   |   AAP2           |  ------------------------>  |  Delegate Host   |       |
    |   |   Controller     |         (Existing Access)   |  (Bastion)       |       |
    |   |                  |                              |                  |       |
    |   +------------------+                              +--------+---------+       |
    |                                                              |                 |
    |                                                              |                 |
    |                    +--------------------+--------------------+                 |
    |                    |                    |                    |                 |
    |                    v                    v                    v                 |
    |           +--------+-------+   +--------+-------+   +--------+-------+        |
    |           |                |   |                |   |                |        |
    |           |    MSSQL       |   |    Oracle      |   |    Sybase      |        |
    |           |    Servers     |   |    Databases   |   |    ASE         |        |
    |           |   (TCP 1433)   |   |   (TCP 1521)   |   |   (TCP 5000)   |        |
    |           |                |   |                |   |                |        |
    |           +----------------+   +----------------+   +----------------+        |
    |                                                                                |
    +--------------------------------------------------------------------------------+
```

**Key Benefits:**

| Benefit | Description |
|---------|-------------|
| No New Firewall Rules | Leverages existing bastion/jump server access |
| Minimal Infrastructure Cost | Uses existing hosts, no new VMs required |
| Compliant Access Path | All access through approved channels |
| Centralized Execution | Single point for client tools and InSpec |

### 1.3 Execution Mode Selection

The framework supports two execution modes controlled by a single variable:

```yaml
# Delegate Mode: InSpec runs on remote delegate host
inspec_delegate_host: "delegate.example.internal"

# Local Mode: InSpec runs on AAP2 execution node
inspec_delegate_host: ""    # or "localhost" or omit entirely
```

**Decision Matrix:**

| Scenario | Mode | Setting |
|----------|------|---------|
| Databases reachable from AAP2 | Local | `inspec_delegate_host: ""` |
| Databases behind jump server | Delegate | `inspec_delegate_host: "jump01"` |
| Testing/Development | Local | `inspec_delegate_host: ""` |
| Production Banking | Delegate | `inspec_delegate_host: "[DELEGATE_HOST]"` |

---

## Part 2: Multi-Platform Database Support

### 2.1 Supported Platforms Overview

| Platform | Versions | Connection Type | Key Challenges |
|----------|----------|-----------------|----------------|
| MSSQL | 2008-2022 | Direct, WinRM | Server-level scanning, Windows auth |
| Oracle | 11g-19c | Easy Connect, TNS, TCPS | Multiple connection methods, environment vars |
| Sybase | 15, 16 | SSH Tunnel, Direct | SSH transport to database host |

### 2.2 MSSQL Implementation

MSSQL uses a **server-level scanning** approach - one scan per server discovers and scans all databases.

**Inventory Example:**
```yaml
all:
  children:
    mssql_databases:
      hosts:
        sqlserver01_1433:
          database_platform: mssql
          mssql_server: sqlserver01.example.internal
          mssql_port: 1433
          mssql_version: "2019"
          mssql_username: nist_scan_user
```

**Connection Flow:**
```
AAP2 --> SSH --> Delegate Host --> sqlcmd --> MSSQL Server (TCP 1433)
```

### 2.3 Oracle Implementation

Oracle supports multiple connection methods to accommodate diverse enterprise configurations:

**Connection Types:**

| Type | Use Case | Configuration |
|------|----------|---------------|
| Easy Connect | Simple environments | Default - no additional config |
| TNS Names | Complex environments | `oracle_use_tns: true` + tnsnames.ora |
| TCPS (SSL/TLS) | Encrypted connections | `oracle_connection_type: tcps` |
| Oracle Wallet | Certificate auth | `oracle_connection_type: wallet` |

**Easy Connect Example:**
```yaml
oracle_databases:
  hosts:
    oracledb01_orcl:
      database_platform: oracle
      oracle_server: oracledb01.example.internal
      oracle_port: 1521
      oracle_service: ORCLPRD
      oracle_version: "19"
```

**TNS Names Example:**
```yaml
oracle_databases:
  hosts:
    oracledb01_orcl:
      database_platform: oracle
      oracle_use_tns: true
      oracle_tns_alias: ORCLPRD
      oracle_tns_admin: /opt/oracle/network/admin
```

**Environment Variable Handling:**

Oracle requires specific environment variables on the delegate host. The framework automatically manages these:

```yaml
oracle_environment:
  PATH: "{{ oracle_extra_path }}:{{ ORACLE_HOME }}/bin:{{ existing_path }}"
  LD_LIBRARY_PATH: "{{ ORACLE_HOME }}/lib:{{ existing_ld_library_path }}"
  ORACLE_HOME: "{{ ORACLE_HOME }}"
  TNS_ADMIN: "{{ oracle_tns_admin }}"
  NLS_LANG: "AMERICAN_AMERICA.AL32UTF8"
```

**Challenge Solved: Remote Environment Variables**

When running via delegate, we needed to:
1. Gather the delegate host's existing PATH
2. Prepend Oracle client paths
3. Set ORACLE_HOME and TNS_ADMIN correctly
4. Pass these to the shell execution task

```yaml
- name: Gather environment facts from execution target
  setup:
    gather_subset: [env]
  delegate_to: "{{ _delegate_host }}"
  delegate_facts: true

- name: Build environment variables
  set_fact:
    oracle_environment:
      PATH: "{{ oracle_extra_path }}:{{ ORACLE_HOME }}/bin:{{ hostvars[_delegate_host].ansible_env.PATH }}"
```

### 2.4 Sybase Implementation

Sybase has a unique requirement: the original scripts used SSH transport to connect to Sybase hosts, then executed InSpec locally on that host.

**SSH Tunnel Pattern:**
```
AAP2 --> SSH --> Delegate --> InSpec (--ssh://) --> Sybase Host --> isql --> Database
```

**Inventory Example:**
```yaml
sybase_databases:
  hosts:
    sybasedb01_master:
      database_platform: sybase
      sybase_server: sybasedb01.example.internal
      sybase_port: 5000
      sybase_database: master
      sybase_version: "16"
      sybase_ssh_user: oracle        # SSH user for InSpec transport
      sybase_use_ssh: true
```

**Three Authentication Layers:**

| Layer | Purpose | Credentials |
|-------|---------|-------------|
| 1. Ansible SSH | AAP2 to Delegate Host | `ansible_user` / SSH key |
| 2. InSpec SSH | Delegate to Sybase Host | `sybase_ssh_user` / `sybase_ssh_password` |
| 3. Database | InSpec to Sybase ASE | `sybase_username` / `sybase_password` |

---

## Part 3: Control File Deployment

### 3.1 Challenge: Making Controls Available on Delegate

InSpec control files are stored in the Git repository but need to execute on the delegate host. The framework handles this through:

1. **Role Path Resolution**: Controls stored in `roles/{platform}_inspec/files/`
2. **Automatic Deployment**: Ansible copies control files to delegate during setup
3. **Version Directories**: Platform and version-specific control organization

**Directory Structure:**
```
roles/
  mssql_inspec/
    files/
      MSSQL2017_ruby/
        trusted.rb
        audit.rb
      MSSQL2019_ruby/
        trusted.rb
        audit.rb
  oracle_inspec/
    files/
      ORACLE19c_ruby/
        trusted.rb
```

**Setup Task (setup.yml):**
```yaml
- name: Discover control files for this version
  find:
    paths: "{{ oracle_controls_base_dir }}/ORACLE{{ oracle_version }}_ruby"
    patterns: "*.rb"
  register: oracle_control_files
  delegate_to: "{{ _delegate_host }}"

- name: Deploy control files to delegate host
  copy:
    src: "{{ item.path }}"
    dest: "{{ remote_controls_dir }}/{{ item.path | basename }}"
    mode: '0644'
  loop: "{{ oracle_control_files.files }}"
  delegate_to: "{{ _delegate_host }}"
```

### 3.2 Result File Naming Convention

Results maintain backward compatibility with legacy scripts:

```
{PLATFORM}_NIST_{PID}_{SERVER}_{DATABASE}_{VERSION}_{TIMESTAMP}_{CONTROL}.json

Example:
MSSQL_NIST_12345_sqlserver01_master_2019_1738234567_trusted.json
```

---

## Part 4: Password Management

### 4.1 Security Architecture

**Golden Rule:** Passwords are NEVER exposed in:
- Command-line arguments
- Ansible logs
- Process listings
- AAP2 job output

**Implementation Pattern:**
```yaml
# SECURE: Password via environment variable
- name: Execute InSpec controls
  shell: |
    inspec exec control.rb \
      --input passwd="$INSPEC_DB_PASSWORD"
  environment:
    INSPEC_DB_PASSWORD: "{{ mssql_password }}"
  no_log: true    # ALWAYS true, never conditional
  delegate_to: "{{ _delegate_host }}"
```

**Why Environment Variables?**
- Not visible in `ps aux` output
- Not logged by Ansible
- Isolated to the specific process
- Cleaned up after task completion

### 4.2 Current State: AAP2 Credential Injection

**How It Works:**

```
+------------------+     +-----------------+     +------------------+
|                  |     |                 |     |                  |
|  AAP2 Vault      | --> |  Job Template   | --> |  Playbook        |
|  (Encrypted)     |     |  (Credentials)  |     |  (Extra Vars)    |
|                  |     |                 |     |                  |
+------------------+     +-----------------+     +------------------+
                              |
                              | Custom Credential Type
                              | (Injector Definition)
                              v
                    +------------------+
                    |                  |
                    |  mssql_password  |
                    |  oracle_password |
                    |  sybase_password |
                    |                  |
                    +------------------+
```

**AAP2 Custom Credential Type Example (MSSQL):**
```json
{
  "inputs": {
    "fields": [
      {"id": "username", "type": "string", "label": "Database Username"},
      {"id": "password", "type": "string", "label": "Database Password", "secret": true}
    ],
    "required": ["username", "password"]
  },
  "injectors": {
    "extra_vars": {
      "mssql_username": "{{ username }}",
      "mssql_password": "{{ password }}"
    }
  }
}
```

### 4.3 Target State: CyberArk Central Credential Provider

For enterprise production environments, CyberArk CCP provides:

```
+------------------+                    +------------------+
|                  |  1. API Request   |                  |
|  AAP2 Job        | -----------------> |  CyberArk CCP    |
|  (Pre-task)      |                    |  (Vault)         |
|                  | <----------------- |                  |
+------------------+  2. Password       +------------------+
        |
        | 3. Pass to Role
        v
+------------------+
|                  |
|  InSpec Execute  |
|  (Environment)   |
|                  |
+------------------+
```

**Benefits of CyberArk Integration:**

| Feature | Description |
|---------|-------------|
| Automatic Rotation | Password changes handled transparently |
| Dual Control | Optional approval workflows |
| Full Audit | Every access logged in CyberArk |
| Zero Exposure | No passwords in AAP2 configuration |

### 4.4 Alternative Credential Management Tools

| Tool | Integration Method | Use Case |
|------|-------------------|----------|
| HashiCorp Vault | AAP2 Credential Plugin | Multi-cloud environments |
| CyberArk CCP | REST API / Custom Credential | Enterprise banking |
| AWS Secrets Manager | AAP2 AWS Credential | AWS-native workloads |

---

## Part 5: AAP2 Integration

### 5.1 Architecture Components

```
+-----------------------------------------------------------------------+
|                      ANSIBLE AUTOMATION PLATFORM 2                     |
|                                                                        |
|  +----------------+    +------------------+    +-------------------+   |
|  |                |    |                  |    |                   |   |
|  | Job Templates  |    | Execution        |    | Credentials       |   |
|  | - MSSQL Scan   |    | Environments     |    | - Machine (SSH)   |   |
|  | - Oracle Scan  |    | - InSpec         |    | - MSSQL Database  |   |
|  | - Sybase Scan  |    | - DB Clients     |    | - Oracle Database |   |
|  | - Multi-Scan   |    | - Ansible        |    | - Sybase Database |   |
|  |                |    |                  |    |                   |   |
|  +----------------+    +------------------+    +-------------------+   |
|           |                    |                       |              |
|           +--------------------+-----------------------+              |
|                                |                                      |
+--------------------------------|--------------------------------------+
                                 |
                                 v
                        +------------------+
                        |                  |
                        |  Delegate Host   |
                        |  - InSpec binary |
                        |  - sqlcmd        |
                        |  - sqlplus       |
                        |  - isql          |
                        |                  |
                        +------------------+
```

### 5.2 Job Template Configuration

**MSSQL Compliance Scan Template:**

| Setting | Value |
|---------|-------|
| Name | MSSQL Compliance Scan - Production |
| Playbook | `test_playbooks/run_mssql_inspec.yml` |
| Inventory | Database Compliance Inventory |
| Limit | `mssql_databases` |
| Credentials | Machine (SSH) + MSSQL Database |
| Execution Environment | db-compliance-ee |

### 5.3 Credential Attachment

Each job template requires **two credential types**:

1. **Machine Credential** (for delegate SSH):
   - Ansible user for SSH to delegate host
   - SSH private key authentication

2. **Custom Credential** (for database access):
   - Injected as extra vars
   - Platform-specific (MSSQL/Oracle/Sybase)

### 5.4 Workflow Orchestration

For enterprise-wide compliance, use AAP2 Workflows:

```
                    +-------------------+
                    |                   |
                    |   START           |
                    |                   |
                    +--------+----------+
                             |
         +-------------------+-------------------+
         |                   |                   |
         v                   v                   v
+--------+-------+  +--------+-------+  +--------+-------+
|                |  |                |  |                |
|  MSSQL Scan    |  |  Oracle Scan   |  |  Sybase Scan   |
|  (Parallel)    |  |  (Parallel)    |  |  (Parallel)    |
|                |  |                |  |                |
+--------+-------+  +--------+-------+  +--------+-------+
         |                   |                   |
         +-------------------+-------------------+
                             |
                             v
                    +--------+----------+
                    |                   |
                    |  Generate Report  |
                    |  (Consolidate)    |
                    |                   |
                    +--------+----------+
                             |
                             v
                    +--------+----------+
                    |                   |
                    |   COMPLETE        |
                    |                   |
                    +-------------------+
```

---

## Part 6: GitHub Version Control

### 6.1 Repository Structure

```
linux-inspec/
|
+-- roles/
|   +-- mssql_inspec/           # MSSQL scanning role
|   +-- oracle_inspec/          # Oracle scanning role
|   +-- sybase_inspec/          # Sybase scanning role
|
+-- test_playbooks/
|   +-- run_mssql_inspec.yml
|   +-- run_oracle_inspec.yml
|   +-- run_sybase_inspec.yml
|   +-- run_compliance_scans.yml
|
+-- inventory_converter/        # Flat file to inventory converter
|
+-- docs/                       # Documentation
|
+-- .gitignore                  # Exclude sensitive files
+-- CLAUDE.md                   # Project instructions
```

### 6.2 Branching Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code |
| `develop` | Integration branch |
| `feat/*` | New features |
| `fix/*` | Bug fixes |
| `release/*` | Release preparation |

### 6.3 Security: What Never Goes in Git

```gitignore
# Sensitive data - NEVER commit
*vault*.yml
*inventory*.yml
*.vaultpass
credentials/
secrets/
terraform.tfstate
*.tfvars

# Local testing
*.log
/tmp/
```

---

## Part 7: Hands-On Exercises

### Exercise 1: Configure Delegate Mode

**Objective:** Switch a playbook from local to delegate execution.

**Steps:**
1. Edit your inventory file
2. Add `inspec_delegate_host: "[DELEGATE_HOST]"`
3. Ensure `ansible_connection: ssh` is set
4. Run the playbook and observe delegate execution

**Validation:**
```bash
# During execution, SSH to delegate and verify InSpec is running there
ssh [DELEGATE_HOST] "ps aux | grep inspec"
```

### Exercise 2: Add a New Oracle Database

**Objective:** Add a new Oracle database to the inventory with TNS configuration.

**Steps:**
1. Add host entry to inventory
2. Configure TNS-specific variables
3. Test connectivity
4. Run compliance scan

**Inventory Addition:**
```yaml
oracle_databases:
  hosts:
    new_oracle_db:
      oracle_server: newdb.example.internal
      oracle_port: 1521
      oracle_service: NEWDB
      oracle_version: "19"
      oracle_use_tns: true
      oracle_tns_alias: NEWDB
```

### Exercise 3: Create AAP2 Job Template

**Objective:** Create a complete job template for MSSQL scanning.

**Steps:**
1. Create Custom Credential Type
2. Create Credential Instance
3. Create Job Template
4. Attach Credentials
5. Execute and verify results

---

## Part 8: Troubleshooting Guide

### 8.1 Common Issues and Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| Delegate not reachable | SSH connection timeout | Verify hostname, check SSH key, test manually |
| Database connection fails | Authentication error | Verify credentials, check network access |
| InSpec not found | Command not found error | Check PATH on delegate, verify InSpec installation |
| Oracle environment | sqlplus errors | Verify ORACLE_HOME, LD_LIBRARY_PATH |
| Control files missing | File not found | Check role files directory, version match |

### 8.2 Diagnostic Commands

**Test SSH to Delegate:**
```bash
ssh -v ansible_svc@[DELEGATE_HOST] "hostname; which inspec"
```

**Test Database Connectivity (from delegate):**
```bash
# MSSQL
sqlcmd -S server,1433 -U user -P "$PASSWORD" -Q "SELECT @@VERSION"

# Oracle
sqlplus user/password@//server:1521/service <<< "SELECT * FROM V\$VERSION;"

# Sybase
isql -S server -U user -P "$PASSWORD" -D master <<< "SELECT @@VERSION"
```

**Verify Environment:**
```bash
# On delegate host
echo $PATH
echo $LD_LIBRARY_PATH
echo $ORACLE_HOME
which sqlcmd sqlplus isql inspec
```

---

## Summary

### Key Takeaways

1. **Delegate Host Pattern**: Leverage existing infrastructure to avoid firewall changes
2. **Multi-Platform Support**: MSSQL, Oracle, and Sybase with platform-specific handling
3. **Secure Credentials**: Environment variables with `no_log: true`
4. **AAP2 Integration**: Custom credential types and job templates
5. **Version Control**: Git-based with strict security exclusions

### Architecture Decision Summary

| Decision | Rationale |
|----------|-----------|
| Delegate Host | Avoids new firewall rules, uses existing bastion |
| Environment Variables | Protects passwords from exposure |
| Platform-Specific Roles | Clean separation, maintainability |
| InSpec | Industry-standard compliance framework |
| AAP2 | Enterprise automation with RBAC, audit |

### Next Steps

1. Deploy to your test environment
2. Onboard service accounts and credentials
3. Configure AAP2 job templates
4. Run pilot scans on non-production databases
5. Scale to production with scheduled workflows

---

## Appendix A: Quick Reference

### Variable Quick Reference

| Variable | Platform | Description |
|----------|----------|-------------|
| `inspec_delegate_host` | All | Delegate hostname or empty for local |
| `mssql_server` | MSSQL | Server hostname |
| `mssql_port` | MSSQL | SQL Server port (default: 1433) |
| `oracle_use_tns` | Oracle | Enable TNS Names mode |
| `oracle_tns_alias` | Oracle | TNS alias name |
| `sybase_use_ssh` | Sybase | Enable SSH transport |

### File Locations

| File | Purpose |
|------|---------|
| `roles/*/defaults/main.yml` | Default variable values |
| `roles/*/tasks/execute.yml` | InSpec execution logic |
| `roles/*/files/` | InSpec control files |
| `test_playbooks/` | Entry point playbooks |

---

**Workshop Complete**

For questions or issues, refer to the project documentation at `/docs/` or raise an issue in the GitHub repository.
