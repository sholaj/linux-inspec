# Copilot Instructions - Centralized Azure Monitor Workspace Architecture

## Project Overview

Migration from per-cluster Azure Monitor Workspaces (50+) to environment-level centralized monitoring (3 workspaces). Reduces resources by 91% while improving observability and supporting cattle-not-pets operations.

**Environments:** dev, preprod, prod  
**Regions:** westeurope, southeastasia, switzerlandnorth  
**Platform:** Azure Kubernetes Service (AKS)

## Core Architecture Principles

### 1. Convention Over Configuration
Resources discovered by naming pattern, NOT configuration files. No hardcoded resource IDs.

```bash
# Discovery pattern
discover_azure_monitor_workspace() {
    local env=$1
    local expected_name="amw-${env}"
    # Query Azure for resource by expected name
    # Return resource ID or fail with clear error
}
```

### 2. Idempotent Operations
Scripts check current state before making changes. Safe to re-run multiple times.

```bash
# Always check current state first
current_state=$(az aks show --query "azureMonitorProfile.metrics.enabled" -o tsv)
if [[ "$current_state" == "true" ]]; then
    echo "Already configured"
    exit 0
fi
```

### 3. Fail Fast with Clear Errors
Provide specific remediation commands, not generic errors.

```bash
if [[ -z "$workspace_id" ]]; then
    echo "[ERROR] Workspace not found: $expected_name"
    echo "[REMEDIATION] Run: ./deploy_monitoring_infrastructure.sh $env"
    return 1
fi
```

### 4. Separate Ephemeral from Persistent
- **Persistent:** Azure Monitor Workspace, DCE, DCR, Recording Rules, Alert Rules
- **Ephemeral:** AKS clusters (destroyed/recreated daily in dev)

## Naming Conventions

### Standard Pattern
```
Resource Group:       rg-monitoring-{env}
Azure Monitor:        amw-{env}
DCE:                  dce-{env}-{region}
DCR:                  dcr-{env}-{region}
Recording Rules:      prometheus-rule-group-{env}
Alert Rules:          alert-rule-group-{env}-{severity}
Action Group:         action-group-{env}-platform-team
```

### Examples
```
rg-monitoring-dev
amw-dev
dce-dev-westeurope
dcr-dev-westeurope
prometheus-rule-group-dev
alert-rule-group-dev-critical
action-group-dev-platform-team
```

### Environment Values
- `dev` - Development (cattle lifecycle, daily destroy/recreate)
- `preprod` - Pre-production (long-lived)
- `prod` - Production (long-lived)

### Region Values
- `westeurope`
- `southeastasia`
- `switzerlandnorth`

## Discovery Library Pattern

All scripts should use discovery library for finding resources:

```bash
# Source discovery library
source "${SCRIPT_DIR}/lib/monitoring_discovery.sh"

# Discover resources
MONITORING_RESOURCES=$(discover_monitoring_resources "$ENV" "$CLUSTER_LOCATION")

# Extract IDs from JSON
WORKSPACE_ID=$(echo "$MONITORING_RESOURCES" | jq -r '.azureMonitorWorkspaceId')
DCR_ID=$(echo "$MONITORING_RESOURCES" | jq -r '.dataCollectionRuleId')
```

Discovery functions return JSON:
```json
{
    "environment": "dev",
    "region": "westeurope",
    "monitoringResourceGroup": "rg-monitoring-dev",
    "azureMonitorWorkspaceId": "/subscriptions/.../amw-dev",
    "dataCollectionEndpointId": "/subscriptions/.../dce-dev-westeurope",
    "dataCollectionRuleId": "/subscriptions/.../dcr-dev-westeurope"
}
```

## Technology Stack

### Azure Services
- Azure Kubernetes Service (AKS)
- Azure Monitor Workspace (managed Prometheus)
- Data Collection Endpoints (DCE)
- Data Collection Rules (DCR)
- Azure Managed Grafana
- Azure Monitor Alerts

### Tools & Languages
- Bash (pipeline scripts)
- Azure CLI (`az` commands)
- kubectl (cluster operations)
- jq (JSON parsing)
- ARM templates (infrastructure as code)
- GitLab CI/CD

### Key Azure CLI Commands
```bash
# Monitor workspace
az monitor account show --name amw-dev --resource-group rg-monitoring-dev

# DCE
az monitor data-collection endpoint show --name dce-dev-westeurope --resource-group rg-monitoring-dev

# DCR
az monitor data-collection rule show --name dcr-dev-westeurope --resource-group rg-monitoring-dev

# DCR association
az monitor data-collection rule association create \
    --name dcr-association-cluster \
    --rule-id $DCR_ID \
    --resource $CLUSTER_RESOURCE_ID

# AKS monitoring
az aks update \
    --name $CLUSTER_NAME \
    --resource-group $RG \
    --azure-monitor-workspace-resource-id $WORKSPACE_ID \
    --enable-azure-monitor-metrics \
    --ksm-metric-annotations-allow-list "namespaces=[owner,swID]"
```

## Critical Configuration Points

### 1. DCR MUST Reference DCE
Most critical configuration. Missing this causes metrics to not flow.

```json
{
    "dataCollectionEndpointId": "/subscriptions/.../dce-dev-westeurope"
}
```

### 2. KSM Annotations Required
```bash
--ksm-metric-annotations-allow-list "namespaces=[owner,swID]"
```

### 3. Recording Rules Need Cluster Dimension
```
OLD (per-cluster): sum(rate(container_cpu_usage_seconds_total[5m]))
NEW (environment): sum(rate(container_cpu_usage_seconds_total[5m])) by (cluster)
```

### 4. Regional Alignment
Cluster connects to DCE in same region:
- westeurope cluster → dce-dev-westeurope
- southeastasia cluster → dce-dev-southeastasia

## Script Patterns

### Safety Checks
```bash
# Environment validation
case "$ENV" in
    dev|preprod|prod)
        ;;
    *)
        echo "[ERROR] Invalid environment: $ENV"
        exit 1
        ;;
esac

# Cattle mode (dev only)
if [[ "$ENV" != "dev" ]]; then
    echo "[ERROR] Operation only allowed for dev environment"
    exit 1
fi

if [[ "${CATTLE_MODE:-false}" != "true" ]]; then
    echo "[ERROR] CATTLE_MODE must be 'true'"
    exit 1
fi
```

### Validation Pattern (7 Checks)
1. Azure Monitor Metrics enabled
2. KSM annotations configured
3. DCR association exists
4. Correct DCR for environment/region
5. **DCR has dataCollectionEndpointId** (CRITICAL)
6. DCE exists with metrics endpoint
7. ama-metrics pods running

```bash
# Check DCR has DCE reference
DCE_REF=$(az monitor data-collection rule show \
    --name $DCR_NAME \
    --resource-group $MONITORING_RG \
    --query "dataCollectionEndpointId" -o tsv)

if [[ -z "$DCE_REF" || "$DCE_REF" == "null" ]]; then
    echo "[ERROR] DCR missing dataCollectionEndpointId - CRITICAL!"
    exit 1
fi
```

### ARM Template Pattern
```json
{
    "type": "Microsoft.Monitor/accounts",
    "apiVersion": "2023-04-03",
    "name": "[parameters('workspaceName')]",
    "location": "[parameters('location')]",
    "properties": {
        "publicNetworkAccess": "Enabled"
    }
}
```

## Grafana Query Patterns

### Using Recording Rules
```promql
# Fast - uses pre-aggregated metric
cluster:cpu_usage:rate5m{cluster=~"$cluster"}

# Slow - raw query
sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (cluster)
```

### Cross-Cluster Queries
```promql
# All clusters
topk(10, cluster:cpu_usage:rate5m)

# Outlier detection
cluster:cpu_usage:rate5m > 2 * avg(cluster:cpu_usage:rate5m)

# Comparison
cluster:namespace:memory_usage:bytes{cluster=~"$cluster", namespace=~"$namespace"}
```

## Common Tasks

### Deploy Monitoring Infrastructure
```bash
./pipelines/scripts/deploy_monitoring_infrastructure.sh dev
# Creates: RG, AMW, 3 DCEs, 3 DCRs
```

### Deploy Recording Rules
```bash
./pipelines/scripts/deploy_prometheus_rules.sh dev
# Creates: prometheus-rule-group-dev
```

### Deploy Alert Rules
```bash
./pipelines/scripts/deploy_alert_rules.sh dev
# Creates: alert-rule-group-dev-critical, alert-rule-group-dev-warning, action-group-dev-platform-team
```

### Migrate Cluster
```bash
./pipelines/scripts/migrate_cluster_to_centralized_monitoring.sh \
    aks-dev-001 \
    rg-aks-dev-001 \
    dev
```

### Validate Monitoring
```bash
./pipelines/scripts/validate_monitoring_chain.sh \
    aks-dev-001 \
    rg-aks-dev-001 \
    dev
```

### Cattle Operations (Dev Only)
```bash
# Nightly teardown (18:00 UTC)
ENV=dev CATTLE_MODE=true ./pipelines/scripts/nightly_cluster_teardown.sh

# Morning recreate (06:00 UTC)
ENV=dev CATTLE_MODE=true ./pipelines/scripts/morning_cluster_recreate.sh
```

## Alert Threshold Patterns

### Environment-Specific
```yaml
dev:
  memory_critical: 0.90    # 90%
  cpu_critical: 0.90
  duration: "PT15M"        # 15 minutes

preprod:
  memory_critical: 0.85    # 85%
  cpu_critical: 0.85
  duration: "PT10M"        # 10 minutes

prod:
  memory_critical: 0.80    # 80%
  cpu_critical: 0.80
  duration: "PT5M"         # 5 minutes
```

## GitLab CI Variables

```yaml
ENV: dev|preprod|prod
CLUSTER_SUFFIX: cluster identifier
SUBSCRIPTION: Azure subscription ID
CATTLE_MODE: true|false (safety check)
SCHEDULE_TYPE: nightly_teardown|morning_recreate
```

## Error Handling

Always provide actionable remediation:

```bash
if resource_not_found; then
    echo "[ERROR] Resource not found: $expected_name"
    echo "[ERROR] Expected location: $expected_location"
    echo "[REMEDIATION] Run deployment script:"
    echo "  ./deploy_monitoring_infrastructure.sh $env"
    exit 1
fi
```

## Code Style

### Bash Scripts
- Use `set -euo pipefail`
- Validate inputs early
- Check current state (idempotency)
- Clear echo messages with [INFO], [ERROR], [DEBUG]
- Exit codes: 0 = success, 1 = error

### Variable Naming
```bash
ENV                # dev, preprod, prod
CLUSTER_NAME       # aks-dev-001
RESOURCE_GROUP     # rg-aks-dev-001
CLUSTER_LOCATION   # westeurope, southeastasia, switzerlandnorth
WORKSPACE_ID       # Full Azure resource ID
DCR_ID             # Full Azure resource ID
DCE_ID             # Full Azure resource ID
```

### JSON Parsing
```bash
# Extract single value
WORKSPACE_ID=$(echo "$JSON" | jq -r '.azureMonitorWorkspaceId')

# Check if empty/null
if [[ -z "$WORKSPACE_ID" || "$WORKSPACE_ID" == "null" ]]; then
    echo "[ERROR] Workspace ID not found"
fi
```

## Recording Rules to Implement

```yaml
# Cluster-level aggregations
cluster:cpu_usage:rate5m
cluster:memory_usage:bytes
cluster:pod_count:total
cluster:node_count:total
cluster:node_cpu_capacity:sum
cluster:node_memory_capacity:sum

# Namespace-level aggregations
cluster:namespace:cpu_usage:rate5m
cluster:namespace:memory_usage:bytes
cluster:namespace:pod_count:total

# Utilization ratios
cluster:node:cpu_utilization:ratio
cluster:node:memory_utilization:ratio
```

## Alert Rules to Implement

### Critical Alerts
- ClusterDown (up == 0 for 5m)
- HighMemoryUsage (>80-90% depending on env)
- HighCPUUsage (>80-90% depending on env)
- PodCrashLooping (restarts > 0 in 15m for 5m)
- NodeNotReady (status != Ready for 5m)

### Warning Alerts
- ElevatedMemoryUsage (>70-80% depending on env)
- ElevatedCPUUsage (>70-80% depending on env)

## Project Structure

```
pipelines/
├── scripts/
│   ├── lib/
│   │   └── monitoring_discovery.sh          # Discovery library
│   ├── deploy_monitoring_infrastructure.sh  # Foundation
│   ├── deploy_prometheus_rules.sh           # Recording rules
│   ├── deploy_alert_rules.sh                # Alert rules
│   ├── validate_monitoring_chain.sh         # 7-check validation
│   ├── migrate_cluster_to_centralized_monitoring.sh
│   ├── nightly_cluster_teardown.sh          # Cattle
│   └── morning_cluster_recreate.sh          # Cattle

src/main/arm/
├── azure-monitor/
│   ├── workspace/
│   │   └── azure-monitor-workspace.json
│   ├── dce/
│   │   └── data-collection-endpoint.json
│   ├── dcr/
│   │   └── shared-data-collection-rule.json
│   ├── prometheus-rules/
│   │   └── prometheus-rule-group.json
│   └── alert-rules/
│       ├── metric-alert-rule-group.json
│       └── action-group.json

docs/
├── Centralized_Azure_Monitor_Architecture_Strategy.md
└── cluster-migration-playbook.md
```

## Anti-Patterns to Avoid

❌ Hardcoded resource IDs in config files  
✅ Discovery by naming convention

❌ Creating per-cluster monitoring resources  
✅ Associate clusters with environment resources

❌ Recording rules without `by (cluster)`  
✅ Recording rules with cluster dimension

❌ DCR without dataCollectionEndpointId  
✅ DCR with DCE reference validated

❌ Direct cutover for alerts  
✅ Parallel deployment during migration

❌ No validation after changes  
✅ Run 7-check validation script

## Testing Patterns

```bash
# Test discovery
source pipelines/scripts/lib/monitoring_discovery.sh
discover_monitoring_resources dev westeurope

# Test idempotency
./script.sh  # First run - makes changes
./script.sh  # Second run - should detect state and skip

# Test validation
./pipelines/scripts/validate_monitoring_chain.sh \
    aks-dev-001 rg-aks-dev-001 dev
# Should pass all 7 checks

# Test alerts
# Create high resource usage, verify alert fires
```

## Debugging Tips

### Check DCR has DCE Reference
```bash
az monitor data-collection rule show \
    --name dcr-dev-westeurope \
    --resource-group rg-monitoring-dev \
    --query 'dataCollectionEndpointId'
# Should return DCE ID, not null
```

### Check ama-metrics Pods
```bash
kubectl get pods -n kube-system -l app=ama-metrics
kubectl logs -n kube-system -l app=ama-metrics --tail=50
```

### Check Metrics Flowing
```bash
# In Grafana, query:
up{job="kubernetes-apiservers"}
# Should return data for cluster
```

### Check DCR Association
```bash
CLUSTER_ID="/subscriptions/.../clusters/$CLUSTER_NAME"
az monitor data-collection rule association list --resource "$CLUSTER_ID"
# Should show association to correct DCR
```

## Key Metrics

- **Resources:** 350+ → 33 (91% reduction)
- **Environments:** 3 (dev, preprod, prod)
- **Regions:** 3 (westeurope, southeastasia, switzerlandnorth)
- **Retention:** 18 months (540 days)
- **Recording Rules:** ~11 per environment
- **Alert Rules:** ~5 critical + ~2 warning per environment
- **Cattle Cycle:** Daily (dev only) - 18:00 teardown, 06:00 recreate

## Documentation Links

- Architecture Strategy: `docs/Centralized_Azure_Monitor_Architecture_Strategy.md`
- Migration Playbook: `docs/cluster-migration-playbook.md`
- GitLab Issues: 12 issues, 42 story points, 8-week timeline
