# AAP Mesh Architecture Spike: Benefits Analysis

**Document Type:** Technical Spike / Architecture Decision Record
**Status:** Draft
**Author:** DevOps Engineering Team
**Date:** December 2024

---

## Executive Summary

This document analyzes the benefits of adopting AAP (Ansible Automation Platform) Mesh architecture versus the current delegate host architecture for database compliance scanning. Given our expanded requirements to support **Azure Cloud regions** and **affiliate/partner isolated environments**, the mesh architecture offers significant advantages in scalability, security isolation, and operational efficiency.

**Recommendation:** Proceed with AAP Mesh architecture for Phase 2 expansion.

---

## Current State: Delegate Host Architecture

### How It Works Today

```
┌─────────────────────────────────────┐
│   AAP Controller (Central)          │
│   - Job orchestration               │
│   - Web UI / API                    │
└──────────────┬──────────────────────┘
               │ SSH Connection
               ▼
        ┌──────────────┐
        │ Bastion Host │  ← Single delegate per environment
        │ (delegate)   │
        └──────┬───────┘
               │
    ┌──────────┼──────────┐
    ▼          ▼          ▼
  MSSQL     Oracle     Sybase
  Servers   Servers    Servers
```

### Current Limitations

| Limitation | Impact | Risk Level |
|------------|--------|------------|
| Single point of failure | If bastion fails, all scans stop | HIGH |
| Network bottleneck | All traffic through one server | MEDIUM |
| No geographic distribution | High latency to remote databases | MEDIUM |
| No tenant isolation | Partners share infrastructure | HIGH |
| Limited scalability | Cannot scale beyond ~50 databases efficiently | MEDIUM |

---

## Proposed State: AAP Mesh Architecture

### Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│              AAP Controller (Central Hub)                     │
│   - Orchestration & scheduling                               │
│   - Web UI / API / RBAC                                      │
│   - Job routing to mesh nodes                                │
└──────────────────────────┬───────────────────────────────────┘
                           │ Receptor Mesh Network
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
    ┌───────────┐    ┌───────────┐    ┌───────────┐
    │ Mesh Node │    │ Mesh Node │    │ Mesh Node │
    │ Azure     │    │ Azure     │    │ Partner   │
    │ East US   │    │ West EU   │    │ Isolated  │
    └─────┬─────┘    └─────┬─────┘    └─────┬─────┘
          │                │                │
    ┌─────┴─────┐    ┌─────┴─────┐    ┌─────┴─────┐
    │ East US   │    │ West EU   │    │ Partner   │
    │ Databases │    │ Databases │    │ Databases │
    └───────────┘    └───────────┘    └───────────┘
```

### Key Components

| Component | Role | Location |
|-----------|------|----------|
| **Controller Node** | Central orchestration, UI, API, job scheduling | On-premises or Azure |
| **Execution Nodes** | Run automation jobs locally | Each Azure region |
| **Hop Nodes** | Route traffic across network boundaries | DMZ / Network edges |
| **Receptor Network** | Encrypted mesh communication (WebSocket) | All nodes |

---

## Benefits of Mesh Architecture

### 1. Azure Cloud Region Support

**Current Problem:** Scanning databases in Azure East US from an on-premises bastion creates:
- High network latency (50-100ms round trip)
- Firewall complexity (multiple holes for SSH)
- Bandwidth constraints

**Mesh Solution:**
```
Azure East US Region
┌─────────────────────────────────────┐
│  ┌─────────────┐                    │
│  │ Mesh Node   │◄── Local execution │
│  │ (Execution) │                    │
│  └──────┬──────┘                    │
│         │                           │
│    ┌────┴────┐                      │
│    ▼         ▼                      │
│  MSSQL    Oracle                    │
│  DB1      DB2                       │
└─────────────────────────────────────┘
         ▲
         │ Receptor (WebSocket, single port)
         ▼
┌─────────────────────────────────────┐
│  AAP Controller (On-Prem/Azure)     │
└─────────────────────────────────────┘
```

**Benefits:**
| Metric | Delegate Host | Mesh Architecture | Improvement |
|--------|---------------|-------------------|-------------|
| Latency | 50-100ms | 5-10ms | 90% reduction |
| Firewall rules | Multiple SSH ports | Single WebSocket port | Simplified |
| Scan duration | ~30 min/database | ~5 min/database | 6x faster |
| Concurrent scans | Limited by bastion | Unlimited (per node) | Scalable |

### 2. Affiliate/Partner Isolation

**Current Problem:** Partners requiring compliance scans must either:
- Share our bastion infrastructure (security risk)
- Deploy their own AAP instance (cost/complexity)

**Mesh Solution:**
```
Partner A Environment (Isolated)
┌─────────────────────────────────────┐
│  ┌─────────────┐                    │
│  │ Mesh Node   │◄── Partner-dedicated│
│  │ (Isolated)  │    execution node   │
│  └──────┬──────┘                    │
│         │ Partner network only      │
│    ┌────┴────┐                      │
│    ▼         ▼                      │
│  Partner   Partner                  │
│  DB1       DB2                      │
└─────────────────────────────────────┘
         ▲
         │ Receptor (encrypted, authenticated)
         ▼
┌─────────────────────────────────────┐
│  AAP Controller (Our Control)       │
│  - RBAC: Partner A can only see     │
│    their own jobs/results           │
└─────────────────────────────────────┘
```

**Benefits:**
| Aspect | Current (Shared Bastion) | Mesh (Isolated Nodes) |
|--------|--------------------------|----------------------|
| Network isolation | None (shared) | Complete (dedicated node) |
| Credential exposure | Risk of cross-tenant | Zero (node-level isolation) |
| Audit trail | Commingled logs | Tenant-specific logs |
| Compliance (SOC2) | Difficult to prove | Clear boundaries |
| Partner onboarding | Complex (shared infra) | Simple (deploy node) |

### 3. High Availability & Resilience

**Current Risk:** Single bastion failure = all scans stop

**Mesh Solution:**
```
Node Failure Scenario:

Before failure:
  Controller → Node 1 (East US) → Databases

Node 1 fails:

  Controller → Node 2 (West US) → Databases
               (automatic failover)

Recovery time: < 30 seconds (automatic)
```

**Resilience Comparison:**
| Scenario | Delegate Host | Mesh Architecture |
|----------|---------------|-------------------|
| Bastion/Node failure | All scans stop | Auto-failover to other nodes |
| Network partition | Complete outage | Nodes continue independently |
| Maintenance window | Downtime required | Rolling updates (zero downtime) |
| Recovery time | Manual (30+ min) | Automatic (< 30 sec) |

### 4. Performance & Scalability

**Current Bottleneck:** All InSpec executions compete for bastion resources

**Mesh Solution:**
```
Parallel Execution Across Nodes:

Time 0:00
├─ Node 1 (East US): Scanning MSSQL-01, MSSQL-02
├─ Node 2 (West EU): Scanning Oracle-01, Oracle-02
└─ Node 3 (Partner): Scanning Sybase-01

Time 0:05 (all complete in parallel)
```

**Scalability Comparison:**
| Metric | Delegate Host | Mesh (3 nodes) | Mesh (10 nodes) |
|--------|---------------|----------------|-----------------|
| Max concurrent scans | 5-10 | 30-50 | 100+ |
| Databases supported | ~50 | ~200 | ~1000 |
| Scan throughput | 20 DBs/hour | 100 DBs/hour | 400+ DBs/hour |

### 5. Simplified Playbook Management

**Current Complexity:** Delegate host requires file copying logic

```yaml
# Current: Complex delegate handling
- name: Copy controls to delegate
  copy:
    src: "{{ role_path }}/files/controls/"
    dest: "/tmp/inspec_controls/"
  delegate_to: "{{ inspec_delegate_host }}"
  when: use_delegate_host | bool
```

**Mesh Solution:** No file copying needed - execution nodes have local access

```yaml
# Mesh: Simplified execution
- name: Execute InSpec scan
  command: inspec exec /opt/inspec/controls/ -t sqlserver://...
  # Runs locally on mesh node - no delegation needed
```

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)
- [ ] Deploy AAP Controller with HA database
- [ ] Configure receptor mesh network
- [ ] Deploy first execution node (primary region)
- [ ] Migrate existing scans to mesh

### Phase 2: Azure Expansion (Weeks 5-8)
- [ ] Deploy execution nodes in Azure East US
- [ ] Deploy execution nodes in Azure West Europe
- [ ] Configure node affinity for regional databases
- [ ] Validate latency improvements

### Phase 3: Partner Isolation (Weeks 9-12)
- [ ] Design partner onboarding process
- [ ] Deploy isolated execution nodes for partners
- [ ] Configure RBAC for multi-tenancy
- [ ] Document partner runbooks

### Phase 4: Optimization (Ongoing)
- [ ] Monitor and tune mesh performance
- [ ] Add nodes as needed for scale
- [ ] Decommission legacy bastion infrastructure

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Complex initial setup | HIGH | MEDIUM | Phased rollout, keep delegate as fallback |
| Learning curve | MEDIUM | LOW | Training, documentation, support |
| Network configuration | MEDIUM | HIGH | Work with network team early |

---

## Decision Matrix

| Requirement | Delegate Host | Mesh Architecture | Winner |
|-------------|---------------|-------------------|--------|
| Azure region support | Poor (high latency) | Excellent (local nodes) | Mesh |
| Partner isolation | Not possible | Native support | Mesh |
| High availability | No (SPOF) | Yes (auto-failover) | Mesh |
| Scalability | Limited (~50 DBs) | Excellent (1000+ DBs) | Mesh |
| Setup complexity | Simple | Complex | Delegate |
| Operational efficiency | Higher ops overhead | Lower (automation) | Mesh |

**Score:** Mesh 5, Delegate 1

---

## Recommendation

**Proceed with AAP Mesh Architecture** for the following reasons:

1. **Azure Cloud Support:** Native capability to place execution nodes in Azure regions reduces latency by 90% and simplifies firewall configuration

2. **Partner Isolation:** Critical requirement that cannot be met with delegate host architecture

3. **Future-Proof:** Scales to support 1000+ databases across multiple regions and partners

4. **Compliance:** Clear tenant boundaries support SOC2 and audit requirements

5. **Resilience:** Eliminates single point of failure, provides automatic failover

### Next Steps

1. **Approve** this architecture direction
2. **Assign** DevOps resources for implementation sprint
3. **Schedule** kickoff meeting with network team for firewall requirements
4. **Define** Azure regions and partner environments for initial rollout

---

## Appendix

### A. Technical Requirements for Mesh Nodes

| Requirement | Specification |
|-------------|---------------|
| OS | RHEL 8.x / 9.x |
| CPU | 4 cores minimum |
| RAM | 8 GB minimum |
| Disk | 50 GB |
| Network | Outbound port 27199 (receptor) |
| Software | receptor, ansible-runner |

### B. Receptor Mesh Configuration Example

```yaml
# receptor.conf for execution node
---
- node:
    id: mesh-node-eastus

- log-level:
    level: info

- tcp-peer:
    address: aap-controller.company.com:27199
    tls: receptor-tls

- work-command:
    worktype: ansible-runner
    command: ansible-runner
    params: worker
```

### C. References

- [AAP 2.4 Mesh Documentation](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/2.4)
- [Receptor Project](https://github.com/ansible/receptor)
- Internal: `AAP_MESH_ARCHITECTURE_GUIDE.md`

---

