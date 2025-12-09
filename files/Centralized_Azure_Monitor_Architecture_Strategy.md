# Centralized Azure Monitor Workspace Architecture - Strategic Plan

**Project Type:** Infrastructure Architecture Migration  
**Author:** Platform Engineering Team  
**Date:** December 2025  
**Status:** APPROVED - Ready for Implementation  
**Environments:** dev, preprod, prod

---

## Executive Summary

Migration from **per-cluster Azure Monitor Workspaces** to **environment-level centralized monitoring** across our AKS platform. This reduces monitoring resources from **350+ to 33** (91% reduction) while improving observability and supporting cattle-not-pets operations.

### Key Benefits

- **91% reduction** in monitoring resources (350+ → 33)
- **Unified observability** - cross-cluster queries in single PromQL statement
- **Historical data continuity** - 18-month retention survives cluster lifecycle
- **Cattle architecture support** - monitoring persists while clusters are ephemeral
- **Operational simplicity** - 3 workspaces vs 50+
- **Zero configuration drift** - single source of truth per environment

### Resource Reduction Summary

| Resource Type | Current | Target | Reduction |
|--------------|---------|--------|-----------|
| Azure Monitor Workspaces | 50+ | **3** | 94% |
| Data Collection Rules | 50+ | **9** | 82% |
| Data Collection Endpoints | 50+ | **9** | 82% |
| Prometheus Rule Groups | 50+ | **3** | 94% |
| Alert Rule Groups | 100+ | **6** | 94% |
| Action Groups | 50+ | **3** | 94% |
| **Total Resources** | **350+** | **33** | **91%** |

---

## Architecture Overview

### Design Principle: Separate Ephemeral from Persistent

| Layer | Components | Lifecycle |
|-------|-----------|-----------|
| **Environment-Level (Persistent)** | Azure Monitor Workspace, DCE, DCR, Recording Rules, Alert Rules | Survives cluster lifecycle |
| **Cluster-Level (Ephemeral)** | AKS Cluster, ama-metrics pods, DCR Association | Created/destroyed (daily for dev) |

### Environment Characteristics

| Environment | Also Called | Purpose | Cluster Lifecycle | Monitoring Strategy |
|-------------|-------------|---------|-------------------|---------------------|
| **dev** | "eng" (same environment) | Development/Engineering | **Cattle** - Daily destroy/recreate | Persistent monitoring survives |
| **preprod** | - | Pre-production validation | **Long-lived** | Persistent monitoring |
| **prod** | - | Production workloads | **Long-lived** | Persistent monitoring |

### Supported Regions

- westeurope (West Europe)
- southeastasia (Southeast Asia)
- switzerlandnorth (Switzerland North)

---

## Resource Naming Conventions

**Convention Over Configuration** - Resources discovered by naming pattern, not configuration files.

```
Resource Naming Pattern:
  rg-monitoring-{env}                    # Resource Group
  amw-{env}                              # Azure Monitor Workspace
  dce-{env}-{region}                     # Data Collection Endpoints
  dcr-{env}-{region}                     # Data Collection Rules
  prometheus-rule-group-{env}            # Recording Rules
  alert-rule-group-{env}-{severity}      # Alert Rules (critical/warning)
  action-group-{env}-platform-team       # Notifications

Examples:
  rg-monitoring-dev
  amw-dev
  dce-dev-westeurope
  dcr-dev-westeurope
  prometheus-rule-group-dev
  alert-rule-group-dev-critical
  action-group-dev-platform-team
```

### Complete Resource Structure

```
rg-monitoring-dev/
├── amw-dev                                # 18-month retention
├── dce-dev-westeurope                     # 3 regional DCEs
├── dce-dev-southeastasia
├── dce-dev-switzerlandnorth
├── dcr-dev-westeurope                     # 3 regional DCRs (MUST have DCE reference)
├── dcr-dev-southeastasia
├── dcr-dev-switzerlandnorth
├── prometheus-rule-group-dev              # Pre-aggregation rules
├── alert-rule-group-dev-critical          # Critical alerts
├── alert-rule-group-dev-warning           # Warning alerts
└── action-group-dev-platform-team         # Notifications

rg-monitoring-preprod/  (same structure)
rg-monitoring-prod/     (same structure)

TOTAL: 33 resources (down from 350+)
```

---

## GitLab Issues - 12 Issues, 42 Story Points

| Phase | Issues | Story Points | Duration |
|-------|--------|--------------|----------|
| Phase 1: Foundation | #1 | 3 SP | Week 1-2 |
| Phase 2: Pipeline, Rules, Alerting | #10A, #2, #3, #4, #5, #11, #12 | 27 SP | Week 3-5 |
| Phase 3: Migration & Cattle | #7, #8, #9 | 16 SP | Week 5-6 |
| Phase 4: Observability & Cleanup | #6, #10 | 8 SP | Week 7-8 |

---

## PHASE 1: FOUNDATION (Week 1-2)

### Issue #1: Create Environment-Level Monitoring Infrastructure
**Story Points:** 3  
**Priority:** Critical

**Objective:** Deploy persistent monitoring infrastructure for all 3 environments that survives cluster lifecycle.

**Key Activities:**
- Create 3 monitoring resource groups: `rg-monitoring-{env}`
- Deploy 3 Azure Monitor Workspaces with 18-month retention: `amw-{env}`
- Deploy 9 Data Collection Endpoints (3 per environment): `dce-{env}-{region}`
- Deploy 9 Data Collection Rules (3 per environment): `dcr-{env}-{region}`
- **CRITICAL:** Each DCR MUST include `dataCollectionEndpointId` reference
- Create discovery library for resource-by-convention lookup
- Implement discovery functions: `discover_monitoring_resources(env, region)`

**Why Discovery Library:**
- No hardcoded resource IDs in configuration files
- Self-documenting infrastructure through naming conventions
- Idempotent deployments - discover existing resources
- More resilient than configuration file maintenance

**Discovery Pattern:**
```
Input: environment="dev", region="westeurope"
Expected Resources:
  - rg-monitoring-dev
  - amw-dev
  - dce-dev-westeurope
  - dcr-dev-westeurope

Discovery validates existence, returns resource IDs as JSON
If missing: fails with clear error and remediation steps
```

**Critical Configuration:**
- DCR must have `dataCollectionEndpointId` configured (root cause of previous monitoring failures)
- Azure Monitor Workspace retention: 540 days (18 months)
- DCE configured for regional ingestion
- DCR routing to workspace via destination

**Deliverables:**
- 3 monitoring resource groups created
- 3 Azure Monitor Workspaces deployed
- 9 DCEs deployed
- 9 DCRs deployed with correct DCE references
- Discovery library functional
- ARM templates created
- Deployment automation

---

## PHASE 2: PIPELINE INTEGRATION, RULES & ALERTING (Week 3-5)

### Issue #10A: Audit and Consolidate Existing Cluster-Level Rules
**Story Points:** 3  
**Priority:** Critical (Must complete before #11, #12)

**Objective:** Inventory existing per-cluster rules and create consolidation strategy.

**Current State:**
- 50+ Prometheus Rule Groups (one per cluster)
- 100+ Alert Rule Groups (critical + warning per cluster)
- 50+ Action Groups (one per cluster)

**Key Activities:**
- Audit existing Prometheus recording rules across all clusters
- Audit existing alert rules and thresholds
- Audit action group configurations
- Identify common patterns vs cluster-specific rules
- Document threshold variations by environment
- Create consolidation plan mapping old rules to new environment-level rules
- Identify any coverage gaps

**Rule Categories to Identify:**
1. **Universal Rules** - Identical across clusters → Direct migration
2. **Environment-Specific Rules** - Different thresholds per env → Parameterize
3. **Cluster-Specific Rules** - Unique to certain clusters → Label selectors
4. **Deprecated Rules** - No longer needed → Document and remove

**Key Insight:**
Recording rules need `by (cluster)` added to handle multiple clusters in workspace:
```
OLD (per-cluster): sum(rate(...))
NEW (environment): sum(rate(...)) by (cluster)
```

**Deliverables:**
- Complete inventory of existing rules
- Rule consolidation plan documented
- Coverage gap analysis
- Team sign-off on consolidated approach

---

### Issue #2: Update ARM Templates for Centralized Monitoring
**Story Points:** 5  
**Priority:** High

**Objective:** Update AKS ARM templates to use shared monitoring instead of creating per-cluster resources.

**Key Changes:**
- Remove Azure Monitor Workspace creation from cluster template
- Remove per-cluster DCR/DCE creation
- Keep `azureMonitorProfile.metrics.enabled: true`
- Add KSM annotations: `namespaces=[owner,swID]`
- Cluster deployment script will handle DCR association via discovery

**Important:**
- Do NOT specify workspace in ARM template
- Cluster deployment script associates with discovered DCR post-creation
- ama-metrics pods still deploy automatically

**Deliverables:**
- Updated AKS ARM template
- Parameter template updated
- Template validated
- Test cluster deployment successful

---

### Issue #3: Update Cluster Deployment Script
**Story Points:** 5  
**Priority:** High

**Objective:** Update deployment script to use discovery for associating clusters with environment-level monitoring.

**Key Logic Flow:**
1. Source discovery library
2. Get cluster location
3. Discover monitoring resources: `discover_monitoring_resources($ENV, $CLUSTER_LOCATION)`
4. Check current monitoring state (idempotency)
5. If update needed:
   - Disable existing monitoring (if wrong workspace)
   - Enable with discovered workspace
   - Associate with discovered DCR
6. Validate configuration

**Idempotency Requirements:**
- Check current state before making changes
- Safe to re-run multiple times
- No errors on repeated execution

**Deliverables:**
- Deployment script updated with discovery
- Script is idempotent
- Error handling with clear troubleshooting messages
- Tested on new cluster
- Tested re-running on existing cluster

---

### Issue #4: Create Validation Script
**Story Points:** 3  
**Priority:** High

**Objective:** Create comprehensive 7-check validation script to verify end-to-end monitoring pipeline.

**7 Critical Checks:**
1. Azure Monitor Metrics enabled on cluster
2. KSM annotations configured
3. DCR association exists
4. Correct DCR for environment/region
5. **DCR has dataCollectionEndpointId configured** (CRITICAL)
6. DCE exists with metrics ingestion endpoint
7. ama-metrics pods running and healthy

**Why This Is Critical:**
Previous issues where clusters appeared "monitored" but no metrics flowed were caused by missing DCE reference in DCR (check #5).

**Validation Output:**
- Clear pass/fail for each check
- Specific remediation commands for failures
- Integration with GitLab CI (JUnit XML)

**Deliverables:**
- Validation script with all 7 checks
- Remediation guidance for each failure
- Integrated as GitLab CI job
- Tested on correct and incorrect configurations

---

### Issue #5: Configure Grafana
**Story Points:** 3  
**Priority:** High

**Objective:** Configure Grafana with 3 environment-level data sources for unified observability.

**Key Activities:**
- Add 3 Prometheus data sources (one per environment)
- Configure Azure Managed Identity authentication
- Grant Grafana MI `Monitoring Data Reader` role on all 3 workspaces
- Test cross-cluster PromQL queries
- Document example queries

**Cross-Cluster Query Examples:**
```promql
# CPU by cluster
sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (cluster)

# Compare all clusters
topk(10, sum(...) by (cluster))

# Filter by cluster selector
{cluster=~"$cluster"}
```

**Deliverables:**
- 3 data sources configured in Grafana
- RBAC permissions granted
- Cross-cluster queries validated
- Documentation with query examples

---

### Issue #11: Deploy Prometheus Recording Rules to Environment Level
**Story Points:** 5  
**Priority:** High

**Objective:** Migrate existing cluster-level recording rules to environment-level for consistent pre-aggregation.

**Recording Rules Strategy:**
- Use audit results from #10A
- Add `by (cluster)` to all aggregations
- Deploy to environment-level workspace
- Scoped to all clusters in environment

**Key Recording Rules:**
```
cluster:cpu_usage:rate5m
cluster:memory_usage:bytes
cluster:namespace:cpu_usage:rate5m
cluster:namespace:memory_usage:bytes
cluster:pod_count:total
cluster:node_count:total
cluster:node_cpu_capacity:sum
cluster:node_memory_capacity:sum
cluster:node:cpu_utilization:ratio
cluster:node:memory_utilization:ratio
```

**Migration Approach:**
1. **Parallel deployment** - Deploy environment-level rules alongside cluster-level
2. **Validation** - Verify metric parity between old and new
3. **Cutover** - Update Grafana dashboards to use new rules
4. **Deprecate** - Stop creating cluster-level rules

**Deliverables:**
- Recording rules deployed to all 3 environments
- Metric parity validated
- Grafana dashboards updated
- Performance improvement documented

---

### Issue #12: Deploy Metric Alert Rules to Environment Level
**Story Points:** 8  
**Priority:** High

**Objective:** Migrate existing cluster-level alert rules to environment-level with no alerting gaps.

**Alert Threshold by Environment:**
```
dev:      memory: 80%/90%, cpu: 80%/90%, duration: 15m
preprod:  memory: 75%/85%, cpu: 75%/85%, duration: 10m
prod:     memory: 70%/80%, cpu: 70%/80%, duration: 5m
```

**Critical Alerts:**
- ClusterDown (up == 0 for 5m)
- HighMemoryUsage (env-specific threshold)
- HighCPUUsage (env-specific threshold)
- PodCrashLooping (restarts > 0 in 15m for 5m)
- NodeNotReady (status != Ready for 5m)

**Warning Alerts:**
- ElevatedMemoryUsage (lower threshold than critical)
- ElevatedCPUUsage (lower threshold than critical)

**Migration Strategy - NO GAPS:**
1. **Parallel deployment** - Both cluster-level and environment-level alerts active
2. **Test dual alerting** - Verify both systems fire correctly
3. **Gradual cutover** - Disable cluster-level alerts one by one
4. **Monitor 24-48h** - Ensure no gaps before proceeding
5. **Complete transition** - All clusters using environment-level alerts

**Action Groups:**
- Consolidate from 50+ to 3 (one per environment)
- Configure: Email, Slack, SMS (prod only), ServiceNow (preprod/prod)

**Deliverables:**
- Action groups deployed (3 total)
- Alert rules deployed (6 total: critical + warning per env)
- Alert rules use recording rules for performance
- Test alerts fired successfully
- Notifications confirmed
- Runbooks created/updated
- No alerting gaps during migration

---

## PHASE 3: MIGRATION & CATTLE (Week 5-6)

### Issue #7: Migrate Dev Clusters
**Story Points:** 5  
**Priority:** High

**Objective:** Migrate existing dev clusters to centralized monitoring as proof of concept.

**Migration Process:**
1. Discover environment-level monitoring resources
2. Remove old DCR associations
3. Disable existing monitoring (if configured)
4. Enable centralized monitoring with discovered workspace
5. Create DCR association to shared DCR
6. Restart ama-metrics pods
7. Validate monitoring chain (7 checks)

**Migration Strategy:**
- Test on single cluster first
- Validate for 24 hours
- Batch migrate remaining clusters
- Keep old workspaces for 7 days (rollback window)

**Validation Requirements:**
- Metrics flowing to centralized workspace
- Historical data still accessible
- Recording rules automatically applied
- Alert rules automatically applied
- No gaps in monitoring

**Deliverables:**
- Migration script created
- Single cluster migrated and validated
- All dev clusters migrated
- Historical data continuity verified
- Lessons learned documented

---

### Issue #8: Implement Cattle Automation
**Story Points:** 8  
**Priority:** High

**Objective:** Automate daily destroy/recreate of dev clusters with persistent monitoring.

**Cattle Philosophy:**
- Clusters are ephemeral (destroyed nightly, recreated morning)
- Monitoring infrastructure persists
- Historical data retained across cluster generations
- Recording rules and alerts automatically apply to new clusters

**Key Components:**
1. **Nightly teardown** (18:00 UTC)
   - Safety checks: ENV=dev, CATTLE_MODE=true, lifecycle=ephemeral tag
   - Delete clusters (keep resource groups)
   - Preserve monitoring infrastructure

2. **Morning recreation** (06:00 UTC)
   - Recreate clusters from configuration
   - Automatic DCR association via discovery
   - ama-metrics pods deploy automatically
   - Inherit recording rules and alert rules

**GitLab Schedules:**
- Nightly Teardown: `0 18 * * *` (SCHEDULE_TYPE=nightly_teardown, ENV=dev, CATTLE_MODE=true)
- Morning Recreate: `0 6 * * *` (SCHEDULE_TYPE=morning_recreate, ENV=dev, CATTLE_MODE=true)

**Safety Mechanisms:**
- Only runs for ENV=dev
- Requires CATTLE_MODE=true
- Only destroys clusters with `lifecycle: ephemeral` tag
- Multiple confirmation checks

**Deliverables:**
- Teardown script with safety checks
- Recreation script with safety checks
- GitLab scheduled pipelines configured
- Full cattle cycle tested end-to-end
- Monitoring verified across destroy/recreate
- Historical data accessible after recreation

---

### Issue #9: Create Migration Script for Preprod/Prod
**Story Points:** 3  
**Priority:** Medium

**Objective:** Prepare reusable migration approach for preprod and prod environments.

**Key Activities:**
- Migration playbook documented
- Environment-specific considerations documented
- Change management templates created
- Rollback procedure documented and tested
- Validation steps documented

**Environment-Specific Considerations:**

**Dev:**
- Cattle lifecycle, daily destroy/recreate
- Minimal change management
- 24-hour rollback window
- Aggressive testing acceptable

**Preprod:**
- Long-lived stable clusters
- Standard change request required
- 7-day rollback window
- Thorough validation required
- Notify stakeholders 24h advance

**Prod:**
- Long-lived critical clusters
- CAB approval required
- 30-day rollback window
- Comprehensive preprod validation first
- Notify stakeholders 1 week advance
- Maintenance window recommended
- Phased approach (1-2 clusters per week)

**Deliverables:**
- Migration playbook created
- Change management templates
- Rollback procedure documented
- Stakeholder approval received

---

## PHASE 4: OBSERVABILITY & CLEANUP (Week 7-8)

### Issue #6: Create Unified Dashboards
**Story Points:** 5  
**Priority:** High

**Objective:** Create Grafana dashboards leveraging environment-level monitoring for cross-cluster observability.

**Dashboard 1: Environment Overview**
- Cluster selector (multi-select)
- CPU/Memory by cluster (using recording rules)
- Pod count trends
- Node health matrix
- Utilization gauges with thresholds

**Dashboard 2: Cross-Cluster Comparison**
- Side-by-side metrics
- Resource utilization heatmap
- Anomaly detection (outlier clusters using >2x average)
- Top N clusters by resource usage

**Dashboard 3: Cluster Detail**
- Deep dive single cluster
- Namespace-level breakdowns
- Pod-level details
- Top pods by CPU/Memory

**Dashboard Variables:**
```
cluster: label_values(cluster:cpu_usage:rate5m, cluster)
namespace: label_values(cluster:namespace:cpu_usage:rate5m{cluster=~"$cluster"}, namespace)
```

**Key Queries Using Recording Rules:**
```promql
# Fast aggregated queries
cluster:cpu_usage:rate5m{cluster=~"$cluster"}
cluster:namespace:memory_usage:bytes{cluster=~"$cluster"}
cluster:pod_count:total{cluster=~"$cluster"}

# Cross-cluster comparisons
topk(10, cluster:cpu_usage:rate5m)

# Outlier detection
cluster:cpu_usage:rate5m > 2 * avg(cluster:cpu_usage:rate5m)
```

**Deliverables:**
- 3 dashboards created
- Dashboards use recording rules for performance
- Dashboard JSON exported to repository
- Team training completed

---

### Issue #10: Cleanup Orphaned Resources
**Story Points:** 3  
**Priority:** Medium

**Objective:** Remove orphaned per-cluster monitoring resources and document cost savings.

**Resources to Clean Up:**
- 50+ Azure Monitor Workspaces (per-cluster)
- 50+ Prometheus Rule Groups (per-cluster)
- 100+ Alert Rule Groups (per-cluster)
- 50+ Action Groups (per-cluster)
- 50+ DCRs (per-cluster)
- 50+ DCEs (per-cluster)

**Cleanup Strategy:**
- Audit all monitoring resources
- Filter out environment-level resources (keep these)
- Wait 30 days post-migration before deletion
- Soft-delete with 30-day recovery window
- Document cost savings

**Cost Savings Documentation:**
- Resource reduction: 350+ → 33 (91%)
- Operational overhead reduction
- Management time savings
- Improved reliability through consistency

**Deliverables:**
- Audit script for orphaned resources
- Cleanup script with safety checks
- 30-day waiting period enforced
- Cost savings documented
- Final metrics report

---

## Monitoring Pipeline Flow

```
AKS Cluster (Ephemeral - daily destroy/recreate in dev)
  ↓ metrics collection via ama-metrics pods
Data Collection Endpoint (DCE) - Regional ingestion gateway
  ↓ metrics forwarding
Data Collection Rule (DCR) - Routing logic (MUST reference DCE)
  ↓ destination configuration
Azure Monitor Workspace (AMW) - 18-month retention
  ↓ data storage
  ├→ Prometheus Recording Rules - Pre-aggregation (1-minute interval)
  └→ Metric Alert Rules - Alerting logic → Action Groups → Notifications
  ↓ query interface
Azure Managed Grafana - Visualization with cross-cluster queries
```

---

## Critical Configuration Points

### 1. DCR Must Have DCE Reference
```json
"dataCollectionEndpointId": "/subscriptions/.../dce-dev-westeurope"
```
**This is the #1 cause of metrics not flowing.** Validation script explicitly checks this.

### 2. KSM Annotations
```json
"kubeStateMetrics": {
  "metricAnnotationsAllowList": "namespaces=[owner,swID]"
}
```

### 3. Recording Rules Need Cluster Dimension
```
OLD: sum(rate(...))                      # Per-cluster workspace
NEW: sum(rate(...)) by (cluster)         # Environment workspace
```

### 4. Environment Config Simplified
```yaml
# OLD WAY (removed):
# monitoring_workspace_id: /subscriptions/.../amw-cluster-001
# monitoring_dcr: /subscriptions/.../dcr-cluster-001

# NEW WAY (discovery):
ENV: dev
CLUSTER_LOCATION: westeurope
# Pipeline discovers: rg-monitoring-dev, amw-dev, dce-dev-westeurope, dcr-dev-westeurope
```

---

## Timeline & Milestones

```
Week 1-2: Phase 1 - Foundation
├── Deploy infrastructure for dev, preprod, prod
└── ✓ Milestone 1: Monitoring Infrastructure Operational (3 environments)

Week 3-5: Phase 2 - Audit, Pipeline, Rules, Alerting
├── Audit existing rules
├── Update templates and scripts
├── Deploy recording rules
├── Deploy alert rules
└── ✓ Milestone 2: New Clusters Use Shared Monitoring

Week 5-6: Phase 3 - Migration & Cattle
├── Migrate dev clusters
├── Implement cattle automation
└── ✓ Milestone 3: Dev Environment Fully Migrated

Week 7-8: Phase 4 - Observability & Cleanup
├── Create unified dashboards
├── Clean up orphaned resources
└── ✓ Milestone 4: Project Complete

Week 9+: Optional - Preprod/Prod Migration
```

---

## Success Criteria

### Quantitative Metrics
- 91% reduction in monitoring resources (350+ → 33)
- 18-month historical data retention maintained
- Zero per-cluster monitoring resources in dev
- Daily cattle lifecycle operational (dev)
- Cross-cluster queries functional in Grafana

### Qualitative Metrics
- Cross-cluster queries work in single PromQL statement
- Consistent alerting across all clusters (no drift)
- Fast dashboard performance (recording rules)
- Monitoring survives cluster destroy/recreate
- Zero hardcoded resource IDs in configuration
- Self-documenting infrastructure via naming conventions

---

## Risk Mitigation

### High Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Metrics data loss during migration | Medium | High | Test on single cluster, keep old workspaces 30 days, rollback plan |
| DCR missing dataCollectionEndpointId | Medium | High | Validation script checks explicitly, automated deployment includes |
| Alert rules not firing | Low | High | Parallel deployment, comprehensive testing, no-gap strategy |

### Medium Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Grafana permissions | Low | Medium | RBAC documented clearly, pre-configured and tested |
| Alert notification fatigue | Medium | Medium | Tune thresholds per environment, gradual rollout |
| Recording rule performance | Low | Medium | Test queries before deployment, adjust intervals |

---

## Architectural Principles

### 1. Convention Over Configuration
Resources discovered by naming pattern, not configuration files. More resilient and self-documenting.

### 2. Idempotent Operations
All scripts check current state before making changes. Safe to re-run multiple times.

### 3. Fail Fast with Clear Errors
Discovery fails immediately if resources missing. Provides specific remediation commands.

### 4. Cattle Not Pets (Dev Only)
Development clusters destroyed/recreated daily. Monitoring persists. Historical data retained.

### 5. Environment Isolation
Each environment (dev, preprod, prod) has separate monitoring infrastructure. No cross-environment dependencies.

### 6. Regional Alignment
DCE and DCR deployed in same region as clusters for optimal ingestion performance.

### 7. No Hardcoded IDs
Zero resource IDs in configuration files. Everything discovered at runtime by naming convention.

---

## Key Decisions & Rationale

### Decision 1: Environment-Level vs Per-Cluster
**Choice:** Environment-level (3 workspaces)  
**Rationale:** Microsoft best practice, reduced complexity, cross-cluster visibility, supports cattle  
**Alternative Considered:** Per-region (more complex, less benefit)

### Decision 2: Discovery Pattern vs Configuration Files
**Choice:** Discovery by naming convention  
**Rationale:** Self-documenting, idempotent, no configuration drift, scales naturally  
**Alternative Considered:** Config files with resource IDs (fragile, maintenance overhead)

### Decision 3: Parallel Deployment for Alerts
**Choice:** Run old and new alerts simultaneously during migration  
**Rationale:** Zero alerting gaps, safe validation, easy rollback  
**Alternative Considered:** Direct cutover (risky, potential gaps)

### Decision 4: Recording Rules in Environment Workspace
**Choice:** Pre-aggregate at environment level  
**Rationale:** Fast dashboard queries, reduced load, consistent metrics  
**Alternative Considered:** On-demand queries (slower, higher load)

### Decision 5: Cattle Automation for Dev Only
**Choice:** Daily destroy/recreate only in dev  
**Rationale:** Balance experimentation with stability needs of higher environments  
**Alternative Considered:** Cattle for all environments (too disruptive for prod)

---

## Lessons Learned from Previous Monitoring Issues

### Issue: Race Condition in DCR/DCE Provisioning
**Problem:** Clusters appeared "monitored" but no metrics flowed  
**Root Cause:** DCR created without `dataCollectionEndpointId` reference  
**Solution:** Validation script check #5 explicitly verifies DCE reference  
**Prevention:** ARM templates require DCE parameter, deployment scripts validate

### Issue: Alert Drift Across Clusters
**Problem:** Inconsistent alert thresholds, some clusters missed critical alerts  
**Root Cause:** Manual configuration per cluster, configuration drift over time  
**Solution:** Environment-level alerts with consistent thresholds, single source of truth  
**Prevention:** No per-cluster alert creation, all from centralized templates

### Issue: Historical Data Loss
**Problem:** Cluster rebuild destroyed monitoring data  
**Root Cause:** Monitoring lifecycle tied to cluster lifecycle  
**Solution:** Separate persistent monitoring from ephemeral clusters  
**Prevention:** Environment-level workspace persists across cluster lifecycle

---

## Stakeholder Communication

### Dev Team
- **Benefit:** Unified dashboards showing all clusters
- **Change:** No per-cluster monitoring resources created
- **Action Required:** Use environment data sources in Grafana
- **Training:** Cross-cluster query patterns

### Operations Team
- **Benefit:** 91% fewer resources to manage
- **Change:** Alerts route to environment-level action groups
- **Action Required:** Update runbooks for centralized alerting
- **Training:** Validation script usage, troubleshooting

### Management
- **Benefit:** Cost reduction, operational efficiency, alignment with best practices
- **Change:** Architectural shift from per-cluster to environment-level
- **Action Required:** Approve migration plan, resource for 8-week project
- **Training:** Architecture overview, success metrics

---

## Next Steps

### Immediate (Week 1)
1. Review and approve this strategic plan
2. Create 12 GitLab issues from specifications
3. Assign Issue #1 to platform engineer
4. Deploy monitoring infrastructure for dev environment
5. Test discovery library

### Short-term (Week 2-5)
6. Audit existing rules (Issue #10A)
7. Update ARM templates and deployment scripts
8. Deploy recording rules and alert rules
9. Migrate first dev cluster as proof of concept

### Medium-term (Week 6-8)
10. Complete dev migration and cattle automation
11. Create unified dashboards
12. Clean up orphaned resources
13. Document lessons learned

### Long-term (Week 9+)
14. Migrate preprod (with change management)
15. Migrate prod (with CAB approval, phased approach)
16. Final metrics report and project closure

---

**Document Status:** Ready for Implementation  
**Approval Required From:** Platform Engineering Lead, Operations Lead, Product Owner  
**Next Review Date:** After Phase 1 completion (Week 2)
