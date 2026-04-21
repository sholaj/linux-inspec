# CIS Benchmark Profile Demand — DBSCAN-756

Demand list for the Chef Automate platform team: which CIS InSpec
profiles need to be published (or uplifted) to satisfy the SME-approved
versions for database compliance scanning.

> **Generated:** 2026-04-21
> **Driver:** internal SME approved the target CIS profile version per
> engine. Local `inspec_cis_database` has been updated to match the SME
> set as placeholder stubs; Chef is the authoritative source for the
> real control content.

## SME-approved target versions

| Platform | Engine version | Required CIS profile ver |
|---|---|---|
| Oracle | 12.1.0.2.0 (12c) | v3.0.0 |
| Oracle | 19              | v1.2.0 |
| Oracle | 21              | v1.2.0 (same controls as 19c per SME) |
| Oracle | 23              | v1.1.0 |
| MSSQL  | 2012            | v1.6.0 |
| MSSQL  | 2014            | v1.5.0 |
| MSSQL  | 2016            | v1.4.0 |
| MSSQL  | 2017            | v1.3.0 |
| MSSQL  | 2019            | v1.5.0 |
| MSSQL  | 2022            | v1.1.0 |

Sybase and PostgreSQL are **out of scope** for this SME alignment —
existing `ssc-cis-sybase15/16-1.0.0-1` and `ssc-cis-postgres15-1.0.0-1`
profiles are untouched.

## Gap summary

| Platform / Version | SME target | Currently on Chef Automate | Action |
|---|---|---|---|
| MSSQL 2012 | v1.6.0 | ❌ not published | 🔴 Publish v1.6.0 |
| MSSQL 2014 | v1.5.0 | ❌ not published | 🔴 Publish v1.5.0 |
| MSSQL 2016 | v1.4.0 | v1.3.0-2 (L1 Database Engine + AWS RDS) | 🟡 Uplift 1.3.0 → 1.4.0 |
| MSSQL 2017 | v1.3.0 | v1.2.0-1 (L1 Database Engine + AWS RDS) | 🟡 Uplift 1.2.0 → 1.3.0 |
| MSSQL 2019 | v1.5.0 | v1.2.0-1 (L1 + L2, Database Engine + AWS RDS) | 🟡 Uplift 1.2.0 → 1.5.0 |
| MSSQL 2022 | v1.1.0 | ❌ not published | 🔴 Publish v1.1.0 |
| Oracle 12c (12.1.0.2.0) | v3.0.0 | v3.0.0-2 (6 audit-mode variants) | 🟢 **Available now** — download Linux RDBMS Traditional Auditing |
| Oracle 19c | v1.2.0 | v1.0.0-1 (6 audit-mode variants) | 🟡 Uplift 1.0.0 → 1.2.0 |
| Oracle 21c | v1.2.0 | ❌ not published | 🔴 Publish v1.2.0 (same controls as 19c) |
| Oracle 23c | v1.1.0 | ❌ not published | 🔴 Publish v1.1.0 |

**Summary counts:** 1 ready to download • 4 need uplift • 5 need fresh publish.

## Local repo state

`inspec_cis_database/cis/files/profiles/` has been realigned to the SME
set (directory names retain the `-1.0.0-1` local suffix so the role's
path resolver doesn't need to change; the CIS profile version lives in
each `inspec.yml` file's `version:` and `summary:` fields):

- Removed: `ssc-cis-mssql2008-*`, `ssc-cis-mssql2018-*`,
  `ssc-cis-oracle11-*`, `ssc-cis-oracle18-*`
- Version-bumped: all 6 MSSQL + Oracle 12c / 19c
- New stubs: `ssc-cis-oracle21-1.0.0-1/` and
  `ssc-cis-oracle23-1.0.0-1/`

The controls content is still the original placeholder `trusted.rb`.
Once Chef publishes the real tarballs (per the JIRA below), they get
downloaded and unpacked into these directories, replacing the
placeholder content.

## JIRA ticket body (copy-paste ready)

Paste the block below into a new JIRA ticket addressed to the Chef
Automate / Compliance Platform team. Suggested ticket header:

- **Summary:** Publish missing / uplift CIS database benchmark profiles
  for DBSCAN-756
- **Type:** Request
- **Priority:** High (blocking DB compliance scan rollout)

```text
Hi Chef/Compliance team,

As part of DBSCAN-756 (database compliance scanning automation), our
internal SME has approved the following CIS InSpec benchmark versions
per database engine. Most are either not currently available on the
Chef Automate profile catalogue, or published at an older version.

Please publish the versions below to the Chef Automate compliance
profile catalogue so our project team can "Get" them through the
standard UI (https://itsrhv123231.it.statestr.com/compliance/compliance-profiles).

--- PUBLISH NEW (5) ---
- CIS Microsoft SQL Server 2012 Benchmark Level 1 - Database Engine, v1.6.0
- CIS Microsoft SQL Server 2014 Benchmark Level 1 - Database Engine, v1.5.0
- CIS Microsoft SQL Server 2022 Benchmark Level 1 - Database Engine, v1.1.0
- CIS Oracle Database 21c Benchmark Level 1 - Linux RDBMS (Traditional Auditing), v1.2.0
  (controls identical to 19c per SME)
- CIS Oracle Database 23c Benchmark Level 1 - Linux RDBMS (Traditional Auditing), v1.1.0

--- UPLIFT EXISTING (4) ---
- CIS Microsoft SQL Server 2016 Benchmark Level 1 - Database Engine
  Current: v1.3.0-2   Needed: v1.4.0
- CIS Microsoft SQL Server 2017 Benchmark Level 1 - Database Engine
  Current: v1.2.0-1   Needed: v1.3.0
- CIS Microsoft SQL Server 2019 Benchmark Level 1 - Database Engine
  Current: v1.2.0-1   Needed: v1.5.0
- CIS Oracle Database 19c Benchmark Level 1 - Linux RDBMS (Traditional Auditing)
  Current: v1.0.0-1   Needed: v1.2.0

--- ALREADY AVAILABLE (1, for reference only) ---
- CIS Oracle Database 12c (12.1.0.2.0) Benchmark Level 1 -
  Linux Host OS RDBMS using Traditional Auditing, v3.0.0-2 ✓
  We will download this one through the existing UI — no action needed.

Scope notes:
- AWS RDS variants are not in scope (we scan on-prem / self-managed DBs).
- Level 2 variants are not requested unless Level 1 is a strict subset.
- Sybase and PostgreSQL are out of scope for this request.

Happy to discuss scope / priority / timing. Thanks!
```

## Follow-ups after Chef publishes

For each profile Chef adds or uplifts:

1. Click "Get" in the Chef Automate UI (downloads a `.tar.gz`).
2. Extract into
   `inspec_cis_database/cis/files/profiles/ssc-cis-<plat><ver>-1.0.0-1/`
   **replacing** the local placeholder content (keep the existing
   directory name and `inspec.yml` metadata).
3. Verify `inspec exec` still resolves inputs (usernm, passwd, hostnm,
   port, servicenm — these are already normalised in the local stubs).
4. Commit with message `update: DBSCAN-756 import CIS <plat><ver> v<x.y.z>`.

When every row in the Gap Summary shows 🟢, this document can be
archived / removed.
