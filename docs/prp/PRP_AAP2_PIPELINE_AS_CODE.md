# PRP: AAP2 Pipeline as Code and Job Template Testing

## Product Requirement Prompt/Plan

**Purpose:** Define requirements and implementation strategy for AAP2 Pipeline as Code, enabling automated provisioning and testing of job templates, workflows, and credential types.

---

## 1. Requirements Questionnaire

### 1.1 Environment and Access

| # | Question | Options | Notes |
|---|----------|---------|-------|
| Q1 | What is your AAP2 deployment model? | a) Containerized (podman) b) Traditional RPM c) OpenShift Operator d) Not yet deployed | Affects automation approach |
| Q2 | What AAP2 version are you targeting? | a) 2.4+ b) 2.3 c) 2.2 d) Unknown | API compatibility varies |
| Q3 | Do you have API access to AAP2 Controller? | a) Yes - admin token b) Yes - service account c) No access yet d) Need to request | Required for automation |
| Q4 | How will credentials be managed? | a) AAP2 Credential Manager b) CyberArk/Vault integration c) Manual entry d) HashiCorp Vault | Affects credential type design |
| Q5 | Is there an existing execution environment? | a) Yes - custom EE b) Using default EE c) Need to build d) Not sure | InSpec requires custom EE |

### 1.2 Scope and Platforms

| # | Question | Options | Notes |
|---|----------|---------|-------|
| Q6 | Which database platforms need job templates? | a) MSSQL only b) Oracle only c) Sybase only d) All platforms e) Subset (specify) | Determines templates needed |
| Q7 | How many database instances per platform? | a) 1-10 b) 11-50 c) 51-100 d) 100+ | Affects concurrency design |
| Q8 | Will you use multi-platform workflows? | a) Yes - all at once b) Yes - selected platforms c) No - individual only d) Not sure | Workflow vs job template |
| Q9 | Are there tiered rollout requirements? | a) Tier 1 (critical) first b) By affiliate/BU c) All at once d) Custom order | Scheduling considerations |
| Q10 | What environments need templates? | a) Dev only b) Dev + Staging c) Dev + Staging + Prod d) Prod only | Promotion workflow |

### 1.3 Integration Requirements

| # | Question | Options | Notes |
|---|----------|---------|-------|
| Q11 | Will results go to Splunk? | a) Yes - Splunk Cloud b) Yes - Splunk Enterprise c) No - file only d) Different SIEM | Splunk HEC credential |
| Q12 | Is ServiceNow integration needed? | a) Yes - CMDB update b) Yes - incident creation c) No d) Not sure | SNOW credential type |
| Q13 | How will inventories be sourced? | a) Static YAML b) Dynamic from CMDB c) Constructed inventory d) AAP2 sourced | Inventory source config |
| Q14 | What notification channels are needed? | a) Email b) Slack c) Teams d) PagerDuty e) None | Notification template |
| Q15 | Git repository for project? | a) GitHub b) GitLab c) Azure DevOps d) Bitbucket e) On-prem Git | Project SCM config |

### 1.4 Scheduling and Operations

| # | Question | Options | Notes |
|---|----------|---------|-------|
| Q16 | What is the scan frequency? | a) Daily b) Weekly c) Monthly d) On-demand e) Multiple | Schedule template |
| Q17 | Preferred maintenance window? | a) Business hours b) Off-hours (night) c) Weekend d) No preference | Schedule configuration |
| Q18 | Timeout requirements? | a) 30 min b) 1 hour c) 2 hours d) 4+ hours | Job timeout setting |
| Q19 | Concurrency (forks) preference? | a) 1 (sequential) b) 5 (balanced) c) 10 (parallel) d) Custom | Performance tuning |
| Q20 | Result retention policy? | a) 30 days b) 90 days c) 1 year d) Indefinite | Cleanup automation |

### 1.5 Testing and Validation

| # | Question | Options | Notes |
|---|----------|---------|-------|
| Q21 | Testing environment available? | a) Azure test infra b) On-prem test env c) Production subset d) None | Testing strategy |
| Q22 | CI/CD pipeline for AAP2 changes? | a) GitHub Actions b) GitLab CI c) Jenkins d) Azure DevOps e) None | Pipeline integration |
| Q23 | Approval workflow needed? | a) Yes - manual gate b) Yes - automated checks c) No d) Different by env | Promotion process |
| Q24 | Rollback strategy? | a) Git revert + redeploy b) AAP2 backup/restore c) Manual d) Not defined | DR/rollback plan |
| Q25 | Compliance reporting needed? | a) Executive dashboard b) Technical reports c) Both d) None | Reporting requirements |

---

## 2. Current State Analysis

### 2.1 Existing AAP2 Configuration

**Location:** `aap2-config/`

```
aap2-config/
├── credential-types/
│   ├── mssql-database.json      # Custom credential type for MSSQL
│   ├── oracle-database.json     # Custom credential type for Oracle
│   ├── sybase-database.json     # Custom credential type for Sybase
│   ├── postgres-database.json   # Custom credential type for PostgreSQL
│   └── splunk-hec.json          # Splunk HEC credential type
├── job-templates/
│   ├── mssql-compliance-scan.yml    # MSSQL job template spec
│   ├── oracle-compliance-scan.yml   # Oracle job template spec
│   ├── sybase-compliance-scan.yml   # Sybase job template spec
│   ├── postgres-compliance-scan.yml # PostgreSQL job template spec
│   └── multi-platform-scan.yml      # Combined scan template
├── workflows/
│   └── full-compliance-workflow.yml # Multi-platform workflow
└── inventories/
    └── aap2-inventory-example.yml   # Sample inventory structure
```

### 2.2 Existing Documentation

| Document | Purpose | Status |
|----------|---------|--------|
| `AAP2_DEPLOYMENT_GUIDE.md` | Azure deployment instructions | Complete |
| `AAP_CREDENTIAL_MAPPING_GUIDE.md` | Credential type reference | Complete |
| `AAP_MESH_ARCHITECTURE_GUIDE.md` | Mesh topology design | Complete |

### 2.3 Terraform Infrastructure

| Resource | Status | Notes |
|----------|--------|-------|
| AAP2 VM (D4s_v3) | Optional | `deploy_aap2=true` |
| Runner VM (B2s) | Deployed | InSpec delegate host |
| Database containers | Deployed | MSSQL, Oracle, Sybase, PostgreSQL |
| ACR | Deployed | Execution environment registry |

---

## 3. Pipeline as Code Design

### 3.1 Configuration Management Approach

**Option A: YAML-Based Configuration (Recommended)**
```yaml
# config/aap2/templates.yml
templates:
  - name: mssql-compliance-scan
    type: job_template
    spec_file: job-templates/mssql-compliance-scan.yml

workflows:
  - name: full-compliance-workflow
    type: workflow
    spec_file: workflows/full-compliance-workflow.yml
```

**Option B: Ansible Collection (awx.awx)**
```yaml
# playbooks/configure_aap2.yml
- name: Configure AAP2 Pipeline as Code
  hosts: localhost
  collections:
    - awx.awx
  tasks:
    - name: Create job templates
      include_role:
        name: aap2_job_templates
```

**Option C: Terraform Provider (ansible/aap)**
```hcl
resource "aap_job_template" "mssql_scan" {
  name        = "MSSQL Compliance Scan"
  inventory   = aap_inventory.compliance.id
  project     = aap_project.linux_inspec.id
  playbook    = "test_playbooks/run_mssql_inspec.yml"
}
```

### 3.2 Recommended Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Git Repository (Source of Truth)                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │ aap2-config/    │  │ test_playbooks/ │  │ roles/                      │  │
│  │ - templates     │  │ - run_*.yml     │  │ - mssql_inspec/             │  │
│  │ - workflows     │  │                 │  │ - oracle_inspec/            │  │
│  │ - credentials   │  │                 │  │ - sybase_inspec/            │  │
│  └────────┬────────┘  └────────┬────────┘  └──────────────┬──────────────┘  │
└───────────┼─────────────────────┼──────────────────────────┼────────────────┘
            │                     │                          │
            ▼                     ▼                          ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                            CI/CD Pipeline                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ Lint/Validate │──▶│ Test (Azure) │──▶│ Deploy DEV  │──▶│ Promote to PROD │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────────┘   │
└───────────────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                            AAP2 Controller                                     │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │ Organizations  │  Projects  │  Inventories  │  Credentials  │ Schedules │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │ Job Templates  │  Workflow Templates  │  Notification Templates         │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Workflow Patterns

**Pattern 1: Sequential Platform Scan**
```
Start → MSSQL Scan → Oracle Scan → Sybase Scan → Generate Report → End
```

**Pattern 2: Parallel Platform Scan**
```
        ┌→ MSSQL Scan  ─┐
Start ──┼→ Oracle Scan ─┼→ Aggregate Results → Generate Report → End
        └→ Sybase Scan ─┘
```

**Pattern 3: Tiered Rollout**
```
Start → Tier 1 (Critical) → Approval → Tier 2 → Approval → Tier 3 → End
```

**Pattern 4: Per-Affiliate Workflow**
```
        ┌→ BU-1 Workflow ─┐
Start ──┼→ BU-2 Workflow ─┼→ Consolidation → Reporting → End
        └→ BU-3 Workflow ─┘
```

---

## 4. Testing Strategy

### 4.1 Test Levels

| Level | Scope | Tools | Automation |
|-------|-------|-------|------------|
| Unit | Individual controls | InSpec verify | CI pipeline |
| Integration | Role execution | Ansible + Azure | CI pipeline |
| System | Full workflow | AAP2 API | Scheduled |
| Acceptance | Production subset | AAP2 UI/API | Manual gate |

### 4.2 Test Scenarios

| ID | Scenario | Expected Result | Priority |
|----|----------|-----------------|----------|
| T1 | Job template creation | Template visible in AAP2 | P1 |
| T2 | Credential type registration | Custom type available | P1 |
| T3 | Single database scan | JSON output generated | P1 |
| T4 | Multi-database scan | All databases scanned | P1 |
| T5 | Workflow execution | All nodes complete | P2 |
| T6 | Failure handling | Skip report generated | P2 |
| T7 | Splunk integration | Events in Splunk | P3 |
| T8 | Schedule execution | Job runs at scheduled time | P2 |

### 4.3 Azure Test Infrastructure

```bash
# Deploy test environment
cd terraform
terraform apply \
  -var="deploy_aap2=true" \
  -var="deploy_oracle=true" \
  -var="deploy_sybase=true"

# Run integration tests
ansible-playbook -i test_inventory.yml test_playbooks/run_compliance_scans.yml

# Validate results
ls -la /tmp/compliance_scans/*.json
```

---

## 5. Implementation Phases

### Phase 1: Foundation (Week 1-2)
- [ ] Answer questionnaire (Section 1)
- [ ] Validate existing aap2-config/ structure
- [ ] Create/update credential types
- [ ] Test basic job template in AAP2 UI

### Phase 2: Automation (Week 3-4)
- [ ] Implement Pipeline as Code approach (3.1)
- [ ] Create CI/CD pipeline for validation
- [ ] Automate job template deployment
- [ ] Test workflow templates

### Phase 3: Integration (Week 5-6)
- [ ] Configure Splunk integration (if Q11 = Yes)
- [ ] Set up notification templates
- [ ] Implement scheduling
- [ ] Create operational runbooks

### Phase 4: Production Readiness (Week 7-8)
- [ ] Security review
- [ ] Performance testing
- [ ] Documentation completion
- [ ] Handover and training

---

## 6. Deliverables

| Deliverable | Description | Format |
|-------------|-------------|--------|
| Questionnaire Responses | Completed Section 1 | Markdown/Confluence |
| AAP2 Configuration | Updated aap2-config/ | YAML/JSON |
| CI/CD Pipeline | GitHub Actions/GitLab CI | YAML |
| Test Results | Integration test evidence | JSON/HTML |
| Runbook | Operational procedures | Markdown |
| Training Materials | User guide | Markdown/Video |

---

## 7. Decision Log

| Date | Decision | Rationale | Owner |
|------|----------|-----------|-------|
| TBD | Pipeline as Code approach | Based on Q22 response | DevOps |
| TBD | Workflow pattern | Based on Q8, Q9 responses | DevOps |
| TBD | Testing strategy | Based on Q21 response | DevOps |

---

## Appendix A: AAP2 API Reference

### Authentication
```bash
# Get OAuth token
curl -X POST https://aap2.example.com/api/v2/tokens/ \
  -H "Content-Type: application/json" \
  -d '{"description": "CI/CD Token", "scope": "write"}'
```

### Create Job Template
```bash
curl -X POST https://aap2.example.com/api/v2/job_templates/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @job-templates/mssql-compliance-scan.json
```

### Launch Job
```bash
curl -X POST https://aap2.example.com/api/v2/job_templates/123/launch/ \
  -H "Authorization: Bearer $TOKEN"
```

---

## Appendix B: Related Documentation

- [AAP2 Deployment Guide](../AAP2_DEPLOYMENT_GUIDE.md)
- [AAP Credential Mapping Guide](../AAP_CREDENTIAL_MAPPING_GUIDE.md)
- [AAP Mesh Architecture Guide](../AAP_MESH_ARCHITECTURE_GUIDE.md)
- [Database Compliance Scanning Design](../DATABASE_COMPLIANCE_SCANNING_DESIGN.md)
