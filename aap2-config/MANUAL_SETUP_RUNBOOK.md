# AAP2 Manual Pipeline Setup Runbook

**Purpose:** Step-by-step click-through to build the database compliance
scanning pipeline directly in the AAP2 Web UI. Use this when AAP2-as-code
(controller CRs, `ansible.controller` collection, `awx-cli` import) is not
available in your environment.

The YAML/JSON files in this directory (`aap2-config/`) are the **source of
truth for field values** — read them as you click through. This runbook
tells you *where* to click and *which file* to copy values from.

---

## Audience

DevOps/Platform engineer with AAP2 Organization Admin (or higher) on the
target controller. Familiarity with AAP2 navigation is assumed.

## Order of operations

Build objects bottom-up — each step depends on the ones above it.

```
1. Organization (verify exists)
2. Project (Git pull of this repo)
3. Execution Environment (db-compliance-ee)
4. Credential Types (import 5 JSON definitions)
5. Credentials (the "secrets" — one per BU per platform)
6. Inventory (one per BU OR one shared with BU groups)
7. Job Templates (one per platform)
8. Workflow Template (full multi-platform run)
9. Schedules (optional)
10. RBAC / team permissions (multi-BU isolation)
```

---

## 1. Organization

**Path:** `Access > Organizations`

Use an existing org (typically `Default`). If multiple BUs share one
controller and you need credential isolation, create one org per BU
(e.g. `db-compliance-alpha`, `db-compliance-bravo`) and scope teams,
inventories, and credentials to it. See [§9 Multi-BU pipeline pattern](#9-multi-bu-pipeline-pattern).

---

## 2. Project

**Path:** `Resources > Projects > Add`

| Field | Value |
|---|---|
| Name | `linux-inspec` |
| Organization | (your org) |
| Source Control Type | `Git` |
| Source Control URL | `<internal-git-url>/linux-inspec.git` |
| Source Control Branch | `main` (or your release branch) |
| Source Control Credential | (Git read-only PAT, see §5.6) |
| Update Revision on Launch | ✅ |
| Clean | ✅ |
| Delete on Update | ✅ |

Click **Save**, then **Sync**. Wait for `Successful` before continuing —
job templates can't reference playbooks until the project has synced once.

> **`requirements.yml`** lives at the repo root and pulls InSpec profiles
> from `inspec_cis_database`. AAP2 honors it automatically when project
> sync runs in an EE that has `ansible-galaxy` (the EE built from
> `execution-environment/` does).

---

## 3. Execution Environment

**Path:** `Administration > Execution Environments > Add`

| Field | Value |
|---|---|
| Name | `db-compliance-ee` |
| Image | `<acr-or-registry>/db-compliance-ee:<tag>` |
| Pull | `Always` |
| Registry credential | (Container Registry credential, see §5.6) |

The image is built from `execution-environment/` in this repo and contains
InSpec, sqlcmd, sqlplus, isql/FreeTDS, psql. See
[`docs/ANSIBLE_EXECUTION_ENVIRONMENT.md`](../docs/ANSIBLE_EXECUTION_ENVIRONMENT.md).

---

## 4. Credential Types (custom)

**Path:** `Administration > Credential Types > Add`

You will create five custom credential types. For each one:

1. Open the JSON file from `aap2-config/credential-types/`.
2. Copy the `name` and `description` fields into the matching UI fields.
3. Copy the `inputs` block (entire JSON object) into **Input configuration**.
4. Copy the `injectors` block into **Injector configuration**.
5. Save.

| Credential Type | Source file |
|---|---|
| MSSQL Database Credential | `credential-types/mssql-database.json` |
| Oracle Database Credential | `credential-types/oracle-database.json` |
| Sybase Database Credential | `credential-types/sybase-database.json` |
| PostgreSQL Database Credential | `credential-types/postgres-database.json` |
| Splunk HEC Credential | `credential-types/splunk-hec.json` |

> **Why custom types?** They give every BU's credential the same shape and
> the same injected variable names (`mssql_username`, `mssql_password`, …)
> so the playbooks don't need to know which BU they're scanning.

---

## 5. Credentials (the "secrets")

**This is the most error-prone step. Read carefully.**

A "credential" in AAP2 is the *instance* of a credential type — an actual
username/password pair (or token, or SSH key) that gets injected at run
time. AAP2 stores secret fields encrypted at rest with the controller's
SECRET_KEY; they are never readable through the API or UI once saved
(only re-writable).

### 5.1 Naming convention (mandatory)

Use a strict pattern so RBAC, surveys, and automation can target
credentials predictably:

```
<Platform> - <ENV> - <REGION> - <BU> - <Account>
```

Examples:

```
MSSQL - PROD - NA - ALPHA - nist_scan_user
MSSQL - PROD - NA - BRAVO - nist_scan_user
Oracle - TEST - EMEA - CHARLIE - nist_scan_user
Sybase - PROD - APAC - DELTA - nist_scan_user
```

Match the BU placeholder used in `aap2-config/inventories/aap2-inventory-example.yml`
(`alpha`, `bravo`, `charlie`, `delta`, `echo`).

### 5.2 Per-BU per-platform secret matrix

For each BU you onboard, create one credential per database platform that
BU runs. A typical BU needs all four (MSSQL, Oracle, Sybase, Postgres);
some BUs only run one platform — only create what's used.

Minimum scaffold for a single BU:

| Credential | Type | Required for |
|---|---|---|
| `MSSQL - <ENV> - <REGION> - <BU> - nist_scan_user` | MSSQL Database Credential | MSSQL job template |
| `Oracle - <ENV> - <REGION> - <BU> - nist_scan_user` | Oracle Database Credential | Oracle job template |
| `Sybase - <ENV> - <REGION> - <BU> - nist_scan_user` | Sybase Database Credential | Sybase job template |
| `Postgres - <ENV> - <REGION> - <BU> - nist_scan_user` | PostgreSQL Database Credential | Postgres job template |

### 5.3 Create each database credential

**Path:** `Resources > Credentials > Add`

| Field | Value |
|---|---|
| Name | (per §5.1 convention) |
| Description | `BU=<BU> ENV=<ENV> REGION=<REGION> Platform=<PLATFORM>` |
| Organization | (BU org, or shared org — see §9) |
| Credential Type | (matching custom type from §4) |
| Username | `nist_scan_user` (or BU-specified service account) |
| Password | (paste from password vault — see §5.5) |

For the **Sybase** credential type only, you'll also see SSL fields. Set
them per the BU's connection requirements; default `ssl_enabled=false`
unless the BU has the SAP ASE SSL listener configured (port `1063` is the
default).

> ⚠️ Do NOT type passwords into Slack, tickets, terminals with shell
> history, or screen-share tools while creating these. Paste directly
> from your password manager into the AAP2 password field.

### 5.4 Shared credentials (one-time)

Create these once for the whole controller, regardless of BU count:

| Credential | Type | Notes |
|---|---|---|
| `Delegate Host SSH Key` | Machine | SSH key + user for `[DELEGATE_HOST]` (only if running in delegate mode) |
| `Splunk HEC - <ENV>` | Splunk HEC Credential | Optional, for forwarding scan results |
| `Git Read Only PAT` | Source Control | Used by the Project (§2) |
| `Container Registry Pull` | Container Registry | Used by the EE (§3) |

For the `Delegate Host SSH Key`:
- **Authentication Method**: SSH Key
- **Username**: the OS user on the delegate (often `ansible_svc` or
  `svc_inspec`)
- **SSH Private Key**: paste the key body (must include both header and
  footer lines)
- **Private Key Passphrase**: only if the key is encrypted

### 5.5 Where the password values come from

This is the boundary between AAP2 and your enterprise secrets store.
There are three patterns; pick the one that matches your environment:

**Pattern A — Manual paste (POC / MVP only)**
DBA team hands you the password through your password manager. You paste
it into the AAP2 credential **once**. AAP2 encrypts at rest. Rotation =
DBA hands you a new value, you edit the credential.

**Pattern B — Cloakware / USM lookup at run time**
The credential's `password` field is set to a Cloakware/USM lookup
expression rather than a literal value. The injector resolves the lookup
when the job launches. Configure per your platform's pattern — there is
no first-class AAP2 lookup plugin for Cloakware out of the box; teams
typically wrap it in a custom credential type that calls the lookup CLI.

**Pattern C — CyberArk Central Credential Provider (future)**
AAP2 ships a built-in CyberArk credential type. Out of scope for the
current phase per `CLAUDE.md`. Document the design now so the
credential names line up with the future CCP target IDs.

### 5.6 Source-control & registry credentials

For the Git read-only PAT (Pattern A):

| Field | Value |
|---|---|
| Credential Type | `Source Control` |
| Username | (PAT username or `oauth2`) |
| Password / Token | (PAT) |

For the registry pull credential, choose the credential type that matches
your registry (e.g. `Container Registry`) and supply the registry URL,
service principal / token user, and secret.

---

## 6. Inventory

**Path:** `Resources > Inventories > Add inventory`

You have a choice between **one shared inventory** (simpler) or **one
inventory per BU** (cleaner RBAC). The decision drives §9.

### 6.1 Option A — one shared inventory

| Field | Value |
|---|---|
| Name | `Database Compliance Inventory` |
| Organization | (shared org) |

Add hosts/groups per `inventories/aap2-inventory-example.yml`. The
top-level structure is:

```
all
├── delegate_hosts
├── db_<bu>           (BU aggregator — vars + children-refs only)
├── mssql_databases
│   └── db_<bu>_mssql (platform subgroup — actual hosts here)
├── oracle_databases
│   └── db_<bu>_oracle
├── sybase_databases
│   └── db_<bu>_sybase
└── postgres_databases
    └── db_<bu>_postgres
```

> ⚠️ **Do not put a plain `db_<bu>` group as a direct child of multiple
> tech groups.** Ansible inventory YAML treats group names as global
> keys. A repeated `db_<bu>` under both `mssql_databases` and
> `oracle_databases` merges the host lists, polluting `mssql_databases`
> with Oracle hosts. Subgroup names must be platform-specific
> (`db_alpha_mssql`, `db_alpha_oracle`, …). The aggregator `db_alpha`
> uses `children:` to reference the platform subgroups — that's fine.

**To populate:**
1. Either upload the YAML via `Sources` (Source from Project + the path
   to the inventory file in the project), or
2. Manually click **Groups > Add** and **Hosts > Add** to mirror the
   structure. Slow for >20 hosts.

The recommended approach is **Source from Project** — point it at the
synced inventory file in the `linux-inspec` project (or better, at the
`oar_tower_inventories` project once that's synced as a separate
project).

### 6.2 Option B — one inventory per BU

| Field | Value |
|---|---|
| Name | `Database Compliance - <BU>` (e.g. `Database Compliance - ALPHA`) |
| Organization | (BU-specific org) |

Each BU's inventory contains only that BU's groups and hosts. RBAC is
trivial — grant a BU's team `Use` on its inventory and they can never
target another BU's hosts. Job templates either become per-BU
(N inventories × M platforms = N×M templates) or use a survey-driven
inventory selector (less common in AAP2).

### Decision guide

| Situation | Choose |
|---|---|
| Single team operates all BUs | A — shared |
| Each BU operates its own scans | B — per-BU |
| Cross-BU summary reports needed | A — shared (easier reporting) |
| Strict regulatory isolation between BUs | B — per-BU (or per-org) |

The remainder of this runbook assumes **Option A**. Notes for Option B
are inline.

---

## 7. Job Templates

**Path:** `Resources > Templates > Add > Add job template`

Create one per platform. Open the matching YAML in `aap2-config/job-templates/`
as you go — copy values directly.

Common fields for all four templates:

| Field | Value |
|---|---|
| Job Type | `Run` |
| Inventory | `Database Compliance Inventory` (Option A) |
| Project | `linux-inspec` |
| Execution Environment | `db-compliance-ee` |
| Verbosity | `0 (Normal)` |
| Forks | `5` |
| Timeout | `3600` |
| Concurrent Jobs | ✅ Enable (different BUs can run in parallel) |
| Survey | ✅ Enable |

Per-template values:

| Template | Playbook | Database credential to attach | Source file |
|---|---|---|---|
| `MSSQL Compliance Scan` | `test_playbooks/run_mssql_inspec.yml` | `MSSQL - <ENV> - <REGION> - <BU> - nist_scan_user` (default) | `job-templates/mssql-compliance-scan.yml` |
| `Oracle Compliance Scan` | `test_playbooks/run_oracle_inspec.yml` | `Oracle - …` | `job-templates/oracle-compliance-scan.yml` |
| `Sybase Compliance Scan` | `test_playbooks/run_sybase_inspec.yml` | `Sybase - …` | `job-templates/sybase-compliance-scan.yml` |
| `PostgreSQL Compliance Scan` | `test_playbooks/run_postgres_inspec.yml` | `Postgres - …` | `job-templates/postgres-compliance-scan.yml` |
| `Compliance Scan Summary` | `test_playbooks/compliance_scan_summary.yml` | (none — Machine cred only) | `job-templates/compliance-scan-summary.yml` |

### 7.1 Attach credentials

For each template, click **Credentials** and add:

1. The matching database credential (the *default* for the BU you scan
   most often — survey or workflow can override).
2. `Delegate Host SSH Key` (Machine credential) — required only when
   `inspec_delegate_host` is set in inventory vars.
3. (Optional) `Splunk HEC - <ENV>` if you want every run to forward.

> AAP2 allows **only one credential per credential type per template**.
> If you need to swap the BU's database credential per run, you have two
> options: (a) the workflow-level pattern in §9, or (b) prompt-on-launch
> on the Credentials field so the launching user picks the right one.

### 7.2 Extra variables

Paste the `extra_vars` block from the source YAML. The defaults are
fine; the survey overrides them at launch.

### 7.3 Survey

Click **Survey** → **Add**. Recreate each survey question from the
source YAML's `survey_spec.spec` block. The Business Unit question
(variable `host_group`) is the most important — it is what makes the
template multi-BU. Default value: `all`.

> **Option B note**: If you went per-BU on inventories, drop the
> Business Unit survey question entirely — the inventory itself scopes
> the run.

### 7.4 Prompt-on-launch fields

Enable **Prompt on launch** for:

- `Limit` — so workflow nodes can override (see §9)
- `Credentials` — so a launching user can swap the database credential
- `Survey` — already on by default if survey is enabled

---

## 8. Workflow Template

**Path:** `Resources > Templates > Add > Add workflow template`

Reference: `aap2-config/workflows/full-compliance-workflow.yml`.

| Field | Value |
|---|---|
| Name | `Full Database Compliance Workflow` |
| Organization | (your org) |
| Inventory | `Database Compliance Inventory` (or prompt-on-launch for Option B) |
| Allow Simultaneous | ❌ (default) |
| Survey | ✅ Enable — copy spec from source YAML |

Click **Save**, then **Visualizer** to wire nodes:

```
[ MSSQL ] ─success─▶ [ Oracle ] ─success─▶ [ Sybase ] ─success─▶ [ Postgres ] ─always─▶ [ Summary ]
    │                    │                     │                     │
   failure              failure               failure               failure
    └────────────────────┴─────────────────────┴─────────────────────┘
                                  │
                                  ▼
                              [ Summary ]
```

For each node:
1. Click **Start** (first node) or `+` on an existing node.
2. Choose **Job Template** as the node type.
3. Select the matching job template.
4. Set the run condition: `On Success`, `On Failure`, or `Always`.
5. **Save** the node.

Failure edges all converge to `Summary` so a partial run still produces
a report. The summary node uses `all_parents_must_converge: false` so it
fires on the first arrival.

---

## 9. Multi-BU pipeline pattern

This is where most of the design effort lives. Three patterns; pick one
**before** building Section 7. Switching later is painful.

### Pattern 1 — Survey-driven (single shared inventory)

**Best for:** Small number of BUs (≤ ~10), single ops team, shared org.

**How it works:**
- One inventory (Option A from §6).
- One job template per platform.
- Survey question `host_group` (variable name) maps to the BU
  aggregator — the launching user picks `db_alpha`, `db_bravo`, etc.
- The template's `Limit` field uses `{{ host_group }}` (or you can
  paste the BU value directly into Limit when launching).
- Database credentials: keep one default attached, prompt-on-launch
  enabled so the launcher picks `MSSQL - PROD - NA - <selected BU> - …`.

**Pros:** Few templates to maintain. Easy to add a new BU (new credential
+ new survey choice).

**Cons:** Manual selection at launch — easy to mismatch BU and
credential. Mitigate with naming convention (§5.1) and team training.

### Pattern 2 — Per-BU job templates (template fan-out)

**Best for:** ≤ ~5 BUs, strong audit requirements, scheduled runs only
(no human launch).

**How it works:**
- One inventory per BU (Option B) OR shared inventory + hard-coded
  `Limit: db_<bu>`.
- N BUs × 4 platforms = 4N templates (e.g. 5 BUs → 20 templates).
- Each template has exactly one database credential bound — no prompt,
  no survey ambiguity.
- Naming: `MSSQL Compliance Scan - ALPHA`, `MSSQL Compliance Scan - BRAVO`.

**Pros:** Zero ambiguity. Schedules trivial (one schedule per template).
RBAC trivial — grant team `Execute` on its 4 BU templates.

**Cons:** Template count explodes. Adding a new control / extra_var
means editing N templates. Use a script + `awx-cli` or
`ansible.controller` collection if you go this route to keep them in
sync — but the user said this isn't currently available, so consider
the maintenance load.

### Pattern 3 — Workflow-per-BU + shared platform templates (recommended)

**Best for:** Most production scenarios. Best balance of maintenance vs.
clarity.

**How it works:**
- Shared inventory (Option A).
- One job template per platform (4 total) — these are *generic*. Set
  prompt-on-launch on `Limit` and `Credentials`.
- One workflow template per BU. Each workflow node:
  - References the generic platform job template.
  - Overrides `Limit` to the BU's aggregator (e.g. `db_alpha`).
  - Overrides `Credentials` to the BU's database credential.
- Naming: `Full DB Compliance - ALPHA`, `Full DB Compliance - BRAVO`.

**Pros:** Platform logic lives in 4 templates. BU specifics live in
workflows (which are easier to template than templates). Schedules are
per-BU (one per workflow). RBAC: grant team `Execute` on its workflow.
A new control = edit 4 templates, BUs inherit. New BU = clone an
existing workflow + create 4 credentials.

**Cons:** Workflow node overrides are easy to forget when adding a new
node — document the override values in the workflow description.

**Build steps for Pattern 3:**

1. Build the four generic platform templates per §7 with prompt-on-launch
   enabled for `Limit` and `Credentials`.
2. For each BU:
   a. Create the workflow template (`Full DB Compliance - <BU>`).
   b. In the visualizer, add the four platform nodes + summary node
      per §8.
   c. **For each node**, click the node → **Edit** → expand
      **Prompts**:
      - Set **Limit** to `db_<bu>` (e.g. `db_alpha`).
      - Set **Credentials** to the BU's matching DB credential.
      - Save.
   d. Save the workflow.
3. Repeat for each BU.

### Pattern decision matrix

| | Pattern 1 | Pattern 2 | Pattern 3 |
|---|---|---|---|
| BU count | ≤ 10 | ≤ 5 | any |
| Template count | 4 | 4 × N | 4 |
| Workflow count | 1 | N (optional) | N |
| Schedules | per-launch | per template | per workflow |
| Risk of credential mismatch | medium | none | low |
| Effort to onboard new BU | low | high | medium |
| RBAC granularity | org-level | template-level | workflow-level |

---

## 10. Schedules (optional)

**Path:** `<template> > Schedules > Add`

Per-BU monthly scan, first Monday at 02:00 UTC:

| Field | Value |
|---|---|
| Name | `Monthly - <BU>` |
| Start Date/Time | next first Monday 02:00 UTC |
| Repeat frequency | `Monthly on the first Monday` |
| Run on launch overrides | (per Pattern 3, set Limit + Credentials) |

For Pattern 3, attach the schedule to the **workflow** (not the
platform templates) so all four platforms run.

---

## 11. RBAC (multi-BU isolation)

If multiple teams use the same controller:

1. **Teams**: `Access > Teams > Add`. One team per BU
   (`db-compliance-alpha`, `db-compliance-bravo`).
2. **Membership**: assign users.
3. **Role grants**:
   - Team → Inventory: `Use` (Pattern 1) or `Read` (Pattern 3 — they
     don't need Use because the workflow node carries the override).
   - Team → Credentials: `Use` on **only** their BU's credentials.
   - Team → Workflow: `Execute` on their workflow.
   - Team → Project: `Use` (so they can launch templates that reference
     it).
4. **Org admins**: keep this list small. Org admins can read every
   credential's metadata and rotate any password.

Rotation reminder: test the rotation workflow once per quarter.

---

## 12. Verification checklist

After every step you've finished, run this minimal smoke test:

1. **Project sync**: `Projects > linux-inspec > Sync`. Status =
   `Successful`.
2. **EE pull**: launch any template once, watch the job → first
   `Pulling image…` line should succeed.
3. **Credential injection**: launch one platform template against a
   single host (`Limit: <one-host-name>`) with `inspec_debug_mode=true`.
   In the job output, confirm the playbook authenticates against the DB.
   You should NOT see the password in stdout.
4. **Workflow run** (Pattern 3): launch the BU's workflow with
   `Limit: <one-host-name>` per platform node prompt. All five nodes
   should reach a terminal state.
5. **Result file**: SSH to the EE-mounted volume or check artifacts —
   `/tmp/compliance_scans/<platform>/<JSON file>` per the legacy
   filename convention `{PLATFORM}_NIST_{PID}_{SERVER}_{DB}_{VERSION}_{TS}_{CONTROL}.json`.

---

## 13. Common errors and fixes

| Symptom | Likely cause | Fix |
|---|---|---|
| `Project sync failed: Permission denied (publickey)` | Source Control credential missing or wrong PAT scope | Re-create §5.6 Git PAT with `repo:read` scope |
| `Could not pull image…` on EE first run | Registry credential missing or expired | Re-create §5.6 Container Registry credential |
| Job runs but `mssql_password is undefined` | Database credential not attached, or wrong credential type | Re-attach in §7.1; confirm credential type matches custom type from §4 |
| Job hits hosts from wrong platform | `db_<bu>` defined as direct child of multiple tech groups | Restructure inventory per §6.1 — use `db_<bu>_<platform>` subgroups |
| Credential mismatch (BU A creds against BU B hosts) | Pattern 1 launch error | Move to Pattern 3, or enforce naming convention + add a pre-task assertion in the playbook that compares `ssc_sn_bu` to a credential-injected BU tag |
| Workflow runs every node twice | Both success and failure edges point to the same next node and `all_parents_must_converge` is on | Set `all_parents_must_converge: false` on the convergence node (per `workflows/full-compliance-workflow.yml`) |
| Survey choice for new BU not visible | Survey choices were edited but template wasn't saved | Re-open template, re-save survey, sync project |

---

## 14. Onboarding a new BU (cheat sheet)

Once Patterns are established (Pattern 3 assumed):

1. Create the four database credentials (§5.3) using the naming convention.
2. Add `db_<newbu>` aggregator + `db_<newbu>_<platform>` subgroups to
   the inventory file in source control. Sync project.
3. Clone an existing BU workflow template. Rename to `Full DB Compliance - <NEWBU>`.
4. Edit each node's prompts: change `Limit` → `db_<newbu>`, change
   credential → matching new credential.
5. (Optional) Attach a schedule.
6. Grant the BU team `Execute` on the new workflow + `Use` on its four
   new credentials.
7. Smoke-test per §12.

Total time: ~30 min once the pattern is internalized.

---

## Related documentation

- `aap2-config/credential-types/*.json` — credential type definitions
- `aap2-config/job-templates/*.yml` — job template field values
- `aap2-config/workflows/full-compliance-workflow.yml` — workflow node graph
- `aap2-config/inventories/aap2-inventory-example.yml` — inventory shape
- `docs/AAP2_DEPLOYMENT_GUIDE.md` — deploying AAP2 itself
- `docs/AAP_CREDENTIAL_MAPPING_GUIDE.md` — credential injection details
- `docs/INVENTORY_PER_BUSINESS_UNIT.md` — inventory layout rationale
- `docs/SECURITY_PASSWORD_HANDLING.md` — password handling policy
