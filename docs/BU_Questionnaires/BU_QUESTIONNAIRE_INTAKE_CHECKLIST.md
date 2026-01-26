# Business Unit Questionnaire Intake Checklist

**Pre-Discovery Validation Checklist for First-Engagement Business Units**

---

## Purpose

Before distributing the Business Unit Discovery Questionnaire, complete this checklist to:
1. **Identify key contacts** and confirm availability
2. **Surface obvious blockers** that will constrain engagement dates (audit windows, change freezes, pending infrastructure)
3. **Validate questionnaire relevance** (ensure applicable regulatory drivers are understood)
4. **Set realistic timeline expectations** based on BU maturity and constraints
5. **Plan blocker removal** in parallel with questionnaire completion

**Expected completion time:** 30 minutes per BU (phone call + email follow-up)

---

## Step 1: Initial Contact & Discovery

### 1.1 Identify Primary Stakeholders

**Primary Technology Owner / Infrastructure Lead**
- [ ] Name: _______________________________
- [ ] Title: _______________________________
- [ ] Email: _______________________________
- [ ] Phone: _______________________________
- [ ] Availability window (e.g., "Tuesday–Thursday 10am–5pm UTC"): _______________________________
- [ ] Primary language: English / Other: _______________________________

**Primary DBA or Database Owner**
- [ ] Name: _______________________________
- [ ] Title: _______________________________
- [ ] Email: _______________________________
- [ ] Phone: _______________________________
- [ ] Platforms owned: ☐ Oracle ☐ MSSQL ☐ Sybase ☐ PostgreSQL ☐ MySQL ☐ Other: ___________

**Security / Compliance Sponsor (if different from above)**
- [ ] Name: _______________________________
- [ ] Title: _______________________________
- [ ] Email: _______________________________

### 1.2 Schedule Intake Call (15–20 min)

**Call logistics:**
- [ ] Intake call scheduled: **Date/Time:** _____________________
- [ ] Attendees confirmed: ☐ Tech owner ☐ DBA ☐ Security sponsor ☐ Engagement lead
- [ ] Meeting invite sent with agenda: _______________
- [ ] Call recording consent obtained: ☐ Yes ☐ No

**Intake call agenda (cover in first 15 minutes):**
1. **Brief introduction (2 min):** "We're assessing your infrastructure to plan a compliance scanning automation POC. Questionnaire is 45–60 minutes to complete."
2. **Regulatory drivers (3 min):** "What regulations or audit requirements drive your database security? (SOX, GDPR, PCI, FCA, etc.)"
3. **Current state (5 min):** "Do you have any database security scanning in place today? Manual or automated?"
4. **Timeline (3 min):** "What's your preferred engagement window? Any blackout periods (audits, year-end, change freeze)?"
5. **Blockers (2 min):** "Are there any known infrastructure gaps (missing scanning host, service account issues, etc.)?"

---

## Step 2: Regulatory & Audit Context

### 2.1 Regulatory Drivers

**Identify applicable regulations (check with BU during intake call or from publicly available sources):**

- [ ] SOX (Section 404 – Financial Reporting Controls)
- [ ] GDPR (Data protection, EU-based data)
- [ ] PCI-DSS (Payment card data)
- [ ] HIPAA (Healthcare data)
- [ ] FCA (Financial Conduct Authority, UK/EMEA)
- [ ] MiFID II (Market in Financial Instruments Directive, trading)
- [ ] NIST (Federal/US government)
- [ ] CIS (Center for Internet Security benchmarks)
- [ ] Internal compliance policy only
- [ ] Other: _______________________________

**Audit / Compliance Bodies:**
- [ ] Internal audit: Frequency _____________ Last audit: _____________ Next audit: _____________
- [ ] External auditor: Firm name _____________ Frequency _____________ Next audit: _____________
- [ ] Regulatory body (FCA, SEC, etc.): _____________ Audit frequency: _____________

### 2.2 Compliance Windows (CRITICAL FOR TIMELINE PLANNING)

**Ask: "When is your next audit or compliance assessment? Are there blackout periods?"**

- [ ] SOX audit period: Dates _____________ Severity: Critical ☐ High ☐ Medium ☐
- [ ] Internal audit period: Dates _____________ Severity: Critical ☐ High ☐ Medium ☐
- [ ] Regulatory assessment: Dates _____________ Severity: Critical ☐ High ☐ Medium ☐
- [ ] Monthly close / financial close: Dates _____________ Severity: Critical ☐ High ☐ Medium ☐
- [ ] Quarterly / year-end freeze: Dates _____________ Severity: Critical ☐ High ☐ Medium ☐
- [ ] Change freeze periods: E.g., "Dec 15–Jan 5, Month-end last 3 days" Severity: Critical ☐ High ☐ Medium ☐

**Impact on engagement:**
- [ ] **Recommended POC start date (avoid blackout):** _____________
- [ ] **Blackout windows must exclude questionnaire completion?** Yes ☐ No ☐

---

## Step 3: Infrastructure Maturity & Quick Assessment

### 3.1 Environment Count (Quick estimate from intake call)

**Ask: "How many database environments do you have? (Prod, DR, UAT, QA, Dev)"**

- [ ] **Production instances:** Estimate _____ instances
  - [ ] Hosting: On-Prem / Cloud / Hybrid
  - [ ] Tier-1 (mission-critical) systems: Estimate _____
- [ ] **DR instances:** Estimate _____ instances
  - [ ] Hosting: On-Prem / Cloud / Hybrid
- [ ] **Non-Prod (UAT/QA/Dev):** Estimate _____ instances

**Complexity rating (initial):**
- [ ] **Small estate:** <10 total instances → **Low complexity**
- [ ] **Medium estate:** 10–50 instances → **Medium complexity**
- [ ] **Large estate:** 50–200 instances → **High complexity**
- [ ] **Very large:** >200 instances → **Very high complexity**

### 3.2 Database Platform Count

**Ask: "What database platforms do you use? (Oracle, MSSQL, Sybase, PostgreSQL, Snowflake, etc.)"**

- [ ] Platforms in use: ☐ Oracle ☐ MSSQL ☐ Sybase ☐ PostgreSQL ☐ MySQL ☐ Snowflake ☐ Databricks ☐ Other: ___________
- [ ] **Platform count:** _____ platforms
- [ ] **Version fragmentation?** Yes (High ☐ Medium ☐) / No ☐
  - [ ] Example fragmentation: _______________________________

**Complexity rating (platform diversity):**
- [ ] **Single platform:** → **Low complexity**
- [ ] **2–3 platforms:** → **Medium complexity**
- [ ] **4+ platforms or legacy versions:** → **High complexity**

### 3.3 Current Scanning Status

**Ask: "Do you currently scan databases for security compliance?"**

- [ ] **No scanning in place:** 
  - [ ] Severity: Critical (audit requirement) ☐ High ☐ Medium ☐ Low ☐
  - [ ] → POC will be net-new initiative
- [ ] **Manual scanning:** 
  - [ ] Tool: _______________________________
  - [ ] Frequency: Weekly / Monthly / Quarterly / Annually
  - [ ] Coverage: Prod only / Prod+DR / All environments
  - [ ] → POC will automate & expand coverage
- [ ] **Partial automated scanning:**
  - [ ] Platforms covered: _______________________________
  - [ ] → POC will extend to other platforms

---

## Step 4: Known Blockers & Dependencies

### 4.1 Infrastructure Blockers

**Ask: "Are there any known infrastructure gaps or pending changes that affect database access?"**

| Blocker | Status | Owner | Target Resolution |
|---|---|---|---|
| **Scanning host not provisioned** | ☐ Yes ☐ No ☐ In progress | _____________ | ___________ |
| **Service accounts not created** | ☐ Yes ☐ No ☐ In progress | _____________ | ___________ |
| **Firewall rules not pre-approved** | ☐ Yes ☐ No ☐ In progress | _____________ | ___________ |
| **Network segmentation restricting access** | ☐ Yes ☐ No | _____________ | ___________ |
| **Credential management / vault not available** | ☐ Yes ☐ No ☐ In progress | _____________ | ___________ |
| **Database client libraries missing (Sybase, Oracle)** | ☐ Yes ☐ No | _____________ | ___________ |
| **CMDB / inventory quality issues** | ☐ Yes ☐ No | _____________ | ___________ |

**Critical blockers (will delay POC start):**
- [ ] Issue #1: _______________________________ Owner: _____________ Target date: ___________
- [ ] Issue #2: _______________________________ Owner: _____________ Target date: ___________

### 4.2 Organizational Blockers

**Ask: "Are there any process or organizational constraints (budgets, approvals, team capacity) that will affect our engagement?"**

- [ ] **Team capacity:** DBA/tech lead available _____% FTE through POC
- [ ] **Approval process:** CAB / InfoSec / Security review required? Lead time: _____ days
- [ ] **Budget approval:** Required? Yes ☐ No ☐ Approver: _____________
- [ ] **Change freeze windows:** Describe: _______________________________
- [ ] **Other constraints:** _______________________________

---

## Step 5: Engagement Timeline & Assumptions

### 5.1 Preferred Engagement Window

**Ask: "When would you prefer to start a POC?"**

- [ ] **Preferred start date or window:** _______________________________
- [ ] **Reason for preference (e.g., "Post-audit April 2026," "Next quarter"):** _______________________________
- [ ] **Avoid dates/windows:** (audit windows, change freeze) _______________________________

### 5.2 Realistic Timeline Estimate

**Based on blockers and BU maturity, estimate realistic timeline:**

| Phase | Duration | Target Date | Notes |
|---|---|---|---|
| **Questionnaire completion** | 1–2 weeks | ___________ | Depends on BU availability |
| **Blocker removal (parallel)** | Variable | ___________ | Service accounts, firewall rules, scanning host |
| **POC planning (post-questionnaire)** | 1–2 weeks | ___________ | Scope, test data, success criteria |
| **POC execution** | 4–6 weeks | ___________ | Depends on platform count & complexity |
| **POC findings & recommendation** | 1 week | ___________ | Go/No-Go decision |
| **MVP onboarding** | 4–8 weeks | ___________ | If POC successful |

**Engagement lead's timeline assessment:**
- [ ] **Optimistic (minimal blockers, high readiness):** POC can start within _____ weeks
- [ ] **Realistic (1–2 blockers, medium readiness):** POC likely starts within _____ weeks
- [ ] **Conservative (multiple blockers, low readiness):** POC may start within _____ weeks or later

---

## Step 6: Questionnaire Distribution & Logistics

### 6.1 Confirm Distribution Details

- [ ] **Primary responder:** _______________________________ (usually Tech Owner or DBA Lead)
- [ ] **Secondary responder (for database sections):** _______________________________ (DBA)
- [ ] **Email address for questionnaire:** _______________________________
- [ ] **Expected completion date:** _____ (typically 1–2 weeks from send date)
- [ ] **Format preferred:** ☐ Markdown file ☐ Confluence page ☐ Google Docs ☐ Excel
- [ ] **Language:** English / Other: _______________________________

### 6.2 Questionnaire Preparation

- [ ] **Template version:** NORTHSTAR_BU_DISCOVERY_QUESTIONNAIRE_TEMPLATE.md (v1.0)
- [ ] **Customizations needed:** (e.g., additional sections, pre-filled contact info, regulatory focus)
  - [ ] _______________________________________________________________________________
- [ ] **Attachment: BU_RESPONSE_GUIDE.md** (role-specific guidance) → Include with questionnaire
- [ ] **Attachment: Examples (Global Markets Trading Platform)** → Optional reference
- [ ] **Cover email drafted:** ☐ Yes ☐ No

---

## Step 7: Success Criteria & Quick-Win Identification

### 7.1 POC Success Criteria (Preliminary)

**Ask: "How will we know the POC was successful? What metrics matter to you?"**

- [ ] **Metrics identified:**
  - [ ] Metric #1: _______________________________ Target: _____________
  - [ ] Metric #2: _______________________________ Target: _____________
  - [ ] Metric #3: _______________________________ Target: _____________

**Example metrics:**
- [ ] Successful scan of X% of production instances without errors
- [ ] Scan results integrated into Splunk / SIEM within 24 hours
- [ ] Zero false positives on compliance findings
- [ ] Scan execution time <Y minutes for Z instances
- [ ] DBA team trained and confident in remediation process

### 7.2 Quick-Win Opportunities (To Discuss During POC Planning)

**Identify low-risk, high-impact opportunities:**

- [ ] **Inventory cleanup:** Any stale/duplicate CMDB records that can be decommissioned quickly? _______________________________ 
- [ ] **Expand current coverage:** If manual scanning exists, which platforms could be automated first? _______________________________
- [ ] **Low-hanging compliance:** Any non-scanned environments (QA, Dev) that could be added easily? _______________________________

---

## Step 8: Completion & Next Actions

### 8.1 Checklist Completion

- [ ] **All sections 1–7 completed**
- [ ] **Primary contact confirmed and questionnaire scheduled**
- [ ] **Known blockers documented and owners assigned**
- [ ] **Realistic timeline established**
- [ ] **Questionnaire customization (if any) identified**

### 8.2 Next Actions (Before Sending Questionnaire)

**To be completed by Engagement Lead:**

| Action | Owner | Target Date | Status |
|---|---|---|---|
| [ ] **Follow up on critical blockers** (e.g., CAB approval, service accounts) | _____________ | ___________ | ☐ Done ☐ In progress ☐ Blocked |
| [ ] **Schedule discovery call** (post-questionnaire completion, 60 min) | _____________ | ___________ | ☐ Done ☐ Scheduled ☐ Pending |
| [ ] **Prepare POC scope & timeline estimate** (for discovery meeting) | _____________ | ___________ | ☐ Done ☐ In progress ☐ Not started |
| [ ] **Identify pilot platforms** (if multiple) based on readiness & impact | _____________ | ___________ | ☐ Done ☐ In progress ☐ Not started |
| [ ] **Create BU-specific engagement plan** (post-discovery) | _____________ | ___________ | ☐ Not yet | 

---

## Document Control

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 2026-01-26 | Northstar Engagement Team | Initial pre-discovery checklist for BU intake |
