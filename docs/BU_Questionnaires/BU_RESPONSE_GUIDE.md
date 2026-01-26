# Business Unit Questionnaire Response Guide

**Role-Specific Instructions & Examples for Completing the Discovery Questionnaire**

---

## How to Use This Guide

This guide provides **role-specific instructions** to help Business Unit stakeholders complete the Discovery Questionnaire accurately and efficiently. Each section maps to a questionnaire section and includes:
- **Who should answer:** Which role(s) typically answer this section
- **What we're looking for:** The key information and why it matters
- **Common pitfalls:** Mistakes to avoid
- **Example answers:** Real-world examples of good responses

**TIP:** Different sections may involve different people. **Assign roles before starting the questionnaire** to avoid bottlenecks. Typical assignment:
- **Technology Owner / Infra Lead:** Sections A, B, C, I
- **DBA Lead:** Sections D, E, F, G
- **Security / Compliance Sponsor:** Section G (compliance), Section H (risks)

---

---

## Section A: Business Unit Context

**WHO SHOULD ANSWER:** Technology Owner / Business Unit Lead + DBA Lead (for regulatory drivers)

### What We're Looking For

Section A establishes **who you are**, **why you matter** (business criticality, regulatory exposure), and **who we'll contact**. This guides our engagement model and timeline planning.

**Key insights:**
- **Regulatory drivers** → Urgency of scanning automation
- **Business criticality** → Maintenance window constraints, change approval complexity
- **Contact info** → Communication path, availability for POC

### Common Pitfalls

❌ **Vague BU description.** Don't write "IT systems." DO write: "Order Management System and Execution Management System supporting real-time trading for equities and fixed income. Processes 2.5M trades/day."

❌ **Missing secondary contact.** If the primary contact goes on vacation, we'll need an escalation path.

❌ **Underestimating regulatory exposure.** If your systems store customer PII (GDPR), payment card data (PCI), or are part of financial reporting (SOX), **say so explicitly.** This affects scan frequency and control strictness.

### Example Answers

**Question: Business Unit Description**

✅ **GOOD:**
> Global Markets Trading Platform providing real-time trade execution and order management for equities, fixed income, and derivatives trading across EMEA, APAC, and Americas. Core systems include OMS (Order Management System), EMS (Execution Management System), and position management. Approximately 2.5M trades per day during peak periods. Regulated by FCA (MiFID II trade reporting), subject to SOX audit (financial reporting controls), and internal compliance audit quarterly.

❌ **WEAK:**
> Trading systems for the business.

---

✅ **GOOD (Primary Contact):**
> John Smith / Head of Trading Technology / john.smith@example.internal / +1-212-xxx-xxxx  
> Available: Tuesday–Thursday, 10am–5pm UTC. Backup: jane.doe@example.internal (DBA Lead)

❌ **WEAK:**
> IT Team

---

**Question: Regulatory / Audit Sensitivity**

✅ **GOOD:**
> SOX (Section 404 – Financial Reporting Controls), MiFID II (Trade Reporting), FCA Regulatory Reporting, Internal Audit (Quarterly)  
> **Key windows:** SOX audit Jan-Mar (no major changes), Month-end close (last 3 business days), Year-end freeze (Dec 15–Jan 5).  
> **Requirement:** Database scanning required monthly per FCA expectations, currently achievable quarterly only with manual process.

❌ **WEAK:**
> SOX

---

---

## Section B: Environment Landscape

**WHO SHOULD ANSWER:** Infrastructure Lead / Cloud Ops Lead

### What We're Looking For

Section B maps your **production, DR, and non-production infrastructure**. This tells us where databases live, whether they're isolated (security risk assessment), and which environments can safely be used for POC testing.

**Key insights:**
- **Network isolation** → Access constraints, delegate host requirements
- **Environment count** → POC scope, phasing approach
- **DR setup** → RPO/RTO requirements affect scanning frequency

### Common Pitfalls

❌ **Assuming "All on-prem" without detail.** Specify which datacenter(s), regions, or cloud account. This affects network access planning.

❌ **Conflating "exists" with "actively used."** That legacy staging environment you're decommissioning? Mark as "Exists" but note EOL status in Notes.

❌ **Vague network isolation answers.** "Partial" is OK—but explain: "Prod is isolated via VLAN, QA is on shared subnet." This matters for firewall rule planning.

### Example Answers

**Question: Environment Landscape (Table)**

| Environment | Exists? | Hosting | Network Isolated? | Notes |
|---|---|---|---|---|
| Production | Yes | On-Prem + Azure hybrid | Yes | **Hosting details:** Primary in [DATACENTER_1] (on-prem, Tier 1 data center), DR failover in Azure UK South. **Network:** Strict VLAN segmentation, dedicated jump server [JUMPSERVER_1]. **Business criticality:** Tier 1 – trading cannot operate without this environment. **Maintenance window:** Sunday 02:00–06:00 UTC, 4-hour window. |
| Disaster Recovery | Yes | Azure UK South | Yes | **Hosting details:** Active-passive DR, failover via Azure Site Recovery. **Network:** ExpressRoute connectivity to on-prem. **Testing:** Monthly DR failover test conducted. **RPO:** 15 minutes, **RTO:** 4 hours. |
| UAT | Yes | On-Prem [DATACENTER_2] | Partial | **Network:** Shared UAT environment, controlled access via [JUMPSERVER_3]. **Data refresh:** Refreshed from production quarterly, data masked (PII redacted). **Maintenance window:** Thursday 18:00–22:00 UTC. **Accessibility for POC:** Good candidate for pilot scanning (can test without impacting production). |
| QA | Yes | On-Prem (shared) | No | **Data:** Synthetic only – no production data. **Network:** On shared infrastructure, lower isolation. **Accessibility:** Good for initial connectivity testing. |
| Development | Yes | Azure (Dev/Test subscription) | No | **Hosting:** Azure Dev/Test, self-service provisioning for developers. **Network:** No isolation requirement. **Accessibility:** Low risk for POC testing. |

---

---

## Section C: Hosting Platforms

**WHO SHOULD ANSWER:** Cloud Lead / Infrastructure Lead

### What We're Looking For

Section C identifies **which cloud/on-prem platforms you use** and **what % of your workload** is on each. This affects:
- **Scanning architecture:** Different platforms (Azure SQL vs. on-prem Oracle) require different connectivity patterns
- **Prioritization:** If 80% of your workload is in Azure, we focus there first
- **Tool selection:** Some platforms are easier to scan than others (managed DBs have API-based scanning; on-prem requires agent-based)

### Common Pitfalls

❌ **Confusing "region" with "platform."** If you use Azure, specify region: "Azure UK South (prod + DR)" vs. "Azure" alone.

❌ **Not quantifying workload distribution.** "We use both on-prem and Azure" is ambiguous. DO say: "65% on-prem, 35% Azure."

❌ **Ignoring SaaS platforms.** If you use Snowflake or Databricks, that's a **database platform** that may need scanning coverage.

### Example Answers

**Question: Hosting Platform Coverage (Table)**

| Platform | In Use? | Scope / Details |
|---|---|---|
| **On-Premises** | Yes | **Datacenters:** [DATACENTER_1] (Tier 1, primary production), [DATACENTER_2] (UAT). **Approx workload:** 65% of database estate. **Key systems:** All legacy Sybase systems, core Oracle/MSSQL production. **Network access:** Jump server required from corporate network. Jump servers: [JUMPSERVER_1], [JUMPSERVER_2] (production), [JUMPSERVER_3] (non-prod). |
| **AWS** | No | Not currently in use. Evaluated in 2024 but Azure selected as strategic cloud partner. |
| **Azure** | Yes | **Regions:** UK South (primary). **Account:** Azure subscription [SUBSCRIPTION_ID]. **Approx workload:** 35% of database estate. **Key systems:** DR environment (active-passive failover), Development environments (Dev/Test subscription), new microservices on Azure SQL MI. **Connectivity:** ExpressRoute to on-prem. **Managed databases:** Azure SQL MI, Azure Database for PostgreSQL (Flexible Server). |
| **GCP** | No | No plans to use GCP. |
| **Snowflake** | No | Under evaluation for analytics workloads (Q3 2026 potential POC). Not yet in production use. |

**Workload distribution summary:** 65% on-prem (legacy Sybase + core Oracle/MSSQL), 35% Azure (DR + new cloud workloads).

---

---

## Section D: Database Estate

**WHO SHOULD ANSWER:** DBA Lead (Oracle / MSSQL / Sybase / Other experts per platform)

### What We're Looking For

Section D is the **most important section** for compliance scanning. We need to understand:
- **What databases you run** and **how many of each**
- **Version fragmentation** (running 12c AND 19c Oracle? This complicates scanning.)
- **HA/DR strategy** (Are they replicated? This affects where we scan.)
- **Total instance count** (Large estates = automation is critical; small estates = manual process may suffice)

**Key insights:**
- **60+ instances** → Automation is non-negotiable
- **Multiple versions per platform** → Need flexible InSpec profiles
- **No HA/DR in place** → Higher risk, more urgent scanning need

### Common Pitfalls

❌ **Confusing "databases" with "instances."** One Oracle instance (e.g., PROD01) can contain multiple databases. For compliance scanning, we count **instances**, not databases.

❌ **Leaving version fields vague.** Don't write "Oracle 19c." DO write: "19c (majority, ~10 instances), 12c (legacy, 3 instances pending upgrade Q2 2026)."

❌ **Not distinguishing Prod / DR / Dev.** If you have 18 Oracle instances, split by environment: "12 Prod, 2 DR, 2 UAT, 2 QA" so we understand coverage target.

### Example Answers

**Question: Database Estate (Table)**

| Database Type | Versions in Use | Hosting | HA / DR Strategy | Approx. Instance Count | Notes |
|---|---|---|---|---|---|
| **Oracle** | **19c** (majority, ~10), **12c** (legacy, 3 instances pending upgrade) | On-Prem (Prod, UAT), Azure (DR) | **HA:** Oracle Data Guard for all production instances. **DR:** Azure Site Recovery + Data Guard replication to Azure. **Failover:** Tested monthly. | **Prod:** 12 **DR:** 2 **UAT:** 2 **QA:** 2 **TOTAL:** 18 | **Key risk:** 12c EOL approaching (support ends Dec 2021, currently in extended support). Upgrade required by Q2 2026 to mitigate audit finding. **Scanning implication:** InSpec profiles must support both 12c and 19c during transition period. **Contact:** [TEAM_MEMBER_5] (Oracle DBA) |
| **MSSQL** | **2019** (prod), **2022** (new deployments), **2016** (legacy, 2 instances EOL Q3 2026) | On-Prem (Prod), Azure SQL MI (DR, new workloads) | **HA:** Always-On Availability Groups (AAG) for all prod instances. **DR:** Azure SQL MI with geo-replication. **Failover testing:** Quarterly. | **Prod:** 14 **DR:** 4 **UAT:** 3 **Dev:** 3 **TOTAL:** 24 | **Key risk:** SQL Server 2016 EOL Dec 2024 (currently extended support). 2 instances must migrate to Azure SQL MI by Q3 2026. **Scanning implication:** Need SQL Authentication support (Windows Auth not feasible from Linux scanning hosts). **Contact:** [TEAM_MEMBER_2] (MSSQL DBA) |
| **Sybase** | **ASE 16.0 SP04** (majority, 8 instances), **ASE 15.7** (legacy, 2 instances, upgrade planned) | On-Prem only | **Replication Server** for 4 critical instances only. Non-critical instances (8) have no formal DR. | **Prod:** 8 **UAT:** 2 **Dev:** 2 **TOTAL:** 12 | **Key risk:** Sybase market decline (fewer vendors support it). Legacy platform – upgrade path unclear. **Scanning implication:** Open Client 16.0 required (only available on RHEL 7 – RHEL 8/9 compatibility testing needed). InSpec profiles for Sybase minimal (no CIS benchmark). **Contact:** [TEAM_MEMBER_8] (Sybase DBA) |
| **PostgreSQL** | **14** (stable), **15** (newer) | Azure (Azure Database for PostgreSQL – Flexible Server, cloud-managed) | **HA:** Zone-redundant HA with automatic failover. **Read replicas:** Configured for 2 prod instances. | **Prod:** 2 **DR:** 2 **UAT:** 1 **Dev:** 1 **TOTAL:** 6 | **Key advantage:** Cloud-managed (Azure handles patching, backups, HA). **Scanning implication:** Can scan via Azure AD authentication (MFA support). No client library needed. **Contact:** Cloud Platform team ([TEAM_MEMBER_9]) |

**Summary:** 
- **Total instance count:** 60 instances (all environments)
- **Production instance count:** 36 instances  
- **Platform complexity:** High (4 platforms, multiple versions per platform)
- **Recommended scanning sequencing:** MSSQL first (24 instances, most mature tooling) → Oracle (18 instances, mature InSpec profiles) → PostgreSQL (6 instances, cloud-managed, lowest complexity) → Sybase (12 instances, legacy client library issues, address last)

---

---

## Section E: Inventory & CMDB

**WHO SHOULD ANSWER:** DBA Lead / Infrastructure Lead / CMDB Admin

### What We're Looking For

Section E assesses **inventory quality** and **CMDB reliability.** This matters because:
- **Poor inventory = scanning blind.** If CMDB has stale records, we'll try to scan decommissioned instances.
- **Inventory reconciliation = prerequisite** for compliance scanning. If you don't know what you own, you can't certify what you're scanning.
- **Audit risk:** If auditors find instances you don't know about, that's a control failure.

**Key insights:**
- **Reliable inventory (>90% accurate)** → Can proceed directly to scanning POC
- **Unreliable inventory (<70% accurate)** → Recommend inventory reconciliation as **first engagement** (may delay scanning POC)
- **No CMDB used** → DBA manual spreadsheet is OK if kept current; otherwise risk

### Common Pitfalls

❌ **Saying "CMDB is our source of truth" when you actually use a spreadsheet.** Be honest: "DBA team maintains Excel, CMDB is secondary and has gaps."

❌ **Not quantifying inventory quality.** Don't write "Some stale records." DO write: "8–10 stale records identified in Q4 2025. Last reconciliation was 2025-12-01. Manual cleanup planned Q1 2026."

❌ **Assuming "it's current."** Database inventory dates quickly. When was the last reconciliation? If >6 months ago, it's stale.

### Example Answers

**Question: Primary Inventory Source**

✅ **GOOD:**
> **Primary source:** Internal SharePoint database register maintained by DBA team. Location: [SHAREPOINT_URL]/DatabaseInventory.xlsx. **Frequency:** Manually updated upon provisioning/decommissioning. Last updated: 2026-01-20. **Confidence level:** High (95%+ accurate) – DBA team reviews monthly and updates within 48 hours of change.  
> **Secondary source:** ServiceNow CMDB. **Reliability:** Medium (70–80% accurate) – known gaps in Sybase instance discovery (network segmentation limits auto-discovery). Database-level CIs inconsistently maintained.  
> **How reconciliation works:** Quarterly manual spot-check (last: 2025-12-01). DBA Excel register validated against CMDB; discrepancies logged and remediated within 2 weeks.

❌ **WEAK:**
> CMDB.

---

**Question: Known Data Quality Issues**

✅ **GOOD:**
> **Stale records:** 8–10 identified in Q4 2025 audit. Example: 3 Oracle instances decommissioned 2025-10 but still in CMDB. Cleanup planned Q1 2026 (owner: CMDB team, target: 2026-02-28).  
> **Duplicates:** 3 duplicate Oracle instance records (likely from auto-discovery overlap). Being deduplicated in Q1 2026.  
> **Missing records:** 2 Sybase instances not reflected in CMDB (network segmentation prevents auto-discovery). Manually added to DBA Excel; CMDB update pending network access change (owner: Network team, target: Q2 2026).

---

---

## Section F: Access & Connectivity

**WHO SHOULD ANSWER:** DBA Lead + Infrastructure/Network Lead

### What We're Looking For

Section F maps **authentication methods**, **network access patterns**, and **approval timelines.** This is critical because compliance scanning requires:
- **Authentication:** Valid service account or user credentials
- **Network access:** Can the scanning host reach each database?
- **Firewall approval:** How long does it take to open database ports?

**Key insights:**
- **Jump server required** → Scanning host must be placed on the same network segment or delegate architecture required
- **Service accounts present** → Good (scanning should use service, not user accounts)
- **Firewall CAB approval required** → Plan for 5–7 day lead time before POC start
- **No service account** → Must be created pre-POC (10–15 day turnaround with InfoSec)

### Common Pitfalls

❌ **Assuming "firewall rules are already approved."** Ask your network team! Many BUs **assume** rules exist but discover they don't during POC setup. Always confirm **pre-POC.**

❌ **Confusing authentication methods.** Windows Auth ≠ SQL Auth. Oracle TNS ≠ LDAP. Be specific: "MSSQL uses SQL Authentication (service account svc_mssql_scan, pwd in Vault)."

❌ **Not mentioning jump servers.** If all DB access requires jump server, that changes our scanning architecture significantly.

### Example Answers

**Question: Service Accounts & Credential Management**

✅ **GOOD:**
> **Service accounts in use:** Yes.  
> **Oracle:** svc_oracle_scan@example.internal (managed in Active Directory, password in HashiCorp Vault). **Privileges:** SELECT on all tables, CREATE/ALTER SESSION, ROLE=DBA. **Verification:** [TEAM_MEMBER_5] confirmed these privileges sufficient for InSpec controls. **Password rotation:** 90 days (automated via Vault).  
> **MSSQL:** svc_mssql_scan@example.internal (SQL Authentication, password in Vault). **Privileges:** Server role: sysadmin (required for DMV access needed for compliance checks). **Password rotation:** 90 days.  
> **Sybase:** svc_sybase (local Sybase account). **Privileges:** DBA role. **Password rotation:** Manual, 90 days. **Vault integration:** Not yet available (planned Q2 2026).  
> **Status:** All accounts created and tested. No InfoSec approval blockers.

❌ **WEAK:**
> We have service accounts.

---

**Question: Jump Server & Network Access**

✅ **GOOD:**
> **Jump server required:** Yes, mandatory for all production database access.  
> **Production jump servers:** [JUMPSERVER_1] (primary, Linux RHEL 8), [JUMPSERVER_2] (secondary, Linux RHEL 8). Both located in [NETWORK_ZONE_PROD].  
> **Non-production jump server:** [JUMPSERVER_3] (Linux RHEL 8), [NETWORK_ZONE_NONPROD].  
> **Access provisioning:** Jump server access managed by Network team. Lead time: 3–5 business days.  
> **Scanning implication:** Scanning host must either (a) be placed behind jump server, or (b) use delegate host pattern (Ansible Tower on jump server delegates to scanning engine on remote network segment).  
> **Status:** Firewall rules from [JUMPSERVER_1/2/3] to all prod database servers already approved and in place. **No additional firewall changes needed for POC.**

❌ **WEAK:**
> We have a jump server. Not sure where.

---

**Question: Firewall Approval Process**

✅ **GOOD:**
> **Approval process:** CAB (Change Advisory Board) required. Weekly CAB meeting: Thursdays 3pm UTC.  
> **Lead time:** 5–7 business days (submit by Thursday for approval following week; change can deploy following Monday).  
> **Emergency expedited process:** Available for P1 incidents (24–48 hour approval). Not typically used for compliance scanning.  
> **Pre-approved rules status:** Firewall rules for jump server → database servers **already approved and in place.** No additional approval needed for POC.  
> **Rule owner:** Network team (contact: [NETWORK_LEAD]@example.internal).

---

---

## Section G: Security & Compliance Scanning

**WHO SHOULD ANSWER:** DBA Lead + Security / Compliance Sponsor

### What We're Looking For

Section G is **critical** because it identifies:
- **Current scanning maturity** (None / Manual / Partial automated / Mature automated)
- **Compliance requirements** (CIS benchmarks, regulatory standards, audit frequency)
- **Desired future state** (e.g., "We want monthly scans of all prod instances in Splunk")
- **Gaps** (e.g., "We want to scan Sybase but don't have InSpec profiles")

**Key insights:**
- **No scanning today** → POC will establish baseline; manage audit risk expectations
- **Manual scanning** → POC will automate & reduce effort (easy win for adoption)
- **Partial automated** → POC will extend to other platforms (incremental improvement)
- **Specific controls required** → Must validate InSpec profiles cover those controls before POC

### Common Pitfalls

❌ **Confusing "CIS benchmark" with "custom baseline."** Do you follow the CIS Benchmark v1.1.0 exactly, or have you modified it? If modified, list the changes.

❌ **Overstating current scanning.** "We scan Oracle" ≠ "We scan 12 prod Oracle instances monthly." Quantify what you actually scan and how often.

❌ **Not distinguishing compliance-driven vs. risk-driven scanning.** SOX audit requirement = compliance-driven (non-negotiable frequency). Internal security policy = risk-driven (can adjust if cost/effort prohibitive).

### Example Answers

**Question: Current Scanning Status**

✅ **GOOD:**
> **Scanning currently performed:** Yes, partial coverage.  
> **Platforms scanned today:** Oracle (production only) and MSSQL (production only). Sybase scanning is **inconsistent** (manual, ad-hoc, due to tooling limitations).  
> **Scanning tool:** Custom bash scripts (legacy, maintained by [TEAM_MEMBER_4] – since departed; scripts are undocumented). Some InSpec profiles exist for Oracle (non-standardized, created by individual DBAs).  
> **Scan frequency:** Oracle & MSSQL: Quarterly (SOX requirement). Sybase: Annually or on-demand (no formal requirement).  
> **Environments scanned:** Production only (36 instances). Non-production (24 instances) **not currently scanned** due to manual effort.  
> **Results storage:** JSON files stored on [INSPEC_HOST], manually uploaded to Compliance SharePoint. **No SIEM integration** (Splunk integration planned as part of modernization).  
> **Owner:** DBA team ([TEAM_MEMBER_5] for Oracle, [TEAM_MEMBER_2] for MSSQL).  
> **Status:** Manual process is **unsustainable.** DBA team reports 40–60 hours/quarter for scanning + reporting. Audit risk: Cannot demonstrate current compliance posture between scans. Regulatory expectation: Monthly scans (currently unachievable with manual process).

❌ **WEAK:**
> We scan databases.

---

**Question: CIS Benchmarks Used**

✅ **GOOD:**
> **Oracle:** CIS Oracle 19c Benchmark v1.1.0 (modified). **Modifications:** Skipped 3 controls (1.1.1, 5.2.3, 7.1.2) based on internal architecture (custom auth provider, not compatible with CIS recommendations). All other 85 controls are implemented as-is.  
> **MSSQL:** CIS SQL Server 2019 Benchmark v1.3.0 (modified). **Modifications:** 2 controls skipped (Audit Logon Failures for diagnostic accounts only – audit noise). All other 60 controls are implemented.  
> **Sybase:** No CIS benchmark available. Using internal baseline (10 custom controls focused on access control, encryption, and audit logging). Validated by InfoSec in 2025.  
> **PostgreSQL:** CIS PostgreSQL 14 Benchmark v1.0.0 (no modifications – fully aligned).

❌ **WEAK:**
> CIS benchmarks.

---

**Question: Desired Future State**

✅ **GOOD:**
> **Desired tool:** InSpec via Ansible Automation Platform (AAP2) – standardized, scriptable, integrates with vault.  
> **Desired frequency (production):** Monthly scanning (regulatory expectation for MiFID II reporting). Currently quarterly only due to manual effort.  
> **Desired environment coverage:** All environments (Prod + DR + UAT + QA + Dev) to establish baseline, even if audit requirement is Prod-only.  
> **Desired platforms:** Oracle, MSSQL, Sybase, PostgreSQL (all systems currently in production or planned).  
> **Central reporting:** Yes – Splunk (we have Splunk Enterprise, can integrate compliance scanning into Security dashboards). Real-time alerting on critical findings desired (e.g., failed authentication controls).  
> **Timeline:** POC (Q2 2026, target 4-6 weeks), MVP (Q3 2026, 4-8 weeks), full rollout (Q4 2026).

---

---

## Section H: Constraints, Risks & Dependencies

**WHO SHOULD ANSWER:** Technology Owner + DBA Lead + Security Sponsor + Engagement Lead

### What We're Looking For

Section H is where **blockers and dependencies** get documented. This is vital because:
- **Constraints explain why you can't "just start scanning immediately."**
- **Cross-team dependencies tell us who else we need to engage** (Network, IAM, Cloud, etc.)
- **Risk assessment** helps prioritize blocker removal

**Key insights:**
- **Multiple critical blockers** → Timeline extends; blocker removal becomes parallel workstream
- **Dependencies on slow teams** (Network CAB, InfoSec approval, Cloud provisioning) → Start early
- **Technical constraints** (legacy client libraries, network segmentation) → May require architecture decisions (e.g., delegate host pattern)

### Common Pitfalls

❌ **Being vague about constraints.** Don't write "Network issues." DO write: "Sybase instances are in isolated VLAN; outbound connectivity blocked; network team must approve firewall rule change; lead time 5–7 days."

❌ **Assuming blockers will resolve magically.** If delegate host provisioning is a blocker, **assign an owner and target date** now. Otherwise it becomes a POC killer.

❌ **Downplaying dependencies.** If you need InfoSec approval for service account privileges, and InfoSec typically takes 2 weeks, **plan for 2 weeks,** not optimistically assume 2 days.

### Example Answers

**Question: Technical Constraints**

✅ **GOOD:**
> **Legacy client libraries:** Sybase Open Client 16.0 is required for Sybase connectivity. This library is **only available on RHEL 7** – RHEL 8/9 compatibility untested.  
> **Implication:** If scanning host is RHEL 8+, Sybase scanning will not work until compatibility is tested (1–2 week effort).  
> **Mitigation:** Recommend testing Sybase client on RHEL 8 **pre-POC** (owner: Unix Platform team, target: 2 weeks before POC start).  
> ---  
> **Network segmentation:** Sybase instances are in isolated VLAN; outbound connectivity to internet/central logging blocked.  
> **Implication:** Scanning host cannot send results to remote Splunk instance directly. Requires intermediate relay or jump server integration.  
> **Mitigation:** Decide on architecture (delegate pattern) before POC start. Network team approval may be required (~5-7 day CAB lead time).  
> ---  
> **Oracle version fragmentation:** Running 12c (legacy) and 19c (current) in production. InSpec profiles must support both until 12c upgrade completes (Q2 2026).  
> **Implication:** If InSpec profiles assume 19c-only features, scans will fail on 12c instances.  
> **Mitigation:** Validate InSpec profiles support both versions before POC. May require profile customization (effort: 1–2 days).

---

**Question: Organizational Constraints**

✅ **GOOD:**
> **Change freeze windows:** Month-end (last 3 business days), Quarter-end (last 5 business days), Year-end (Dec 15–Jan 5).  
> **SOX audit period:** Jan-Mar (no major changes to compliance tooling permitted). POC must not conflict with this.  
> **DBA team capacity:** 2 FTE supporting 60 database instances. Limited availability for POC support (estimated 10–15% FTE for 6-week POC).  
> **Implication:** POC success depends on reducing manual effort, not increasing it. Must automate quickly to show value.  
> **Mitigation:** Phased approach – start with MSSQL only (1–2 weeks), then expand to Oracle (2–3 weeks), minimizing DBA burden per phase.

---

**Question: Cross-Team Dependencies**

✅ **GOOD:**

| Dependency | Criticality | Owner | Notes | Target Resolution |
|---|---|---|---|---|
| **Service account permissions review** | ☐ **CRITICAL** ☐ High ☐ Medium ☐ Low | InfoSec ([SECURITY_LEAD]@example.internal) | Current scanning accounts may not have sufficient privileges for all InSpec controls (e.g., DBA role may not grant access to certain system views). Must validate before POC. Typical turnaround: 10–15 days. | 2 weeks before POC start |
| **Scanning host provisioning** | ☐ **CRITICAL** ☐ High ☐ Medium ☐ Low | Unix Platform Team (ticket INFRA-4521) | No centralized scanning host exists. Must provision on-prem Linux host (RHEL 8+). Includes OS hardening, Ansible agent install, and network access setup. Typical turnaround: 3–4 weeks. | 4 weeks before POC start |
| **Firewall rule approval** | ☐ Crit ☐ **HIGH** ☐ Medium ☐ Low | Network Team ([NETWORK_LEAD]@example.internal) | Existing rules approve jump server → databases. But if scanning host differs from jump server, may need additional rules. Standard CAB lead time: 5–7 business days. | 2 weeks before POC start |
| **Sybase client library compatibility testing** | ☐ Crit ☐ **HIGH** ☐ Medium ☐ Low | Unix Platform Team + DBA ([TEAM_MEMBER_8]) | Sybase Open Client 16.0 compatibility with RHEL 8 unknown. Must test before Sybase inclusion in POC. Effort: 1–2 weeks. | 2 weeks before POC start |
| **Azure AD authentication setup (PostgreSQL)** | ☐ Crit ☐ High ☐ **MEDIUM** ☐ Low | Cloud Platform Team / IAM | PostgreSQL on Azure DB requires Azure AD authentication (under evaluation). May require Managed Identity or service principal setup. Low priority for POC (can use SQL Auth as backup). | 3 weeks before POC start |

---

---

## Section I: Readiness & Engagement

**WHO SHOULD ANSWER:** Technology Owner + DBA Lead (+ Engagement Lead)

### What We're Looking For

Section I assesses **your appetite for engagement** and **realistic timelines.** This section is about **expectations setting:**
- Are you **motivated** to automate scanning?
- Are there **known blockers** we must address before starting?
- **When can you realistically start** a POC?

**Key insights:**
- **"Yes, willing, no blockers" is rare.** Most BUs have 1–3 blockers. That's normal and manageable.
- **Blockers are OK to surface.** It's better to know now than discover them week 3 of a POC.
- **Timeline transparency helps us plan.** If you say "Q2 2026, post-SOX audit," we know not to push for Q1 start.

### Common Pitfalls

❌ **Saying "yes" to POC but not identifying blockers.** You're setting yourself up for failure. Be honest: "Yes, willing, but we need service account permissions reviewed first."

❌ **Being overly optimistic about timeline.** "We can start immediately!" (vs. reality: "We can start 2 weeks after firewall rules are approved.") Plan conservatively.

❌ **Not identifying the **right person** to assign blockers to.** "Service account permissions reviewed" by **whom?** Assign a specific owner, title, and target date.

### Example Answers

**Question: Willing to Engage in POC**

✅ **GOOD:**
> **Answer:** Yes, **strongly motivated.**  
> **Reasoning:** Current manual scanning process is unsustainable (40–60 hours/quarter for 36 production instances). DBA team capacity is bottleneck. Audit risk: Cannot demonstrate current compliance between quarterly scans (regulators expect monthly). Automation is critical to our roadmap. DBA team is supportive of POC.

❌ **WEAK:**
> Yes.

---

**Question: Key Blockers**

✅ **GOOD:**

| Blocker | Criticality | Mitigation / Owner | Target Resolution |
|---|---|---|---|
| Service account permissions insufficient for all InSpec controls | ☐ **CRITICAL** ☐ High ☐ Medium | InfoSec review (2-week turnaround). Owner: [SECURITY_LEAD]. Contact: [SECURITY_LEAD]@example.internal | 2026-02-28 |
| Scanning host provisioning (INFRA-4521) | ☐ **CRITICAL** ☐ High ☐ Medium | Unix Platform team (3–4 week lead). Owner: [UNIX_LEAD]. Contact: [UNIX_LEAD]@example.internal | 2026-03-15 |
| Sybase client library compatibility testing on RHEL 8 | ☐ Crit ☐ **HIGH** ☐ Medium | Test in lab (1–2 week effort). Owner: [TEAM_MEMBER_8] (Sybase DBA) + Unix team. | 2026-03-01 |
| Firewall rule approval for scanning host (if needed) | ☐ Crit ☐ **HIGH** ☐ Medium | CAB approval (5–7 day lead). Owner: Network team. Trigger: Once scanning host host/IP known. | Dependent on host provisioning |

---

**Question: Preferred Engagement Timeline**

✅ **GOOD:**
> **POC start window:** Post-SOX audit completion, **April 2026** (Q1 SOX audit period Jan-Mar blocks major changes; Q1 restricted).  
> **Rationale:** DBA team has limited availability Jan-Mar (audit support), additional availability post-audit.  
> **POC duration target:** 4–6 weeks (mid-April to late-May).  
> **Platform sequencing:** MSSQL first (24 instances, largest estate, most mature InSpec profiles available) → Oracle (18 instances, mature profiles) → PostgreSQL (6 instances, cloud-managed, simplest) → Sybase last (12 instances, legacy tooling, highest complexity).  
> **MVP onboarding:** June–July 2026 (Q2 2026).  
> **Full rollout:** August–September 2026 (Q3 2026).  
> **Hard constraints:** Must complete POC before Q3 audit window (exact dates TBD; assume August onwards is audit period).

---

---

## General Tips for All Responders

### Before You Start the Questionnaire

1. **Assign roles** – Don't have one person answer all sections. Assign per role (Tech Owner, DBA, Security).
2. **Gather current inventory** – Pull together existing docs: CMDB export, DBA spreadsheet, service account list, firewall rules spreadsheet.
3. **Schedule 1 hour** – Don't rush. Block dedicated time to complete the questionnaire thoroughly.
4. **Clarify ambiguities** – If you don't understand a question, **ask the engagement lead** (don't guess).

### During Completion

- **Be specific.** Vague answers delay us. "Yes/No" is often incomplete; add details.
- **Be honest about unknowns.** If you don't know the answer, write "Unknown – will confirm with [OWNER]" and follow up later.
- **Quantify everything.** Instance counts, % of workload, lead times, FTE availability.
- **List names.** Not just "DBA team" – actual names, emails, phone numbers. We'll need to contact these people.

### After Completion

- **Review before submitting.** Spot-check a few answers: Do instance counts add up? Are dates realistic?
- **Send to engagement lead 1 week before discovery call.** Don't wait until the discovery call to submit (creates delay).
- **Expect follow-up questions.** We may contact responders to clarify complex areas (e.g., network segmentation setup, current tooling details).

---

## Common Questions to Clarify

### "What's the difference between 'Database Instance' and 'Database'?"

**Instance:** A running database server process. Example: Oracle instance **PROD01** on server HOST_A.  
**Database:** A logical collection of data within an instance. Example: Instance PROD01 contains databases TRADING, REPORTING, CUSTOMER.

For compliance scanning, **count instances.** One instance can contain multiple databases.

---

### "What does 'Approx. Instance Count' mean?"

It means an estimate. You don't need the exact count – within 5–10% is fine. But for **production**, try to be accurate (this is what we'll scan).

**Example:** "Prod: 12 Oracle instances (exact, we know for sure), Dev: 4 instances (estimate, developers provision ad-hoc)."

---

### "What's 'Network Isolated'?"

It describes whether the environment is network-separated from other environments (e.g., via firewall, VLANs, security groups).

- **Yes:** "Production has dedicated VLAN, firewall blocks traffic from other networks."
- **No:** "QA is on shared corporate subnet, firewall rules don't restrict internal traffic."
- **Partial:** "UAT has dedicated VLAN but shares jump server with QA."

---

### "What if I don't have data for a section?"

Mark it as **"Unknown"** or **"Not applicable"** and explain why:
- "Unknown – we don't track instance counts per environment, only total. Will confirm with DBA team."
- "Not applicable – no Sybase in our environment."

---

## Document Control

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 2026-01-26 | Northstar Engagement Team | Initial role-specific response guide with examples |
