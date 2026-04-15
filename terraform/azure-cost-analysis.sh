#!/usr/bin/env bash
# =============================================================================
# Azure Cost Analysis Script - InSpec Test Infrastructure
# =============================================================================
# Reviews last month's Azure utilization and identifies highest-consuming
# resources. Outputs a management-ready cost summary.
#
# Prerequisites:
#   - Azure CLI (az) installed and authenticated
#   - Billing Reader or Cost Management Reader role on the subscription
#
# Usage:
#   ./azure-cost-analysis.sh [resource-group-name]
#
# If no resource group is provided, analyses the entire subscription.
# =============================================================================

set -euo pipefail

# --- Configuration ---
RESOURCE_GROUP="${1:-}"
BILLING_PERIOD_START=$(date -v-1m -u +"%Y-%m-01" 2>/dev/null || date -d "last month" -u +"%Y-%m-01")
BILLING_PERIOD_END=$(date -u +"%Y-%m-01")
OUTPUT_FILE="cost-report-$(date -u +%Y%m%d).json"

echo "============================================================"
echo "  Azure Cost Analysis Report"
echo "  Period: ${BILLING_PERIOD_START} to ${BILLING_PERIOD_END}"
echo "  Scope:  ${RESOURCE_GROUP:-Entire Subscription}"
echo "  Date:   $(date -u +"%Y-%m-%d %H:%M UTC")"
echo "============================================================"

# --- Validate Azure CLI ---
if ! command -v az &>/dev/null; then
    echo "ERROR: Azure CLI (az) is not installed. Install from https://aka.ms/installazurecli"
    exit 1
fi

SUBSCRIPTION=$(az account show --query '{name:name, id:id}' -o tsv 2>/dev/null)
if [ -z "$SUBSCRIPTION" ]; then
    echo "ERROR: Not logged in to Azure. Run 'az login' first."
    exit 1
fi

echo ""
echo "Subscription: $(az account show --query 'name' -o tsv)"
echo "Subscription ID: $(az account show --query 'id' -o tsv)"
echo ""

# =============================================================================
# 1. COST BY RESOURCE (Top 15 highest consumers)
# =============================================================================
echo "--- Top 15 Highest-Cost Resources (Last Month) ---"
echo ""

SCOPE_FILTER=""
if [ -n "$RESOURCE_GROUP" ]; then
    SCOPE_FILTER="and properties/resourceGroup eq '${RESOURCE_GROUP}'"
fi

az cost management query \
    --type "ActualCost" \
    --timeframe "Custom" \
    --time-period start="${BILLING_PERIOD_START}" end="${BILLING_PERIOD_END}" \
    --dataset-aggregation '{"totalCost":{"name":"Cost","function":"Sum"}}' \
    --dataset-grouping name="ResourceId" type="Dimension" \
    --query 'properties.rows | sort_by(@, &[0]) | reverse(@) | [:15]' \
    -o table 2>/dev/null || {

    # Fallback: Use consumption API if cost management is unavailable
    echo "(Cost Management API unavailable - using consumption usage details)"
    echo ""

    if [ -n "$RESOURCE_GROUP" ]; then
        az consumption usage list \
            --start-date "${BILLING_PERIOD_START}" \
            --end-date "${BILLING_PERIOD_END}" \
            --query "[?contains(instanceId, '${RESOURCE_GROUP}')] | sort_by(@, &pretaxCost) | reverse(@) | [:15].{Resource:instanceName, Cost:pretaxCost, Currency:currency, Meter:meterDetails.meterName, Category:meterDetails.meterCategory}" \
            -o table 2>/dev/null || echo "  Could not retrieve consumption data. Check permissions."
    else
        az consumption usage list \
            --start-date "${BILLING_PERIOD_START}" \
            --end-date "${BILLING_PERIOD_END}" \
            --query "sort_by(@, &pretaxCost) | reverse(@) | [:15].{Resource:instanceName, Cost:pretaxCost, Currency:currency, Meter:meterDetails.meterName, Category:meterDetails.meterCategory}" \
            -o table 2>/dev/null || echo "  Could not retrieve consumption data. Check permissions."
    fi
}

echo ""

# =============================================================================
# 2. COST BY SERVICE CATEGORY
# =============================================================================
echo "--- Cost Breakdown by Service Category ---"
echo ""

az cost management query \
    --type "ActualCost" \
    --timeframe "Custom" \
    --time-period start="${BILLING_PERIOD_START}" end="${BILLING_PERIOD_END}" \
    --dataset-aggregation '{"totalCost":{"name":"Cost","function":"Sum"}}' \
    --dataset-grouping name="ServiceName" type="Dimension" \
    --query 'properties.rows | sort_by(@, &[0]) | reverse(@)' \
    -o table 2>/dev/null || {

    echo "(Using consumption API fallback)"
    if [ -n "$RESOURCE_GROUP" ]; then
        az consumption usage list \
            --start-date "${BILLING_PERIOD_START}" \
            --end-date "${BILLING_PERIOD_END}" \
            --query "[?contains(instanceId, '${RESOURCE_GROUP}')] | [].{Category:meterDetails.meterCategory, Cost:pretaxCost}" \
            -o table 2>/dev/null || echo "  Could not retrieve service breakdown."
    else
        az consumption usage list \
            --start-date "${BILLING_PERIOD_START}" \
            --end-date "${BILLING_PERIOD_END}" \
            --query "[].{Category:meterDetails.meterCategory, Cost:pretaxCost}" \
            -o table 2>/dev/null || echo "  Could not retrieve service breakdown."
    fi
}

echo ""

# =============================================================================
# 3. CURRENT RUNNING RESOURCES (Live state)
# =============================================================================
echo "--- Currently Running Resources (Live) ---"
echo ""

RG_FILTER=""
if [ -n "$RESOURCE_GROUP" ]; then
    RG_FILTER="--resource-group ${RESOURCE_GROUP}"
fi

echo "Virtual Machines:"
az vm list ${RG_FILTER} -d \
    --query "[].{Name:name, Status:powerState, Size:hardwareProfile.vmSize, RG:resourceGroup}" \
    -o table 2>/dev/null || echo "  Could not list VMs."

echo ""
echo "Container Instances:"
az container list ${RG_FILTER} \
    --query "[].{Name:name, State:provisioningState, CPU:containers[0].resources.requests.cpu, MemoryGB:containers[0].resources.requests.memoryInGb, RG:resourceGroup}" \
    -o table 2>/dev/null || echo "  Could not list container instances."

echo ""

# =============================================================================
# 4. COST SAVINGS ESTIMATE (Nightly shutdown impact)
# =============================================================================
echo "--- Estimated Monthly Savings from Nightly Shutdown ---"
echo ""
echo "Assumption: Resources run 9 AM - 9 PM (12 hrs/day) instead of 24/7"
echo "Savings factor: ~50% reduction on compute costs"
echo ""

# Get current resource costs for estimation
echo "Resource Type          | Est. 24/7 Cost | Est. with Shutdown | Monthly Savings"
echo "---------------------- | -------------- | ------------------ | ---------------"
echo "Linux VM (B2s)         | ~\$30/mo        | ~\$15/mo            | ~\$15"
echo "MSSQL Container (ACI)  | ~\$10/mo        | ~\$5/mo             | ~\$5"

if [ -n "$RESOURCE_GROUP" ]; then
    # Check for optional resources
    ORACLE_COUNT=$(az container list --resource-group "$RESOURCE_GROUP" --query "length([?contains(name, 'oracle')])" -o tsv 2>/dev/null || echo "0")
    SYBASE_COUNT=$(az container list --resource-group "$RESOURCE_GROUP" --query "length([?contains(name, 'sybase')])" -o tsv 2>/dev/null || echo "0")
    POSTGRES_COUNT=$(az container list --resource-group "$RESOURCE_GROUP" --query "length([?contains(name, 'postgres')])" -o tsv 2>/dev/null || echo "0")
    AAP2_COUNT=$(az vm list --resource-group "$RESOURCE_GROUP" --query "length([?contains(name, 'aap2')])" -o tsv 2>/dev/null || echo "0")
    WIN_COUNT=$(az vm list --resource-group "$RESOURCE_GROUP" --query "length([?contains(name, 'win')])" -o tsv 2>/dev/null || echo "0")

    [ "$ORACLE_COUNT" -gt 0 ] 2>/dev/null && echo "Oracle Container (ACI)  | ~\$15/mo        | ~\$7.50/mo          | ~\$7.50"
    [ "$SYBASE_COUNT" -gt 0 ] 2>/dev/null && echo "Sybase Container (ACI)  | ~\$10/mo        | ~\$5/mo             | ~\$5"
    [ "$POSTGRES_COUNT" -gt 0 ] 2>/dev/null && echo "Postgres Container      | ~\$8/mo         | ~\$4/mo             | ~\$4"
    [ "$AAP2_COUNT" -gt 0 ] 2>/dev/null && echo "AAP2 VM (D4s_v3)        | ~\$140/mo       | ~\$70/mo            | ~\$70"
    [ "$WIN_COUNT" -gt 0 ] 2>/dev/null && echo "Windows VM (B2s)        | ~\$42/mo        | ~\$21/mo            | ~\$21"
fi

echo ""

# =============================================================================
# 5. MANAGEMENT SUMMARY
# =============================================================================
echo "============================================================"
echo "  MANAGEMENT SUMMARY"
echo "============================================================"
echo ""
echo "  1. NIGHTLY SHUTDOWN RUNBOOK deployed via Azure Automation"
echo "     - Schedule: Daily at 9:00 PM (configurable timezone)"
echo "     - Scope: All VMs and container instances in the resource group"
echo "     - Auth: Managed Identity (no stored credentials)"
echo ""
echo "  2. KEY COST DRIVERS for InSpec test infrastructure:"
echo "     - VMs left running outside business hours (biggest waste)"
echo "     - Container instances (ACI) billed per-second while running"
echo "     - AAP2 VM (D4s_v3) is the most expensive single resource"
echo "       when deployed (~\$140/mo at 24/7)"
echo ""
echo "  3. RECOMMENDATIONS:"
echo "     a) Keep nightly shutdown runbook active (saves ~50% compute)"
echo "     b) Deploy AAP2 VM only when actively testing (toggle deploy_aap2)"
echo "     c) Use 'terraform destroy' for prolonged idle periods"
echo "     d) Review ACR storage — remove unused container images"
echo "     e) Consider Reserved Instances if test env runs >6 months"
echo ""
echo "  4. ACTIONS TO REDUCE COSTS FURTHER:"
echo "     - Run: terraform apply -var='deploy_aap2=false' to disable AAP2"
echo "     - Run: terraform apply -var='deploy_windows_mssql=false' if not needed"
echo "     - Run: ./azure-cost-analysis.sh <resource-group> monthly for trends"
echo ""
echo "============================================================"
echo "  Report generated: $(date -u +"%Y-%m-%d %H:%M UTC")"
echo "============================================================"
