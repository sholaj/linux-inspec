h1. Business Unit Infrastructure & Database Discovery Questionnaire

{info}
This is a COMPLETED EXAMPLE questionnaire for reference purposes.
Business Unit: Global Markets Trading Platform
Completed by: [TEAM_MEMBER_1] (Technology Owner)
Date: 2026-01-15
{info}

Purpose:
This questionnaire captures a consistent, current-state view of a Business Unit's infrastructure and database estate. The information collected will be used for visibility, risk assessment, and planning purposes.

h2. A. Business Unit Context

|| Field || Response ||
| Business Unit Name | Global Markets Trading Platform (GMTP) |
| Business Unit Description | Real-time trading operations platform supporting equities, fixed income, and derivatives trading across EMEA, APAC, and Americas regions. Core systems include order management (OMS), execution management (EMS), position management, and regulatory reporting. Platform processes approximately 2.5 million trades per day during peak periods. |
| Primary Technology Owner(s) | [TEAM_MEMBER_1] - Head of Trading Technology |
| Primary Contact (Name / Role / Email) | [TEAM_MEMBER_2] / Lead Database Administrator / [TEAM_MEMBER_2]@example.internal |
| Secondary / Escalation Contact | [TEAM_MEMBER_3] / Senior Platform Engineer / [TEAM_MEMBER_3]@example.internal |
| Regulatory / Audit Sensitivity (e.g. SOX, GDPR, PCI, Internal Audit) | SOX (Section 404 - Financial Reporting Controls), MiFID II (Trade Reporting), Internal Audit (Quarterly), FCA Regulatory Reporting. All production databases are in-scope for annual SOX attestation. |

h2. B. Environment Landscape

|| Environment || Exists (Yes/No) || Hosting (On-Prem / Cloud) || Network Isolated (Yes/No/Partial) || Notes ||
| Production | Yes | Hybrid (On-Prem primary, Azure DR) | Yes | Primary on-prem DC in [DATACENTER_1], secondary failover in Azure UK South. Strict network segmentation with dedicated VLANs for trading systems. |
| Disaster Recovery | Yes | Azure | Yes | Active-passive DR in Azure UK South region. RPO: 15 minutes, RTO: 4 hours. Monthly DR testing conducted. |
| UAT | Yes | On-Prem | Partial | Shared UAT environment with controlled access. Refreshed from production quarterly (data masked). Located in [DATACENTER_2]. |
| QA | Yes | On-Prem | No | QA environment on shared infrastructure. Synthetic data only - no production data permitted. |
| Development | Yes | Azure | No | Dev environments hosted in Azure Dev/Test subscription. Developers have self-service provisioning within guardrails. |
| Other | Yes | On-Prem | Partial | Performance Testing environment (on-prem) - used for capacity planning and regression testing. Isolated network segment. Also legacy staging environment pending decommission (EOL Q2 2026). |

h2. C. Hosting Platforms

|| Platform || In Use (Yes/No) || Scope / Notes ||
| On-Prem | Yes | Primary production workloads in [DATACENTER_1] (Tier 1 data center). Core trading databases, OMS, EMS systems. Approximately 65% of total database estate. Legacy Sybase systems exclusively on-prem. |
| AWS | No | Not currently in use. Evaluated in 2024 but Azure selected as strategic cloud partner. |
| Azure | Yes | DR environment (UK South), Development environments (UK South Dev/Test), and new microservices platform (Azure SQL). Approximately 35% of database estate. ExpressRoute connectivity to on-prem. |
| OCI | No | N/A |
| Other | No | N/A |

h2. D. Database Estate

|| Database Type || Versions in Use || Hosting || HA / DR / RAC || Approx. Instance Count ||
| Oracle | 19c (majority), 12c (legacy - 3 instances pending upgrade) | On-Prem (Production, UAT), Azure (DR) | Yes - Oracle Data Guard for Production. RAC not in use. DR via Azure Site Recovery + Data Guard. | 18 instances (12 Production, 2 DR, 2 UAT, 2 QA) |
| MSSQL | SQL Server 2019 (Production), SQL Server 2022 (new deployments), SQL Server 2016 (2 legacy systems EOL Q3 2026) | Hybrid - On-Prem (Production), Azure SQL MI (DR and new workloads) | Yes - Always On Availability Groups for Production. Azure SQL MI with geo-replication for cloud workloads. | 24 instances (14 Production, 4 DR, 3 UAT, 3 Dev/QA) |
| Sybase | ASE 16.0 SP04 (majority), ASE 15.7 (2 legacy instances - upgrade planned) | On-Prem only | Partial - Sybase Replication Server for critical systems only (4 of 12 instances). No formal DR for non-critical Sybase. | 12 instances (8 Production, 2 UAT, 2 Dev) |
| PostgreSQL | PostgreSQL 14, PostgreSQL 15 | Azure (Azure Database for PostgreSQL - Flexible Server) | Yes - Zone-redundant HA with read replicas | 6 instances (2 Production, 2 DR, 1 UAT, 1 Dev) |
| MySQL | Not in use | N/A | N/A | 0 |
| DB2 / Mainframe | Not in use | N/A | N/A | 0 |
| Cloud-Native (Aurora, Redshift, etc.) | Not in use | N/A | N/A | 0 |

{note}
Total Database Instance Count: 60 instances across all environments
Production Instance Count: 36 instances
{note}

h2. E. Inventory & CMDB

|| Question || Response ||
| Primary source of truth for database inventory | Internal SharePoint database register maintained by DBA team. Updated manually upon provisioning/decommissioning. Secondary reference in ServiceNow CMDB but known to have gaps. |
| Is CMDB used as a source of truth? (Yes / Partial / No) | Partial - CMDB (ServiceNow) contains server-level CIs but database-level CIs are inconsistently maintained. Discovery tool runs weekly but does not capture all Sybase instances due to network segmentation. |
| Known duplicate, stale, or incorrect CI records | Yes - Approximately 8-10 stale records identified in Q4 2025 audit. 3 duplicate Oracle instance records. 2 Sybase instances not reflected in CMDB at all (isolated network segment). Cleanup activity planned for Q1 2026. |
| Inventory reconciliation process in place | Partial - Quarterly manual reconciliation between DBA SharePoint register and CMDB. Last reconciliation: 2025-12-01. Automated reconciliation tooling under evaluation. |

Additional comments:
The DBA team maintains a detailed spreadsheet ([SHAREPOINT_URL]/DatabaseInventory.xlsx) which is considered the most accurate source. This includes instance names, versions, environment tags, business criticality ratings, and maintenance windows. We are working with the CMDB team to improve discovery and establish automated sync, but this is dependent on network access changes for the discovery tool. Sybase instances are particularly challenging due to legacy network configurations.

h2. F. Access & Connectivity

|| Area || Response ||
| Service / non-human accounts used | Yes - Dedicated service accounts per database platform: svc_oracle_scan@example.internal (Oracle), svc_mssql_scan@example.internal (MSSQL), svc_sybase_scan (local Sybase account). Accounts managed via USM (Unified Secrets Management). Password rotation: 90 days. |
| Individual user accounts used | Yes - DBA team members have individual named accounts for administrative access. Compliance scanning should NOT use individual accounts. |
| Jump server required | Yes - All database access from corporate network requires jump server. Production: [JUMPSERVER_1] (primary), [JUMPSERVER_2] (secondary). Non-production: [JUMPSERVER_3]. SSH access only - no direct RDP to database servers. |
| Direct DB connectivity permitted | Restricted - Direct connectivity permitted only from approved management hosts and jump servers. Source IP whitelisting enforced at firewall level. Database ports blocked from general corporate network. |
| Firewall rules pre-approved | No - Firewall changes require CAB approval (weekly CAB meeting Thursdays). Standard lead time: 5-7 business days. Emergency changes possible via expedited process (24-48 hours). Existing rules permit connectivity from [JUMPSERVER_1] and [JUMPSERVER_2] to all production database servers. |

h2. G. Security & Compliance Scanning

|| Area || Response ||
| Database security scanning currently performed | Yes - Partial coverage. Manual process using legacy bash scripts on [INSPEC_HOST]. Oracle and MSSQL production instances scanned. Sybase scanning inconsistent due to tooling limitations. |
| Tooling used (e.g. InSpec, custom scripts, vendor tool) | Current: Custom bash scripts (legacy, maintained by [TEAM_MEMBER_4] - now departed), some InSpec profiles for Oracle. Planned: Standardized InSpec controls via AAP2. |
| Scan frequency | Production: Quarterly (SOX requirement). Non-production: Annually or on-demand. Regulatory expectation is monthly scanning - currently not achievable with manual process. |
| Environments covered | Production only (36 instances). Non-production environments not currently scanned. |
| CIS benchmarks used | Custom - Based on CIS benchmarks but customized for internal security policy. Oracle: CIS Oracle 19c Benchmark v1.1.0 (modified). MSSQL: CIS SQL Server 2019 Benchmark v1.3.0 (modified). Sybase: Internal baseline (no CIS benchmark available). |
| Central reporting (SIEM, Splunk, etc.) | Partial - Scan results currently stored as JSON files on [INSPEC_HOST]. Manual upload to Compliance SharePoint. No automated SIEM integration. Splunk integration planned as part of modernization initiative. |

h2. H. Constraints, Risks & Dependencies

Known technical constraints:
- Sybase connectivity requires specific client libraries (Open Client 16.0) only available on legacy RHEL 7 hosts
- Oracle scanning requires Oracle Instant Client - version compatibility issues with some 12c instances
- MSSQL Windows Authentication not feasible from Linux delegate hosts - SQL Authentication required
- Network segmentation prevents direct connectivity from AAP2 controller to database servers - delegate host pattern mandatory
- Legacy bash scripts have hardcoded paths and credentials - refactoring required before AAP2 migration
- Performance Testing environment has restricted access windows (weekends only) due to load testing schedules
- Azure SQL MI instances require different connectivity approach (Azure AD authentication under evaluation)

Organisational or process constraints:
- CAB approval required for any firewall rule changes (5-7 day lead time)
- Service account provisioning requires approval from Information Security team (10-15 day lead time for new accounts)
- Change freeze periods: Month-end (last 3 business days), Quarter-end (last 5 business days), Year-end (Dec 15 - Jan 5)
- SOX audit period (Jan-Mar) - no major changes to compliance tooling permitted
- DBA team capacity limited - 2 FTE supporting 60 instances across 3 database platforms
- Production access requires break-glass approval outside maintenance windows

Dependencies on other teams (IAM, Network, Cloud, Mainframe):
- IAM Team: Service account provisioning, password rotation policy exceptions
- Network Team: Firewall rule changes, jump server access provisioning
- Cloud Platform Team: Azure connectivity, ExpressRoute configuration, Azure AD integration
- Information Security: Scanning account permissions approval, compliance profile review
- Unix Platform Team: Delegate host provisioning ([DELEGATE_HOST]), InSpec binary deployment
- Windows Platform Team: MSSQL Windows server patching coordination
- Change Management: CAB approvals, emergency change process

h2. I. Readiness & Engagement

|| Area || Response ||
| Willing to engage in pilot activity | Yes - Strong interest in automating compliance scanning. Current manual process is unsustainable and creates audit risk. DBA team supportive of POC. |
| Key blockers to engagement | 1. Service account permissions - current scanning accounts may not have sufficient privileges for all InSpec controls. Review with InfoSec required. 2. Delegate host not yet provisioned - dependency on Unix Platform Team (ticket INFRA-4521 raised). 3. Sybase client library availability on RHEL 8 - testing required. 4. Q1 2026 SOX audit period - limited availability Jan-Mar. |
| Preferred engagement timeframe | POC: Q1 2026 (post-SOX audit completion, target April 2026). MVP: Q2 2026. Full rollout: Q3 2026. Suggest starting with MSSQL (largest estate, most mature tooling) then Oracle, then Sybase. |

----

h2. Additional Information (Optional)

h3. Key Contacts by Database Platform

|| Platform || Primary DBA || Secondary DBA ||
| Oracle | [TEAM_MEMBER_5] | [TEAM_MEMBER_6] |
| MSSQL | [TEAM_MEMBER_2] | [TEAM_MEMBER_7] |
| Sybase | [TEAM_MEMBER_8] | [TEAM_MEMBER_2] (backup) |

h3. Critical Systems (Tier 1)

The following systems are classified as Tier 1 (business critical) and have additional change control requirements:

|| System || Database Platform || Instance Name || Business Criticality ||
| Order Management System (OMS) | Oracle 19c | [DB_SERVER_OMS_1], [DB_SERVER_OMS_2] | Tier 1 - Trading cannot operate without this system |
| Execution Management System (EMS) | MSSQL 2019 | [DB_SERVER_EMS_1], [DB_SERVER_EMS_2] | Tier 1 - Required for trade execution |
| Position Management | Sybase ASE 16.0 | [DB_SERVER_POS_1] | Tier 1 - EOD position calculations |
| Regulatory Reporting | Oracle 19c | [DB_SERVER_REG_1] | Tier 1 - MiFID II reporting obligations |

h3. Maintenance Windows

|| Environment || Day || Time (UTC) || Duration ||
| Production (Tier 1) | Sunday | 02:00 - 06:00 | 4 hours |
| Production (Tier 2/3) | Saturday | 22:00 - 06:00 | 8 hours |
| UAT | Thursday | 18:00 - 22:00 | 4 hours |
| QA/Dev | No restrictions | N/A | N/A |

h3. Pending Infrastructure Changes

|| Change || Target Date || Impact on Compliance Scanning ||
| Oracle 12c to 19c upgrade (3 instances) | Q2 2026 | InSpec profiles must support both versions during transition |
| MSSQL 2016 EOL decommission | Q3 2026 | 2 instances to be migrated to Azure SQL MI |
| Sybase ASE 15.7 to 16.0 upgrade | Q2 2026 | Scanning connectivity unchanged |
| Delegate host provisioning ([DELEGATE_HOST]) | Q1 2026 | Prerequisite for AAP2 scanning |
| Azure ExpressRoute bandwidth upgrade | Q1 2026 | Improved DR scanning performance |

----

End of Questionnaire

{panel:title=Next Steps|borderStyle=solid|borderColor=#ccc|titleBGColor=#f0f0f0}
1. Schedule discovery review meeting with DBA team and Project Lead
2. Validate service account permissions against InSpec control requirements
3. Track delegate host provisioning (INFRA-4521)
4. Confirm Sybase client library availability on RHEL 8
5. Plan POC scope and timeline (target: April 2026)
{panel}

{panel:title=Document Control|borderStyle=solid|borderColor=#ccc|titleBGColor=#e0e0e0}
|| Version || Date || Author || Changes ||
| 1.0 | 2026-01-15 | [TEAM_MEMBER_1] | Initial completion |
| 1.1 | 2026-01-20 | [TEAM_MEMBER_2] | Added maintenance windows and critical systems detail |
{panel}
