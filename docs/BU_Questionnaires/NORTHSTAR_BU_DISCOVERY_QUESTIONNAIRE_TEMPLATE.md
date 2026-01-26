# Business Unit Infrastructure & Database Discovery Questionnaire

**[NORTHSTAR ADAPTED TEMPLATE FOR FIRST ENGAGEMENT]**

---

## Document Metadata

| Field | Value |
|-------|-------|
| **Business Unit Name** | `[INSERT_BU_NAME]` |
| **Completed by** | `[TEAM_MEMBER_NAME]` (Role) |
| **Date Completed** | `[YYYY-MM-DD]` |
| **Contact Email** | `[email@example.internal]` |
| **Questionnaire Version** | Northstar BU Discovery v1.0 |
| **Template Purpose** | First engagement infrastructure & database discovery for new Northstar business units |

---

## Purpose

This questionnaire captures a comprehensive, current-state view of a Business Unit's infrastructure and database estate. The information collected will be used for:
- **Visibility:** Establishing baseline infrastructure inventory
- **Risk Assessment:** Identifying security, compliance, and operational risks
- **Planning:** Informing POC scope, MVP phasing, and long-term automation roadmap
- **Compliance:** Supporting regulatory requirements (SOX, GDPR, PCI, FCA, etc.)

**Expected Completion Time:** 45–60 minutes  
**Who Should Complete:** Primary Technology Owner or Infrastructure Lead (may require input from DBAs, Security team)

---

---

# SECTION A: Business Unit Context

This section establishes the organizational and regulatory context for the business unit.

## A.1 Business Unit Identity

| Field | Response |
|-------|----------|
| **Business Unit Name** | |
| **Business Unit Description** | Provide 2–3 sentences describing the BU's purpose, primary systems, and business criticality. *Example: "Global Markets Trading Platform supporting equities, fixed income, and derivatives trading across EMEA, APAC, Americas regions. Processes ~2.5M trades/day during peak periods."* |
| **Primary Business Functions** | List 3–5 key business functions (e.g., "Trade Execution," "Order Management," "Position Reporting," "Regulatory Compliance") |
| **Business Criticality** | Select: **Mission-Critical** / **Business-Critical** / **Important** / **Standard** |

## A.2 Organizational Contacts

| Field | Response |
|-------|----------|
| **Primary Technology Owner (Name / Title / Email)** | E.g., "John Smith / Head of Trading Technology / john.smith@example.internal" |
| **Primary DBA Contact (Name / Title / Email)** | E.g., "Jane Doe / Lead Database Administrator / jane.doe@example.internal" |
| **Secondary / Escalation Contact (Name / Title / Email)** | E.g., "Robert Chen / Senior Platform Engineer / robert.chen@example.internal" |
| **Security/Compliance Sponsor (Name / Title / Email)** | Name of person accountable for security scanning & compliance posture |

## A.3 Regulatory & Audit Sensitivity

| Field | Response |
|-------|----------|
| **Applicable Regulations** | Select all that apply: ☐ SOX (Section 404) ☐ GDPR ☐ PCI-DSS ☐ HIPAA ☐ FCA ☐ MiFID II ☐ NIST ☐ CIS ☐ Internal Policy ☐ Other: ____________ |
| **Audit/Compliance Bodies** | List any external or internal audit bodies that assess this BU (e.g., "Internal Audit (Quarterly), External Auditor (Annual), FCA Regulatory Reporting") |
| **Key Compliance Windows** | List any restricted engagement periods (e.g., "SOX audit Jan-Mar, Month-end freeze last 3 business days, Year-end Dec 15–Jan 5"). **CRITICAL FOR TIMELINE PLANNING.** |
| **Compliance Scanning Requirements** | Describe any documented requirements for database security scanning frequency, coverage, or standards (e.g., "Quarterly Oracle/MSSQL scans required for SOX attestation"). |

**💡 Note:** Regulatory drivers often explain urgency, prioritize platforms, and define success metrics. Compliance windows constrain engagement dates.

---

---

# SECTION B: Environment Landscape

This section captures what environments exist, where they're hosted, and their isolation/security posture.

## B.1 Environment Inventory Table

| Environment | **Exists?** | **Hosting** | **Network Isolated?** | **Notes / Details** |
|---|---|---|---|---|
| **Production** | Yes / No | On-Prem / Cloud / Hybrid | Yes / No / Partial | Primary production workloads. Specify datacenter location, region, or cloud account. |
| **Disaster Recovery** | Yes / No | On-Prem / Cloud / Hybrid | Yes / No / Partial | RPO/RTO targets if defined. Failover frequency testing schedule. |
| **UAT** | Yes / No | On-Prem / Cloud / Hybrid | Yes / No / Partial | Data refresh frequency (e.g., "refreshed from prod monthly, data masked"). |
| **QA / Testing** | Yes / No | On-Prem / Cloud / Hybrid | Yes / No / Partial | Synthetic data only, or production-derived? Test windows / constraints? |
| **Development** | Yes / No | On-Prem / Cloud / Hybrid | Yes / No / Partial | Self-service provisioning? Isolation approach? |
| **Other (specify)** | Yes / No | On-Prem / Cloud / Hybrid | Yes / No / Partial | E.g., "Performance Testing," "Staging," "Legacy," etc. |

## B.2 Environment-Specific Details

**Production Environment:**
- Primary datacenter(s) / cloud region(s): _______________
- Tier-1 (mission-critical) system count: _______________
- Estimated user/transaction volume: _______________
- Change management process (e.g., CAB approval required?): _______________

**Disaster Recovery Environment:**
- Hosting location (must differ from production): _______________
- Failover automation available? Yes / No / Partial
- Last tested: _______________
- RTO (Recovery Time Objective): _______________
- RPO (Recovery Point Objective): _______________

**Non-Production Environments:**
- Shared or dedicated? Shared / Dedicated / Mixed
- Data refresh cadence: _______________
- Access controls (open to all developers or restricted)? _______________

---

---

# SECTION C: Hosting Platforms

This section identifies cloud and on-premises platforms in use.

## C.1 Hosting Platform Coverage

| Platform | **In Use?** | **Scope / Details** |
|---|---|---|
| **On-Premises** | Yes / No | Datacenter(s): _____________ Approx % of workload: ___% |
| **AWS** | Yes / No | Regions: _____________ Approx % of workload: ___% |
| **Azure** | Yes / No | Regions: _____________ Approx % of workload: ___% Account/Subscription: _____________ |
| **Google Cloud (GCP)** | Yes / No | Regions: _____________ Approx % of workload: ___% |
| **OCI (Oracle Cloud)** | Yes / No | Regions: _____________ Approx % of workload: ___% |
| **Databricks** | Yes / No | Workspace(s): _____________ Approx % of workload: ___% |
| **Snowflake** | Yes / No | Account(s): _____________ Approx % of workload: ___% |
| **Other (specify)** | Yes / No | Name: _____________ Details: _____________ |

## C.2 Multi-Cloud / Hybrid Strategy Details

- **Primary platform:** _______________
- **Strategic cloud partner (if any):** _______________
- **Rationale for multi-platform approach:** _______________
- **Cloud migration status:** On-going / Planned / Paused / None
- **Timeline for cloud migration (if applicable):** _______________

---

---

# SECTION D: Database Estate

This section catalogs all database platforms and instance counts.

## D.1 Database Platform Inventory

| **Database Type** | **Versions in Use** | **Hosting** | **HA / DR Strategy** | **Approx. Instance Count** | **Notes** |
|---|---|---|---|---|---|
| **Oracle** | E.g., "19c (majority), 12c (legacy)" | On-Prem / Cloud / Hybrid | Data Guard / ASM / RAC / Other | **Prod:** ___ **DR:** ___ **Dev:** ___ | End-of-life versions? Migration planned? |
| **MSSQL** | E.g., "2019 (prod), 2022 (new)" | On-Prem / Cloud / Hybrid | Always-On / Failover / Mirror | **Prod:** ___ **DR:** ___ **Dev:** ___ | On-Prem or Azure SQL MI? |
| **Sybase** | E.g., "ASE 16.0 SP04 (prod)" | On-Prem / Cloud / Hybrid | Replication Server / Manual | **Prod:** ___ **DR:** ___ **Dev:** ___ | Legacy risk? Upgrade timeline? |
| **PostgreSQL** | E.g., "14, 15 (newer)" | On-Prem / Cloud / Hybrid | Streaming Replication / HA Cluster | **Prod:** ___ **DR:** ___ **Dev:** ___ | Cloud-managed (Azure DB / RDS / GCP)? |
| **MySQL** | E.g., "8.0" | On-Prem / Cloud / Hybrid | InnoDB / Percona Cluster | **Prod:** ___ **DR:** ___ **Dev:** ___ | Cloud-managed (AWS RDS / Azure)? |
| **MongoDB / NoSQL** | E.g., "4.4, 5.0" | On-Prem / Cloud / Hybrid | Replica Set / Sharding | **Prod:** ___ **DR:** ___ **Dev:** ___ | Document store, time-series, graph DB? |
| **Snowflake** | E.g., "Cloud-native" | Cloud (SaaS) | Cloud-managed HA | **Prod:** ___ **Dev:** ___ | Data warehouse, data lake use case? |
| **Databricks** | E.g., "Delta Lake" | Cloud (SaaS) | Cloud-managed HA | **Prod:** ___ **Dev:** ___ | Lakehouses, ML/analytics workloads? |
| **Elasticsearch / Search** | E.g., "7.x, 8.x" | On-Prem / Cloud / Hybrid | Cluster / Replication | **Prod:** ___ **Dev:** ___ | Observability, search, logging use case? |
| **Redis / Memcached** | E.g., "Redis 6, 7" | On-Prem / Cloud / Hybrid | Cluster / Sentinel / Managed | **Prod:** ___ **Dev:** ___ | Caching, sessions, real-time data? |
| **Other (specify)** | | | | | |

**Total Database Instance Count (All Environments):** _______________  
**Total Production Instance Count:** _______________

## D.2 Database-Specific Risks & Constraints

**EOL / Legacy Platforms:**
- Any databases approaching end-of-life (EOL) in next 12–24 months? Yes / No
- If yes, list with EOL date and planned replacement: _______________

**Version Fragmentation:**
- Major version distribution challenges (e.g., "12c and 19c Oracle, hard to script uniformly")? _______________

**Specialized / Uncommon Databases:**
- Any uncommon platforms (Teradata, Netezza, Informix, etc.) not listed above? _______________

---

---

# SECTION E: Inventory & CMDB

This section assesses the quality and currency of infrastructure inventory.

## E.1 Inventory Source of Truth

| Field | Response |
|-------|----------|
| **Primary inventory source** | E.g., "ServiceNow CMDB," "Internal Excel spreadsheet," "Ansible inventory," "Terraform state," etc. Describe tool and update frequency. |
| **Is CMDB (e.g., ServiceNow) used?** | Yes / Partial / No |
| **If CMDB used, reliability rating** | **High** (95%+ confidence in accuracy) / **Medium** (70–95%) / **Low** (<70%) |
| **Who maintains inventory?** | E.g., "DBA team (manual), Cloud Platform team (Terraform), Unix team (CMDB sync)" |
| **Update frequency** | Real-time / Daily / Weekly / Monthly / On-demand only / Manual, ad-hoc |

## E.2 Inventory Quality Assessment

| Item | Yes | No | Partial | Details |
|---|---|---|---|---|
| **Known stale records in inventory** | | | | How many? When identified? Cleanup plan? |
| **Known duplicate records** | | | | How many? Platform distribution? |
| **Known missing records (systems exist but not in inventory)** | | | | How many? Why missing (network isolation, legacy, recent provisioning)? |
| **Database instance-level inventory captured** | | | | Or only server-level? |
| **Version information captured per instance** | | | | Critical for compliance scanning. |

## E.3 Reconciliation Process

| Field | Response |
|-------|----------|
| **Formal reconciliation process in place?** | Yes / No / Partial |
| **If yes, reconciliation frequency** | Quarterly / Semi-annually / Annually / Ad-hoc |
| **Last reconciliation date** | _______________  |
| **Owner of reconciliation activity** | E.g., "DBA team," "Infrastructure team," "Cloud Ops" |

## E.4 Open Inventory Comments

**Free text:** Describe any known inventory challenges, data quality concerns, or planned improvements:

_______________________________________________________________________________________________________________________________________________

---

---

# SECTION F: Access & Connectivity

This section captures network access patterns, authentication methods, and connectivity requirements.

## F.1 Authentication & Account Types

| Aspect | Response |
|---|---|
| **Service / non-human accounts used for DB access?** | Yes / No |
| **If yes, how many service accounts per platform?** | Oracle: ___ MSSQL: ___ Sybase: ___ PostgreSQL: ___ Other: ___ |
| **Service account naming convention** | E.g., "svc_[platform]_scan@example.internal" |
| **Service account credential management** | Vault / Secrets Manager / Ansible Tower / Manual file / Other: _______________  |
| **Password rotation policy** | Every ___ days (standard: 90 days recommended) |
| **Individual user accounts used for DB access?** | Yes / No |
| **If yes, should scanning use individual accounts?** | Yes / No / Not recommended |

## F.2 Network Connectivity

| Aspect | Response |
|---|---|
| **Jump server required to access databases?** | Yes / No / Partial (some envs only) |
| **If yes, jump server names/IPs** | Production: _____________ Non-Prod: _____________ |
| **Jump server ownership** | _______________  |
| **Direct database connectivity permitted from corporate network?** | Yes / Restricted / No |
| **If restricted, what hosts can connect directly?** | E.g., "Management hosts only," "Specific subnets," "Jump servers only" |
| **Network segmentation (VLANs / security groups)?** | Yes / No / Partial |
| **Firewall rules pre-approved for compliance scanning access?** | Yes / No / Needs approval |

## F.3 Firewall & Access Approval Process

| Aspect | Response |
|-------|----------|
| **Firewall rule approval process** | E.g., "CAB approval required," "Network team approval," "Self-service within guardrails," "No approval needed" |
| **Typical lead time for firewall changes** | _____ business days |
| **Emergency / expedited change process available?** | Yes / No |
| **If yes, expedited lead time** | _____ hours / _____ days |
| **Firewall approval owner** | _______________  |

## F.4 Database-Specific Connectivity Notes

**Oracle:**
- TNS entry required? Yes / No
- Instant Client available on scanning host(s)? Yes / No / Not yet
- Port: _______________

**MSSQL:**
- Windows Authentication or SQL Authentication? Windows / SQL / Both
- If Windows Auth: Kerberos delegation configured? Yes / No / Partial
- Port(s): _______________

**Sybase:**
- INTERFACES file or LDAP? Interfaces file / LDAP / Both
- Open Client available on scanning host(s)? Yes / No / Not yet
- Port: _______________

**PostgreSQL:**
- Standard port or custom? _______________
- Connection pooler in use (PgBouncer, pgpool)? Yes / No

**Other platforms:**
- _______________________________________________________________________________

---

---

# SECTION G: Security & Compliance Scanning

This section assesses current and desired state of database security scanning.

## G.1 Current Scanning Status

| Aspect | Response |
|---|---|
| **Database security scanning currently performed?** | Yes / No / Partial (some platforms only) |
| **If yes, platforms covered** | ☐ Oracle ☐ MSSQL ☐ Sybase ☐ PostgreSQL ☐ MySQL ☐ Other: ___________ |
| **Scanning tool(s) in use** | E.g., "Custom bash scripts," "InSpec," "OpenSCAP," "Qualys," "Tenable Nessus," "Vendor tool (specify)" |
| **Scan frequency (production)** | Weekly / Monthly / Quarterly / Annually / Ad-hoc / Never |
| **Scan frequency (non-production)** | Weekly / Monthly / Quarterly / Annually / Ad-hoc / Never |
| **Environments currently scanned** | ☐ Production ☐ DR ☐ UAT ☐ QA ☐ Development |
| **Scanning owner** | E.g., "DBA team," "Security team," "Compliance team" |
| **Scan results storage location** | E.g., "SIEM (Splunk)," "Shared drive," "JSON files," "Confluence," "ServiceNow" |

## G.2 Compliance & Benchmarking

| Aspect | Response |
|-------|----------|
| **CIS benchmarks in use (select all that apply)** | ☐ CIS Oracle Benchmark ☐ CIS MSSQL Benchmark ☐ CIS PostgreSQL Benchmark ☐ CIS Sybase Benchmark ☐ Custom baseline ☐ None / Not defined ☐ Other: __________ |
| **If custom baseline, describe** | _______________________________________________________________________________________________________________________________________________  |
| **NIST CSF / NIST 800-53 alignment required?** | Yes / No |
| **SOX / GDPR / PCI-DSS specific controls required?** | Yes / No (if yes, list key controls): ___________ |
| **Scanning standard or regulation** | Compliance-driven (required by regulation) / Risk-driven (internal security policy) / Audit-driven (external auditor request) / Not defined |

## G.3 Desired Future State

| Aspect | Response |
|-------|----------|
| **Desired future scanning tool** | InSpec via Ansible / Vendor tool / Custom / Undecided |
| **Desired scan frequency (production)** | Weekly / Monthly / Quarterly / Annually / Real-time monitoring |
| **Desired environment coverage** | Production only / Production + DR / All environments (Prod+DR+UAT+QA+Dev) |
| **Desired platforms for automated scanning** | ☐ Oracle ☐ MSSQL ☐ Sybase ☐ PostgreSQL ☐ MySQL ☐ Snowflake ☐ Databricks ☐ Other: __________ |
| **Central reporting desired?** | Yes / No (if yes, platform): E.g., "Splunk," "ServiceNow," "Confluence," "Custom dashboard" |

## G.4 Scanning Constraints & Risks

| Aspect | Response |
|-------|----------|
| **Service account permissions sufficient for all controls?** | Yes / No / Unknown (requires InfoSec review) |
| **Any database connectivity constraints for scanning?** | _______________________________________________________________________________  |
| **Any licensing or cost constraints for scanning tools?** | _______________________________________________________________________________  |
| **Any organizational constraints (approval, change windows)?** | _______________________________________________________________________________  |

---

---

# SECTION H: Constraints, Risks & Dependencies

This section captures blockers, technical constraints, and cross-team dependencies that will affect implementation.

## H.1 Technical Constraints

**Database-specific:**
- Legacy client library requirements (e.g., Sybase Open Client version requirements, Oracle Instant Client compatibility)
- Version fragmentation (e.g., "Multiple Oracle versions from 12c–19c, difficult to script uniformly")
- Network segmentation preventing direct connectivity (e.g., "Sybase instances in isolated VLAN, limited egress")
- Other: _______________________________________________________________________________________________________________________________________________

**Scanning infrastructure:**
- No centralized scanning host available yet (require provisioning)
- Scanning host OS / software version constraints (e.g., "Only RHEL 7 available, but InSpec requires RHEL 8+")
- No password/secrets management in place (credentials hardcoded, manual)
- Other: _______________________________________________________________________________________________________________________________________________

## H.2 Organizational / Process Constraints

- **Change freeze windows:** Describe any blackout periods (e.g., "Month-end last 3 business days," "Year-end Dec 15–Jan 5," "SOX audit Jan-Mar"): _______________________________________________________________________________________________________________________________________________
- **Change approval process:** CAB, Network CAB, InfoSec approval, etc. Lead time: _____ days
- **Audit / compliance windows:** Periods when major tooling changes restricted (e.g., "Q1 SOX audit period"): _______________________________________________________________________________________________________________________________________________
- **Team capacity constraints:** FTE available for implementation, BAU, training: _______________________________________________________________________________________________________________________________________________
- **Other:** _______________________________________________________________________________________________________________________________________________

## H.3 Cross-Team Dependencies

**Rate each dependency as Critical / High / Medium / Low:**

| Dependency | Criticality | Owner | Notes |
|---|---|---|---|
| **IAM / Credential Management** | ☐ Crit ☐ High ☐ Med ☐ Low | Team name: _____________ | Service account provisioning, password rotation, secrets vault access |
| **Network Team** | ☐ Crit ☐ High ☐ Med ☐ Low | Team name: _____________ | Firewall rules, jump server access, network segmentation changes |
| **Cloud Platform Team** | ☐ Crit ☐ High ☐ Med ☐ Low | Team name: _____________ | Azure / AWS / GCP connectivity, managed DB setup, cloud account access |
| **Infrastructure / Unix Team** | ☐ Crit ☐ High ☐ Med ☐ Low | Team name: _____________ | Scanning host provisioning, OS patching, agent deployment |
| **Windows / Database Admin Team** | ☐ Crit ☐ High ☐ Med ☐ Low | Team name: _____________ | MSSQL patching, Windows Auth setup, DB configuration changes |
| **Information Security** | ☐ Crit ☐ High ☐ Med ☐ Low | Team name: _____________ | Security control validation, compliance profile review, vulnerability remediation |
| **Change Management / CAB** | ☐ Crit ☐ High ☐ Med ☐ Low | Team name: _____________ | Approval for production changes, baseline scanning tool changes |
| **Other (specify)** | ☐ Crit ☐ High ☐ Med ☐ Low | Team name: _____________ | |

---

---

# SECTION I: Readiness & Engagement

This section assesses the BU's willingness and readiness to participate in a pilot / POC.

## I.1 Pilot / POC Engagement

| Aspect | Response |
|---|---|
| **Willing to engage in POC / pilot activity?** | Yes / No / Conditional (if conditional, specify): _______________ |
| **Primary motivation for engagement** | ☐ Regulatory compliance ☐ Reduce audit risk ☐ Improve automation ☐ Reduce manual effort ☐ Cost optimization ☐ Performance improvement ☐ Other: __________ |
| **Success criteria for POC** | E.g., "Successful scan of 5 prod Oracle instances," "Zero false positives," "Result in Splunk," "Team trained" |

## I.2 Key Blockers to Engagement

**List all known blockers and rate each as Critical / High / Medium / Low:**

| Blocker | Criticality | Mitigation / Owner | Target Resolution Date |
|---|---|---|---|
| E.g., "Service account permissions insufficient" | ☐ Crit ☐ High ☐ Med ☐ Low | InfoSec review, 2-week turnaround | MM/DD/YYYY |
| E.g., "Scanning host not yet provisioned" | ☐ Crit ☐ High ☐ Med ☐ Low | Unix team ticket INFRA-4521 | MM/DD/YYYY |
| E.g., "Sybase client library compatibility untested" | ☐ Crit ☐ High ☐ Med ☐ Low | Testing on RHEL 8, 1-week turnaround | MM/DD/YYYY |
| | | | |

## I.3 Timeline & Sequencing

| Aspect | Response |
|---|---|
| **Preferred POC start date (or window)** | E.g., "Post-SOX audit, April 2026" or "Q2 2026" |
| **Preferred POC duration** | E.g., "4–6 weeks" |
| **Platform sequencing preference (if multi-platform)** | E.g., "MSSQL first (largest estate), then Oracle, then Sybase" or "No preference" |
| **MVP onboarding target date** | E.g., "Q3 2026" |
| **Full rollout target date** | E.g., "Q4 2026" or "End of 2026" |
| **Any hard constraints on timeline?** | E.g., "SOX audit period blocks Jan-Mar," "Must complete before Year-end" |

## I.4 Team Capacity & Engagement Model

| Aspect | Response |
|---|---|
| **DBA/Tech lead availability for POC** | Full-time / Part-time (% FTE): _____ / Limited (scheduled sessions) / Unavailable until (date): _____________ |
| **Preferred engagement model** | Hands-on (DBA/tech lead actively implementing) / Observational (support from sidelines) / Guided (step-by-step, we lead) / Self-service (minimal support needed) |
| **Preference for training / enablement** | Workshop / Written guide / Video / One-on-one pairing / No training needed |
| **Key person(s) to loop in** | Names & roles of 2–3 critical stakeholders for steering conversations |

## I.5 Success Metrics & Reporting

| Aspect | Response |
|---|---|
| **How will success be measured?** | E.g., "% of instances scanned," "Time to scan," "Findings trending," "Audit pass," "Team satisfaction" |
| **Preferred reporting frequency** | Weekly / Bi-weekly / Monthly / Monthly+ |
| **Preferred reporting format** | Dashboard / Email / Confluence / ServiceNow / Slack / In-person sync |
| **Key metrics to track** | E.g., "# instances scanned," "Scan duration," "False positive rate," "Control pass/fail rate," "Time to remediate findings" |

---

---

# SECTION J: Additional Context (Optional)

Use this section for any other relevant details not captured above.

## J.1 Systems of Record & Criticality

**Tier-1 (Mission-Critical) Systems:**
- List any systems where unplanned downtime has immediate business impact

| System Name | Database Platform | Instance(s) | Business Impact / SLA |
|---|---|---|---|
| Example: "Order Management System (OMS)" | Oracle 19c | [DB_SERVER_OMS_1], [DB_SERVER_OMS_2] | Trading cannot operate without this system. RTO: <30 min |
| | | | |

## J.2 Maintenance Windows

| Environment | Day | Time (UTC) | Duration |
|---|---|---|---|
| Production (Tier 1) | E.g., "Sunday" | E.g., "02:00–06:00" | E.g., "4 hours" |
| Production (Tier 2/3) | | | |
| UAT | | | |
| QA / Dev | | | |

## J.3 Planned Infrastructure Changes (Next 12–24 months)

| Change | Platform | Target Date | Impact on Scanning |
|---|---|---|---|
| E.g., "Oracle 12c to 19c upgrade (3 instances)" | Oracle | Q2 2026 | InSpec profiles must support both versions during transition |
| | | | |

## J.4 Current Tools & Integrations

| Area | Tool / Platform | Notes |
|---|---|---|
| **CMDB / Inventory** | E.g., "ServiceNow," "Custom Excel" | How frequently refreshed? |
| **Credential Management** | E.g., "HashiCorp Vault," "Azure Key Vault," "Manual files" | Any API integrations? |
| **Monitoring / Observability** | E.g., "Splunk," "Datadog," "Prometheus" | Can scan results feed into this? |
| **Change Management** | E.g., "ServiceNow CAB," "Jira," "Manual email" | Approval SLA? |
| **CI/CD / Automation** | E.g., "Ansible," "Jenkins," "GitLab CI" | Can scanning be integrated into pipeline? |

---

---

# Completion Checklist

Before submitting this questionnaire, confirm:

- ☐ All contact information filled in (Section A.2)
- ☐ Environment landscape completed (Section B)
- ☐ Database inventory complete (Section D) — instance counts required
- ☐ Inventory quality assessed (Section E)
- ☐ Access & connectivity documented (Section F)
- ☐ Current scanning status captured (Section G.1)
- ☐ Key blockers listed with criticality (Section I.2)
- ☐ Timeline & preferred engagement dates provided (Section I.3)

**Incomplete questionnaires may delay POC planning. If unsure about any response, mark as "Unknown" and follow up by email.**

---

---

# Next Steps

1. **Submission:** Return completed questionnaire to [PRIMARY_ENGAGEMENT_CONTACT] by [DUE_DATE]
2. **Review & Validation:** Engagement team reviews questionnaire for completeness (1 week)
3. **Discovery Meeting:** Schedule 60-min discovery review with BU technology lead, DBA lead, and engagement lead to clarify gaps and validate findings
4. **Blocker Removal:** Begin work on Critical/High blockers in parallel (firewall rules, service accounts, scanning host provisioning)
5. **POC Planning:** Develop detailed POC scope & timeline based on questionnaire + discovery meeting outputs

---

---

# Document Control

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 2026-01-26 | Northstar Engagement Team | Initial Northstar-adapted template with multi-cloud, modern databases, and enhanced first-engagement guidance |

---

**Questions or clarifications?** Contact [ENGAGEMENT_LEAD_EMAIL] or [ENGAGEMENT_LEAD_PHONE]
