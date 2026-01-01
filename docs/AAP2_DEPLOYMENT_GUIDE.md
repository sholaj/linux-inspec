# AAP2 Deployment Guide for Database Compliance Scanning

This guide covers deploying Ansible Automation Platform 2 (AAP2) on Azure for database compliance scanning.

## Prerequisites

- Azure subscription with sufficient quota
- Red Hat subscription with AAP2 entitlement
- Terraform 1.0+
- Azure CLI authenticated

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Azure Resource Group                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐   │
│  │   AAP2 VM       │     │   Runner VM     │     │   Database      │   │
│  │   (D4s_v3)      │────▶│   (B2s)         │────▶│   Containers    │   │
│  │                 │     │                 │     │                 │   │
│  │  - Controller   │     │  - InSpec       │     │  - MSSQL        │   │
│  │  - EE Registry  │     │  - DB Clients   │     │  - Oracle       │   │
│  │  - Web UI       │     │  - Delegate     │     │  - Sybase       │   │
│  └─────────────────┘     └─────────────────┘     │  - PostgreSQL   │   │
│         │                                         └─────────────────┘   │
│         │                                                               │
│         ▼                                                               │
│  ┌─────────────────┐                                                    │
│  │   ACR           │                                                    │
│  │   (EE Images)   │                                                    │
│  └─────────────────┘                                                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Step 1: Deploy AAP2 VM with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Deploy AAP2 VM (along with existing infrastructure)
terraform apply \
  -var="deploy_aap2=true" \
  -var="aap2_vm_size=Standard_D4s_v3"

# Note the outputs
terraform output aap2_public_ip
terraform output aap2_ssh_command
```

## Step 2: Install AAP2 on the VM

SSH to the AAP2 VM and complete installation:

```bash
# SSH to AAP2 VM
ssh -i ~/.ssh/inspec_azure azureuser@<aap2_public_ip>

# Register with Red Hat (requires valid subscription)
sudo subscription-manager register --username YOUR_USERNAME --password YOUR_PASSWORD
sudo subscription-manager attach --pool=YOUR_AAP_POOL_ID

# Install AAP2 Containerized (recommended for dev/test)
sudo dnf install -y ansible-automation-platform-containerized-setup

# Run the installer
cd /opt/aap2
sudo ansible-playbook -i inventory containerized_install.yml

# Access AAP2 at https://<aap2_public_ip>
```

## Step 3: Build and Push Execution Environment

On the AAP2 VM or a build machine:

```bash
cd /opt/aap2/linux-inspec/execution-environment

# Build the Execution Environment
ansible-builder build \
  --tag acrinspecwzrr.azurecr.io/db-compliance-ee:1.0.0 \
  --container-runtime podman

# Login to ACR
az acr login --name acrinspecwzrr

# Push to ACR
podman push acrinspecwzrr.azurecr.io/db-compliance-ee:1.0.0
```

## Step 4: Configure AAP2

### 4.1 Register Execution Environment

1. Navigate to **Administration > Execution Environments**
2. Click **Add**
3. Configure:
   - **Name**: `db-compliance-ee`
   - **Image**: `acrinspecwzrr.azurecr.io/db-compliance-ee:1.0.0`
   - **Pull**: `Always`
   - **Registry Credential**: Create if needed for ACR access

### 4.2 Create Credential Types

Import credential types from `aap2-config/credential-types/`:

1. Navigate to **Administration > Credential Types**
2. Click **Add** for each credential type:

| Name | File |
|------|------|
| MSSQL Database Credential | `mssql-database.json` |
| Oracle Database Credential | `oracle-database.json` |
| Sybase Database Credential | `sybase-database.json` |
| PostgreSQL Database Credential | `postgres-database.json` |
| Splunk HEC Credential | `splunk-hec.json` |

3. Copy the `inputs` and `injectors` JSON from each file

### 4.3 Create Credentials

1. Navigate to **Resources > Credentials**
2. Create credentials for each database platform using the custom credential types
3. Create a Machine credential for SSH access to delegate host (if using delegate mode)

### 4.4 Create Project

1. Navigate to **Resources > Projects**
2. Click **Add**
3. Configure:
   - **Name**: `linux-inspec`
   - **Source Control Type**: Git
   - **Source Control URL**: `https://github.com/sholaj/linux-inspec.git`
   - **Source Control Branch**: `feat/infraTest`
   - **Update Revision on Launch**: Enabled

### 4.5 Create Inventory

1. Navigate to **Resources > Inventories**
2. Click **Add > Add inventory**
3. Configure:
   - **Name**: `Database Compliance Inventory`
4. Add inventory source:
   - Use the inventory converter to generate inventory
   - Or manually add hosts from `aap2-config/inventories/aap2-inventory-example.yml`

### 4.6 Create Job Templates

Create job templates from `aap2-config/job-templates/`:

| Template | Playbook | Inventory Limit |
|----------|----------|-----------------|
| MSSQL Compliance Scan | `test_playbooks/run_mssql_inspec.yml` | `mssql_databases` |
| Oracle Compliance Scan | `test_playbooks/run_oracle_inspec.yml` | `oracle_databases` |
| Sybase Compliance Scan | `test_playbooks/run_sybase_inspec.yml` | `sybase_databases` |
| PostgreSQL Compliance Scan | `test_playbooks/run_postgres_inspec.yml` | `postgres_databases` |
| Multi-Platform Scan | `test_playbooks/run_compliance_scans.yml` | (none) |

For each template:
1. Navigate to **Resources > Templates**
2. Click **Add > Add job template**
3. Configure per the YAML files in `aap2-config/job-templates/`
4. Attach appropriate credentials

### 4.7 Create Workflow (Optional)

1. Navigate to **Resources > Templates**
2. Click **Add > Add workflow template**
3. Configure the workflow per `aap2-config/workflows/full-compliance-workflow.yml`

## Step 5: Generate Inventory from Flat File

Use the inventory converter to generate AAP2-compatible inventory:

```bash
# Create your database flat file
cat > databases.txt << 'EOF'
MSSQL prod-db-01 master null 1433 2019
ORACLE prod-ora-01 PROD prod_svc 1521 19
SYBASE prod-syb-01 master MYSYBASE 5000 16
POSTGRES prod-pg-01 appdb null 5432 15
EOF

# Run the converter
ansible-playbook inventory_converter/convert_flatfile_to_inventory.yml \
  -e "flatfile_input=databases.txt" \
  -e "inventory_output=aap2-inventory.yml"

# Upload the generated inventory to AAP2
```

## Step 6: Run Compliance Scans

### Via AAP2 Web UI

1. Navigate to **Resources > Templates**
2. Select the desired job template
3. Click **Launch**
4. Fill in survey options if prompted
5. Monitor job output

### Via API/CLI

```bash
# Using awx-cli (if installed)
awx job_templates launch "MSSQL Compliance Scan" \
  --extra_vars '{"inspec_debug_mode": true}'
```

## Cost Management

| Resource | Size | Monthly Cost |
|----------|------|--------------|
| AAP2 VM | D4s_v3 | ~$140 |
| Runner VM | B2s | ~$30 |
| Database ACIs | Various | ~$40 |
| Storage | Standard | ~$5 |
| **Total** | | **~$215/month** |

### Cost Saving Tips

1. **Deallocate when not in use**:
   ```bash
   az vm deallocate -g rg-inspec-dev-wzrr -n vm-aap2-inspec-dev
   ```

2. **Auto-shutdown**: Enabled by default at 11 PM UTC

3. **Stop database containers**:
   ```bash
   az container stop -g rg-inspec-dev-wzrr -n aci-mssql-inspec-dev
   ```

## Troubleshooting

### AAP2 Web UI Not Accessible

```bash
# Check if AAP2 services are running
sudo systemctl status automation-controller

# Check firewall
sudo firewall-cmd --list-all

# View logs
sudo journalctl -u automation-controller -f
```

### Execution Environment Pull Fails

```bash
# Verify ACR access
az acr login --name acrinspecwzrr
podman pull acrinspecwzrr.azurecr.io/db-compliance-ee:1.0.0

# Check AAP2 container registry credential
```

### Database Connection Fails

```bash
# Test from runner VM
ssh -i ~/.ssh/inspec_azure azureuser@<runner_ip>

# Test MSSQL
sqlcmd -S 10.0.2.4,1433 -U sa -P 'TestPass123' -Q "SELECT 1"

# Test Oracle
sqlplus system/OraclePass123@10.0.2.6:1521/ORCLCDB
```

## Security Considerations

1. **Credentials**: Never store passwords in inventory - use AAP2 Custom Credentials
2. **Network**: Database containers have no public IP - access via VNet only
3. **SSH**: Use SSH keys, not passwords, for VM access
4. **RBAC**: Configure AAP2 roles to limit access to credentials and templates
5. **Audit**: Enable AAP2 activity stream for audit logging

## Next Steps

- Configure Splunk integration for centralized results
- Set up scheduled scans via AAP2 Schedules
- Implement RBAC for multi-team access
- Add notification templates for scan failures
