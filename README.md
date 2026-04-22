# Database Compliance Scanning — Execution Repository

Automated CIS benchmark compliance scanning for MSSQL, Oracle, Sybase, and PostgreSQL databases using Ansible and InSpec. Part of a 3-repository architecture following State Street enterprise patterns.

## Repository Architecture

| Repository | Purpose | Contents |
|------------|---------|----------|
| **linux-inspec** (this repo) | Execution roles and playbooks | Ansible roles, playbooks, AAP2 config, Terraform test infra |
| **inspec_cis_database** | CIS InSpec profiles | 15 profiles across 4 platforms, organized as `cis/files/profiles/` |
| **oar_tower_inventories** | Inventory by business unit | BU-based inventory files (placeholder BU names: ALPHA, BRAVO, CHARLIE, DELTA, ECHO) |

Profiles are pulled from `inspec_cis_database` via `requirements.yml`. Inventories are stored in `oar_tower_inventories` organized by business unit and environment branch.

## Project Structure

```
linux-inspec/
├── requirements.yml               # Pulls CIS profiles from inspec_cis_database
├── roles/
│   ├── mssql_inspec/              # MSSQL server-level scanning (8 versions: 2008-2022)
│   ├── oracle_inspec/             # Oracle database-level scanning (4 versions: 11-19)
│   ├── sybase_inspec/             # Sybase/SAP ASE scanning (2 versions: 15-16)
│   └── postgres_inspec/           # PostgreSQL scanning (version 15)
├── aap2-config/                   # AAP2 configuration templates
│   ├── credential-types/          # Custom credential type definitions (5 types)
│   ├── inventories/               # AAP2 inventory examples (BU-based)
│   ├── job-templates/             # Per-platform and multi-platform scan templates
│   └── workflows/                 # Full compliance workflow definition
├── test_playbooks/                # Playbooks for scanning and testing
├── terraform/                     # Azure test infrastructure
├── inventories/                   # Local test inventories
└── docs/                          # Documentation

# Inventory tooling lives in the oar_tower_inventories repo:
#   oar_tower_inventories/tools/   # CMDB/flat file → BU-based inventory converters
```

## Quick Start

### Prerequisites

- Ansible 2.14+
- InSpec 5.x (on delegate host or execution environment)
- Database client tools: `sqlcmd` (MSSQL), `sqlplus` (Oracle), `isql` (Sybase), `psql` (PostgreSQL)

### Setup

```bash
# 1. Clone and install profile dependencies
git clone <repository-url>
cd linux-inspec
ansible-galaxy role install -r requirements.yml -p requirements_roles/

# 2. Run a compliance scan (one playbook per platform)
ansible-playbook -i <inventory-file> test_playbooks/run_mssql_inspec.yml \
  -e @vault.yml --vault-password-file .vaultpass
```

### Inventory Format

One env-level inventory file per (env, region). Technology groups
(`mssql_databases`, `oracle_databases`, ...) own per-BU child groups
(`db_alpha`, `db_bravo`, ...). BU-scoped vars live on the child group.
The parent group implies the platform — no per-host `database_platform`:

```yaml
all:
  children:
    mssql_databases:
      children:
        db_alpha:
          vars:
            ssc_sn_environment: test   # Required: environment identifier
            ssc_sn_region: na          # Required: region identifier
            ssc_sn_bu: alpha           # Required: business unit identifier
            ansible_connection: local
          hosts:
            ALPHA_DBSERVER01_1433:
              mssql_server: "[DB_SERVER].example.internal"
              mssql_port: 1433
              mssql_version: "2019"
              mssql_username: nist_scan_user
```

Each single-platform playbook targets its matching tech group via
`hosts: <plat>_databases`.

### Running Scans

```bash
# All MSSQL hosts in all BUs
ansible-playbook -i inventory.yml test_playbooks/run_mssql_inspec.yml

# Limit to a specific BU
ansible-playbook -i inventory.yml test_playbooks/run_oracle_inspec.yml --limit "db_alpha"

# Other platforms
ansible-playbook -i inventory.yml test_playbooks/run_sybase_inspec.yml
ansible-playbook -i inventory.yml test_playbooks/run_postgres_inspec.yml

# Debug mode
ansible-playbook -i inventory.yml test_playbooks/run_mssql_inspec.yml -e "enable_debug=true"
```

## Controls (InSpec Profiles)

Profiles are stored in `inspec_cis_database` and pulled via `requirements.yml`:

| Platform | Versions | Profile Naming | Controls |
|----------|----------|----------------|----------|
| MSSQL | 2008-2022 (8 profiles) | `ssc-cis-mssql{ver}-{cis_version}-1` | 40-72 per version |
| Oracle | 11, 12, 18, 19 (4 profiles) | `ssc-cis-oracle{ver}-{cis_version}-1` | 91 per version |
| Sybase | 15, 16 (2 profiles) | `ssc-cis-sybase{ver}-{cis_version}-1` | 7-84 per version |
| PostgreSQL | 15 (1 profile) | `ssc-cis-postgres15-{cis_version}-1` | 59 |

`{cis_version}` is the CIS benchmark version declared in each profile's `inspec.yml` (e.g. `ssc-cis-mssql2019-1.5.0-1`). Roles discover the profile folder via a prefix glob on `ssc-cis-<plat><ver>-*`, so they remain agnostic to the benchmark-version suffix. Falls back to legacy embedded `roles/*/files/` paths if the requirements role is absent.

## AAP2 Integration

AAP2 configuration templates are in `aap2-config/`:

- **Credential Types**: MSSQL, Oracle, Sybase, PostgreSQL, Splunk HEC
- **Job Templates**: Per-platform scans with BU survey selectors
- **Workflow**: Sequential multi-platform scan with error handling

AAP2 automatically installs `requirements.yml` roles at project sync. Profiles resolve to `$AWX_PRIVATE_DATA_DIR/requirements_roles/cis/`.

## Azure Test Infrastructure

Terraform templates in `terraform/` provision a complete test environment:

```bash
cd terraform
terraform init && terraform apply

# Resources:
# - Linux runner VM (RHEL 8 with InSpec + all DB clients)
# - MSSQL container (ACI)
# - Oracle, Sybase, PostgreSQL containers (optional)
# - Nightly shutdown runbook (9 PM, saves ~50% compute costs)

terraform destroy   # When done
```

Cost analysis: `./terraform/azure-cost-analysis.sh [resource-group]`

## Execution Modes

All roles support two execution modes:

| Mode | Config | Use Case |
|------|--------|----------|
| **Localhost** | `inspec_delegate_host: ""` | InSpec runs on AAP2 EE container |
| **Delegate** | `inspec_delegate_host: "runner-host"` | InSpec runs on remote bastion/jump server |

## Security

- Never commit credentials — use Ansible Vault or AAP2 Custom Credentials
- Production inventories are in `oar_tower_inventories` (not this repo)
- All placeholder data uses `[DB_SERVER]`, `[DELEGATE_HOST]`, `example.internal`
- See `docs/SECURITY_PASSWORD_HANDLING.md`

## Documentation

See `docs/` directory for detailed guides:

- `QUICK_START_GUIDE.md` — Getting started
- `AAP2_DEPLOYMENT_GUIDE.md` — AAP2 setup and configuration
- `INVENTORY_USAGE.md` — Inventory format reference
- `ANSIBLE_VARIABLES_REFERENCE.md` — All configurable variables
- `LOCAL_TESTING_GUIDE.md` — Local development testing

---

**Last Updated**: 2026-04-15
**Version**: 3.0.0
**Maintainer**: DevOps Team
