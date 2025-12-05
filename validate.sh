#!/bin/bash
#===============================================================================

# AKS Monitoring Validation Script v2.2

# Enhanced DCE (Data Collection Endpoint) Validation

# 

# REQUIRED VARIABLES (export before running):

# CLUSTER_NAME     - AKS cluster name

# RESOURCE_GROUP   - Resource group containing the cluster

# SUBSCRIPTION     - Azure subscription ID

# AZURE_MONITOR_ID - Azure Monitor Workspace full resource ID

# GRAFANA_ID       - Azure Managed Grafana full resource ID

# 

# USAGE:

# export CLUSTER_NAME="my-cluster"

# export RESOURCE_GROUP="my-rg"

# export SUBSCRIPTION="12345678-1234-1234-1234-123456789abc"

# export AZURE_MONITOR_ID="/subscriptions/…/microsoft.monitor/accounts/my-amw"

# export GRAFANA_ID="/subscriptions/…/Microsoft.Dashboard/grafana/my-grafana"

# ./validate_monitoring_enhanced.sh

#===============================================================================

set -euo pipefail

#------------------------------------------------------

# Colors and Formatting

#------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

#------------------------------------------------------

# Counters and Result Arrays

#------------------------------------------------------
TOTAL=0
PASSED=0
FAILED=0
WARNINGS=0

declare -a FAILED_ITEMS=()
declare -a REMEDIATION=()

#------------------------------------------------------

# Logging Functions

#------------------------------------------------------
log_info() {
echo -e "${BLUE}[INFO]${NC} $1"
}

log_pass() {
echo -e "${GREEN}[PASS]${NC} $1"
((PASSED++))
((TOTAL++))
}

log_fail() {
echo -e "${RED}[FAIL]${NC} $1"
FAILED_ITEMS+=("$1")
((FAILED++))
((TOTAL++))
}

log_warn() {
echo -e "${YELLOW}[WARN]${NC} $1"
((WARNINGS++))
((TOTAL++))
}

log_section() {
echo ""
echo -e "${BOLD}======================================================================${NC}"
echo -e "${BOLD}  $1${NC}"
echo -e "${BOLD}======================================================================${NC}"
}

log_subsection() {
echo ""
echo -e "${BOLD}-- $1 --${NC}"
}

#------------------------------------------------------

# Header

#------------------------------------------------------
echo ""
echo -e "${BOLD}+====================================================================+${NC}"
echo -e "${BOLD}|     AKS MONITORING PIPELINE VALIDATION v2.2                       |${NC}"
echo -e "${BOLD}|     Enhanced DCE (Data Collection Endpoint) Checks                |${NC}"
echo -e "${BOLD}+====================================================================+${NC}"
echo ""

#------------------------------------------------------

# Validate Required Variables

#------------------------------------------------------
log_section "REQUIRED VARIABLES"

missing=()

if [[ -z "${CLUSTER_NAME:-}" ]]; then
missing+=("CLUSTER_NAME")
else
log_pass "CLUSTER_NAME = $CLUSTER_NAME"
fi

if [[ -z "${RESOURCE_GROUP:-}" ]]; then
missing+=("RESOURCE_GROUP")
else
log_pass "RESOURCE_GROUP = $RESOURCE_GROUP"
fi

if [[ -z "${SUBSCRIPTION:-}" ]]; then
missing+=("SUBSCRIPTION")
else
log_pass "SUBSCRIPTION = $SUBSCRIPTION"
fi

if [[ -z "${AZURE_MONITOR_ID:-}" ]]; then
missing+=("AZURE_MONITOR_ID")
else
log_pass "AZURE_MONITOR_ID set"
# Extract name and resource group from the full ID
AMW_NAME=$(echo "$AZURE_MONITOR_ID" | grep -oP '(?<=accounts/)[^/]+$' || basename "$AZURE_MONITOR_ID")
AMW_RG=$(echo "$AZURE_MONITOR_ID" | grep -oP '(?<=resourceGroups/)[^/]+' || echo "")
log_info "  Workspace Name: $AMW_NAME"
log_info "  Workspace RG: $AMW_RG"
fi

if [[ -z "${GRAFANA_ID:-}" ]]; then
missing+=("GRAFANA_ID")
else
log_pass "GRAFANA_ID set"
# Extract name and resource group from the full ID
GRAF_NAME=$(echo "$GRAFANA_ID" | grep -oP '(?<=grafana/)[^/]+$' || basename "$GRAFANA_ID")
GRAF_RG=$(echo "$GRAFANA_ID" | grep -oP '(?<=resourceGroups/)[^/]+' || echo "")
log_info "  Grafana Name: $GRAF_NAME"
log_info "  Grafana RG: $GRAF_RG"
fi

# Exit if any variables are missing

if [[ ${#missing[@]} -gt 0 ]]; then
echo ""
echo -e "${RED}${BOLD}ERROR: Missing required variables:${NC}"
for var in "${missing[@]}"; do
echo -e "  ${RED}x${NC} $var"
done
echo ""
echo "Export these variables before running:"
echo '  export CLUSTER_NAME="your-cluster-name"'
echo '  export RESOURCE_GROUP="your-resource-group"'
echo '  export SUBSCRIPTION="your-subscription-id"'
echo '  export AZURE_MONITOR_ID="/subscriptions/…/microsoft.monitor/accounts/…"'
echo '  export GRAFANA_ID="/subscriptions/…/Microsoft.Dashboard/grafana/…"'
exit 2
fi

#------------------------------------------------------

# Prerequisites Check

#------------------------------------------------------
log_section "PREREQUISITES"

# Check Azure CLI

if command -v az &>/dev/null; then
log_pass "Azure CLI installed"
else
log_fail "Azure CLI not installed"
exit 2
fi

# Check jq

if command -v jq &>/dev/null; then
log_pass "jq installed"
else
log_fail "jq not installed - required for JSON parsing"
exit 2
fi

# Check Azure authentication

if az account show &>/dev/null; then
log_pass "Authenticated to Azure"
else
log_fail "Not authenticated - run 'az login' first"
exit 2
fi

# Set subscription

if az account set --subscription "$SUBSCRIPTION" &>/dev/null; then
log_pass "Subscription set: $SUBSCRIPTION"
else
log_fail "Failed to set subscription: $SUBSCRIPTION"
exit 2
fi

# Check kubectl (optional)

SKIP_KUBECTL="false"
if command -v kubectl &>/dev/null; then
log_pass "kubectl installed"
else
log_warn "kubectl not available - skipping in-cluster checks"
SKIP_KUBECTL="true"
fi

#------------------------------------------------------

# Phase 1: Cluster Validation

#------------------------------------------------------
log_section "PHASE 1: CLUSTER VALIDATION"

log_subsection "Cluster Existence"

CLUSTER_JSON=$(az aks show \
--name "$CLUSTER_NAME" \
--resource-group "$RESOURCE_GROUP" \
--output json 2>/dev/null) || {
log_fail "Cluster '$CLUSTER_NAME' not found in resource group '$RESOURCE_GROUP'"
exit 1
}

log_pass "Cluster exists: $CLUSTER_NAME"

# Extract cluster details

CLUSTER_ID=$(echo "$CLUSTER_JSON" | jq -r '.id')
CLUSTER_LOC=$(echo "$CLUSTER_JSON" | jq -r '.location')
CLUSTER_STATE=$(echo "$CLUSTER_JSON" | jq -r '.provisioningState')
CLUSTER_POWER=$(echo "$CLUSTER_JSON" | jq -r '.powerState.code')
K8S_VERSION=$(echo "$CLUSTER_JSON" | jq -r '.kubernetesVersion')

log_info "  Location: $CLUSTER_LOC"
log_info "  Kubernetes Version: $K8S_VERSION"
log_info "  Provisioning State: $CLUSTER_STATE"
log_info "  Power State: $CLUSTER_POWER"

# Validate cluster state

if [[ "$CLUSTER_STATE" == "Succeeded" ]]; then
log_pass "Cluster provisioned successfully"
else
log_fail "Cluster provisioning state: $CLUSTER_STATE"
fi

if [[ "$CLUSTER_POWER" == "Running" ]]; then
log_pass "Cluster is running"
else
log_fail "Cluster not running: $CLUSTER_POWER"
fi

log_subsection "Azure Monitor Configuration"

# Check Azure Monitor Metrics enabled

METRICS_ENABLED=$(echo "$CLUSTER_JSON" | jq -r '.azureMonitorProfile.metrics.enabled // false')
if [[ "$METRICS_ENABLED" == "true" ]]; then
log_pass "Azure Monitor Metrics is ENABLED"
else
log_fail "Azure Monitor Metrics is NOT enabled"
REMEDIATION+=("Enable metrics: az aks update -n $CLUSTER_NAME -g $RESOURCE_GROUP --enable-azure-monitor-metrics --azure-monitor-workspace-resource-id $AZURE_MONITOR_ID")
fi

# Check Container Insights (OMS Agent)

OMS_ENABLED=$(echo "$CLUSTER_JSON" | jq -r '.addonProfiles.omsagent.enabled // false')
if [[ "$OMS_ENABLED" == "true" ]]; then
log_pass "Container Insights (OMS Agent) is ENABLED"
else
log_warn "Container Insights not enabled - logs won't flow to Log Analytics"
fi

# Store kubelet identity for RBAC checks (currently not used)
# shellcheck disable=SC2034
KUBELET_ID=$(echo "$CLUSTER_JSON" | jq -r '.identityProfile.kubeletidentity.objectId // empty')

#------------------------------------------------------

# Phase 2: In-Cluster Agents

#------------------------------------------------------
log_section "PHASE 2: IN-CLUSTER AGENTS"

if [[ "$SKIP_KUBECTL" == "true" ]]; then
log_warn "Skipping in-cluster checks (kubectl not available)"
else
log_subsection "Cluster Credentials"

# Try to get credentials
if az aks get-credentials \
    --name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --overwrite-existing \
    --admin 2>/dev/null || \
   az aks get-credentials \
    --name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --overwrite-existing 2>/dev/null; then
    log_pass "Obtained cluster credentials"
else
    log_warn "Could not get cluster credentials - skipping in-cluster checks"
    SKIP_KUBECTL="true"
fi

# Test cluster connectivity
if [[ "$SKIP_KUBECTL" != "true" ]]; then
    if kubectl cluster-info &>/dev/null; then
        log_pass "Connected to cluster API"
        
        log_subsection "ama-metrics Deployment"
        
        # Check ama-metrics deployment
        AMA_DEPLOY=$(kubectl get deployment -n kube-system ama-metrics -o json 2>/dev/null) || AMA_DEPLOY=""
        
        if [[ -n "$AMA_DEPLOY" ]]; then
            READY=$(echo "$AMA_DEPLOY" | jq -r '.status.readyReplicas // 0')
            DESIRED=$(echo "$AMA_DEPLOY" | jq -r '.spec.replicas // 0')
            
            if [[ "$READY" -eq "$DESIRED" && "$READY" -gt 0 ]]; then
                log_pass "ama-metrics deployment: $READY/$DESIRED replicas ready"
            else
                log_fail "ama-metrics deployment: $READY/$DESIRED replicas ready"
                REMEDIATION+=("Check ama-metrics: kubectl describe deployment -n kube-system ama-metrics")
            fi
        else
            log_fail "ama-metrics deployment NOT FOUND"
            REMEDIATION+=("Verify Azure Monitor Metrics addon is enabled on the cluster")
        fi
        
        log_subsection "ama-metrics Pod Logs"
        
        # Check pod logs for errors
        AMA_POD=$(kubectl get pods -n kube-system -l rsName=ama-metrics -o jsonpath='{.items[0].metadata.name}' 2>/dev/null) || AMA_POD=""
        
        if [[ -n "$AMA_POD" ]]; then
            # Check for DCE/connectivity specific errors
            DCE_ERRORS=$(kubectl logs -n kube-system "$AMA_POD" --tail=500 2>/dev/null | grep -ci "dce\|endpoint\|ingestion\|connection refused\|no route\|unreachable" || echo "0")
            
            if [[ "$DCE_ERRORS" -gt 5 ]]; then
                log_fail "Found $DCE_ERRORS DCE/connectivity errors in ama-metrics logs"
                log_info "  Sample errors:"
                kubectl logs -n kube-system "$AMA_POD" --tail=500 2>/dev/null | grep -i "dce\|endpoint\|ingestion\|refused\|unreachable" | head -3 | while read -r line; do
                    echo -e "    ${YELLOW}$line${NC}"
                done
                REMEDIATION+=("Check DCE connectivity and configuration")
            else
                log_pass "No DCE connectivity errors in logs"
            fi
            
            # Check for general errors
            GENERAL_ERRORS=$(kubectl logs -n kube-system "$AMA_POD" --tail=200 2>/dev/null | grep -ci "error\|fail" || echo "0")
            if [[ "$GENERAL_ERRORS" -gt 10 ]]; then
                log_warn "Found $GENERAL_ERRORS general errors in ama-metrics logs"
            else
                log_pass "No significant errors in ama-metrics logs"
            fi
        else
            log_warn "Could not find ama-metrics pod to analyze logs"
        fi
    else
        log_warn "Cannot connect to cluster API - skipping in-cluster checks"
        SKIP_KUBECTL="true"
    fi
fi

fi

#------------------------------------------------------

# Phase 3: Data Collection Rules (DCR)

#------------------------------------------------------
log_section "PHASE 3: DATA COLLECTION RULES (DCR)"

log_subsection "DCR Associations"

# List DCR associations for the cluster

DCR_ASSOC=$(az monitor data-collection rule association list \
--resource "$CLUSTER_ID" \
--output json 2>/dev/null) || DCR_ASSOC="[]"

DCR_COUNT=$(echo "$DCR_ASSOC" | jq 'length')

# Initialize variables for chain validation

DCE_IN_DCR=""
AMW_DEST=""
DCR_NAME=""
DCR_RG=""

if [[ "$DCR_COUNT" -gt 0 ]]; then
log_pass "Found $DCR_COUNT DCR association(s)"

# List all associations
echo "$DCR_ASSOC" | jq -r '.[] | "  - \(.name) -> \(.dataCollectionRuleId | split("/") | .[-1])"'

# Get first DCR for detailed validation
DCR_ID=$(echo "$DCR_ASSOC" | jq -r '.[0].dataCollectionRuleId')
DCR_NAME=$(echo "$DCR_ID" | grep -oP '(?<=dataCollectionRules/)[^/]+' || echo "")
DCR_RG=$(echo "$DCR_ID" | grep -oP '(?<=resourceGroups/)[^/]+' || echo "")

log_subsection "DCR Configuration Details"

if [[ -n "$DCR_NAME" && -n "$DCR_RG" ]]; then
    log_info "Validating DCR: $DCR_NAME (in $DCR_RG)"
    
    DCR_DETAILS=$(az monitor data-collection rule show \
        --name "$DCR_NAME" \
        --resource-group "$DCR_RG" \
        --output json 2>/dev/null) || DCR_DETAILS=""
    
    if [[ -n "$DCR_DETAILS" ]]; then
        # Check DCR provisioning state
        DCR_STATE=$(echo "$DCR_DETAILS" | jq -r '.provisioningState')
        if [[ "$DCR_STATE" == "Succeeded" ]]; then
            log_pass "DCR provisioning state: Succeeded"
        else
            log_fail "DCR provisioning state: $DCR_STATE"
        fi
        
        # Check data flows
        FLOWS=$(echo "$DCR_DETAILS" | jq -r '.dataFlows | length')
        if [[ "$FLOWS" -gt 0 ]]; then
            log_pass "DCR has $FLOWS data flow(s) configured"
        else
            log_fail "DCR has no data flows configured"
        fi
        
        #-------------------------------------------------------------------
        # CRITICAL: Check DCE configuration in DCR
        #-------------------------------------------------------------------
        log_subsection "DCE Configuration in DCR (CRITICAL)"
        
        DCE_IN_DCR=$(echo "$DCR_DETAILS" | jq -r '.dataCollectionEndpointId // empty')
        
        if [[ -n "$DCE_IN_DCR" ]]; then
            log_pass "DCR has dataCollectionEndpointId configured"
            
            # Extract DCE details from the ID
            DCE_NAME=$(echo "$DCE_IN_DCR" | grep -oP '(?<=dataCollectionEndpoints/)[^/]+' || basename "$DCE_IN_DCR")
            DCE_RG=$(echo "$DCE_IN_DCR" | grep -oP '(?<=resourceGroups/)[^/]+' || echo "")
            
            log_info "  DCE Name: $DCE_NAME"
            log_info "  DCE Resource Group: $DCE_RG"
        else
            log_fail "DCR has NO dataCollectionEndpointId - THIS MAY BE YOUR ISSUE"
            log_info "  The DCR exists but has no DCE configured"
            log_info "  Metrics have nowhere to be ingested"
            REMEDIATION+=("Add dataCollectionEndpointId to your DCR configuration")
        fi
        
        #-------------------------------------------------------------------
        # Check AMW destination in DCR
        #-------------------------------------------------------------------
        log_subsection "Azure Monitor Workspace Destination"
        
        AMW_DEST=$(echo "$DCR_DETAILS" | jq -r '.destinations.monitoringAccounts[0].accountResourceId // empty')
        
        if [[ -n "$AMW_DEST" ]]; then
            log_pass "DCR has Azure Monitor Workspace destination"
            log_info "  Destination: $(basename "$AMW_DEST")"
            
            # Check if it matches the provided AZURE_MONITOR_ID
            if [[ "$AMW_DEST" == "$AZURE_MONITOR_ID" ]]; then
                log_pass "DCR destination matches provided AZURE_MONITOR_ID"
            else
                log_warn "DCR routes to different workspace than provided AZURE_MONITOR_ID"
                log_info "  DCR destination: $AMW_DEST"
                log_info "  Provided ID:     $AZURE_MONITOR_ID"
            fi
        else
            log_fail "DCR has NO Azure Monitor Workspace destination"
            REMEDIATION+=("Configure monitoringAccounts destination in DCR")
        fi
    else
        log_fail "Could not retrieve DCR details for: $DCR_NAME"
    fi
fi

else
log_fail "NO DCR associations found for cluster - THIS IS LIKELY YOUR PROBLEM"
REMEDIATION+=("Associate a DCR to the cluster: az monitor data-collection rule association create --name prometheus-assoc --resource '$CLUSTER_ID' --data-collection-rule-id '<DCR_ID>'")

# Search for available DCRs
log_info "Searching for available DCRs in subscription..."
AVAILABLE_DCRS=$(az monitor data-collection rule list \
    --subscription "$SUBSCRIPTION" \
    --query "[].{name:name, resourceGroup:resourceGroup, location:location}" \
    --output json 2>/dev/null) || AVAILABLE_DCRS="[]"

AVAIL_COUNT=$(echo "$AVAILABLE_DCRS" | jq 'length')
if [[ "$AVAIL_COUNT" -gt 0 ]]; then
    log_info "Found $AVAIL_COUNT DCR(s) in subscription:"
    echo "$AVAILABLE_DCRS" | jq -r '.[] | "  - \(.name) (location: \(.location))"' | head -5
fi

fi

#------------------------------------------------------

# Phase 4: Data Collection Endpoint (DCE) - ENHANCED VALIDATION

#------------------------------------------------------
log_section "PHASE 4: DATA COLLECTION ENDPOINT (DCE)"

# Initialize DCE validation variables

METRICS_EP=""

if [[ -n "${DCE_NAME:-}" && -n "${DCE_RG:-}" ]]; then
log_subsection "Validating DCE: $DCE_NAME"

DCE_DETAILS=$(az monitor data-collection endpoint show \
    --name "$DCE_NAME" \
    --resource-group "$DCE_RG" \
    --output json 2>/dev/null) || DCE_DETAILS=""

if [[ -n "$DCE_DETAILS" ]]; then
    log_pass "DCE exists: $DCE_NAME"
    
    # Check DCE provisioning state
    DCE_STATE=$(echo "$DCE_DETAILS" | jq -r '.provisioningState')
    if [[ "$DCE_STATE" == "Succeeded" ]]; then
        log_pass "DCE provisioning state: Succeeded"
    else
        log_fail "DCE provisioning state: $DCE_STATE"
    fi
    
    # Check DCE location vs cluster location
    DCE_LOC=$(echo "$DCE_DETAILS" | jq -r '.location')
    log_info "  DCE Location: $DCE_LOC"
    
    if [[ "$DCE_LOC" == "$CLUSTER_LOC" ]]; then
        log_pass "DCE is in same region as cluster ($CLUSTER_LOC)"
    else
        log_warn "DCE ($DCE_LOC) is in DIFFERENT region than cluster ($CLUSTER_LOC)"
        log_info "  Cross-region ingestion may have latency or connectivity issues"
    fi
    
    log_subsection "DCE Ingestion Endpoints"
    
    # Check metrics ingestion endpoint - CRITICAL
    METRICS_EP=$(echo "$DCE_DETAILS" | jq -r '.metricsIngestion.endpoint // empty')
    
    if [[ -n "$METRICS_EP" ]]; then
        log_pass "DCE has metrics ingestion endpoint"
        log_info "  Endpoint: $METRICS_EP"
    else
        log_fail "DCE has NO metrics ingestion endpoint - metrics cannot be ingested"
        REMEDIATION+=("DCE is missing metricsIngestion.endpoint configuration")
    fi
    
    # Check logs ingestion endpoint (informational)
    LOGS_EP=$(echo "$DCE_DETAILS" | jq -r '.logsIngestion.endpoint // empty')
    
    if [[ -n "$LOGS_EP" ]]; then
        log_pass "DCE has logs ingestion endpoint"
        log_info "  Endpoint: $LOGS_EP"
    else
        log_info "DCE has no logs ingestion endpoint (OK for metrics-only scenarios)"
    fi
    
    # Check network access configuration
    NETWORK_ACCESS=$(echo "$DCE_DETAILS" | jq -r '.networkAcls.publicNetworkAccess // "Enabled"')
    log_info "  Public network access: $NETWORK_ACCESS"
    
    if [[ "$NETWORK_ACCESS" == "Disabled" ]]; then
        log_warn "Public network access is DISABLED"
        log_info "  Ensure private endpoint is configured and accessible from cluster"
    fi
    
else
    log_fail "DCE '$DCE_NAME' not found in resource group '$DCE_RG'"
    REMEDIATION+=("Create DCE or verify the dataCollectionEndpointId in DCR is correct")
fi

else
log_fail "No DCE configured in DCR - searching for available DCEs…"

# Search for existing DCEs in the subscription
ALL_DCES=$(az monitor data-collection endpoint list \
    --subscription "$SUBSCRIPTION" \
    --output json 2>/dev/null) || ALL_DCES="[]"

DCE_TOTAL=$(echo "$ALL_DCES" | jq 'length')

if [[ "$DCE_TOTAL" -gt 0 ]]; then
    log_info "Found $DCE_TOTAL DCE(s) in subscription:"
    echo "$ALL_DCES" | jq -r '.[] | "  - \(.name) (location: \(.location))"' | head -10
    
    # Check for DCE in cluster region
    REGIONAL_DCE=$(echo "$ALL_DCES" | jq -r --arg loc "$CLUSTER_LOC" '.[] | select(.location == $loc) | .name' | head -1)
    
    if [[ -n "$REGIONAL_DCE" ]]; then
        REGIONAL_DCE_RG=$(echo "$ALL_DCES" | jq -r --arg name "$REGIONAL_DCE" '.[] | select(.name == $name) | .id' | grep -oP '(?<=resourceGroups/)[^/]+' | head -1)
        REGIONAL_DCE_ID="/subscriptions/$SUBSCRIPTION/resourceGroups/$REGIONAL_DCE_RG/providers/Microsoft.Insights/dataCollectionEndpoints/$REGIONAL_DCE"
        
        log_info "Found DCE in cluster region ($CLUSTER_LOC): $REGIONAL_DCE"
        REMEDIATION+=("Update DCR to use regional DCE: az monitor data-collection rule update --name '$DCR_NAME' --resource-group '$DCR_RG' --data-collection-endpoint-id '$REGIONAL_DCE_ID'")
    else
        log_warn "No DCE found in cluster region ($CLUSTER_LOC)"
        log_info "  Available DCE regions: $(echo "$ALL_DCES" | jq -r '[.[].location] | unique | join(", ")')"
        REMEDIATION+=("Create DCE in cluster region: az monitor data-collection endpoint create --name dce-$CLUSTER_LOC --resource-group $RESOURCE_GROUP --location $CLUSTER_LOC")
    fi
else
    log_fail "NO Data Collection Endpoints found in subscription"
    REMEDIATION+=("Create DCE: az monitor data-collection endpoint create --name dce-$CLUSTER_LOC --resource-group $RESOURCE_GROUP --location $CLUSTER_LOC --public-network-access Enabled")
fi

fi

#------------------------------------------------------

# DCE-DCR-AMW Chain Validation Summary

#------------------------------------------------------
log_subsection "Complete Data Flow Chain Validation"

echo ""
log_info "Checking complete metrics flow chain:"
echo ""

CHAIN_OK=true

# Check 1: DCR Association

if [[ "$DCR_COUNT" -gt 0 ]]; then
echo -e "  ${GREEN}[OK]${NC} DCR Association exists"
else
echo -e "  ${RED}[X]${NC} DCR Association MISSING"
CHAIN_OK=false
fi

# Check 2: DCE in DCR

if [[ -n "${DCE_IN_DCR:-}" ]]; then
echo -e "  ${GREEN}[OK]${NC} DCE configured in DCR: $DCE_NAME"
else
echo -e "  ${RED}[X]${NC} DCE NOT configured in DCR"
CHAIN_OK=false
fi

# Check 3: DCE Metrics Ingestion Endpoint

if [[ -n "${METRICS_EP:-}" ]]; then
echo -e "  ${GREEN}[OK]${NC} DCE metrics ingestion endpoint available"
else
echo -e "  ${RED}[X]${NC} DCE metrics ingestion endpoint MISSING"
CHAIN_OK=false
fi

# Check 4: AMW Destination

if [[ -n "${AMW_DEST:-}" ]]; then
echo -e "  ${GREEN}[OK]${NC} Azure Monitor Workspace destination configured"
else
echo -e "  ${RED}[X]${NC} Azure Monitor Workspace destination MISSING"
CHAIN_OK=false
fi

echo ""
if [[ "$CHAIN_OK" == "true" ]]; then
log_pass "Complete DCE-DCR-AMW chain is properly configured"
else
log_fail "DCE-DCR-AMW chain has gaps - metrics cannot flow end-to-end"
fi

#------------------------------------------------------

# Phase 5: Azure Monitor Workspace

#------------------------------------------------------
log_section "PHASE 5: AZURE MONITOR WORKSPACE"

log_subsection "Workspace Validation"

AMW_DETAILS=$(az monitor account show \
--name "$AMW_NAME" \
--resource-group "$AMW_RG" \
--output json 2>/dev/null) || AMW_DETAILS=""

if [[ -n "$AMW_DETAILS" ]]; then
log_pass "Azure Monitor Workspace exists: $AMW_NAME"

# Check provisioning state
AMW_STATE=$(echo "$AMW_DETAILS" | jq -r '.provisioningState')
if [[ "$AMW_STATE" == "Succeeded" ]]; then
    log_pass "Workspace provisioning state: Succeeded"
else
    log_fail "Workspace provisioning state: $AMW_STATE"
fi

# Check location alignment
AMW_LOC=$(echo "$AMW_DETAILS" | jq -r '.location')
log_info "  Location: $AMW_LOC"

if [[ "$AMW_LOC" == "$CLUSTER_LOC" ]]; then
    log_pass "Workspace is in same region as cluster"
else
    log_warn "Workspace ($AMW_LOC) is in different region than cluster ($CLUSTER_LOC)"
fi

# Check Prometheus query endpoint
QUERY_EP=$(echo "$AMW_DETAILS" | jq -r '.metrics.prometheusQueryEndpoint // empty')
if [[ -n "$QUERY_EP" ]]; then
    log_pass "Prometheus query endpoint available"
    log_info "  Endpoint: $QUERY_EP"
else
    log_warn "No Prometheus query endpoint found"
fi

else
log_fail "Azure Monitor Workspace '$AMW_NAME' not found in resource group '$AMW_RG'"
fi

#------------------------------------------------------

# Phase 6: Grafana Integration

#------------------------------------------------------
log_section "PHASE 6: GRAFANA INTEGRATION"

log_subsection "Grafana Instance"

GRAF_DETAILS=$(az grafana show \
--name "$GRAF_NAME" \
--resource-group "$GRAF_RG" \
--output json 2>/dev/null) || GRAF_DETAILS=""

if [[ -n "$GRAF_DETAILS" ]]; then
log_pass "Grafana instance exists: $GRAF_NAME"

# Check provisioning state
GRAF_STATE=$(echo "$GRAF_DETAILS" | jq -r '.properties.provisioningState')
if [[ "$GRAF_STATE" == "Succeeded" ]]; then
    log_pass "Grafana provisioning state: Succeeded"
else
    log_fail "Grafana provisioning state: $GRAF_STATE"
fi

# Get Grafana endpoint
GRAF_ENDPOINT=$(echo "$GRAF_DETAILS" | jq -r '.properties.endpoint')
log_info "  Endpoint: $GRAF_ENDPOINT"

# Get Grafana managed identity
GRAF_IDENTITY=$(echo "$GRAF_DETAILS" | jq -r '.identity.principalId // empty')

log_subsection "Data Sources"

# Check data sources
DS=$(az grafana data-source list \
    --name "$GRAF_NAME" \
    --resource-group "$GRAF_RG" \
    --output json 2>/dev/null) || DS="[]"

DS_COUNT=$(echo "$DS" | jq 'length')
log_info "Found $DS_COUNT data source(s)"

# Check for Prometheus data source
PROM_DS=$(echo "$DS" | jq -r '.[] | select(.type | test("prometheus";"i")) | .name' | head -1)

if [[ -n "$PROM_DS" ]]; then
    log_pass "Prometheus data source configured: $PROM_DS"
else
    log_fail "No Prometheus data source found in Grafana"
    REMEDIATION+=("Add Azure Managed Prometheus as a data source in Grafana")
fi

log_subsection "Grafana RBAC on Azure Monitor Workspace"

if [[ -n "$GRAF_IDENTITY" ]]; then
    log_info "Grafana Managed Identity: $GRAF_IDENTITY"
    
    # Check role assignments
    ROLES=$(az role assignment list \
        --assignee "$GRAF_IDENTITY" \
        --scope "$AZURE_MONITOR_ID" \
        --output json 2>/dev/null) || ROLES="[]"
    
    ROLE_COUNT=$(echo "$ROLES" | jq 'length')
    
    if [[ "$ROLE_COUNT" -gt 0 ]]; then
        log_pass "Grafana has $ROLE_COUNT role assignment(s) on Azure Monitor Workspace"
        echo "$ROLES" | jq -r '.[].roleDefinitionName' | while read -r role; do
            log_info "  Role: $role"
        done
    else
        log_fail "Grafana has NO permissions on Azure Monitor Workspace"
        REMEDIATION+=("Grant Grafana access: az role assignment create --assignee $GRAF_IDENTITY --role 'Monitoring Reader' --scope $AZURE_MONITOR_ID")
    fi
else
    log_warn "Could not determine Grafana managed identity"
fi

else
log_fail "Grafana instance '$GRAF_NAME' not found in resource group '$GRAF_RG'"
fi

#------------------------------------------------------

# Phase 7: Network Connectivity

#------------------------------------------------------
log_section "PHASE 7: NETWORK CONNECTIVITY"

if [[ "$SKIP_KUBECTL" != "true" ]]; then
log_info "Required endpoints for metrics ingestion:"
log_info "  - *.monitor.azure.com"
log_info "  - *.ingest.monitor.azure.com"
log_info "  - ${CLUSTER_LOC}.monitoring.azure.com"

if [[ -n "${METRICS_EP:-}" ]]; then
    log_info "  - $METRICS_EP (DCE endpoint)"
fi

log_subsection "Network Policies"

NET_POL=$(kubectl get networkpolicy -A --no-headers 2>/dev/null | wc -l || echo "0")

if [[ "$NET_POL" -gt 0 ]]; then
    log_warn "Found $NET_POL NetworkPolicy objects in cluster"
    log_info "  Verify egress to Azure Monitor endpoints is allowed"
else
    log_pass "No NetworkPolicies found (egress unrestricted)"
fi

else
log_warn "Skipping network checks (kubectl not available)"
fi

#------------------------------------------------------

# Summary Report

#------------------------------------------------------
log_section "VALIDATION SUMMARY"

echo ""
echo -e "${BOLD}Configuration:${NC}"
echo "  Cluster:            $CLUSTER_NAME"
echo "  Cluster Location:   $CLUSTER_LOC"
echo "  Resource Group:     $RESOURCE_GROUP"
echo "  Subscription:       $SUBSCRIPTION"
echo "  AMW:                $AMW_NAME"
echo "  Grafana:            $GRAF_NAME"
echo "  DCR:                ${DCR_NAME:-NOT FOUND}"
echo "  DCE:                ${DCE_NAME:-NOT CONFIGURED}"
echo ""
echo -e "${BOLD}Results:${NC}"
echo -e "  ${GREEN}Passed:${NC}   $PASSED"
echo -e "  ${RED}Failed:${NC}   $FAILED"
echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "  Total:    $TOTAL"
echo ""

# Determine overall status

if [[ "$FAILED" -eq 0 ]]; then
echo -e "${GREEN}${BOLD}STATUS: HEALTHY${NC}"
echo "All critical checks passed. Monitoring pipeline should be functioning."
elif [[ "$FAILED" -le 3 ]]; then
echo -e "${YELLOW}${BOLD}STATUS: DEGRADED${NC}"
echo "Some issues detected. Review failed checks below."
else
echo -e "${RED}${BOLD}STATUS: UNHEALTHY${NC}"
echo "Multiple issues detected. Monitoring pipeline is likely not functioning."
fi

# List failed items

if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
echo ""
echo -e "${RED}${BOLD}Failed Checks:${NC}"
for item in "${FAILED_ITEMS[@]}"; do
echo -e "  ${RED}x${NC} $item"
done
fi

# List remediation steps

if [[ ${#REMEDIATION[@]} -gt 0 ]]; then
echo ""
echo -e "${CYAN}${BOLD}Remediation Steps:${NC}"
i=1
for step in "${REMEDIATION[@]}"; do
echo "  $i. $step"
((i++))
done
fi

echo ""
echo -e "${BOLD}======================================================================${NC}"

# Exit with appropriate code

[[ "$FAILED" -gt 0 ]] && exit 1 || exit 0