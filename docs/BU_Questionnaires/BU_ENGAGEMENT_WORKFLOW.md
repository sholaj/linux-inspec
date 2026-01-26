# Business Unit Engagement Workflow

**Progression from Discovery Questionnaire → POC Assessment → MVP Onboarding → Profile**

---

## Purpose

This document outlines the **complete engagement lifecycle** for a Northstar Business Unit, from initial discovery questionnaire through to production rollout. It defines:
- **Stages:** Discovery → POC Planning → POC Execution → POC Findings → MVP Onboarding → Profile/BAU
- **Decision gates:** Go/No-Go criteria at each stage
- **Timelines:** Typical duration per stage (with factors affecting duration)
- **Responsibilities:** What the BU, Engagement Team, and cross-functional teams deliver at each stage
- **Artifacts:** Documents produced at each stage

---

---

# Stage 1: Discovery (Intake → Questionnaire → Discovery Meeting)

## 1.1 Intake Phase

**Objective:** Confirm business unit contact, identify regulatory drivers, establish engagement expectations.

**Duration:** 1–2 weeks

### Activities

| Activity | Owner | Duration | Deliverable |
|---|---|---|---|
| **Initial contact & availability check** | Engagement Lead | 2–3 days | BU primary contact confirmed, intake call scheduled |
| **Pre-discovery intake call** | Engagement Lead + BU Technology Owner | 30 min | Regulatory drivers identified, timeline expectations set, blockers surfaced |
| **Questionnaire customization (if needed)** | Engagement Lead | 2–3 days | Questionnaire adapted for BU-specific context (pre-filled contacts, regulatory focus, custom fields) |
| **Distribute questionnaire** | Engagement Lead | 1 day | Email with questionnaire, response guide, examples, submission deadline (1–2 weeks) |
| **Begin blocker removal (parallel)** | Assigned owners (Network, IAM, Unix) | Ongoing | Service accounts, firewall pre-approval, scanning host provisioning tickets created |

### Go/No-Go Decision

**Proceed to Questionnaire Response if:**
- ☑ Primary contact identified and available
- ☑ Regulatory drivers & compliance windows documented
- ☑ Timeline expectations aligned (if audit window blocks Q1, acknowledge Q2 start)
- ☑ Questionnaire distributed with clear deadline

**Hold if:**
- ❌ No primary contact available (delay 2–4 weeks)
- ❌ BU not willing to engage (revisit later or deprioritize)
- ❌ Critical blockers with no clear resolution path (address first before POC planning)

---

## 1.2 Questionnaire Response Phase

**Objective:** Capture comprehensive current-state infrastructure, database, and compliance posture.

**Duration:** 1–2 weeks (after distribution)

### Activities

| Activity | Owner | Duration | Deliverable |
|---|---|---|---|
| **Questionnaire completion** | BU Technology Owner + DBA Lead + Security Lead | 45–60 min (actual time to complete) | Completed questionnaire (all 9 sections) |
| **Blocker removal (parallel)** | Network, IAM, Unix Platform teams | Ongoing | Service accounts created, firewall pre-approval obtained, scanning host provisioning underway |
| **Follow-up clarifications** | Engagement Lead | 2–3 days (as needed) | Questionnaire refinement (e.g., "What's the exact instance count?" "Can you quantify the 'approx'?") |

### Quality Checklist (Before Discovery Meeting)

**Engagement Lead verifies:**
- ☑ All required sections (A–I) completed
- ☑ Instance counts quantified (not "some" or "many")
- ☑ Blockers listed with criticality ratings & owners
- ☑ Timeline expectations captured (POC start window, preferred platform sequencing)
- ☑ Key contacts identified (tech owner, DBAs, security sponsor)

**If incomplete, send back** for completion (adds 3–5 days).

---

## 1.3 Discovery Meeting Phase

**Objective:** Validate questionnaire findings, clarify gaps, align on POC approach, confirm timeline.

**Duration:** 1 hour (meeting) + 1 week (post-meeting planning)

### Activities

| Activity | Owner | Duration | Deliverable |
|---|---|---|---|
| **Discovery meeting** | Engagement Lead + BU Technology Owner + DBA Lead + Security Sponsor | 60 min | Meeting notes: findings summary, blockers prioritized, platform sequencing confirmed, open questions documented |
| **Detailed POC scope draft** | Engagement Lead (with DBA input) | 2–3 days | POC scope document: platforms in scope, environments in scope, success criteria, 4–6 week timeline |
| **Blocker resolution confirmation** | Engagement Lead + Assigned owners | 2–3 days | Status update: which blockers resolved, which remain, target resolution dates confirmed |
| **POC planning meeting (pre-planning)** | Engagement Lead + Project Manager | 1 day | POC planning schedule set, roles assigned, kickoff date identified |

### Discovery Meeting Agenda (60 minutes)

1. **Welcome & recap (5 min):** Engagement team intro, POC goal: "Automate compliance scanning, reduce manual effort, improve audit posture"
2. **Questionnaire validation (20 min):**
   - "Your estate is 60 instances across 4 platforms. Does that align with your understanding?"
   - Clarify any ambiguities: "You mentioned 'network segmentation for Sybase' – can you describe exactly which VLAN it's isolated on?"
   - Instance counts validated (critical: instance counts will determine POC workload)
3. **Blockers & dependencies (15 min):**
   - Review Critical/High blockers from questionnaire
   - "Scanning host provisioning (INFRA-4521) is critical path. Unix team says 3–4 week lead. Do we have an owner assigned? Target date?"
   - "Service account permissions – InfoSec can review in 2 weeks. Can we do this in parallel?"
4. **POC approach (10 min):**
   - Proposed platform sequencing: "Start MSSQL (largest, most mature), then Oracle, then Sybase. Does this align with your priorities?"
   - "POC timeline: 4–6 weeks (mid-April to late-May). Feasible for your team?"
5. **Timeline & next steps (10 min):**
   - Confirm POC start date & duration
   - Identify key milestones (blocker resolution targets, kickoff date, findings date)
   - Assign post-meeting work: "We'll draft POC scope by Friday; you review and confirm by following Monday."

### Go/No-Go Decision

**Proceed to POC Planning if:**
- ☑ Questionnaire findings validated (no major surprises)
- ☑ Instance counts, database platforms, and environment count confirmed
- ☑ Blockers understood and owners assigned
- ☑ Timeline expectations aligned (POC start date acknowledged)
- ☑ Platform sequencing agreed

**Hold/Redirect if:**
- ❌ Significant gaps in questionnaire data (return to responders for clarification; delay 1–2 weeks)
- ❌ Critical blockers unresolved with no clear path (address before POC start; may delay 4+ weeks)
- ❌ Timeline misalignment (BU not available until Q3; engagement lead not available until Q3; deprioritize or replan)

---

---

# Stage 2: POC Planning

## 2.1 POC Scope Definition

**Objective:** Define POC scope, success criteria, test data approach, and detailed timeline.

**Duration:** 1–2 weeks (after discovery meeting)

### Activities

| Activity | Owner | Duration | Deliverable |
|---|---|---|---|
| **POC scope document** | Engagement Lead + BU DBA | 3–5 days | POC Scope: platforms in scope (e.g., "MSSQL + Oracle"), environments (e.g., "Prod + UAT"), instance count, success metrics |
| **Test plan development** | Engagement Lead + DBA + QA | 2–3 days | Test plan: which instances will be scanned in POC, expected findings, false positive threshold, remediation approach |
| **POC timeline & resource plan** | Project Manager | 2–3 days | Detailed 4–6 week timeline with weekly milestones, resource assignment (DBA FTE, engagement lead time, cross-team support) |
| **Blocker removal tracking** | Engagement Lead | Ongoing | Weekly blocker status update: firewall rules approved? Service accounts created? Scanning host provisioned? |

### POC Scope Document (Key Sections)

**Section 1: Platforms & Environments**
- Platforms in scope: "MSSQL (24 instances) and Oracle (18 instances); Sybase (12 instances) deferred pending client library testing"
- Environments: "Production only (Phase 1, 20 instances); UAT added in Phase 2 if Phase 1 successful"
- Instance count: "POC will scan 20 production instances (10 MSSQL, 10 Oracle)"

**Section 2: Success Criteria**
- "All 20 POC instances scanned without errors"
- "Scan results delivered in JSON + Splunk dashboard format"
- "<=2 false positives per platform (acceptable for first scan)"
- "Scan execution time <30 min for 20 instances"
- "DBA team trained on remediation workflow"

**Section 3: Known Risks & Mitigation**
- "Risk: Sybase client library compatibility untested. Mitigation: Defer Sybase from Phase 1; test in parallel lab environment."
- "Risk: Service account permissions insufficient. Mitigation: InfoSec review completed before POC start; privilege escalation in place."

**Section 4: Phasing (if multi-platform)**
- **Phase 1 (Weeks 1–2):** MSSQL only (10 instances) – quickest to validate, proven tooling
- **Phase 2 (Weeks 3–4):** Add Oracle (10 instances) – medium complexity, mature profiles
- **Phase 3 (Weeks 5–6):** Findings review, documentation, recommendation

---

## 2.2 Pre-POC Setup (Blocker Removal)

**Objective:** Resolve all Critical/High blockers before POC execution begins.

**Duration:** Varies (2–4 weeks typical)

### Critical-Path Blockers (Typical Timelines)

| Blocker | Typical Lead Time | Owner | Go/No-Go Gate |
|---|---|---|---|
| **Service account provisioning & permission review** | 10–15 days | IAM + InfoSec | Accounts created & tested for database connectivity |
| **Scanning host provisioning** | 3–4 weeks | Unix Platform + Infrastructure | Host deployed, hardened, network access tested, Ansible agent installed |
| **Firewall rule approval** | 5–7 days | Network team (CAB) | Rules approved & deployed; connectivity from scanning host to all POC databases confirmed |
| **Database client library installation** | 1–2 days (if available) or 1–2 weeks (if compatibility testing needed) | Unix Platform + DBA | Client libraries (Oracle Instant Client, Sybase Open Client, MSSQL tools) installed & tested on scanning host |

**Blocker Removal Tracking Template:**

| Blocker | Owner | Status | Target Date | Current Date | Blocker? |
|---|---|---|---|---|---|
| Service account permissions | InfoSec ([SECURITY_LEAD]) | ☐ Not started ☐ In progress ☐ Complete | 2026-03-15 | 2026-03-12 | ☐ Blocking ☐ On track |
| Scanning host provisioning | Unix team (ticket INFRA-4521) | ☐ Not started ☐ In progress ☐ Complete | 2026-03-20 | 2026-03-10 | ☐ Blocking ☐ On track |
| Firewall rules | Network team | ☐ Not started ☐ In progress ☐ Complete | 2026-03-22 | 2026-03-12 | ☐ Blocking ☐ On track |

### Go/No-Go Gate: Pre-POC Readiness Check

**Before POC kickoff, verify:**
- ☑ All Critical blockers resolved
- ☑ High blockers resolved OR mitigation plan in place (e.g., "Service account permissions partial; InfoSec will grant additional privileges during POC")
- ☑ Scanning host is deployed, hardened, and network-connected to at least one POC database (test connectivity)
- ☑ Service accounts created, credentials in vault, and validated for database login
- ☑ DBA team confirmed available for POC support (allocated FTE confirmed)

**If blockers remain:**
- ❌ **Delay POC start.** Pushing forward with unresolved blockers = POC failure.
- **Typical delay:** 1–2 weeks per critical blocker.

---

---

# Stage 3: POC Execution

## 3.1 POC Kickoff

**Objective:** Launch POC, establish communication cadence, confirm roles and success criteria.

**Duration:** 1 day (kickoff meeting) + 4–6 weeks (POC execution)

### POC Kickoff Meeting (2 hours)

| Agenda Item | Duration | Owner |
|---|---|---|
| **Welcome & goals** | 10 min | Engagement Lead |
| **POC scope review** | 15 min | Engagement Lead (walk through POC Scope document) |
| **Success criteria & timeline** | 15 min | Project Manager (timeline walk-through, milestone dates) |
| **Roles & responsibilities** | 15 min | Project Manager (who does what, escalation path) |
| **Communication plan** | 10 min | Engagement Lead (weekly syncs, Slack channel, status updates) |
| **First week activities** | 15 min | Engagement Lead + DBA (Day 1–2: finalize test data; Day 3–5: scanning execution on first batch) |
| **Q&A** | 30 min | All |

### Communication Cadence

- **Daily standup (async):** Slack channel updates (Engagement Lead posts daily status: completed, blockers, next steps)
- **Weekly sync (30 min):** Engagement Lead + DBA + Project Manager + tech sponsor
  - Review weekly progress (instances scanned, issues encountered)
  - Address blockers (if any)
  - Adjust timeline if needed
- **Bi-weekly stakeholder update (15 min):** Engagement Lead + BU Technology Owner + Project Sponsor
  - High-level progress, findings summary, on-track/at-risk status

---

## 3.2 POC Execution Phases (Typical 6-Week Timeline)

### Phase 1: Foundation & Quick-Win (Weeks 1–2)

**Objective:** Execute scanning on simplest platform/environment to build confidence and validate tooling.

**Activities:**
- [ ] **Week 1:**
  - Day 1–2: Finalize test data and scanning host configuration
  - Day 3: Execute first scan (single instance, validate no errors)
  - Day 4–5: Run scans on 5 instances of first platform
  - Troubleshooting: Debug connection issues, permission gaps, false positives
- [ ] **Week 2:**
  - Complete scans on all Phase 1 instances (e.g., 10 MSSQL instances)
  - Results ingestion: Validate JSON output, load into Splunk dashboard
  - Findings review: Categorize findings (critical/high/medium/low), identify false positives
  - Team training: DBA team learns remediation workflow

**Success Criteria (Phase 1 Gate):**
- ✅ All Phase 1 instances scanned without errors
- ✅ Scan results generated & validated
- ✅ Results ingested into reporting tool (Splunk, Confluence, etc.)
- ✅ DBA team understands findings & remediation approach
- ✅ <=2 false positives per instance (acceptable)

**If Phase 1 fails:** Troubleshoot (adds 1–2 weeks) before proceeding to Phase 2.

---

### Phase 2: Expansion (Weeks 3–4)

**Objective:** Extend scanning to next platform; validate multi-platform approach and reporting.

**Activities:**
- [ ] **Week 3:**
  - Execute scans on second platform (e.g., 10 Oracle instances)
  - Compare findings across platforms (Oracle vs. MSSQL)
  - Validate version compatibility (if running multiple versions)
  - Troubleshoot platform-specific issues
- [ ] **Week 4:**
  - Complete scans on all Phase 2 instances
  - Aggregate reporting: Combined Splunk dashboard showing MSSQL + Oracle findings
  - Refine false positive filters based on Phase 1 learnings
  - Begin documenting findings & recommendations

**Success Criteria (Phase 2 Gate):**
- ✅ All Phase 2 instances scanned without errors
- ✅ Multi-platform results aggregated in reporting tool
- ✅ Findings trends identified (e.g., "80% of findings are access control; 15% are audit logging; 5% false positives")
- ✅ Remediation approach validated across platforms

---

### Phase 3: Hardening & Documentation (Weeks 5–6)

**Objective:** Address findings, refine scanning approach, document recommendations.

**Activities:**
- [ ] **Week 5:**
  - Findings triage: DBA team reviews findings, prioritizes remediation
  - Remediation execution: Address critical/high findings (if time permits)
  - Scanning optimization: Tune false positive filters, adjust schedule (frequency, timing)
  - Documentation: Capture lessons learned, issues encountered, resolutions
- [ ] **Week 6:**
  - Final scans: Validate remediation success (re-scan after fixes)
  - POC findings report: Summarize findings, remediation status, remaining risks
  - Recommendations: Go/Conditional Go/No-Go assessment for MVP onboarding
  - Presentation: Present findings & recommendation to BU leadership

**Deliverables (End of Phase 3):**
- POC Findings Report (see Stage 4)
- Recommendations: Go / Conditional Go / No-Go
- Proposed MVP timeline & scope

---

## 3.3 Weekly Status Report Template

**For Engagement Lead to complete each week:**

| Item | Status |
|---|---|
| **Instances scanned this week** | 5 (MSSQL: 3, Oracle: 2) |
| **Cumulative instances scanned** | 15 / 20 POC target (75%) |
| **Blockers encountered** | Sybase client library compatibility untested (Medium severity); Oracle 12c profile validation pending (Low severity) |
| **Blockers mitigated** | N/A |
| **Key findings (high-level)** | 18 findings across 15 instances; 12 medium/high severity (access control), 6 low severity (audit logging) |
| **On track? (Yes/At risk/No)** | ✅ On track (Week 2 of 6; 75% of instances scanned; no critical blockers) |
| **Next week plan** | Complete Phase 1 scanning; begin Phase 2 Oracle scans; present Phase 1 findings to DBA team |
| **Engagement lead confidence** | ✅ High – tooling working well, DBA team engaged, no major technical surprises |

---

---

# Stage 4: POC Findings & Recommendation

## 4.1 POC Assessment Document

**Objective:** Formally document POC outcomes, findings, and recommendation for MVP onboarding.

**Duration:** 1–2 weeks (post-POC execution)

### POC Assessment Structure (from template)

**Section A: Scope Definition**
- **Business Unit:** Northstar unit name
- **Environments in scope:** Production (20 instances)
- **Database platforms in scope:** MSSQL (10), Oracle (10)
- **Duration of POC:** 2026-04-15 to 2026-05-27 (6 weeks actual)
- **Key stakeholders:** List by name/role

**Section B: Connectivity Validation**

| Check | Status | Notes |
|---|---|---|
| Network connectivity validated | ✅ Pass | Scanning host can reach all 20 POC databases; jump server pattern working as designed |
| Firewall rules confirmed | ✅ Pass | Approved rules deployed; no additional CAB approval needed for MVP |
| Credentials provisioned | ✅ Pass | Service accounts created & tested for all platforms |
| Authentication successful | ✅ Pass | Oracle TNS connectivity, MSSQL SQL Auth, Sybase Open Client all working |

**Section C: Scanning Validation**

| Check | Status | Notes |
|---|---|---|
| Scanning tool executed | ✅ Pass | InSpec + Ansible working well; no tool failures |
| Scan completed without error | ✅ Pass | All 20 instances scanned successfully; average scan time 8 min per instance |
| Results generated | ✅ Pass | JSON output validated; 350 total findings (12 critical, 48 high, 180 medium, 110 low) |
| Results ingested centrally | ✅ Pass | Splunk integration working; dashboard updated real-time |

**Section D: Inventory Reconciliation**

| Check | Status | Notes |
|---|---|---|
| Inventory source validated | ✅ Pass | DBA Excel register matches scanned instances; 100% alignment |
| CMDB comparison performed | ✅ Pass | 19 of 20 instances found in ServiceNow CMDB; 1 instance missing (newer provisioning, CMDB not updated) |
| Duplicate / missing records identified | ⚠️ Partial | 1 CMDB record for decommissioned Oracle instance (false positive); 1 missing MSSQL instance. Cleanup planned for MVP onboarding. |

**Section E: Key Findings**

**High-Level Findings Summary:**
- **Total findings:** 350 across 20 instances
- **Critical findings:** 12 (3.4%) – Recommend remediation before MVP onboarding
  - Examples: "Weak password policies (6 instances), default accounts enabled (3 instances), audit logging disabled (3 instances)"
- **High findings:** 48 (13.7%) – Should remediate before MVP, but not blocking
- **Medium findings:** 180 (51.4%) – Remediation plan recommended; can extend beyond MVP
- **Low findings:** 110 (31.4%) – Document for future remediation; not urgent
- **False positives:** 14 (4%) – Lower than typical (industry avg 5–10%)

**Platform-Specific Findings:**
- **MSSQL:** 180 findings (9/instance avg) – mostly password policy, audit logging
- **Oracle:** 170 findings (17/instance avg) – access control, audit logging, encryption
- **Findings trending:** 80% are remediable via policy changes; 20% require code/app changes

**Issues Encountered During POC:**
- Issue 1: "Oracle 12c profile validation – initial scans failed on legacy syntax. InSpec profile customized to support both 12c & 19c."
  - Resolution: Profile updated; re-scans validated; ready for MVP
  - Effort: 2 days
- Issue 2: "Sybase Open Client compatibility with RHEL 8 – client library not available."
  - Resolution: Deferred Sybase from POC. Parallel lab testing underway; targeting Sybase inclusion in MVP Week 3.
  - Effort: To be determined (1–2 week estimate)

---

## 4.2 Risk Assessment & Recommendations

### Risk Assessment

| Risk Area | Assessment | Notes |
|---|---|---|
| **Access risk** | ✅ Low | Service accounts properly scoped; no over-privileged access required |
| **Network risk** | ✅ Low | Jump server pattern + firewall segmentation working as designed |
| **Inventory quality risk** | ⚠️ Medium | 1 CMDB record missing; recommend inventory reconciliation before MVP |
| **Operational risk** | ✅ Low | Scan execution time acceptable; no impact on production performance observed |
| **Compliance risk (if no remediation)** | ⚠️ High | 12 critical findings represent audit risk; recommend remediation before next external audit |

### MVP Readiness Recommendation

**Overall POC Outcome: ✅ GO**

**Rationale:**
- ✅ All connectivity & authentication validations passed
- ✅ Scanning tooling (InSpec + Ansible) proven reliable
- ✅ Results ingestion into Splunk working; reporting dashboard functional
- ✅ DBA team trained and confident in remediation workflow
- ✅ No critical blockers to MVP onboarding
- ⚠️ 1 minor CMDB discrepancy (remediate in MVP Phase 1)
- ⚠️ 12 critical findings require remediation (prioritize in MVP Phase 1)

**Conditions for MVP:**
1. Remediate all 12 critical findings (1–2 week effort)
2. Reconcile 1 missing CMDB record
3. Include Sybase scanning once Open Client compatibility confirmed (target: MVP Week 3)

**MVP Timeline:** Recommend MVP onboarding start **June 1, 2026** (2 weeks post-POC for findings remediation).

---

---

# Stage 5: MVP Onboarding

## 5.1 MVP Scope & Phasing

**Objective:** Transition from POC to production scanning; expand coverage, establish BAU process.

**Duration:** 4–8 weeks (typical MVP duration)

### MVP Scope (Example)

**Platforms:**
- MSSQL: All 24 production instances (Phase 1, Weeks 1–2)
- Oracle: All 18 production instances (Phase 2, Weeks 3–4)
- PostgreSQL: All 6 production instances (Phase 3, Week 5)
- Sybase: All 12 production instances (Phase 4, Weeks 6–7, pending client library validation)

**Environments:**
- Phase 1–2: Production only
- Phase 3: Add DR (if failover scanning required by compliance)
- Phase 4: Optional non-production (UAT, QA) if team capacity allows

**Frequency:** Monthly scans (compliance requirement per FCA; previously quarterly)

**Reporting:** Splunk dashboard updated post-scan; escalations to Security team for critical findings

### MVP Execution Timeline

| Week | Platform | Instances | Objective | Owner |
|---|---|---|---|---|
| **Week 1** | MSSQL | All 24 prod | Execute monthly scans, validate at scale, establish scan schedule | DBA + Eng Lead |
| **Week 2** | MSSQL | All 24 prod | Remediation of high/critical findings, refine false positive filters | DBA + Security |
| **Week 3** | Oracle | All 18 prod | Execute monthly scans, expand to second platform | DBA + Eng Lead |
| **Week 4** | Oracle | All 18 prod | Remediation, aggregate reporting (MSSQL + Oracle) | DBA + Security |
| **Week 5** | PostgreSQL | All 6 prod | Execute scans, add cloud-managed databases to coverage | Cloud team + DBA |
| **Week 6–7** | Sybase | All 12 prod | (Pending client library validation) execute scans, complete coverage | DBA + Eng Lead |
| **Week 8** | All platforms | 60 prod instances | Final validation, BAU handoff, process documentation | All |

### MVP Success Criteria

- ☑ All production instances scanned monthly (60 instances)
- ☑ Findings < 2% false positives
- ☑ Critical findings remediated within 48–72 hours
- ☑ High findings remediated within 2 weeks
- ☑ Reporting automated (no manual export)
- ☑ DBA team & Security team trained on remediation workflow
- ☑ Audit trail established (scan history, remediation tracking)
- ☑ SLA defined: Monthly scans, results in Splunk within 24 hours

---

---

# Stage 6: Profile & BAU (Business-as-Usual)

## 6.1 Post-MVP: Infrastructure & Database Profile

**Objective:** Establish authoritative reference for BU's compliance scanning posture; define ongoing operations.

**Duration:** 2–4 weeks (post-MVP completion)

### Infrastructure & Database Profile Structure

**Section 1: Executive Summary**
- BU name, criticality (mission-critical / business-critical), maturity level (low/medium/high)
- Key risks (e.g., "12 critical findings from MVP; remediation plan in place; on track for June audit")
- Key constraints (e.g., "Sybase legacy client library limits scanning frequency")

**Section 2: Environment Coverage**

| Environment | Hosting | Coverage % | Notes |
|---|---|---|---|
| Production | On-Prem + Azure | 100% (60 instances) | Monthly scans, real-time alerting on critical findings |
| DR | Azure | 50% (15 of 30 instances) | Quarterly scans (not required by compliance but recommended) |
| UAT | On-Prem | 50% (planned, not yet scanned) | On roadmap for Q4 2026 |
| QA/Dev | On-Prem + Azure | Not scanned | Lower priority; not required by compliance |

**Section 3: Database Coverage**

| Database Type | Coverage % | Instances | Notes |
|---|---|---|---|
| Oracle | 100% | 18 | Monthly scans, CIS Oracle 19c Benchmark (with 3 approved exceptions) |
| MSSQL | 100% | 24 | Monthly scans, CIS MSSQL 2019 Benchmark |
| PostgreSQL | 100% | 6 | Monthly scans, CIS PostgreSQL 14 Benchmark |
| Sybase | 100% | 12 | Monthly scans, internal baseline (CIS not available) |
| **TOTAL** | **100%** | **60** | All production instances scanned monthly |

**Section 4: Ownership & Accountability**

| Area | Owner | Contact |
|---|---|---|
| **Platform ownership (Oracle)** | [TEAM_MEMBER_5] / Oracle DBA | [email] |
| **Platform ownership (MSSQL)** | [TEAM_MEMBER_2] / MSSQL DBA | [email] |
| **Platform ownership (Sybase)** | [TEAM_MEMBER_8] / Sybase DBA | [email] |
| **Security scanning ownership** | [TEAM_MEMBER_2] / Security Sponsor | [email] |
| **Results reporting & escalation** | [SECURITY_LEAD] / Security team | [email] |
| **Compliance/audit coordination** | [COMPLIANCE_LEAD] / Compliance team | [email] |

**Section 5: Scan Frequency & SLA**

- **Scan frequency:** Monthly (every 1st of month, 02:00 UTC, ~45 min duration)
- **Results delivery:** Within 24 hours of scan completion (automated to Splunk)
- **Critical findings escalation:** Within 1 hour of scan completion (Slack alert + email to Security team)
- **Findings remediation SLA:**
  - Critical: 48–72 hours
  - High: 2 weeks
  - Medium: 30 days
  - Low: 90 days
- **Audit reporting:** Monthly summary emailed to Compliance team; annual attestation prepared for external audit

---

## 6.2 BAU Operations & Ongoing Improvement

### Monthly Scan Cycle

**Day 1 (Scan execution):** 
- 02:00 UTC: Automated monthly scan triggered (InSpec via Ansible)
- 02:45 UTC: Scan complete
- 03:00 UTC: Results parsed & loaded into Splunk dashboard
- 03:15 UTC: Critical findings escalated (Slack alert to Security team)

**Day 1–2 (Triage):**
- Security team reviews critical findings
- DBA team assigns to instance owners for remediation

**Days 2–7 (Remediation – Critical findings):**
- Instance owners remediate critical findings
- Validation: DBA re-scans instance post-remediation to confirm

**Week 2 (Reporting & escalation):**
- Findings summary prepared: Critical/high/medium/low distribution, trends, remediation status
- Monthly report shared with BU Technology Owner & Compliance team

**Week 4 (Next month):** Cycle repeats

### Continuous Improvement Activities

- **Quarterly false positive review:** Assess false positive rate; refine InSpec profiles to reduce noise
- **Semi-annual version assessment:** Monitor database version EOL; plan upgrade strategies (e.g., Oracle 12c → 19c)
- **Annual audit coordination:** Prepare compliance evidence for external audit (scanning frequency, coverage %, findings remediation tracking)
- **Roadmap:** Extend coverage (non-production environments), add new platforms (if adopted), enhance reporting (additional metrics, trends)

---

---

# Overall Engagement Timeline & Milestones

## Typical End-to-End Timeline (6-Month Engagement)

| Phase | Duration | Dates (Example) | Key Deliverable |
|---|---|---|---|
| **Stage 1: Discovery** | 4–6 weeks | Jan 26 – Feb 28 | Discovery Questionnaire completed; POC scope defined; blockers identified |
| **Stage 2: POC Planning** | 2–4 weeks | Mar 1 – Mar 28 | POC Scope document; blocker removal tracking; POC kickoff scheduled |
| **Stage 3: POC Execution** | 4–6 weeks | Mar 29 – May 9 | POC completed; findings documented; recommendation prepared |
| **Stage 4: Findings & Rec** | 1–2 weeks | May 10 – May 23 | POC Assessment document; Go/No-Go recommendation |
| **Stage 5: MVP Onboarding** | 4–8 weeks | May 24 – Jul 18 | All production instances onboarded; BAU process established |
| **Stage 6: Profile & BAU** | 2–4 weeks | Jul 19 – Aug 8 | Infrastructure & Database Profile published; BAU operations handed off |
| **TOTAL** | **~6 months** | **Jan 26 – Aug 8** | Compliance scanning automated, audit risk reduced, team enabled |

## Key Milestones & Decision Gates

| Milestone | Date | Decision | Go/No-Go Criteria |
|---|---|---|---|
| **Discovery Complete** | ~Feb 28 | Proceed to POC Planning | ✅ Questionnaire validated; contacts confirmed; timeline aligned |
| **Blockers Resolved** | ~Mar 28 | Proceed to POC Execution | ✅ Service accounts created; scanning host provisioned; firewall approved |
| **POC Execution Complete** | ~May 9 | Proceed to MVP | ✅ All instances scanned; findings documented; tooling validated |
| **POC Assessment** | ~May 23 | MVP Onboarding Go/No-Go | ✅ Go – remediate critical findings; Conditional Go – address X blockers; No-Go – redesign approach |
| **MVP Onboarding Complete** | ~Jul 18 | Transition to BAU | ✅ All prod instances scanned monthly; reporting automated; team trained |
| **Profile Published** | ~Aug 8 | Handoff to BAU | ✅ Documentation complete; ownership clear; ongoing process defined |

---

---

# Appendix: Templates & Checklists

## Template Filenames (Available in `/docs/BU_Questionnaires/`)

1. **NORTHSTAR_BU_DISCOVERY_QUESTIONNAIRE_TEMPLATE.md** – Discovery questionnaire (9 sections A–I)
2. **BU_QUESTIONNAIRE_INTAKE_CHECKLIST.md** – Pre-discovery validation checklist
3. **BU_RESPONSE_GUIDE.md** – Role-specific guidance for questionnaire completion
4. **BU_ENGAGEMENT_WORKFLOW.md** – This document (complete engagement lifecycle)
5. **POC_ASSESSMENT_TEMPLATE.md** – POC findings & recommendation (Sections A–G)
6. **BU_PROFILE_TEMPLATE.md** – Infrastructure & Database Profile (Sections 1–7)

## Typical File Organization (Per BU)

```
/docs/BU_Questionnaires/
├── NORTHSTAR_BU_DISCOVERY_QUESTIONNAIRE_TEMPLATE.md         (master template)
├── BU_QUESTIONNAIRE_INTAKE_CHECKLIST.md                     (intake process)
├── BU_RESPONSE_GUIDE.md                                     (guidance for responders)
├── BU_ENGAGEMENT_WORKFLOW.md                                (this document)
├── [BU_NAME_1]/
│   ├── [BU_NAME_1]_DISCOVERY_QUESTIONNAIRE.md              (completed discovery Q)
│   ├── [BU_NAME_1]_INTAKE_CHECKLIST.md                     (intake findings)
│   ├── [BU_NAME_1]_POC_ASSESSMENT.md                       (POC findings)
│   └── [BU_NAME_1]_PROFILE.md                              (BAU profile)
├── [BU_NAME_2]/
│   ├── [BU_NAME_2]_DISCOVERY_QUESTIONNAIRE.md
│   ├── [BU_NAME_2]_INTAKE_CHECKLIST.md
│   └── ... (etc.)
```

---

---

# Document Control

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 2026-01-26 | Northstar Engagement Team | Initial BU engagement workflow; complete lifecycle from discovery through BAU |
