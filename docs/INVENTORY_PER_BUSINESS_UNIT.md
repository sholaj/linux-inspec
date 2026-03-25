# Inventory Per Business Unit: Design Rationale

**Document Type:** Architecture Decision Record
**Status:** Proposed
**Date:** 2026-03-25
**Author:** [TEAM_MEMBER]

---

## Summary

This document recommends maintaining **separate AAP2 inventories per business unit** for database compliance scanning, rather than consolidating all business units into a single inventory. This approach provides operational isolation, independent scheduling, and cleaner credential management across the enterprise rollout.

---

## Context

The database compliance scanning framework scans ~100 MSSQL and ~105 Oracle databases across three business units (BU-1, BU-2, BU-3). Each business unit has:

- Its own CMDB inventory export
- Its own service accounts and credentials
- Its own network connectivity requirements (some require SSH tunnels, others connect directly)
- Its own onboarding timeline and rollout phase

The question is whether to manage these as one consolidated inventory or as separate inventories per business unit.

---

## Recommendation: Separate Inventories Per Business Unit

```
AAP2 Inventories
├── BU-1 DB Compliance
│   ├── mssql_databases (hosts with per-host vars)
│   └── oracle_databases (hosts with per-host vars)
├── BU-2 DB Compliance
│   ├── mssql_databases
│   └── oracle_databases
└── BU-3 DB Compliance
    ├── mssql_databases
    └── oracle_databases
```

Each inventory uses the **same group names** (`mssql_databases`, `oracle_databases`) and the **same playbook**. Only the inventory source and credentials change per business unit.

---

## Reasons

### 1. Credential Isolation

Each business unit has its own service accounts for database access. AAP2 injects credentials at the job template level via Custom Credential Types.

| Business Unit | Service Account | Credential Store |
|---------------|----------------|-----------------|
| BU-1 | `[BU1_SVC_ACCOUNT]` | AAP2 Credential |
| BU-2 | `[BU2_SVC_ACCOUNT]` | AAP2 Credential |
| BU-3 | `[BU3_SVC_ACCOUNT]` | AAP2 Credential |

With separate inventories, each job template maps to exactly one credential. With a single inventory, credentials would need to be per-host or per-group, which AAP2 does not natively support for Custom Credential Types - the credential is injected as extra vars at the job level, not the host level.

**Risk of single inventory:** A single job template cannot inject different `mssql_password` values for different hosts. You would need workarounds (vault per host, lookup plugins) that add complexity and reduce auditability.

### 2. Independent Rollout Phases

Business units are onboarded at different times:

```
BU-1: ████████████ Production (scanning live)
BU-2: ████████░░░░ MVP (validating)
BU-3: ████░░░░░░░░ Onboarding (not ready)
```

With separate inventories:
- BU-1 scans run on schedule without disruption
- BU-2 can be tested independently without affecting BU-1
- BU-3 inventory does not exist yet - no risk of accidental scanning

With a single inventory, adding BU-3 hosts requires careful use of `--limit` flags or host grouping to prevent scanning databases that are not yet ready for compliance checks.

### 3. Different Connectivity Patterns

Some business units require SSH tunnel-based connectivity while others connect directly to databases:

| Business Unit | Connectivity | Playbook Behaviour |
|---------------|-------------|-------------------|
| BU-1 | SSH tunnel via `localhost` | `business_unit == target_bu` triggers tunnel |
| BU-2 | Direct connection | Standard `db_server:db_port` |
| BU-3 | TBD | Will be configured during onboarding |

The `business_unit` group var drives this logic cleanly at the inventory level. Mixing connectivity patterns in a single inventory increases the risk of misconfiguration.

### 4. Independent Scheduling

Each business unit may require different scan frequencies based on regulatory requirements, change windows, and database team availability:

| Business Unit | Schedule | Batch Size | Window |
|---------------|----------|-----------|--------|
| BU-1 | Monthly | 50 | Saturday 02:00-06:00 |
| BU-2 | Weekly | 30 | Sunday 00:00-04:00 |
| BU-3 | TBD | TBD | TBD |

Separate inventories map to separate AAP2 job templates, each with its own schedule. A single inventory would require a single job template with complex `--limit` logic per schedule.

### 5. Blast Radius Control

If a scan job fails (expired credentials, network outage, database maintenance), the failure is contained to one business unit:

- **Separate inventories:** BU-1 credential expires → BU-1 scans fail → BU-2 and BU-3 unaffected
- **Single inventory:** Depending on failure mode, all scans could be blocked or produce incomplete results

### 6. CMDB Source Alignment

Each business unit provides its own CMDB export with different:
- Validation states and readiness levels
- Server naming conventions and domains
- Permission assignment workflows
- Support group ownership

The CMDB converter (`convert_cmdb_to_inventory.yml`) runs per-BU CSV file, producing a clean inventory per business unit. This aligns naturally with how the source data is managed.

### 7. Audit and Compliance Reporting

Separate inventories enable per-BU compliance reporting:
- "BU-1 scanned 40 MSSQL servers on 2026-03-01, 100% coverage"
- "BU-2 scanned 28 of 30 MSSQL servers, 2 unreachable"

With a single inventory, extracting per-BU metrics requires post-processing of scan results rather than simply querying AAP2 job history per job template.

---

## AAP2 Implementation

### Job Template Structure

```
Job Template: "[BU_NAME] MSSQL Compliance Scan"
├── Inventory:    [BU_NAME] DB Compliance
├── Project:      Database Compliance Scanning
├── Playbook:     test_playbooks/run_mssql_inspec.yml
├── Credentials:
│   ├── Machine Credential (SSH to delegate host)
│   └── [BU_NAME] DB Credential (mssql_username/mssql_password)
├── Extra Variables:
│   ├── host_group: mssql_databases
│   ├── target_bu: [BU_ID]
│   ├── batch_size: 50
│   └── debug_mode: false
├── Schedule:     Per-BU schedule
└── Limit:        (none needed - entire inventory is one BU)
```

### Inventory Generation Workflow

```bash
# Per business unit, run the CMDB converter
ansible-playbook inventory_converter/convert_cmdb_to_inventory.yml \
  -e "cmdb_mssql_csv=/path/to/bu1_mssql.csv" \
  -e "cmdb_oracle_csv=/path/to/bu1_oracle.csv" \
  -e "inventory_output=bu1_inventory.yml" \
  -e "target_bu=[BU_ID]"
```

The generated inventory is then uploaded to AAP2 as a static inventory source, or synced via SCM if stored in the project repository (with sensitive hostnames excluded via `.gitignore`).

---

## Trade-offs

### What We Lose With Separate Inventories

| Concern | Mitigation |
|---------|-----------|
| More job templates to manage | Use AAP2 Workflow Templates to orchestrate multi-BU scans |
| Duplicated playbook configuration | Same playbook, same project - only inventory/credential changes |
| Cross-BU reporting requires aggregation | Post-processing of per-BU results, or Splunk dashboards |
| Inventory maintenance overhead | Automated via CMDB converter - one command per BU |

### When a Single Inventory Would Be Appropriate

A consolidated inventory could work if:
- All business units share the same service account (unlikely in enterprise banking)
- All business units use identical connectivity patterns (not the case)
- All business units are at the same rollout phase (not the case)
- There is no requirement for independent scheduling (there is)

None of these conditions currently apply.

---

## Decision

Maintain **separate AAP2 inventories per business unit** for database compliance scanning. The same playbooks, roles, and InSpec profiles are shared across all business units - only the inventory and credentials are BU-specific.

This approach scales naturally as new affiliates are onboarded: create a new inventory from their CMDB export, attach the appropriate credentials, and schedule scans independently.
