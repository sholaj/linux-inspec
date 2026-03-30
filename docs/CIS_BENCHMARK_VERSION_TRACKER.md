# CIS Benchmark Version Tracker

Tracks internally certified CIS benchmark versions against latest public releases.
Ensures compliance percentages are measured against the correct baseline.

## Current Certified Versions

| Platform | DB Version | CIS Benchmark | Certified Version | Latest Public | Profile Path | Controls | Certification Date |
|----------|-----------|---------------|-------------------|---------------|--------------|----------|-------------------|
| MSSQL | 2016 | CIS Microsoft SQL Server 2016 | v1.3.0 | TBD | `roles/mssql_inspec/files/MSSQL2016_ruby/` | 46 | TBD |
| MSSQL | 2017 | CIS Microsoft SQL Server 2017 | v1.3.0 | TBD | `roles/mssql_inspec/files/MSSQL2017_ruby/` | 68 | TBD |
| MSSQL | 2019 | CIS Microsoft SQL Server 2019 | v1.3.0 | TBD | `roles/mssql_inspec/files/MSSQL2019_ruby/` | 69 | TBD |
| MSSQL | 2022 | CIS Microsoft SQL Server 2022 | v1.0.0 | TBD | `roles/mssql_inspec/files/MSSQL2022_ruby/` | 72 | TBD |
| Oracle | 12c | CIS Oracle Database 12c | v1.1.0 | TBD | `roles/oracle_inspec/files/ORACLE12_ruby/` | 91 | TBD |
| Oracle | 18c | CIS Oracle Database 18c | v1.1.0 | TBD | `roles/oracle_inspec/files/ORACLE18_ruby/` | 91 | TBD |
| Oracle | 19c | CIS Oracle Database 19c | v1.1.0 | TBD | `roles/oracle_inspec/files/ORACLE19_ruby/` | 91 | TBD |

> **Action required:** Fill in `Certification Date` with the date your Security/Compliance team formally adopted each version.
> **Action required:** Fill in `Latest Public` by checking [cisecurity.org/benchmark](https://www.cisecurity.org/cis-benchmarks) for current releases.

---

## Version Upgrade Process

### Step 1: Monitor
- Subscribe to CIS benchmark release notifications at [cisecurity.org](https://www.cisecurity.org)
- Check quarterly for new benchmark releases

### Step 2: Gap Analysis
When a new CIS version is published, create a delta record below and compare against current controls.

### Step 3: Pre-build Controls
Implement new/changed controls in a feature branch. Add waiver entries (see below) so they don't affect compliance scores until certified.

### Step 4: Internal Certification
Submit new controls to Security/Compliance team for review and formal adoption.

### Step 5: Activate
- Remove waiver entries for newly certified controls
- Update the `Certified Version` column above
- Update `inspec.yml` profile metadata
- Update control file headers

---

## Delta Log

Record version changes here when a new CIS benchmark is evaluated.

### Template

```markdown
#### [Platform] [Version]: v[old] -> v[new]
- **Date evaluated:** YYYY-MM-DD
- **Evaluated by:** [TEAM_MEMBER]
- **New controls added:** [count]
  - [control-id]: [title]
- **Controls modified:** [count]
  - [control-id]: [description of change]
- **Controls removed:** [count]
  - [control-id]: [reason]
- **Internal certification status:** Pending / Approved (YYYY-MM-DD) / Rejected
- **JIRA ticket:** DBSCAN-XXX
```

### Example

#### MSSQL 2019: v1.3.0 -> v1.5.0
- **Date evaluated:** TBD
- **Evaluated by:** TBD
- **New controls added:** TBD
- **Controls modified:** TBD
- **Controls removed:** TBD
- **Internal certification status:** Pending
- **JIRA ticket:** TBD

---

## Waiver File Usage

Use InSpec waiver files to include pre-built controls that are not yet internally certified.
This allows controls to exist in code without affecting compliance scores.

### Waiver File Locations

Every InSpec profile has a waiver directory:

```
roles/mssql_inspec/files/
├── MSSQL2008_ruby/waivers/pending_certification.yml
├── MSSQL2012_ruby/waivers/pending_certification.yml
├── MSSQL2014_ruby/waivers/pending_certification.yml
├── MSSQL2016_ruby/waivers/pending_certification.yml
├── MSSQL2017_ruby/waivers/pending_certification.yml
├── MSSQL2018_ruby/waivers/pending_certification.yml
├── MSSQL2019_ruby/waivers/pending_certification.yml
└── MSSQL2022_ruby/waivers/pending_certification.yml

roles/oracle_inspec/files/
├── ORACLE11_ruby/waivers/pending_certification.yml
├── ORACLE12_ruby/waivers/pending_certification.yml
├── ORACLE18_ruby/waivers/pending_certification.yml
└── ORACLE19_ruby/waivers/pending_certification.yml

roles/postgres_inspec/files/
└── POSTGRES15_ruby/waivers/pending_certification.yml

roles/sybase_inspec/files/
├── SYBASE15_ruby/waivers/pending_certification.yml
└── SYBASE16_ruby/waivers/pending_certification.yml
```

### Waiver File Format

```yaml
# waivers/pending_certification.yml
# Controls implemented but pending internal certification
# These controls will NOT run or affect compliance scores
#
# Remove entries from this file once the control is certified

mssql-2019-2.19:
  justification: "New in CIS v1.5.0 - pending internal certification (DBSCAN-XXX)"
  run: false

mssql-2019-2.20:
  justification: "New in CIS v1.5.0 - pending internal certification (DBSCAN-XXX)"
  run: false
```

### Running with Waivers

```bash
# Standard scan (certified controls only)
inspec exec MSSQL2019_ruby/ \
  --waiver-file MSSQL2019_ruby/waivers/pending_certification.yml \
  --input usernm=scan_user passwd=xxx hostnm=server port=1433

# Full scan including pending controls (for testing/preview)
inspec exec MSSQL2019_ruby/ \
  --input usernm=scan_user passwd=xxx hostnm=server port=1433
```

### Ansible Integration

```yaml
# In roles/mssql_inspec/tasks/main.yml, add waiver support:
- name: Run InSpec with waivers
  ansible.builtin.command: >
    inspec exec {{ inspec_profile_path }}
    --waiver-file {{ inspec_profile_path }}/waivers/pending_certification.yml
    --input usernm={{ mssql_username }} passwd={{ mssql_password }}
    hostnm={{ mssql_server }} port={{ mssql_port }}
    --reporter json:{{ inspec_output_file }}
  when: use_waivers | default(true) | bool
```

---

## Profile Metadata Requirements

Each `inspec.yml` must include the certified CIS benchmark version. Update when version changes:

```yaml
name: mssql-2019-cis
title: CIS Microsoft SQL Server 2019 Benchmark
version: 1.0.0
summary: >
  InSpec profile for CIS Microsoft SQL Server 2019 compliance.
  CIS Benchmark Version: v1.3.0 (internally certified YYYY-MM-DD).
```

---

## Runtime CIS Version Display

The CIS benchmark version is extracted from the `inspec.yml` summary field at runtime and displayed in two places:

### 1. Scan Start Banner (in Ansible output)

```
╔══════════════════════════════════════════════════════════════════╗
║  MSSQL InSpec Compliance Scan                                    ║
╠══════════════════════════════════════════════════════════════════╣
║  Server:          [DB_SERVER]:1433
║  Database:        master
║  MSSQL Version:   2019
║  Profile:         mssql-2019-cis v1.0.0
║  CIS Benchmark:   v1.3.0
╚══════════════════════════════════════════════════════════════════╝
```

### 2. Summary Report (written to file)

The summary report (`summary_*.txt`) includes a CIS Benchmark Information section showing the profile name, version, and CIS benchmark version.

### Implementation

The version is extracted in each role's `setup.yml` using:
- `roles/mssql_inspec/tasks/setup.yml` — reads `inspec.yml`, extracts `CIS Benchmark Version vX.Y.Z` from summary
- `roles/oracle_inspec/tasks/setup.yml` — same pattern for Oracle

The extracted facts are:
- `_cis_benchmark_version` — e.g., `v1.3.0`
- `_inspec_profile_name` — e.g., `mssql-2019-cis`
- `_inspec_profile_version` — e.g., `1.0.0`

---

## Compliance Reporting

When generating compliance reports, always include:
1. The **certified CIS benchmark version** being measured against
2. The **profile version** from `inspec.yml`
3. The number of **waived/pending controls** excluded from the score
4. The **date of last certification review**

This ensures stakeholders understand that compliance percentage reflects the internally adopted standard, not the latest public release.
