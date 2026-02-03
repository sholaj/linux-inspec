# Database Compliance Scanning Workshop

**Format:** Demonstration + Group Discussion | **Duration:** 45-60 minutes | **Presenter:** Shola

---

## Workshop Purpose

This session demonstrates our database compliance scanning capability and facilitates discussion on:

- **Current capabilities** — What we can do today
- **Challenges** — The pain points blocking enterprise rollout
- **Gaps** — What we need from affiliates and stakeholders

*This is not a hands-on lab. The goal is shared understanding and action planning.*

---

## Agenda

| Time | Section | Focus |
|------|---------|-------|
| 11:15 | Demo | Live database compliance scan |
| 11:30 | Challenges | The four pain points |
| 11:45 | Discussion | Capabilities, challenges, gaps |
| 12:00 | Next Steps | What we need to move forward |

---

# Part 1: The Demo (15 minutes)

*Show, don't tell. Run a live compliance scan.*

## What You'll See

1. **Inventory-driven scanning** — Databases defined in YAML, not hardcoded
2. **Multi-platform support** — MSSQL, Oracle, Sybase from one framework
3. **Delegate host pattern** — Scans run through existing jump servers (no new firewall rules)
4. **Standardized output** — JSON results compatible with compliance reporting

## Demo Script

```
1. Show inventory file (database definitions)
2. Launch scan from AAP2 / command line
3. Observe execution on delegate host
4. Review JSON output format
5. Show compliance summary
```

**Key message:** *The technical capability exists. The challenge is operationalizing it across affiliates.*

---

# Part 2: The Pain Points (15 minutes)

*These are the real blockers. Each one needs discussion.*

---

## Pain Point 1: Discovery

### The Challenge

**We can't scan databases we don't know about.**

Getting accurate database inventory from affiliates is difficult:

| What We Need | What We Get |
|--------------|-------------|
| Server hostname, port, version | Outdated spreadsheets |
| Service account with scan permissions | "We'll get back to you" |
| Network path from delegate host | "Check with infrastructure" |
| Contact for access issues | Rotating team members |

### Why This Is Hard

- **No single source of truth** — SNOW, Server Guru, local CMDBs all have partial data
- **Affiliate autonomy** — Each business unit manages their own inventory differently
- **Data staleness** — Databases get provisioned/decommissioned without central notification
- **Sensitivity** — Teams hesitant to share full database lists

### Questions for Discussion

> - Can we create an ansible playbook to gather database inventory from SNOW? 
> - Who owns the "source of truth" for database assets?
> - Can we tie into existing discovery mechanisms?

---

## Pain Point 2: Password Management

### The Challenge

**Different affiliates use different credential management tools.**

| Affiliate | Password Tool | Integration Method |
|-----------|--------------|-------------------|
| IMS West | CyberArk | API lookup (CCP) |
| CORP | Cloakware | File-based retrieval |
| IMS West | USM (User System Manager) | Manual rotation tracking |
| Others | AAP2 Vault | Direct injection |

### Why This Is Hard

- **No single integration** — We can't build one connector for all affiliates
- **Rotation schedules vary** — Some rotate weekly, others quarterly
- **Ownership unclear** — Who provisions the service account? Who rotates it?
- **Testing complexity** — Need test credentials for each tool in each environment

### Current Approach

```
┌─────────────────────────────────────────────────────────────────┐
│  Current: Password injected via AAP2 custom credential type    │
│           Works if someone manually updates AAP2 when password │
│           rotates. Doesn't scale.                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Target: Dynamic lookup at scan time                           │
│          → CyberArk CCP for affiliates using CyberArk          │
│          → Cloakware integration for those affiliates          │
│          → Fallback to AAP2 vault for others                   │
└─────────────────────────────────────────────────────────────────┘
```

### Questions for Discussion

> - Can we standardize on one tool, or must we support all?
> - We need multiple APMD accounts for each affiliate?
> - What's the process when a scan fails due to password rotation?

---

## Pain Point 3: Network Connectivity

### The Challenge

**Every affiliate has different network architecture.**

```
                    AAP2 Controller
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │  BU-1    │    │  BU-2    │    │  BU-3    │
    │ Jump Box │    │ Jump Box │    │ Jump Box │
    │ (Linux)  │    │ (Linux)  │    │ (Linux)  │
    └────┬─────┘    └────┬─────┘    └────┬─────┘
         │               │               │
    ┌────┴────┐     ┌────┴────┐     ┌────┴────┐
    │ DBs     │     │ DBs     │     │ DBs     │
    │(reachable)    │(partial)│     │(unknown)│
    └─────────┘     └─────────┘     └─────────┘
```

### Why This Is Hard

- **Different delegate hosts per affiliate** — No single jump server reaches all databases
- **Firewall rules vary** — Some paths exist, others need requests
- **SSH vs WinRM** — Linux jump servers require different playbook handling
- **Validation is manual** — No automated way to test "can we reach this database?"

### What We Need

| For Each Affiliate | Status Today |
|--------------------|--------------|
| Designated delegate host | Some known, some TBD |
| SSH/WinRM access from AAP2 | Partial |
| Database ports open from delegate | Unknown until we test |
| Client tools installed on delegate | Varies |

### Questions for Discussion

> - Can we get a network diagram per affiliate showing scan path?
> - Who do we engage for firewall rule requests?
> - Is there a standard "scanning host" pattern we should follow?

---

## Pain Point 4: RBAC & Connection Posture

### The Challenge

**Database connection methods vary by platform, environment, and affiliate policy.**

| Platform | Connection Options | Complexity |
|----------|-------------------|------------|
| **MSSQL** | SQL Auth, Windows Auth, WinRM | Windows Auth requires domain trust |
| **Oracle** | Easy Connect, TNS, TCPS, Wallet | Some require tnsnames.ora, others certificates |
| **Sybase** | Direct isql, SSH tunnel | Legacy pattern requires SSH to DB host |

### Why This Is Hard

**Example: MSSQL Connection Variability**

```
Affiliate A (SQL Auth):
  sqlcmd -S server,1433 -U scanuser -P $PASSWORD

Affiliate B (Windows Auth + WinRM):
  - AAP2 must authenticate to Linux jump server via WinRM
  - Then use trusted connection (no password in command)
  - Requires Kerberos/domain configuration

Affiliate C (SQL Auth, non-standard port):
  sqlcmd -S server,14333 -U different_user -P $PASSWORD
```

**Example: Oracle Connection Variability**

```
Affiliate A (Easy Connect):
  sqlplus user/pass@//server:1521/service

Affiliate B (TNS Names required):
  - Must have tnsnames.ora on delegate host
  - Must set TNS_ADMIN environment variable
  - Alias must match affiliate's naming convention

Affiliate C (TCPS mandatory):
  - Encrypted connections required by policy
  - Certificate must be installed on delegate
  - Wallet configuration needed
```

### What We Need to Know Per Database

| Question | Why It Matters |
|----------|---------------|
| SQL Auth or Windows Auth? | Different playbook paths |
| Standard port or custom? | Inventory configuration |
| Easy Connect or TNS? | Environment setup on delegate |
| Encryption required? | Certificate/wallet setup |
| Service account permissions | What can the scan actually query? |

### Questions for Discussion

> - Can we get a "connection profile" documented per affiliate?
> - Who can tell us the RBAC requirements for each environment?
> - What's the minimum permission set for compliance scanning?

---

# Part 3: The Project Phases

*Where we are and what's blocking progress.*

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Discovery  │──▶│     POC     │──▶│  Onboarding │──▶│     MVP     │──▶│   Rollout   │
│             │   │             │   │             │   │             │   │             │
│ Gathering   │   │ Proving the │   │ Access &    │   │ Real env,   │   │ Enterprise  │
│ requirements│   │ pattern     │   │ credentials │   │ small scale │   │ deployment  │
│             │   │ works       │   │ setup       │   │             │   │             │
│   ┌───┐     │   │   ┌───┐     │   │   ┌───┐     │   │   ┌───┐     │   │   ┌───┐     │
│   │ ✓ │     │   │   │ ✓ │     │   │   │ ● │     │   │   │   │     │   │   │   │     │
│   └───┘     │   │   └───┘     │   │   └───┘     │   │   └───┘     │   │   └───┘     │
└─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘
                                          ▲
                                          │
                                    WE ARE HERE
                                   (Most problematic)
```

## Phase Details

| Phase | Description | Status |
|-------|-------------|--------|
| **Discovery** | Business requirements, constraints, SNOW/Server Guru data, connectivity mapping, interfaces, access requirements | ✓ Complete |
| **POC** | Simulate on own environment, prove end-to-end pattern works (Windows & Linux platforms) | ✓ Complete |
| **Onboarding** | Host access, credential ownership, identify profiles, policy configurations | ● **Current — Most Problematic** |
| **MVP** | Business Unit environment, small number of servers, real inventory, real access | Pending onboarding |
| **Rollout** | Scan deployment across whole estate, waves by Tier level, scheduled jobs via AAP2 | Future |

## Why Onboarding Is the Bottleneck

| Blocker | What's Needed |
|---------|--------------|
| Host access | SSH access to delegate hosts in each affiliate |
| Credential ownership | Who provisions and maintains scan service accounts? |
| Profile identification | Which compliance profiles apply to which databases? |
| Policy configuration | What security policies might block automation? |

**This is not a technical problem. It's a coordination problem.**

---

# Part 4: Group Discussion

*Facilitated conversation on capabilities, challenges, and gaps.*

## Discussion Questions

### On Discovery
1. What's the best source of database inventory for your affiliate?
2. How do we stay current when databases are added/removed?
3. Who should we contact for database information?

### On Password Management
1. Which credential tool does your affiliate use?
2. Who owns the service accounts for scanning?
3. What happens when passwords rotate?

### On Network Connectivity
1. Do you have a designated "scanning host" or jump server?
2. What firewall/access requests would be needed?
3. Who approves network access changes?

### On Connection Posture
1. SQL Auth vs Windows Auth — what does your environment use?
2. Are there encryption requirements (TCPS, etc.)?
3. What permissions does the scan service account have?

---

# Part 5: What We Need From You

*Clear asks to move from POC to MVP.*

## From Each Affiliate

| Item | Description | Who Provides |
|------|-------------|-------------|
| **Database inventory** | Server, port, version, platform for databases in scope | DBA Team |
| **Delegate host** | Linux/Windows host we can execute scans from | Infrastructure |
| **Service account** | Credentials with compliance scan permissions | DBA + Security |
| **Credential tool access** | How we retrieve passwords (CyberArk/Cloakware/USM) | Security Team |
| **Connection details** | SQL Auth vs Windows Auth, TNS vs Easy Connect, ports | DBA Team |
| **Point of contact** | Who to call when scans fail | Operations |

## From Security/Compliance

| Item | Description |
|------|-------------|
| Minimum scan permissions | What database privileges does the scan account need? |
| Compliance profile mapping | Which NIST controls apply to which database tiers? |
| Exception handling | Process when databases can't be scanned |

## From Infrastructure/Network

| Item | Description |
|------|-------------|
| Network paths | Can delegate host reach target databases? |
| Firewall requests | Process for requesting new access rules |
| AAP2 connectivity | SSH/WinRM access to delegate hosts |

---

# Part 6: Next Steps

## Immediate Actions

| Action | Owner | Timeline |
|--------|-------|----------|
| Share discovery questionnaire with affiliates | Workshop facilitator | Done |
| Identify delegate hosts per affiliate | Infrastructure leads | Ongoing task |
| Provision service accounts | DBA teams/APMD | Ongoing task |
| Document connection profiles | DBA teams | Ongoing task |

## Success Criteria for MVP

- [ ] At least one affiliate with complete onboarding
- [ ] Scan output sent to splunk/compliance reporting
- [ ] Automated scheduling of scans via AAP2
- [ ] Working scan against real (non-production) databases
- [ ] Credential retrieval working (not manual password entry)
- [ ] Results flowing to compliance reporting

---

# Appendix: Technical Reference

*For those who want the details after the workshop.*

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           AAP2 Controller                                │
│                                                                          │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐             │
│  │ MSSQL Job      │  │ Oracle Job     │  │ Sybase Job     │             │
│  │ Template       │  │ Template       │  │ Template       │             │
│  └───────┬────────┘  └───────┬────────┘  └───────┬────────┘             │
│          │                   │                   │                       │
└──────────┼───────────────────┼───────────────────┼───────────────────────┘
           │                   │                   │
           │ SSH               │ SSH               │ SSH
           │                   │                   │
    ┌──────▼──────┐     ┌──────▼──────┐     ┌──────▼──────┐
    │ Delegate    │     │ Delegate    │     │ Delegate    │
    │ Host (BU-1) │     │ Host (BU-2) │     │ Host (BU-3) │
    │             │     │             │     │             │
    │ ┌─────────┐ │     │ ┌─────────┐ │     │ ┌─────────┐ │
    │ │ InSpec  │ │     │ │ InSpec  │ │     │ │ InSpec  │ │
    │ │ sqlcmd  │ │     │ │ sqlplus │ │     │ │ isql    │ │
    │ └────┬────┘ │     │ └────┬────┘ │     │ └────┬────┘ │
    └──────┼──────┘     └──────┼──────┘     └──────┼──────┘
           │                   │                   │
           ▼                   ▼                   ▼
    ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
    │ MSSQL DBs   │     │ Oracle DBs  │     │ Sybase DBs  │
    └─────────────┘     └─────────────┘     └─────────────┘
```

## Inventory Example

```yaml
all:
  children:
    mssql_databases:
      hosts:
        sqlserver01_1433:
          database_platform: mssql
          mssql_server: sqlserver01.example.internal
          mssql_port: 1433
          mssql_version: "2019"
          inspec_delegate_host: delegate01.example.internal

    oracle_databases:
      hosts:
        oracledb01_orcl:
          database_platform: oracle
          oracle_server: oracledb01.example.internal
          oracle_port: 1521
          oracle_service: ORCLPRD
          oracle_version: "19"
          oracle_use_tns: false
          inspec_delegate_host: delegate01.example.internal
```

## Password Security

Passwords are **never** exposed in command lines or logs:

```yaml
- name: Execute compliance scan
  shell: |
    inspec exec control.rb --input passwd="$DB_PASSWORD"
  environment:
    DB_PASSWORD: "{{ database_password }}"
  no_log: true  # Always true, never conditional
```

---

**Questions?**

Contact: Platform Engineering Team
