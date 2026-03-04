# ServiceNow Inventory Data Sanitisation - Findings & Recommendations

**Date:** 2026-03-04
**Author:** DevOps Engineering
**Status:** Investigation Complete
**JIRA:** TBD

---

## 1. Problem Statement

Colleague feedback indicates that data received from ServiceNow (which we convert to Ansible inventory YAML) **cannot be trusted**. Specific concerns:

- Database version for a given archetype may be incorrect, leading to **wrong InSpec controls being applied**
- Port numbers may be stale or defaulted
- Decommissioned databases may still appear in exports
- Missing or incorrect relationship data (which server hosts which database)
- Instance names / service names may not match reality

This is a significant risk: if we scan a SQL Server 2019 instance using 2016 controls (because CMDB says "2016"), we get **false compliance results** - both false passes and false failures.

---

## 2. Why CMDB Data is Unreliable (Industry Context)

This is not unique to our organisation. Research shows:

| Issue | Description | Impact on Our Project |
|-------|-------------|----------------------|
| **Stale versions** | DB upgraded but CMDB not updated. Fewer than half of organisations trust their CMDB data (Forrester) | Wrong InSpec profile selected |
| **Orphan CIs** | DB decommissioned but CI record remains | Scan fails, wastes time, false reporting |
| **Duplicate CIs** | Same DB appears multiple times from different data sources | Duplicate scans, inflated counts |
| **Missing ports** | `tcp_port` null or defaulted to 1433/1521/5000 | Connection failures |
| **Missing relationships** | DB instance not linked to hosting server | Can't determine connection target |
| **Sybase weakest link** | ServiceNow Discovery's Sybase support is least mature | Sybase inventory likely least accurate |

### Root Causes

1. **ServiceNow Discovery gaps** - Discovery may not reach all network segments (especially behind jump servers in our architecture)
2. **Manual update lag** - DBAs upgrade databases but don't update CMDB tickets
3. **No closed-loop feedback** - Nothing currently validates CMDB data against reality
4. **Multiple data sources** - Imports from different tools create conflicting records

---

## 3. Current State: How We Handle Inventory Today

### Current Flow
```
ServiceNow Export (flat file)
        │
        ▼
Inventory Converter (Python/Ansible)
  - Parses: PLATFORM SERVER DB SERVICE PORT VERSION
  - Generates: Ansible inventory YAML
        │
        ▼
Role Validation (validate.yml)
  - Checks fields are non-empty
  - Checks version is in supported list
  - Does NOT verify version is correct
        │
        ▼
Preflight (preflight.yml)
  - Tests connectivity (port reachable, auth works)
  - Does NOT query actual DB version
        │
        ▼
InSpec Execution
  - Selects controls based on inventory version field
  - e.g. mssql_version: "2019" → MSSQL2019_ruby/controls/
```

### The Gap

There is **no step that validates CMDB-provided data against the actual database**. The version from ServiceNow flows straight through to profile selection with no verification.

### Version-to-Controls Mapping (What's at Stake)

| Platform | Version Field | Controls Directory | Control Count |
|----------|--------------|-------------------|---------------|
| MSSQL | `mssql_version: "2016"` | `MSSQL2016_ruby/` | 46 controls |
| MSSQL | `mssql_version: "2019"` | `MSSQL2019_ruby/` | 69 controls |
| MSSQL | `mssql_version: "2022"` | `MSSQL2022_ruby/` | TBD |
| Oracle | `oracle_version: "11g"` | `ORACLE11g_ruby/` | 91 controls (traditional audit) |
| Oracle | `oracle_version: "19c"` | `ORACLE19c_ruby/` | 91 controls (unified audit) |
| Sybase | `sybase_version: "15"` | `SYBASE15_ruby/` | TBD |
| Sybase | `sybase_version: "16"` | `SYBASE16_ruby/` | TBD |

A version mismatch doesn't just mean wrong control counts - it means **fundamentally different SQL queries** being run (e.g. Oracle 11g uses traditional audit vs 19c uses unified audit).

---

## 4. Can We Build a Sanitisation Role? - YES

### Recommended Architecture: `inventory_sanitise` Role

A dedicated Ansible role that sits between inventory loading and compliance scanning. It queries each target database to validate and correct CMDB-supplied metadata before controls are applied.

```
ServiceNow Data ──▶ Inventory YAML ──▶ inventory_sanitise role ──▶ Corrected Facts ──▶ Compliance Scan
                                              │
                                              ├─ Query actual DB version
                                              ├─ Verify port/connectivity
                                              ├─ Validate instance name
                                              ├─ Check DB is alive/responding
                                              └─ Flag discrepancies for reporting
```

### What the Role Would Do

#### Phase 1: Connectivity Validation
```yaml
# Verify the target is reachable on the claimed port
- name: Test database connectivity
  ansible.builtin.wait_for:
    host: "{{ db_server }}"
    port: "{{ db_port }}"
    timeout: 10
  register: connectivity_result
  ignore_errors: true
```

#### Phase 2: Actual Version Detection

**MSSQL:**
```sql
-- Returns e.g. "Microsoft SQL Server 2019 (RTM-CU18)"
SELECT @@VERSION;
-- Or more structured:
SELECT SERVERPROPERTY('ProductVersion'),    -- e.g. 15.0.2000.5
       SERVERPROPERTY('ProductMajorVersion'), -- e.g. 15
       SERVERPROPERTY('Edition');             -- e.g. Enterprise Edition
```

**Oracle:**
```sql
-- Returns e.g. "Oracle Database 19c Enterprise Edition Release 19.0.0.0.0"
SELECT * FROM V$VERSION WHERE BANNER LIKE 'Oracle%';
-- Or:
SELECT VERSION FROM V$INSTANCE;
```

**Sybase:**
```sql
-- Returns version string
SELECT @@VERSION;
-- e.g. "Adaptive Server Enterprise/16.0 SP04 PL01/..."
```

#### Phase 3: Version Normalisation & Comparison

```yaml
# Map detected version to our supported version identifiers
# MSSQL: "15.0.x" → "2019", "16.0.x" → "2022", "14.0.x" → "2017"
# Oracle: "19.x" → "19c", "12.x" → "12c", "11.x" → "11g"
# Sybase: "16.x" → "16", "15.x" → "15"

- name: Set corrected version fact
  ansible.builtin.set_fact:
    sanitised_mssql_version: "{{ detected_version_map[detected_major_version] }}"
    version_mismatch: "{{ mssql_version != detected_version_map[detected_major_version] }}"
```

#### Phase 4: Discrepancy Reporting

```yaml
- name: Log version mismatch warning
  ansible.builtin.debug:
    msg: >
      CMDB DISCREPANCY: {{ inventory_hostname }}
      CMDB says: {{ mssql_version }}
      Actual: {{ sanitised_mssql_version }}
      Action: Using actual version for compliance scan
  when: version_mismatch | bool

- name: Record discrepancy for CMDB feedback report
  ansible.builtin.set_fact:
    cmdb_discrepancies: "{{ cmdb_discrepancies | default([]) + [discrepancy_record] }}"
  when: version_mismatch | bool
```

#### Phase 5: Override Inventory Variables

```yaml
# Replace CMDB-supplied version with detected version
- name: Override version with detected value
  ansible.builtin.set_fact:
    mssql_version: "{{ sanitised_mssql_version }}"
  when: version_mismatch | bool and sanitised_mssql_version in supported_mssql_versions
```

### Role Structure

```
roles/inventory_sanitise/
├── defaults/main.yml          # Version mapping tables, thresholds
├── tasks/
│   ├── main.yml               # Entry point - dispatch by platform
│   ├── sanitise_mssql.yml     # MSSQL version detection & validation
│   ├── sanitise_oracle.yml    # Oracle version detection & validation
│   ├── sanitise_sybase.yml    # Sybase version detection & validation
│   └── report_discrepancies.yml  # Generate CMDB accuracy report
├── vars/
│   └── main.yml               # Version mapping dictionaries
└── templates/
    └── cmdb_discrepancy_report.json.j2  # Discrepancy report template
```

### Version Mapping Tables

```yaml
# vars/main.yml
mssql_major_version_map:
  "16": "2022"
  "15": "2019"
  "14": "2017"
  "13": "2016"

oracle_version_map:
  "19": "19c"
  "18": "18c"
  "12": "12c"
  "11": "11g"

sybase_version_map:
  "16": "16"
  "15": "15"
```

---

## 5. Does the Ansible ServiceNow Module Help? - YES, Significantly

The `servicenow.itsm` collection (v2.13.x, Red Hat certified) provides direct CMDB query capabilities that could **replace the current flat-file export workflow entirely**.

### Key Modules for Our Use Case

| Module | How It Helps Us |
|--------|----------------|
| `servicenow.itsm.configuration_item_info` | Query database CIs by class (`cmdb_ci_db_mssql_instance`, `cmdb_ci_db_ora_instance`, `cmdb_ci_db_syb_instance`) |
| `servicenow.itsm.api_info` | Query any CMDB table, including relationship tables |
| `servicenow.itsm.configuration_item_relations_info` | Get "Runs on" relationships (DB → Server) |
| `servicenow.itsm.now` (inventory plugin) | **Dynamic inventory directly from CMDB** - no flat file needed |
| `servicenow.itsm.configuration_item` | Write back corrected data to CMDB (future) |

### Relevant ServiceNow CMDB Tables

| Table | Description |
|-------|-------------|
| `cmdb_ci_db_mssql_instance` | MSSQL instances (version, edition, port, instance_name) |
| `cmdb_ci_db_ora_instance` | Oracle instances (version, oracle_home, SID) |
| `cmdb_ci_db_sybase` | Sybase instances (version, instance_name) |
| `cmdb_ci_db_instance` | Base class for all DB instances |
| `cmdb_ci_db_mssql_catalog` | Individual MSSQL databases within an instance |
| `cmdb_ci_db_ora_catalog` | Individual Oracle databases (PDBs) |
| `cmdb_ci_db_syb_catalog` | Individual Sybase databases |
| `cmdb_rel_ci` | Relationship table (DB "Runs on" Server) |

### Option A: Direct CMDB Query (Replace Flat File)

```yaml
- name: Query MSSQL instances from ServiceNow CMDB
  servicenow.itsm.configuration_item_info:
    instance:
      host: "https://{{ snow_instance }}.service-now.com"
      username: "{{ snow_username }}"
      password: "{{ snow_password }}"
    sys_class_name: cmdb_ci_db_mssql_instance
    query:
      - operational_status: "= 1"
        install_status: "= 1"
    return_fields:
      - name
      - ip_address
      - version
      - tcp_port
      - host_name
      - instance_name
  register: mssql_from_cmdb
```

### Option B: Dynamic Inventory Plugin (Eliminate Inventory Files)

```yaml
# snow_inventory.now.yml
plugin: servicenow.itsm.now
table: cmdb_ci_db_instance
columns:
  - name
  - ip_address
  - sys_class_name
  - version
  - tcp_port
  - operational_status
  - host_name
query:
  - operational_status: "= 1"
    install_status: "= 1"
keyed_groups:
  - key: sn_sys_class_name
    prefix: db_type
compose:
  ansible_host: sn_ip_address
  db_version: sn_version
  db_port: sn_tcp_port
```

### Authentication Options

The collection supports methods compatible with AAP2:
- Basic auth (username/password)
- OAuth2 (password grant, client credentials, refresh token)
- API key
- Client certificate
- Environment variables (`SN_HOST`, `SN_USERNAME`, `SN_PASSWORD`)

All can be mapped to AAP2 credential types.

---

## 6. ServiceNow API Access Requirements

To query ServiceNow CMDB via the `servicenow.itsm` collection, the following access must be provisioned.

### Service Account

| Requirement | Detail |
|---|---|
| **Account type** | Non-personal service account (not tied to an individual) |
| **License** | Must have a ServiceNow license that includes REST API access |
| **MFA** | Service accounts typically need MFA exclusion for API usage |

### Required ServiceNow Roles

| Role | Purpose | Required? |
|---|---|---|
| `itil` | Base ITSM access, read CIs | Yes (for `configuration_item_info`) |
| `cmdb_read` | Read-only CMDB access | Yes |
| `rest_api_explorer` | REST API access | Yes |
| `personalize_dictionary` | Read table schema/metadata | Helpful |
| `cmdb_write` | Write back corrections (Phase 3 only) | Future |

### Table-Level ACLs

The service account needs **read** ACLs on these specific tables:

- `cmdb_ci_db_mssql_instance`
- `cmdb_ci_db_ora_instance`
- `cmdb_ci_db_sybase` (note: not `_syb_instance`)
- `cmdb_ci_db_instance` (parent class)
- `cmdb_ci_db_mssql_catalog` / `cmdb_ci_db_ora_catalog` / `cmdb_ci_db_syb_catalog`
- `cmdb_rel_ci` (relationship table, for "Runs on" lookups)

### Network Requirements

```text
AAP2 Controller ──(HTTPS/443)──▶ ServiceNow Instance
       OR
Delegate Host ──(HTTPS/443)──▶ ServiceNow Instance
```

- Outbound HTTPS (port 443) to `https://<instance>.service-now.com`
- If behind a proxy, the proxy must allow this traffic
- No inbound firewall rules needed (we are only querying)

### Authentication Methods

| Method | What You Need | Best For |
|---|---|---|
| **Basic auth** | Username + password | Quick start / POC |
| **OAuth2 client credentials** | Client ID + client secret (registered OAuth app in SNOW) | Production / AAP2 (recommended) |
| **OAuth2 password grant** | Username + password + client ID + client secret | Transitional |
| **API key** | API key provisioned in ServiceNow | Simpler than OAuth |

For AAP2 integration, **OAuth2 client credentials** is recommended - the client ID/secret map cleanly to AAP2 credential types.

### AAP2 Credential Type Mapping

```yaml
# AAP2 custom credential type for ServiceNow
fields:
  - id: snow_host
    label: ServiceNow Instance URL
  - id: snow_client_id
    label: OAuth2 Client ID
  - id: snow_client_secret
    label: OAuth2 Client Secret
    secret: true

# Injected as environment variables
env:
  SN_HOST: "{{ snow_host }}"
  SN_CLIENT_ID: "{{ snow_client_id }}"
  SN_CLIENT_SECRET: "{{ snow_client_secret }}"
```

The `servicenow.itsm` modules automatically pick up `SN_HOST`, `SN_CLIENT_ID`, `SN_CLIENT_SECRET` from environment variables, so no credentials appear in playbooks.

### Ready-to-Send Access Request

> **Request:** Service account with REST API read access to CMDB database CI tables
>
> **Purpose:** Automated compliance scanning inventory - querying database assets to build scan target lists
>
> **Access needed:**
>
> - Roles: `itil`, `cmdb_read`, `rest_api_explorer`
> - Tables: `cmdb_ci_db_mssql_instance`, `cmdb_ci_db_ora_instance`, `cmdb_ci_db_sybase`, `cmdb_ci_db_instance`, `cmdb_rel_ci`
> - Access type: **Read-only** (no create/update/delete)
> - Auth method: OAuth2 client credentials (preferred) or basic auth
> - Network: Outbound HTTPS from `[DELEGATE_HOST]` to ServiceNow instance

---

## 7. Recommended Approach - Three-Phase Implementation

### Phase 1: Sanitisation Role (Immediate - Low Risk)

Build `inventory_sanitise` role that validates CMDB data against actual databases **before** running compliance scans. This works with the existing flat-file workflow.

```
Existing Flow:  SNOW export → flat file → converter → inventory → scan
Enhanced Flow:  SNOW export → flat file → converter → inventory → SANITISE → scan
```

**Effort:** ~1 sprint
**Risk:** Low - additive, doesn't change existing workflow
**Value:** Correct controls applied, discrepancy reporting

### Phase 2: Direct CMDB Query (Medium Term)

Replace flat-file export with direct ServiceNow API queries using `servicenow.itsm.configuration_item_info`. Still generates inventory YAML, but sourced live from CMDB.

```
Enhanced Flow:  SNOW CMDB API → query playbook → inventory → SANITISE → scan
```

**Effort:** ~1 sprint
**Risk:** Medium - requires ServiceNow API credentials and network access
**Dependencies:** ServiceNow service account, API access approval, network path from delegate host or AAP2

### Phase 3: Closed-Loop Feedback (Future)

Feed corrected version/metadata back to ServiceNow CMDB using `servicenow.itsm.configuration_item` module. Compliance scanning becomes a CMDB accuracy tool.

```
Full Loop:  CMDB API → query → inventory → SANITISE → scan → results
                ▲                               │
                └───── corrected metadata ◄──────┘
```

**Effort:** ~1 sprint
**Risk:** Higher - writing to CMDB requires change management approval
**Dependencies:** CMDB write permissions, IRE reconciliation rules, change approval

---

## 8. Integration with Existing Roles

The sanitisation role would be called **before** the platform-specific scan roles:

```yaml
# run_compliance_scans.yml (enhanced)
---
- name: Sanitise inventory data
  hosts: all_databases
  gather_facts: false
  roles:
    - role: inventory_sanitise
      tags: [sanitise, preflight]

- name: Run MSSQL compliance scans
  hosts: mssql_databases
  gather_facts: false
  roles:
    - role: mssql_inspec
      tags: [mssql, scan]

- name: Run Oracle compliance scans
  hosts: oracle_databases
  gather_facts: false
  roles:
    - role: oracle_inspec
      tags: [oracle, scan]

- name: Run Sybase compliance scans
  hosts: sybase_databases
  gather_facts: false
  roles:
    - role: sybase_inspec
      tags: [sybase, scan]
```

Each existing role's `validate.yml` already checks that the version is in the supported list - the sanitisation role ensures the version is **correct** before that check happens.

---

## 9. Discrepancy Report Output

The sanitisation role should produce a structured report:

```json
{
  "scan_id": "CMDB_AUDIT_20260304_143022",
  "total_targets": 205,
  "reachable": 198,
  "unreachable": 7,
  "version_mismatches": 23,
  "discrepancies": [
    {
      "host": "[DB_SERVER]",
      "platform": "MSSQL",
      "cmdb_version": "2016",
      "actual_version": "2019",
      "cmdb_port": 1433,
      "actual_port": 1433,
      "action_taken": "overridden_to_actual",
      "severity": "HIGH"
    },
    {
      "host": "[DB_SERVER]",
      "platform": "Oracle",
      "cmdb_version": "12c",
      "actual_version": "19c",
      "cmdb_port": 1521,
      "actual_port": 1521,
      "action_taken": "overridden_to_actual",
      "severity": "HIGH"
    },
    {
      "host": "[DB_SERVER]",
      "platform": "Sybase",
      "status": "unreachable",
      "cmdb_status": "operational",
      "action_taken": "skipped",
      "severity": "MEDIUM"
    }
  ]
}
```

This report serves dual purposes:
1. **Audit trail** for compliance - proves correct controls were applied
2. **CMDB feedback** - can be sent to ServiceNow team for remediation

---

## 10. Key Findings Summary

| Question | Answer |
|----------|--------|
| Can we build a sanitisation role? | **Yes** - query actual DB version, compare with CMDB, override if different |
| Does `servicenow.itsm` help with querying? | **Yes** - can query CMDB directly, supports all our DB types, Red Hat certified |
| Can we eliminate the flat file? | **Yes** - dynamic inventory plugin or query playbook can replace it |
| Can we feed corrections back to CMDB? | **Yes** - `configuration_item` module supports updates (requires permissions) |
| What's the biggest risk? | Sybase - least mature Discovery support, sparsest CMDB data |
| What should we do first? | Build the sanitisation role - it works with existing workflow, immediate value |

---

## 11. Open Questions for Stakeholders

1. **ServiceNow API access** - Do we have (or can we get) a service account with read access to CMDB database CI tables?
2. **Network path** - Can the delegate host reach the ServiceNow instance API endpoint?
3. **CMDB write permissions** - For Phase 3 closed-loop, would we be granted write access to update version fields?
4. **Discovery coverage** - Which network segments are currently covered by ServiceNow Discovery? Are our database segments included?
5. **Override policy** - Should the sanitisation role automatically override CMDB versions, or flag-and-pause for human review?
6. **Scan behaviour on mismatch** - If CMDB says "2016" but actual is "2022" (unsupported), should we skip the host or fail the play?

---

## Appendix A: ServiceNow CMDB Database CI Hierarchy

```
cmdb_ci (base)
  └── cmdb_ci_appl (Application)
        └── cmdb_ci_db_instance (Database Instance)
              ├── cmdb_ci_db_mssql_instance
              │     Fields: instance_name, version, version_name, edition, tcp_port
              ├── cmdb_ci_db_ora_instance
              │     Fields: instance_name (SID), version, oracle_home
              ├── cmdb_ci_db_sybase
              │     Fields: instance_name, version
              ├── cmdb_ci_db_mysql_instance
              ├── cmdb_ci_db_postgresql_instance
              └── cmdb_ci_db_db2_instance
```

## Appendix B: `servicenow.itsm` Module Quick Reference

| Task | Module | Key Parameter |
|------|--------|---------------|
| Query DB instances | `configuration_item_info` | `sys_class_name: cmdb_ci_db_mssql_instance` |
| Query any table | `api_info` | `resource: cmdb_ci_db_instance` |
| Get CI relationships | `configuration_item_relations_info` | parent/child sys_id |
| Dynamic inventory | `now` inventory plugin | `table: cmdb_ci_db_instance` |
| Update CI record | `configuration_item` | `sys_id`, updated fields |
| Batch update CIs | `configuration_item_batch` | list of CI updates |

## Appendix C: Version Detection SQL Queries

### MSSQL
```sql
SELECT SERVERPROPERTY('ProductVersion') AS full_version,      -- 15.0.2000.5
       SERVERPROPERTY('ProductMajorVersion') AS major_version, -- 15
       SERVERPROPERTY('ProductLevel') AS service_pack,         -- RTM / SP1 / CU18
       SERVERPROPERTY('Edition') AS edition;                   -- Enterprise Edition
-- Major version mapping: 16→2022, 15→2019, 14→2017, 13→2016
```

### Oracle
```sql
SELECT VERSION FROM V$INSTANCE;              -- 19.0.0.0.0
SELECT BANNER FROM V$VERSION WHERE ROWNUM=1; -- Oracle Database 19c ...
-- Major version mapping: 19→19c, 18→18c, 12→12c, 11→11g
```

### Sybase
```sql
SELECT @@VERSION;
-- Returns: "Adaptive Server Enterprise/16.0 SP04 PL01/..."
-- Parse first version number: 16→16, 15→15
```
