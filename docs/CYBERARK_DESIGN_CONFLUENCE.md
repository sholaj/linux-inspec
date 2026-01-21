# CyberArk Enterprise Credential Management Design

| **Document Type** | Design Document |
|-------------------|-----------------|
| **Status** | Draft |
| **Owner** | DevOps Engineering - Database Compliance |
| **Last Updated** | January 2026 |
| **Stakeholders** | Database Administrators, Security Team, Affiliate IT Teams |

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current State Analysis](#current-state-analysis)
3. [Problem Statement](#problem-statement)
4. [Options Analysis](#options-analysis)
5. [Recommended Approach](#recommended-approach)
6. [CyberArk Integration Architecture](#cyberark-integration-architecture)
7. [Implementation Roadmap](#implementation-roadmap)
8. [Decision Matrix](#decision-matrix)
9. [Appendix](#appendix)

---

## Executive Summary

This document proposes a strategic decision for enterprise database credential management to support automated compliance scanning across **~205 databases** (approximately 100 MSSQL and 105 Sybase instances). The organization faces a critical challenge: **disparate password management tools across affiliates** create operational complexity, security inconsistencies, and onboarding friction.

### Key Decision Required

| Option | Description | Recommendation |
|--------|-------------|----------------|
| **Option A** | Status Quo - Adapt Ansible for current per-affiliate password management (Cloakware, UMW) | Not Recommended |
| **Option B** | CyberArk - Centralized credential provider for all affiliates | **Recommended** |

---

## Current State Analysis

### Affiliate Password Management Landscape

Different business units currently rely on disparate credential management toolsets:

| Tool | Affiliates Using | Characteristics |
|------|------------------|-----------------|
| **Cloakware** | Multiple affiliates | Legacy credential vaulting, limited API support |
| **UMW (User Maintenance)** | Multiple affiliates | Also known as USM (Universal Secret Manager), varying implementations |
| **Manual/Local** | Some affiliates | Spreadsheets, local password files, configuration files |

### Current Challenges

```
+------------------+     +------------------+     +------------------+
|   Affiliate A    |     |   Affiliate B    |     |   Affiliate C    |
|   (Cloakware)    |     |     (UMW)        |     |   (Manual)       |
+--------+---------+     +--------+---------+     +--------+---------+
         |                        |                        |
         v                        v                        v
+------------------+     +------------------+     +------------------+
|  Custom Scripts  |     |  Custom Scripts  |     |  Custom Scripts  |
|  for Retrieval   |     |  for Retrieval   |     |  for Retrieval   |
+--------+---------+     +--------+---------+     +--------+---------+
         |                        |                        |
         +------------------------+------------------------+
                                  |
                                  v
                    +---------------------------+
                    |   AAP2 Compliance Scans   |
                    |   (Complex Integration)   |
                    +---------------------------+
```

### Pain Points Identified

| Pain Point | Impact | Severity |
|------------|--------|----------|
| **Fragmented Credential Storage** | Credentials scattered across multiple platforms with no unified retrieval mechanism | High |
| **Inconsistent Security Controls** | Each tool has different encryption, rotation, and access policies | High |
| **Onboarding Complexity** | Each new affiliate requires custom integration work | High |
| **Operational Overhead** | Multiple toolchains to maintain, monitor, and support | Medium |
| **Audit Challenges** | No centralized audit trail across all credential access | High |
| **Password Rotation** | Manual or inconsistent rotation schedules across tools | Medium |

---

## Problem Statement

> **How do we establish a unified, secure, and scalable credential management approach that simplifies affiliate onboarding while maintaining compliance requirements across ~205 databases?**

### Business Drivers

1. **Enterprise Standardization Initiative**: Executive mandate for uniform security controls across all business units
2. **Compliance Requirements**: NIST 800-53, CIS benchmarks require consistent credential management
3. **Operational Efficiency**: Reduce time-to-onboard new affiliates from weeks to days
4. **Security Posture**: Eliminate credential exposure risks from disparate tooling

---

## Options Analysis

### Option A: Status Quo with Ansible Adaptation

**Description**: Maintain current affiliate-specific password tools (Cloakware, UMW) and develop Ansible adapters for each.

#### Architecture

```
+------------------+     +------------------+     +------------------+
|   Cloakware      |     |      UMW         |     |   Future Tool    |
+--------+---------+     +--------+---------+     +--------+---------+
         |                        |                        |
         v                        v                        v
+------------------+     +------------------+     +------------------+
| Ansible Adapter  |     | Ansible Adapter  |     | Ansible Adapter  |
|   (Custom)       |     |   (Custom)       |     |   (Custom)       |
+--------+---------+     +--------+---------+     +--------+---------+
         |                        |                        |
         +------------------------+------------------------+
                                  |
                                  v
                    +---------------------------+
                    |        AAP2 Platform      |
                    +---------------------------+
```

#### Pros

| Advantage | Description |
|-----------|-------------|
| No Migration Required | Affiliates continue using existing tools |
| Lower Initial Cost | No new platform licensing |
| Familiar Tooling | Teams already trained on current tools |

#### Cons

| Disadvantage | Description |
|--------------|-------------|
| N Adapters Required | Each affiliate tool needs custom Ansible integration |
| Maintenance Burden | Multiple codebases to maintain, test, and update |
| Security Inconsistency | Cannot enforce uniform security policies |
| Scalability Issues | Adding new affiliates requires new adapter development |
| No Unified Audit | Audit trails remain fragmented |
| Technical Debt | Custom adapters accumulate technical debt over time |

#### Effort Estimate

| Component | Effort |
|-----------|--------|
| Cloakware Adapter Development | Medium |
| UMW Adapter Development | Medium |
| Per-Affiliate Testing | High (repeated for each) |
| Ongoing Maintenance | High (multiplied by number of tools) |

---

### Option B: CyberArk Centralized Credential Provider (Recommended)

**Description**: Implement CyberArk Central Credential Provider (CCP) as the enterprise-standard credential broker for all affiliates.

#### Architecture

```
+------------------+     +------------------+     +------------------+
|   Affiliate A    |     |   Affiliate B    |     |   Affiliate C    |
+--------+---------+     +--------+---------+     +--------+---------+
         |                        |                        |
         v                        v                        v
+------------------------------------------------------------------+
|                    CyberArk Enterprise Vault                      |
|                                                                   |
|  +------------+   +------------+   +------------+   +----------+  |
|  |  Safe A    |   |  Safe B    |   |  Safe C    |   | Safe ... |  |
|  | (Affiliate |   | (Affiliate |   | (Affiliate |   |          |  |
|  |    A)      |   |    B)      |   |    C)      |   |          |  |
|  +------------+   +------------+   +------------+   +----------+  |
|                                                                   |
+--------------------------------+---------------------------------+
                                 |
                                 | CCP REST API
                                 | (Certificate Authentication)
                                 v
                    +---------------------------+
                    |     AAP2 Platform         |
                    |  (Single Integration)     |
                    +---------------------------+
                                 |
                                 v
                    +---------------------------+
                    |   Database Compliance     |
                    |   Scanning (InSpec)       |
                    +---------------------------+
```

#### Pros

| Advantage | Description |
|-----------|-------------|
| Single Integration Point | One API to retrieve all credentials |
| Enterprise-Grade Security | Consistent encryption, rotation, and access policies |
| Simplified Onboarding | New affiliates only need credentials loaded into CyberArk |
| Unified Audit Trail | Complete visibility across all credential access |
| Automatic Rotation | Built-in password rotation policies |
| RBAC Compliance | Role-based access control out of the box |
| Certificate Authentication | Strong authentication via client certificates |

#### Cons

| Disadvantage | Description |
|--------------|-------------|
| Initial Migration Effort | Credentials must be migrated to CyberArk |
| Licensing Costs | CyberArk licensing fees apply |
| Training Required | Teams need CyberArk administration training |
| Dependency | Centralized dependency on CyberArk availability |

#### Effort Estimate

| Component | Effort |
|-----------|--------|
| CyberArk CCP Integration (One-Time) | Medium |
| Credential Migration (Per Affiliate) | Low |
| Per-Affiliate Testing | Low |
| Ongoing Maintenance | Low (single integration) |

---

## Recommended Approach

### Decision: Option B - CyberArk Central Credential Provider

CyberArk is recommended as the enterprise credential management solution for the following reasons:

#### 1. Scalability

```
Current State:                    Future State (CyberArk):

Affiliate 1 → Adapter 1           Affiliate 1 ─┐
Affiliate 2 → Adapter 2           Affiliate 2 ─┼─→ CyberArk → AAP2
Affiliate 3 → Adapter 3           Affiliate 3 ─┤
...                               Affiliate N ─┘
Affiliate N → Adapter N
                                  (Single Integration)
(N Integrations)
```

#### 2. Security Benefits

| Feature | CyberArk | Status Quo |
|---------|----------|------------|
| Centralized Audit | Yes | No |
| Automatic Rotation | Yes | Varies |
| Certificate Auth | Yes | Varies |
| Encryption Standard | AES-256 | Varies |
| RBAC | Yes | Varies |
| Dual Control | Yes | Limited |

#### 3. Onboarding Simplification

| Phase | Status Quo | CyberArk |
|-------|------------|----------|
| Tool Assessment | Required | Not Required |
| Adapter Development | Required | Not Required |
| Custom Testing | Required | Minimal |
| Credential Loading | Custom | Standard Process |
| Go-Live | Complex | Streamlined |

---

## CyberArk Integration Architecture

### AAP2 Custom Credential Type

```yaml
# CyberArk Database Credential Type
credential_type:
  name: CyberArk Database Credential
  description: Retrieves database credentials from CyberArk CCP

  inputs:
    fields:
      - id: cyberark_url
        type: string
        label: CyberArk CCP URL
        help_text: Base URL for CyberArk Central Credential Provider

      - id: app_id
        type: string
        label: Application ID
        help_text: Registered AAP2 AppID in CyberArk

      - id: safe_name
        type: string
        label: Safe Name
        help_text: CyberArk safe containing the credentials

      - id: object_name
        type: string
        label: Object Name
        help_text: Account identifier (e.g., SERVICE_ACCOUNT_ID)

      - id: cert_path
        type: string
        label: Client Certificate Path
        secret: false

      - id: cert_key_path
        type: string
        label: Client Certificate Key Path
        secret: true

  injectors:
    env:
      CYBERARK_URL: "{{ cyberark_url }}"
      CYBERARK_APP_ID: "{{ app_id }}"
      CYBERARK_SAFE: "{{ safe_name }}"
      CYBERARK_OBJECT: "{{ object_name }}"
    extra_vars:
      cyberark_safe: "{{ safe_name }}"
      cyberark_object: "{{ object_name }}"
```

### Credential Retrieval Flow

```
+------------------+     +------------------+     +------------------+
|   AAP2 Job       |     |   CyberArk CCP   |     |   Database       |
|   Template       |     |   REST API       |     |   Server         |
+--------+---------+     +--------+---------+     +--------+---------+
         |                        |                        |
         | 1. Request Credential  |                        |
         |  (Certificate Auth)    |                        |
         +----------------------->|                        |
         |                        |                        |
         | 2. Return Password     |                        |
         |<-----------------------+                        |
         |                        |                        |
         | 3. Inject into Env Var |                        |
         | (INSPEC_DB_PASSWORD)   |                        |
         +----------------------------------------------->|
         |                        |                        |
         | 4. Execute InSpec      |                        |
         |  Compliance Scan       |                        |
         |<-----------------------------------------------+
         |                        |                        |
```

### Service Account Configuration

| Parameter | Value | Notes |
|-----------|-------|-------|
| Service Account | `<SERVICE_ACCOUNT_ID>` | UNIX process account registered in CyberArk |
| Authentication | Certificate-Based | Client certificate preferred over username/password |
| Initial Environment | DEV | Start with development environment |
| Target Databases | MSSQL, Sybase, Oracle | ~205 total databases |

### Safe Structure Recommendation

```
CyberArk Vault
├── Safe: DB-Compliance-MSSQL
│   ├── Account: mssql-server01-1733
│   ├── Account: mssql-server02-1433
│   └── Account: mssql-server03-1433
│
├── Safe: DB-Compliance-Sybase
│   ├── Account: sybase-server01-5000
│   ├── Account: sybase-server02-5000
│   └── Account: sybase-server03-5000
│
└── Safe: DB-Compliance-Oracle
    ├── Account: oracle-server01-1521
    ├── Account: oracle-server02-1521
    └── Account: oracle-server03-1521
```

---

## Implementation Roadmap

### Phase 1: Foundation

| Task | Description | Dependencies |
|------|-------------|--------------|
| CyberArk Safe Setup | Create safes for database credentials | CyberArk admin access |
| AppID Registration | Register AAP2 as authorized application | CyberArk admin access |
| Certificate Generation | Generate client certificates for AAP2 | Security team approval |
| AAP2 Credential Type | Create custom credential type in AAP2 | AAP2 admin access |

### Phase 2: Pilot Migration

| Task | Description | Dependencies |
|------|-------------|--------------|
| Select Pilot Affiliate | Choose one affiliate for initial migration | Business stakeholder approval |
| Migrate Credentials | Load pilot affiliate credentials to CyberArk | Database team support |
| Integration Testing | Test AAP2 → CyberArk → Database flow | Phase 1 complete |
| Compliance Scan Validation | Run InSpec scans with CyberArk credentials | Integration testing complete |

### Phase 3: Affiliate Rollout

| Task | Description | Dependencies |
|------|-------------|--------------|
| Affiliate Onboarding Template | Create standardized onboarding process | Phase 2 complete |
| Credential Migration (per affiliate) | Load credentials for each affiliate | Affiliate coordination |
| Testing (per affiliate) | Validate scans work for each affiliate | Credential migration complete |
| Decommission Legacy Adapters | Remove Cloakware/UMW custom code | All affiliates migrated |

### Phase 4: Steady State

| Task | Description | Dependencies |
|------|-------------|--------------|
| Monitoring & Alerting | Implement CyberArk health monitoring | Phase 3 complete |
| Rotation Policies | Configure automatic password rotation | Security team approval |
| Documentation | Complete runbooks and troubleshooting guides | Phase 3 complete |

---

## Decision Matrix

### Weighted Criteria Evaluation

| Criteria | Weight | Option A (Status Quo) | Option B (CyberArk) |
|----------|--------|----------------------|---------------------|
| **Security** | 25% | 2/5 | 5/5 |
| **Scalability** | 20% | 2/5 | 5/5 |
| **Onboarding Speed** | 20% | 2/5 | 4/5 |
| **Operational Cost** | 15% | 2/5 | 4/5 |
| **Audit Compliance** | 15% | 2/5 | 5/5 |
| **Implementation Risk** | 5% | 4/5 | 3/5 |
| **Weighted Total** | 100% | **2.15/5** | **4.55/5** |

### Scoring Guide

| Score | Description |
|-------|-------------|
| 5 | Excellent - Fully meets requirements |
| 4 | Good - Meets most requirements |
| 3 | Adequate - Meets minimum requirements |
| 2 | Poor - Significant gaps |
| 1 | Unacceptable - Does not meet requirements |

---

## Appendix

### A. Affiliate Inventory

| Affiliate | Current Tool | Database Count | Migration Priority |
|-----------|--------------|----------------|-------------------|
| Affiliate A | Cloakware | ~50 MSSQL | High |
| Affiliate B | UMW | ~30 Sybase | High |
| Affiliate C | Cloakware | ~50 MSSQL | Medium |
| Affiliate D | UMW | ~75 Sybase | Medium |
| Additional | Various | Variable | Low |

### B. Security Requirements Alignment

| Requirement | CyberArk Capability |
|-------------|---------------------|
| TLS 1.2+ for API calls | Supported |
| Certificate authentication | Supported (preferred) |
| Dual control policies | Supported |
| No plaintext storage | Enforced |
| Immutable audit logs | Built-in |
| Automatic rotation | Configurable policies |

### C. Related Documentation

| Document | Location |
|----------|----------|
| Database Compliance Scanning Design | `docs/DATABASE_COMPLIANCE_SCANNING_DESIGN.md` |
| Security Password Handling | `docs/SECURITY_PASSWORD_HANDLING.md` |
| AAP Credential Mapping Guide | `docs/AAP_CREDENTIAL_MAPPING_GUIDE.md` |
| Service Account Permissions Request | `docs/request.md` |
| Original Demand Document | `docs/demand.md` |

### D. Glossary

| Term | Definition |
|------|------------|
| **AAP2** | Ansible Automation Platform 2 |
| **CCP** | CyberArk Central Credential Provider |
| **Cloakware** | Legacy credential vaulting solution |
| **UMW** | User Maintenance / Universal Secret Manager |
| **Safe** | CyberArk logical container for credentials |
| **AppID** | Application identifier registered in CyberArk |
| **InSpec** | Chef InSpec compliance scanning framework |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | January 2026 | DevOps Engineering | Initial draft |

---

## Approval

| Role | Name | Date | Status |
|------|------|------|--------|
| Technical Lead | | | Pending |
| Security Architect | | | Pending |
| Database Administrator | | | Pending |
| Business Stakeholder | | | Pending |
