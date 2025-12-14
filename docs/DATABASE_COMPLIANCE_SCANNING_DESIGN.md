# Database Compliance Scanning Framework - Design Document

**Author:** Platform Engineering / DevOps
**Version:** 1.0
**Date:** 2025-10-14
**Tooling:** Ansible AAP2, InSpec, Splunk (optional)

---

## 1. Purpose

This document defines the design and architecture of the **Database Compliance Scanning Framework** using Ansible AAP2 and InSpec. The framework enables automated NIST compliance scanning across multiple database platforms — **MSSQL**, **Oracle**, and **Sybase** — using native credentials, standard Ansible roles, and repeatable playbooks executed from AAP2.

This solution refactors the original  bash script into a modern, scalable, and maintainable Ansible-based orchestration framework while maintaining full backward compatibility with existing file formats and workflows.

---

## 2. Architecture Overview

### 2.1 Logical Overview

Each compliance scan is orchestrated from **Ansible AAP2**, which triggers job templates that execute on delegate hosts (execution environments). These delegate hosts run InSpec scans using the appropriate platform-specific role (`mssql_inspec`, `oracle_inspec`, `sybase_inspec`), and results are exported as JSON for analysis or ingestion into Splunk.

The framework operates on an **inventory-based architecture** where:
- Each database (or database server for MSSQL) is represented as an inventory host
- A single APMD service account is used for AAP2 SSH connectivity and database access
- Platform-specific roles handle database-specific connectivity and scanning
- Results follow the original script naming conventions for compatibility

---

### 2.2 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    ANSIBLE AUTOMATION PLATFORM 2 (AAP2)                         │
│  ┌──────────────────┐    ┌─────────────────┐    ┌────────────────────────┐    │
│  │  Job Templates   │───▶│  Execution Env  │───▶│   Service Account      │    │
│  │  - run_mssql     │    │  - InSpec       │    │   - SSH Connectivity   │    │
│  │  - run_oracle    │    │  - sqlcmd       │    │   - DB Authentication  │    │
│  │  - run_sybase    │    │  - sqlplus      │    │                        │    │
│  │                  │    │  - isql         │    │                        │    │
│  └──────────────────┘    └─────────────────┘    └────────────────────────┘    │
│                                   │                                             │
│                                   │ SSH Port 22                                 │
└───────────────────────────────────┼─────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         DELEGATE HOST / EXECUTION NODE                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                           ANSIBLE ROLES                                  │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │   │
│  │  │  mssql_inspec   │  │  oracle_inspec  │  │  sybase_inspec  │        │   │
│  │  │  - validate     │  │  - validate     │  │  - validate     │        │   │
│  │  │  - setup        │  │  - setup        │  │  - setup        │        │   │
│  │  │  - execute      │  │  - execute      │  │  - execute      │        │   │
│  │  │  - process      │  │  - process      │  │  - process      │        │   │
│  │  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘        │   │
│  └───────────┼─────────────────────┼─────────────────────┼─────────────────┘   │
└──────────────┼─────────────────────┼─────────────────────┼─────────────────────┘
               │                     │                     │
        TCP 1733 (sqlcmd)     TCP 1521 (sqlplus)   TCP 5000 (isql)
               │                     │                     │
               ▼                     ▼                     ▼
     ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
     │  MSSQL SERVER    │  │  ORACLE DATABASE │  │  SYBASE ASE      │
     │  ────────────    │  │  ────────────    │  │  ────────────    │
     │  SQL Server      │  │  Oracle 12c/19c  │  │  Sybase 15/16    │
     │  2017/2019/2022  │  │  Port: 1521      │  │  Port: 5000      │
     │  Port: 1733      │  │  Service: XE     │  │  Service: ASE    │
     │                  │  │                  │  │                  │
     │  InSpec Controls │  │  InSpec Controls │  │  InSpec Controls │
     │  ✓ Auditing      │  │  ✓ Auditing      │  │  ✓ Auditing      │
     │  ✓ Encryption    │  │  ✓ Encryption    │  │  ✓ Encryption    │
     │  ✓ Access        │  │  ✓ Access        │  │  ✓ Access        │
     └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘
              │                     │                     │
              └─────────────────────┴─────────────────────┘
                                    │
                                    ▼
              ┌─────────────────────────────────────────────┐
              │         RESULTS MANAGEMENT                  │
              │  ┌──────────────────────────────────────┐  │
              │  │  JSON Results (Local Storage)        │  │
              │  │  /tmp/compliance_scans/              │  │
              │  │  ├── mssql/                          │  │
              │  │  │   └── MSSQL_NIST_*.json           │  │
              │  │  ├── oracle/                         │  │
              │  │  │   └── ORACLE_NIST_*.json          │  │
              │  │  └── sybase/                         │  │
              │  │      └── SYBASE_NIST_*.json          │  │
              │  └──────────────────────────────────────┘  │
              │                    │                        │
              │                    ├──────────────────┐     │
              │                    ▼                  ▼     │
              │  ┌──────────────────────────┐  ┌──────────┐│
              │  │  Summary Reports (TXT)   │  │  Splunk  ││
              │  │  - Compliance Scores     │  │   HEC    ││
              │  │  - Pass/Fail Counts      │  │ Optional ││
              │  │  - Failed Control Details│  │HTTPS:8088││
              │  └──────────────────────────┘  └──────────┘│
              └─────────────────────────────────────────────┘
```

---

### 2.3 Connectivity Matrix

| Component | Source | Destination | Protocol | Port | Description |
|-----------|--------|-------------|----------|------|-------------|
| AAP2 Controller | AAP2 | Delegate Host | SSH | 22 | Launches jobs to EE (APMD account) |
| Delegate Host | EE Runner | MSSQL Server | TCP | 1733 | SQL Server connectivity (APMD account) |
| Delegate Host | EE Runner | Oracle DB | TCP | 1521 | Oracle listener (APMD account) |
| Delegate Host | EE Runner | Sybase DB | TCP | 5000/1025 | Sybase ASE listener (APMD account) |
| Delegate Host | EE Runner | Splunk HEC | HTTPS | 8088 | Optional metrics/log ingestion |

---

## 3. Execution Flow

### 3.1 High-Level Workflow

```
┌──────────┐      ┌──────────┐      ┌─────────────────┐      ┌──────────────┐      ┌──────────┐      ┌─────────┐
│   User   │      │   AAP2   │      │   Execution     │      │   Platform   │      │ Database │      │ Splunk  │
│          │      │          │      │   Environment   │      │     Role     │      │          │      │   HEC   │
└────┬─────┘      └────┬─────┘      └────────┬────────┘      └──────┬───────┘      └────┬─────┘      └────┬────┘
     │                 │                     │                       │                   │                 │
     │ 1. Launch Job   │                     │                       │                   │                 │
     │ Template        │                     │                       │                   │                 │
     ├────────────────>│                     │                       │                   │                 │
     │                 │                     │                       │                   │                 │
     │                 │ 2. Deploy via SSH   │                       │                   │                 │
     │                 │ (Service Account)   │                       │                   │                 │
     │                 ├────────────────────>│                       │                   │                 │
     │                 │                     │                       │                   │                 │
     │                 │                     │ 3. Load Inventory     │                   │                 │
     │                 │                     │ & Select Platform     │                   │                 │
     │                 │                     ├───┐                   │                   │                 │
     │                 │                     │   │                   │                   │                 │
     │                 │                     │<──┘                   │                   │                 │
     │                 │                     │                       │                   │                 │
     │                 │                     │ 4. Execute Role       │                   │                 │
     │                 │                     │ (mssql_inspec/        │                   │                 │
     │                 │                     │  oracle_inspec/       │                   │                 │
     │                 │                     │  sybase_inspec)       │                   │                 │
     │                 │                     ├──────────────────────>│                   │                 │
     │                 │                     │                       │                   │                 │
     │                 │                     │                       │ 5. Validate Params│                 │
     │                 │                     │                       │ & Setup Dirs      │                 │
     │                 │                     │                       ├───┐               │                 │
     │                 │                     │                       │   │               │                 │
     │                 │                     │                       │<──┘               │                 │
     │                 │                     │                       │                   │                 │
     │                 │                     │                       │ 6. Test           │                 │
     │                 │                     │                       │ Connectivity      │                 │
     │                 │                     │                       ├──────────────────>│                 │
     │                 │                     │                       │                   │                 │
     │                 │                     │                       │ ┌─────────────────┴──────────────┐  │
     │                 │                     │                       │ │ IF CONNECTION SUCCESS:         │  │
     │                 │                     │                       │ │                                │  │
     │                 │                     │                       │ 7. Execute InSpec │  │
     │                 │                     │                       │    Controls       │  │
     │                 │                     │                       ├──────────────────>│  │
     │                 │                     │                       │                   │  │
     │                 │                     │                       │ 8. Return Results │  │
     │                 │                     │                       │<──────────────────┤  │
     │                 │                     │                       │                   │  │
     │                 │                     │                       │ 9. Process JSON   │  │
     │                 │                     │                       ├───┐               │  │
     │                 │                     │                       │   │               │  │
     │                 │                     │                       │<──┘               │  │
     │                 │                     │                       │ │                                │  │
     │                 │                     │                       │ └────────────────┬───────────────┘  │
     │                 │                     │                       │ │ ELSE CONNECTION FAILURE:       │  │
     │                 │                     │                       │ │                                │  │
     │                 │                     │                       │ │ Generate "Unreachable" JSON    │  │
     │                 │                     │                       │ └────────────────────────────────┘  │
     │                 │                     │                       │                   │                 │
     │                 │                     │ 10. Save Results      │                   │                 │
     │                 │                     │     /tmp/compliance   │                   │                 │
     │                 │                     │<──────────────────────┤                   │                 │
     │                 │                     │                       │                   │                 │
     │                 │                     │                       │ 11. Generate      │                 │
     │                 │                     │                       │     Summary Report│                 │
     │                 │                     │                       ├───┐               │                 │
     │                 │                     │                       │   │               │                 │
     │                 │                     │                       │<──┘               │                 │
     │                 │                     │                       │                   │                 │
     │                 │                     │                       │ ┌─────────────────┴──────────────┐  │
     │                 │                     │                       │ │ IF SPLUNK ENABLED:             │  │
     │                 │                     │                       │ │                                │  │
     │                 │                     │                       │ │ 12. Forward Results via HEC    │  │
     │                 │                     │                       │ │     (HTTPS:8088)               │  │
     │                 │                     │                       ├────────────────────────────────────>│
     │                 │                     │                       │ │                                │  │
     │                 │                     │                       │ └────────────────────────────────┘  │
     │                 │                     │                       │                   │                 │
     │                 │ 13. Job Complete    │                       │                   │                 │
     │                 │<────────────────────┤                       │                   │                 │
     │                 │                     │                       │                   │                 │
     │ 14. Display     │                     │                       │                   │                 │
     │     Results     │                     │                       │                   │                 │
     │<────────────────┤                     │                       │                   │                 │
     │                 │                     │                       │                   │                 │
     ▼                 ▼                     ▼                       ▼                   ▼                 ▼
```

**Execution Flow Summary:**
1. User triggers job template in AAP2
2. AAP2 deploys execution environment via SSH using service account
3. Execution environment loads inventory and selects appropriate platform role
4. Platform-specific role (mssql_inspec, oracle_inspec, or sybase_inspec) is executed
5. Role validates parameters and sets up result directories
6. Database connectivity test performed using service account credentials
7. If connection succeeds: InSpec controls are executed against the database
8. Database returns scan results
9. Role processes JSON output and applies naming conventions
10. Results saved to local filesystem (/tmp/compliance_scans/)
11. Summary report generated with compliance metrics
12. Optional: Results forwarded to Splunk HEC endpoint (if enabled)
13. Job completion status returned to AAP2
14. User views results and summary in AAP2 UI

### 3.2 Detailed Step-by-Step Flow

#### Step 1: Job Trigger
- AAP2 launches a job template using APMD service account credentials
- Execution environment (EE) deployed to delegate host containing:
  - InSpec binary
  - Database client tools (sqlcmd, sqlplus, isql)
  - Ansible roles and playbooks

#### Step 2: Inventory Selection
- Hosts are dynamically loaded from inventory files organized by platform:
  - `mssql_databases` - Server-level MSSQL hosts (scans all databases on server)
  - `oracle_databases` - Database-level Oracle hosts
  - `sybase_databases` - Database-level Sybase hosts
- APMD service account used for all database connections

#### Step 3: Role Execution
Platform-specific role is executed based on `database_platform` variable:

**For MSSQL (`mssql_inspec`):**
1. `validate.yml` - Validates MSSQL connection parameters
2. `setup.yml` - Creates result directories, discovers control files
3. `execute.yml` - Runs InSpec using sqlcmd backend
4. `process_results.yml` - Parses JSON results, applies file naming
5. `cleanup.yml` - Generates summary report, optional cleanup
6. `splunk_integration.yml` - Forwards to Splunk (if enabled)

**For Oracle (`oracle_inspec`):**
1. `validate.yml` - Validates Oracle connection (TNS/Service Name)
2. `setup.yml` - Creates result directories, discovers control files
3. `execute.yml` - Runs InSpec using sqlplus backend
4. `process_results.yml` - Parses JSON results
5. `cleanup.yml` - Generates summary report
6. `splunk_integration.yml` - Forwards to Splunk (if enabled)

**For Sybase (`sybase_inspec`):**
1. `validate.yml` - Validates Sybase connection parameters
2. `setup.yml` - Creates result directories, discovers control files
3. `execute.yml` - Runs InSpec using isql backend
4. `process_results.yml` - Parses JSON results
5. `cleanup.yml` - Generates summary report
6. `splunk_integration.yml` - Forwards to Splunk (if enabled)

#### Step 4: InSpec Scan Execution
- InSpec runs using native database clients with APMD service account
- Control files loaded from version-specific directories:
  - MSSQL: `mssql_inspec/files/MSSQL{VERSION}_ruby/*.rb`
  - Oracle: `oracle_inspec/files/ORACLE{VERSION}_ruby/*.rb`
  - Sybase: `sybase_inspec/files/SYBASE{VERSION}_ruby/*.rb`
- Results saved in JSON format with original script naming convention:
  - `{PLATFORM}_NIST_{PID}_{SERVER}_{DB}_{VERSION}_{TIMESTAMP}_{CONTROL}.json`

#### Step 5: Result Processing & Reporting
- JSON results parsed for compliance status
- Summary reports generated with:
  - Total controls executed
  - Pass/Fail counts
  - Compliance percentage
  - Failed control details
- Results exported to: `/tmp/compliance_scans/{PLATFORM}/{HOST}/{TIMESTAMP}/`
- Optional forwarding to Splunk HEC endpoint

---

## 4. Role and File Structure

### 4.1 Repository Structure

```
roles/
├── mssql_inspec/                    # MSSQL InSpec role
│   ├── tasks/
│   │   ├── main.yml                 # Main orchestration
│   │   ├── validate.yml             # Parameter validation
│   │   ├── setup.yml                # Directory and control file setup
│   │   ├── execute.yml              # InSpec execution
│   │   ├── process_results.yml      # Result processing
│   │   ├── cleanup.yml              # Cleanup and reporting
│   │   └── splunk_integration.yml   # Splunk forwarding
│   ├── defaults/main.yml            # Default variables
│   ├── vars/main.yml                # Role variables
│   ├── templates/
│   │   └── summary_report.j2        # Report template
│   ├── files/                       # InSpec control files
│   │   ├── MSSQL2008_ruby/
│   │   ├── MSSQL2012_ruby/
│   │   ├── MSSQL2014_ruby/
│   │   ├── MSSQL2016_ruby/
│   │   ├── MSSQL2017_ruby/
│   │   ├── MSSQL2018_ruby/
│   │   └── MSSQL2019_ruby/
│   │       └── trusted.rb           # Sample InSpec control
│   └── README.md
│
├── oracle_inspec/                   # Oracle InSpec role
│   ├── tasks/
│   │   ├── main.yml
│   │   ├── validate.yml
│   │   ├── setup.yml
│   │   ├── execute.yml
│   │   ├── process_results.yml
│   │   ├── cleanup.yml
│   │   └── splunk_integration.yml
│   ├── defaults/main.yml
│   ├── vars/main.yml
│   ├── templates/
│   │   └── oracle_summary_report.j2
│   ├── files/
│   │   ├── ORACLE11g_ruby/
│   │   ├── ORACLE12c_ruby/
│   │   ├── ORACLE18c_ruby/
│   │   └── ORACLE19c_ruby/
│   │       └── trusted.rb
│   └── README.md
│
├── sybase_inspec/                   # Sybase InSpec role
│   ├── tasks/
│   │   ├── main.yml
│   │   ├── validate.yml
│   │   ├── setup.yml
│   │   ├── execute.yml
│   │   ├── process_results.yml
│   │   ├── cleanup.yml
│   │   └── splunk_integration.yml
│   ├── defaults/main.yml
│   ├── vars/main.yml
│   ├── templates/
│   │   └── sybase_summary_report.j2
│   ├── files/
│   │   ├── SYBASE15_ruby/
│   │   └── SYBASE16_ruby/
│   └── README.md
│
├── inventory_converter/             # Flat file converter
│   ├── convert_flatfile_to_inventory.yml
│   ├── process_flatfile_line.yml
│   ├── templates/
│   │   └── vault_template.j2
│   └── README.md
│
├── playbooks/
│   ├── run_mssql_inspec.yml         # MSSQL scanning playbook
│   ├── run_oracle_inspec.yml        # Oracle scanning playbook
│   ├── run_sybase_inspec.yml        # Sybase scanning playbook
│   └── run_compliance_scans.yml     # Multi-platform playbook
│
└── group_vars/
    └── all/
        └── vars.yml                 # Non-sensitive variables
```

### 4.2 Inventory Structure

**MSSQL Inventory (Server-Level):**
```yaml
all:
  children:
    mssql_databases:
      hosts:
        server01_1733:
          database_platform: mssql
          mssql_server: server01
          mssql_port: 1733
          mssql_version: "2019"
          # Note: APMD service account used for connection
          # InSpec scans ALL databases on this server
```

**Oracle/Sybase Inventory (Database-Level):**
```yaml
all:
  children:
    oracle_databases:
      hosts:
        oracleserver01_orcl_1521:
          database_platform: oracle
          oracle_server: oracleserver01
          oracle_database: orcl
          oracle_service: XE
          oracle_port: 1521
          oracle_version: "19c"
          # Note: APMD service account used for connection

    sybase_databases:
      hosts:
        sybaseserver01_master_5000:
          database_platform: sybase
          sybase_server: sybaseserver01
          sybase_database: master
          sybase_service: SAP_ASE
          sybase_port: 5000
          sybase_version: "16"
          # Note: APMD service account used for connection
```

---

## 5. Security

This section outlines the technical integration approach for connecting Ansible Automation Platform 2 (AAP2) with CyberArk to enable secure, programmatic retrieval of database service account credentials for our compliance scanning initiative.

---

### 5.1 Background

**Current:**
- Legacy bash scripts running on conductor/jump servers with manual credential management
- Service account <SERVICE_ACCOUNT_ID> created and stored in CyberArk
- Need to transition to AAP2-based automation

**Target :**
- AAP2 dynamically retrieves credentials from CyberArk at runtime
- No hardcoded passwords in playbooks, inventory files, or AAP2 configurations
- Full RBAC compliance and audit trail

---

### 5.2 Service Account Details

| Property | Value |
|----------|-------|
| Account Identifier | <SERVICE_ACCOUNT_ID> |
| Account Type | Process Account (UNIX) |
| Password Vault | CyberArk |
| Owner Identity Type | Application Identity |
| Environment | DEV |
| Purpose | Database scanning via Ansible InSpec |
| Target Databases | Oracle, MSSQL, Sybase |

---

### 5.3 Integration Architecture

#### High-Level Flow

```
┌─────────────┐         ┌──────────────┐         ┌────────────┐
│   AAP2      │         │  CyberArk    │         │  Database  │
│   Tower     │─────────▶│  Vault       │         │  Servers   │
│             │  (1)    │              │         │            │
└─────────────┘         └──────────────┘         └────────────┘
      │                        │                        │
      │                        │                        │
      │    (2) Retrieve        │                        │
      │◀───────────────────────│                        │
      │    Password            │                        │
      │                        │                        │
      │                        │      (3) Connect       │
      └────────────────────────┼────────────────────────▶
                               │      with Creds        │
                               │                        │
```

**Step 1:** AAP2 job execution triggered (manual or scheduled)
**Step 2:** AAP2 queries CyberArk API/CLI to retrieve service account password
**Step 3:** AAP2 uses credentials to connect to target databases for scanning
**Step 4:** InSpec controls execute against databases
**Step 5:** Results pushed to Cloakware reporting system

---

### 5.4 Technical Implementation Approach

#### CyberArk Central Credential Provider (CCP) Integration

This design follows industry best practices by leveraging CyberArk Central Credential Provider (CCP) or Application Access Manager (AAM) for secure, programmatic credential retrieval. This approach is the gold standard for enterprise credential management and provides:

**Key Benefits:**
- Industry-standard integration pattern widely adopted in enterprise environments
- Native password rotation handling without playbook modifications
- Comprehensive audit logs across both AAP2 and CyberArk platforms
- Zero credential exposure in AAP2 logs or playbook outputs
- Separation of concerns between application logic and credential management
- Built-in high availability and failover capabilities

**Architecture Components:**

1. **CyberArk Central Credential Provider (CCP)** - REST API endpoint for credential retrieval
2. **Application Identity (AppID)** - Registered AAP2 application identity in CyberArk
3. **Safe** - Secure vault container storing the service account credentials
4. **AAP2 Custom Credential Type** - Native AAP2 integration with CyberArk

#### AAP2 Custom Credential Type Configuration

```yaml
# AAP2 Custom Credential Type for CyberArk Integration
---
credential_type:
  name: CyberArk Database Credential
  description: Retrieves database credentials from CyberArk vault
  kind: cloud

  inputs:
    fields:
      - id: cyberark_url
        type: string
        label: CyberArk CCP URL
        help_text: "Base URL for CyberArk Central Credential Provider API"

      - id: app_id
        type: string
        label: Application ID
        help_text: "Registered AppID in CyberArk for AAP2"

      - id: safe_name
        type: string
        label: Safe Name
        help_text: "CyberArk safe containing the target account"

      - id: object_name
        type: string
        label: Object Name
        help_text: "Account identifier (e.g., <SERVICE_ACCOUNT_ID>)"

      - id: cert_path
        type: string
        label: Client Certificate Path
        help_text: "Path to client certificate for CCP authentication"
        secret: false

      - id: cert_key_path
        type: string
        label: Client Certificate Key Path
        help_text: "Path to client certificate private key"
        secret: true

    required:
      - cyberark_url
      - app_id
      - safe_name
      - object_name
      - cert_path

  injectors:
    env:
      CYBERARK_USERNAME: "{{ object_name }}"
      CYBERARK_SAFE: "{{ safe_name }}"
    extra_vars:
      cyberark_username: "{{ object_name }}"

    # Password retrieved dynamically at runtime
    file:
      template: |
        [defaults]
        cyberark_password_script = /usr/local/bin/get_cyberark_password.py
```

#### CyberArk CCP Integration Script

```python
#!/usr/bin/env python3
"""
CyberArk CCP Password Retrieval Script
Called by AAP2 at runtime to fetch service account password
"""

import requests
import sys
import json
import os

def get_password_from_cyberark():
    """
    Retrieve password from CyberArk Central Credential Provider
    Uses certificate-based authentication for secure access
    """

    cyberark_url = os.environ.get('CYBERARK_CCP_URL')
    app_id = os.environ.get('CYBERARK_APP_ID')
    safe = os.environ.get('CYBERARK_SAFE')
    object_name = os.environ.get('CYBERARK_OBJECT')
    cert_path = os.environ.get('CYBERARK_CERT_PATH')
    key_path = os.environ.get('CYBERARK_KEY_PATH')

    # Construct CCP API endpoint
    endpoint = f"{cyberark_url}/AIMWebService/api/Accounts"

    # Request parameters
    params = {
        'AppID': app_id,
        'Safe': safe,
        'Object': object_name,
        'Query': f"Object={object_name}"
    }

    try:
        # Make authenticated request to CyberArk CCP
        response = requests.get(
            endpoint,
            params=params,
            cert=(cert_path, key_path),
            verify=True,  # Always verify SSL in production
            timeout=30
        )

        response.raise_for_status()

        # Extract password from response
        data = response.json()
        password = data.get('Content', '')

        if not password:
            sys.stderr.write("ERROR: No password returned from CyberArk\n")
            sys.exit(1)

        # Return password to AAP2 (stdout is captured securely)
        print(password)
        sys.exit(0)

    except requests.exceptions.RequestException as e:
        sys.stderr.write(f"ERROR: Failed to retrieve password from CyberArk: {e}\n")
        sys.exit(1)

if __name__ == "__main__":
    get_password_from_cyberark()
```

---

### 5.5 Workflow Logic

#### Playbook Execution Flow

```
START: AAP2 Job Template Execution
  │
  ├─▶ Load inventory and variables
  │
  ├─▶ Pre-task: Validate CyberArk connectivity
  │     │
  │     ├─ Check CyberArk API endpoint reachability
  │     └─ Verify certificate validity
  │
  ├─▶ Task: Retrieve service account password
  │     │
  │     ├─ Call CyberArk API/CCP
  │     ├─ Pass AppID, Safe, Object parameters
  │     ├─ Authenticate using client certificate
  │     └─ Store password in memory (no_log enabled)
  │
  ├─▶ Task: Test database connectivity
  │     │
  │     ├─ Use retrieved credentials
  │     ├─ Validate connection to each DB type
  │     └─ Handle connection errors
  │
  ├─▶ Task: Execute InSpec compliance scans
  │     │
  │     ├─ Run controls for MSSQL
  │     ├─ Run controls for Oracle
  │     ├─ Run controls for Sybase
  │     └─ Collect results
  │
  ├─▶ Task: Generate Cloakware-compatible reports
  │     │
  │     ├─ Format results per Cloakware schema
  │     └─ Upload to Cloakware system
  │
  ├─▶ Post-task: Clear sensitive variables
  │     │
  │     └─ Unset password variables from memory
  │
END: Job completion with status
```

---

### 5.6 Security Considerations

#### Credential Handling

1. **No Logging:** Use `no_log: true` on all tasks handling credentials
2. **Memory Only:** Credentials should never be written to disk
3. **Scope Limiting:** Credentials should be variables scoped to specific plays/tasks
4. **Rotation Awareness:** Handle CyberArk password rotation gracefully

#### Network Security

- **Encryption:** All API calls to CyberArk must use TLS 1.2+
- **Certificate Authentication:** Prefer certificate-based auth over username/password
- **Network Segmentation:** AAP2 should connect to CyberArk via dedicated network paths

#### RBAC Integration

**AAP2 Side:**
- Only authorized AAP2 users/teams can execute credential-dependent playbooks
- Separate credentials for DEV, UAT, PROD environments

**CyberArk Side:**
- Application ID (AppID) registered for AAP2
- Safe permissions configured for the AppID to retrieve service account credentials
- Dual control policies (if required by security team)

---

### 5.7 Security Best Practices

**Access Control:**
- Service account configured as AAP2 Machine Credential
- Account granted RBAC permissions on MSSQL servers for scan execution
- Account granted necessary permissions on Oracle and Sybase databases
- Read-only access enforced at database level
- Principle of Least Privilege applied

**Monitoring & Compliance:**
- All scan activities logged in AAP2 job output
- Database connection attempts logged in DB audit logs
- Service account activity monitored for anomalies
- Regular access reviews for account permissions
- CyberArk audit logs reviewed for unauthorized access attempts
- Complete audit trail from AAP2 → CyberArk → Database

---

## 6. Error Handling

### 6.1 Error Detection & Recovery

| Failure Type | Detection Method | Recovery Action | Result |
|--------------|------------------|-----------------|---------|
| **SSH Connection Failure** | AAP2 cannot SSH to delegate host | Retry 2x, alert on failure | Job fails with connection error |
| **Database Connection Failure** | SQL client exit code != 0 | Retry 2x with 30s delay | Generate "Unreachable" JSON if all retries fail |
| **InSpec Execution Failure** | InSpec returns non-zero exit code | Log stderr, continue | Generate error JSON with details |
| **JSON Parse Failure** | Invalid JSON in InSpec output | Move to `/tmp/failed_results/` | Log parse error, skip result processing |
| **Missing Control File** | Control file not found in role files | Fail task with descriptive message | Abort scan for that database |
| **Network Timeout** | Connection timeout to database | Retry with exponential backoff | Generate "Unreachable" after max retries |
| **Splunk Forwarding Failure** | HEC endpoint unreachable | Log warning, continue | Results saved locally, Splunk optional |

### 6.2 Error JSON Format (Original Script Compatibility)

**Connection Failure JSON:**
```json
{
  "platform": "MSSQL",
  "version": "1",
  "profiles": [
    {
      "name": "MSSQL Compliance",
      "version": "1.0.0",
      "status": "Unreachable",
      "controls": [
        {
          "id": "connection-test",
          "title": "Database Connection Test",
          "status": "failed",
          "code_desc": "Connection to server01:1733 failed",
          "results": [
            {
              "status": "failed",
              "code_desc": "Connection failed",
              "run_time": 0.0,
              "start_time": "2025-10-14T12:00:00Z"
            }
          ]
        }
      ],
      "statistics": {
        "duration": 0.0
      }
    }
  ],
  "statistics": {
    "duration": 0.0
  }
}
```

### 6.3 Retry Logic

**Connection Retry Configuration:**
```yaml
# In role defaults/main.yml
max_connection_retries: 2
retry_delay: 30  # seconds
connection_timeout: 60  # seconds
inspec_timeout: 1800  # 30 minutes per control
```

---

## 7. Result Management

### 7.1 Result File Structure

**Base Directory:**
```
/tmp/compliance_scans/
├── mssql/
│   └── server01_1733_1728912345/
│       ├── MSSQL_NIST_12345_server01_db01_2019_1728912345_trusted.json
│       ├── MSSQL_NIST_12345_server01_db01_2019_1728912345_audit.json
│       └── summary_report.txt
├── oracle/
│   └── oracleserver01_orcl_1728912456/
│       ├── ORACLE_NIST_12346_oracleserver01_orcl_19c_1728912456_trusted.json
│       └── summary_report.txt
└── sybase/
    └── sybaseserver01_master_1728912567/
        ├── SYBASE_NIST_12347_sybaseserver01_master_16_1728912567_trusted.json
        └── summary_report.txt
```

**File Naming Convention (Original Script Compatibility):**
```
{PLATFORM}_NIST_{PID}_{SERVER}_{DATABASE}_{VERSION}_{TIMESTAMP}_{CONTROL}.json

Where:
- PLATFORM: MSSQL, ORACLE, SYBASE
- PID: Ansible process ID (ansible_pid variable)
- SERVER: Database server hostname
- DATABASE: Database name
- VERSION: Database version (2019, 19c, 16, etc.)
- TIMESTAMP: Unix epoch timestamp
- CONTROL: Control file basename (trusted, audit, etc.)
```

**Examples:**
```
MSSQL_NIST_98765_sqlserver01_master_2019_1728912345_trusted.json
ORACLE_NIST_98766_oracleserver01_orcl_19c_1728912456_trusted.json
SYBASE_NIST_98767_sybaseserver01_master_16_1728912567_trusted.json
```

### 7.2 Summary Report Format (Text)

```
=====================================
Database Compliance Scan Summary
=====================================
Platform: MSSQL
Server: sqlserver01:1733
Database: master
Version: 2019
Scan Date: 2025-10-14 12:00:00
Scan Duration: 45.67 seconds

Control Results:
================
Total Controls: 150
Passed: 142 (94.67%)
Failed: 5 (3.33%)
Skipped: 3 (2.00%)

Failed Controls:
================
1. [MSSQL-2019-042] Ensure 'sa' account is disabled
   Status: FAILED
   Description: The 'sa' account is enabled

2. [MSSQL-2019-078] Ensure 'Remote Access' is disabled
   Status: FAILED
   Description: Remote access is enabled

... [truncated]

Compliance Score: 94.67%
Overall Status: PASSED (threshold: 90%)

Results Location: /tmp/compliance_scans/mssql/sqlserver01_1733_1728912345/
=====================================
```

### 7.3 Splunk Integration (Optional)

**HEC Event Format:**
```json
{
  "time": 1728912345,
  "index": "compliance_scans",
  "source": "ansible_database_compliance",
  "sourcetype": "ansible:database:compliance",
  "event": {
    "job_id": "AAP2-12345",
    "project": "database_compliance",
    "platform": "MSSQL",
    "server": "sqlserver01",
    "port": 1733,
    "database": "master",
    "version": "2019",
    "scan_timestamp": 1728912345,
    "controls_total": 150,
    "controls_passed": 142,
    "controls_failed": 5,
    "controls_skipped": 3,
    "compliance_score": 94.67,
    "scan_duration": 45.67,
    "status": "completed",
    "result_file": "/tmp/compliance_scans/mssql/sqlserver01_1733_1728912345/MSSQL_NIST_98765_sqlserver01_master_2019_1728912345_trusted.json"
  }
}
```

---

**End of Design Document**
