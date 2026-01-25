# Azure InSpec Database Compliance Testing – Runbook

Last updated: 2025-12-28

## Current State (MVP Completed)
- Azure resources (Terraform-managed) are up:
  - ACR: `acrinspecwzrr.azurecr.io`
  - Runner VM: public `40.114.45.75`, private `10.0.1.4`
  - MSSQL: `10.0.2.4:1433` password `TestPass123`
  - Oracle: `10.0.2.6:1521` service `ORCLCDB` password `OraclePass123`
  - Sybase: `10.0.2.5:5000` server `MYSYBASE` password `myPassword`
  - PostgreSQL: `10.0.2.4:5432` database `testdb` password `PostgresPass123` (optional, deploy_postgres=true)
- Runner VM tools installed: InSpec 5.22.29, sqlcmd, sqlplus, psql, tsql (FreeTDS).
- Repo already cloned on runner at `/home/azureuser/linux-inspec`, branch `feat/infraTest`.

## Objective
Run and validate all three InSpec roles (mssql_inspec, oracle_inspec, sybase_inspec) in localhost mode, then add a delegate VM and validate delegate mode for all three. Generate combined results via `test_playbooks/run_compliance_scans.yml`.

## Files to Use
- Playbooks (localhost):
  - test_playbooks/run_mssql_inspec.yml
  - test_playbooks/run_oracle_inspec.yml
  - test_playbooks/run_sybase_inspec.yml
  - test_playbooks/run_compliance_scans.yml (combined run)
- Playbooks (delegate mode, to update):
  - test_playbooks/run_mssql_inspec_delegate.yml
  - test_playbooks/run_oracle_inspec_delegate.yml
  - test_playbooks/run_sybase_inspec_delegate.yml
- Inventory: inventories/hosts.yml (update IPs, passwords, delegate host)
- Roles: roles/mssql_inspec, roles/oracle_inspec, roles/sybase_inspec

## Runner VM – Localhost Mode Steps
1) SSH to runner
```
ssh -i ~/.ssh/inspec_rsa azureuser@40.114.45.75
```
2) Checkout branch and update inventory
```
cd /home/azureuser/linux-inspec
git checkout feat/infraTest

# ensure inventories/hosts.yml has:
#  - runner host: 10.0.1.4
#  - mssql: 10.0.2.4 / TestPass123
#  - oracle: 10.0.2.6 / OraclePass123
#  - sybase: 10.0.2.5 / myPassword
```
3) Sanity checks (tools + connectivity)
```bash
inspec version
which sqlcmd sqlplus

# Test MSSQL
sqlcmd -S 10.0.2.4,1433 -U sa -P 'TestPass123' -Q "SELECT 1"

# Test Oracle
echo "SELECT 1 FROM DUAL;" | sqlplus -s sys/OraclePass123@10.0.2.6:1521/ORCLCDB as sysdba

# Sybase: InSpec's sybase_session handles connectivity directly
# Verify interfaces file exists:
cat /opt/sap/interfaces
```
4) Run individual playbooks (localhost)
```
ansible-playbook test_playbooks/run_mssql_inspec.yml -i inventories/hosts.yml
ansible-playbook test_playbooks/run_oracle_inspec.yml -i inventories/hosts.yml
ansible-playbook test_playbooks/run_sybase_inspec.yml -i inventories/hosts.yml
```
5) Run combined playbook (localhost)
```
ansible-playbook test_playbooks/run_compliance_scans.yml -i inventories/hosts.yml
```
6) Collect results
- Check `/tmp/compliance_scans/` on runner for JSON outputs and logs.

## Delegate Mode Plan (Second VM)
Goal: a dedicated delegate VM (clone of runner) to execute all roles in delegate mode.

1) Provision delegate VM via Terraform (new resource/module):
  - Name: `vm-delegate-inspec-<env>`
  - Size: B2s; image: RHEL 8+; same VNet/subnet as runner; NSG allows SSH from runner subnet and maintenance jump if needed.
  - Cloud-init: reuse runner cloud-init to install InSpec, sqlcmd, sqlplus, tsql, git, and clone repo (branch `feat/infraTest`).
  - Outputs: private IP for delegate (use in inventory). No public IP needed; access via runner SSH proxy if required.

2) Update inventories/hosts.yml:
  - Add host `delegate` with its private IP.
  - Set `inspec_delegate_host: delegate` (or the delegate IP) for DB hosts/groups.
  - Ensure SSH key path points to the same key used for runner; user `azureuser`.

3) Update delegate playbooks to target delegate host:
  - test_playbooks/run_mssql_inspec_delegate.yml
  - test_playbooks/run_oracle_inspec_delegate.yml
  - test_playbooks/run_sybase_inspec_delegate.yml
  Each should:
  - `hosts: delegate`
  - set `inspec_delegate_host: delegate`
  - use DB connection vars from inventory (MSSQL 10.0.2.4, Oracle 10.0.2.6/ORCLCDB, Sybase 10.0.2.5).

4) Run delegate-mode playbooks from runner:
```
ansible-playbook test_playbooks/run_mssql_inspec_delegate.yml -i inventories/hosts.yml
ansible-playbook test_playbooks/run_oracle_inspec_delegate.yml -i inventories/hosts.yml
ansible-playbook test_playbooks/run_sybase_inspec_delegate.yml -i inventories/hosts.yml
```

5) Combined delegate run (optional):
```
ansible-playbook test_playbooks/run_compliance_scans.yml -i inventories/hosts.yml -e "inspec_delegate_host=delegate"
```

6) Verify results in `/tmp/compliance_scans/` on the delegate VM (or shared path if configured). Fetch artifacts via scp from delegate.

## Validation Checklist
y- Localhost mode: all three roles run without errors; queries succeed; InSpec JSON present and schema-valid; no critical failures (impact >= 0.7).
- Delegate mode: delegate host reachable; DB connectivity via delegate; all three delegate playbooks succeed; results captured.
- inventories/hosts.yml reflects current IPs/passwords and delegate host.

## Notes
- Runner already has repo cloned at `/home/azureuser/linux-inspec` on branch `feat/infraTest`.
- ACR hosts DB images; ACIs are already running for MSSQL/Oracle/Sybase with the credentials above.
- Keep costs down: stop/destroy delegate VM when not testing; consider ACI stop/start scripts for off-hours.# Azure InSpec Database Compliance Testing - CLAUDE.md

## Project Goal

Create a minimal, cost-effective Azure test environment to validate InSpec database compliance scanning across MSSQL, Oracle, and Sybase. Focus on getting core scanning working before production deployment.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         🎯 @orchestrator                                     │
│                    Coordinates: deploy → validate → test → cleanup           │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
            ┌───────────────────────────┼───────────────────────────┐
            │                           │                           │
            ▼                           ▼                           ▼
┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐
│  🏗️ @infra-agent    │   │  ✅ @validator      │   │  🧪 @test-runner    │
│                     │   │                     │   │                     │
│  • Terraform apply  │   │  • SSH connectivity │   │  • mssql_inspec     │
│  • Azure resources  │   │  • DB port checks   │   │  • oracle_inspec    │
│  • Cost optimization│   │  • InSpec ready     │   │  • sybase_inspec    │
│  • Auto-shutdown    │   │  • Client binaries  │   │  • localhost mode   │
│                     │   │                     │   │  • delegate mode    │
└─────────────────────┘   └─────────────────────┘   └─────────────────────┘
```

## MVP Cost Strategy

| Resource | Choice | Monthly Cost | Rationale |
|----------|--------|--------------|-----------|
| Runner VM | B2s (2 vCPU, 4GB) | ~$30 | Minimum for InSpec + clients |
| MSSQL | Azure Container Instance | ~$5-10 | Pay-per-use, no VM overhead |
| Oracle | Skip for MVP | $0 | Add later - complex licensing |
| Sybase | Skip for MVP | $0 | Add later - limited Azure support |
| Storage | Standard LRS | ~$2 | Cheapest tier |
| **Total MVP** | | **~$40/month** | MSSQL-only validation first |

## Directory Structure

```
linux-inspec/
├── CLAUDE.md                          # This file
├── .claude/
│   └── agents/
│       ├── orchestrator.md            # Main coordinator
│       ├── infra-agent.md             # Terraform/Azure
│       ├── validator.md               # Infrastructure validation
│       └── test-runner.md             # InSpec execution
├── terraform/
│   ├── main.tf                        # Core infrastructure
│   ├── variables.tf
│   ├── outputs.tf
│   └── mssql-container.tf             # ACI for MSSQL
├── roles/
│   ├── mssql_inspec/
│   ├── oracle_inspec/
│   └── sybase_inspec/
├── test_playbooks/
│   ├── run_mssql_inspec.yml
│   ├── run_oracle_inspec.yml
│   ├── run_sybase_inspec.yml
│   ├── test_delegate_connection.yml
│   └── azure_test_inventory.yml
├── scripts/
│   ├── validate_infra.sh
│   ├── run_tests.sh
│   └── setup_runner.sh
└── inventories/
    └── azure/
        ├── hosts.yml
        └── group_vars/
```

---

## Sub-Agent Definitions

### 🎯 @orchestrator

**Purpose:** Coordinate the full deployment lifecycle with a single command.

**Invoke with:** "Deploy and test the Azure InSpec environment"

**Workflow:**
```
1. PLAN    → Review what will be created, estimate costs
2. DEPLOY  → Call @infra-agent to provision Azure resources
3. WAIT    → Allow cloud-init to complete (~5 min)
4. VALIDATE→ Call @validator to verify infrastructure
5. TEST    → Call @test-runner to execute InSpec scans
6. REPORT  → Summarize results, identify failures
7. CLEANUP → Optionally destroy resources
```

---

### 🏗️ @infra-agent

**Purpose:** Provision minimal Azure infrastructure via Terraform.

**Invoke with:** "Create the Azure test environment" or "Destroy Azure resources"

**Resources Created:**
- Resource Group: `rg-inspec-dev-xxxx`
- VNet + Subnet: `10.0.0.0/16`
- Runner VM: RHEL 8, B2s, with InSpec + sqlcmd
- MSSQL: Azure Container Instance (2019-latest)
- NSG: SSH + DB ports

**Cost Controls:**
- Auto-shutdown at 11 PM UTC
- B-series burstable VMs
- Standard LRS storage
- No public IPs for databases

---

### ✅ @validator

**Purpose:** Verify infrastructure is ready before running tests.

**Invoke with:** "Validate the Azure environment is ready"

**Checks:**
1. SSH to runner VM works
2. `inspec version` returns valid output
3. `sqlcmd` binary exists
4. MSSQL port 1433 reachable from runner
5. Sample query `SELECT 1` succeeds
6. Results directory `/tmp/compliance_scans` writable

**Output:** JSON report with pass/fail per check

---

### 🧪 @test-runner

**Purpose:** Execute InSpec compliance scans in localhost and delegate modes.

**Invoke with:** "Run InSpec tests against MSSQL"

**Test Matrix:**
| Database | Localhost Mode | Delegate Mode |
|----------|----------------|---------------|
| MSSQL    | ✅ Primary     | ✅ Secondary  |
| Oracle   | ⏸️ Phase 2     | ⏸️ Phase 2    |
| Sybase   | ⏸️ Phase 2     | ⏸️ Phase 2    |

**Success Criteria:**
- InSpec JSON output valid
- No controls with `impact >= 0.7` failed
- Results in `/tmp/compliance_scans/`

---

## Quick Start Commands

```bash
# 1. Set Azure credentials
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."

# 2. Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/inspec_azure -N ""

# 3. Set passwords
export TF_VAR_mssql_password='YourStr0ngP@ssw0rd!'
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/inspec_azure.pub)"

# 4. Deploy infrastructure
cd terraform
terraform init
terraform apply

# 5. Save MSSQL IP to runner (for test inventory)
RUNNER_IP=$(terraform output -raw runner_public_ip)
MSSQL_IP=$(terraform output -raw mssql_private_ip)
ssh -i ~/.ssh/inspec_azure azureuser@$RUNNER_IP "echo $MSSQL_IP > /tmp/mssql_ip.txt"

# 6. Validate infrastructure
cd ..
chmod +x scripts/*.sh
./scripts/validate_infra.sh $RUNNER_IP ~/.ssh/inspec_azure $MSSQL_IP $TF_VAR_mssql_password

# 7. Run tests
export MSSQL_PASSWORD=$TF_VAR_mssql_password
./scripts/run_tests.sh $RUNNER_IP ~/.ssh/inspec_azure

# 8. Cleanup
cd terraform && terraform destroy
```

---

## Installing Additional Agents

You can install community agents from claude-code-templates:

```bash
# DevOps/Infrastructure agents
npx claude-code-templates@latest --agent devops/terraform-engineer --yes
npx claude-code-templates@latest --agent devops/ansible-playbook-creator --yes

# Testing agents
npx claude-code-templates@latest --agent development-tools/code-reviewer --yes
npx claude-code-templates@latest --agent testing/test-automation --yes

# Browse all available agents
npx claude-code-templates@latest
# Or visit: https://aitmpl.com/agents
```

---

## Environment Variables

```bash
# Azure Authentication
ARM_CLIENT_ID
ARM_CLIENT_SECRET
ARM_SUBSCRIPTION_ID
ARM_TENANT_ID

# Database Passwords (Terraform)
TF_VAR_mssql_password
TF_VAR_oracle_password    # Phase 2
TF_VAR_sybase_password    # Phase 2

# SSH Key
TF_VAR_admin_ssh_public_key
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `terraform/main.tf` | Core Azure infrastructure |
| `terraform/outputs.tf` | IPs and connection info |
| `scripts/setup_runner.sh` | cloud-init for runner VM |
| `test_playbooks/azure_test_inventory.yml` | Dynamic inventory for tests |
| `roles/mssql_inspec/` | MSSQL scanning role |

---

## Troubleshooting

### SSH Connection Failed
```bash
# Check VM is running
az vm show -g rg-inspec-dev-xxxx -n vm-runner-inspec-dev --query "powerState"

# Check public IP
terraform output runner_public_ip

# Test SSH
ssh -i ~/.ssh/inspec_azure azureuser@<IP> -v
```

### MSSQL Connection Failed
```bash
# From runner VM
sqlcmd -S <mssql_private_ip>,1433 -U sa -P 'YourP@ssw0rd!' -Q "SELECT @@VERSION"

# Check container status
az container show -g rg-inspec-dev-xxxx -n aci-mssql-inspec-dev --query "instanceView.state"
```

### InSpec Not Found
```bash
# Check cloud-init completed
sudo cloud-init status --long

# Manual install if needed
sudo gem install inspec-bin --no-document
```

---

## Phase 2 Roadmap

After MSSQL validation succeeds:

1. **Add Oracle** - Oracle XE container or VM
2. **Add Sybase** - SAP ASE Developer Edition
3. **GitHub Actions** - Automated CI/CD pipeline
4. **Key Vault** - Centralized secret management
5. **Delegate Mode** - Full jump server testing

---

## Success Criteria for MVP

- [ ] Runner VM deploys and accessible via SSH
- [ ] MSSQL container running and accepting connections
- [ ] InSpec installed and functional on runner
- [ ] `mssql_inspec` role executes in localhost mode
- [ ] JSON results generated in correct format
- [ ] No critical control failures
- [ ] Total cost < $50/month

---

*Last Updated: December 2024*
*Focus: MVP - MSSQL scanning validation*å
