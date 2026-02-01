# Database Compliance Scanning Framework
## Workshop Presentation Outline

**Duration:** 2-3 hours
**Audience:** DevOps Engineers, Platform Engineers, Security Teams
**Date:** 2026-01-30

---

# Slide Deck Outline

This document provides a slide-by-slide outline that can be converted to PowerPoint, Google Slides, or any presentation format.

---

## SECTION 1: Introduction (5 slides)

---

### Slide 1: Title Slide

**Database Compliance Scanning Framework**

Automating NIST Compliance Across Enterprise Databases

- Workshop Facilitated by: Platform Engineering Team
- Technologies: Ansible AAP2 | InSpec | GitHub

---

### Slide 2: Agenda

**Workshop Agenda**

1. Architecture & Design Patterns (20 min)
2. Multi-Platform Database Support (25 min)
3. Password Management & Security (15 min)
4. AAP2 Integration (20 min)
5. GitHub Workflow (10 min)
6. Hands-On Exercises (45 min)
7. Q&A (15 min)

---

### Slide 3: The Challenge

**Enterprise Database Compliance: Current State**

Manual Process Challenges:
- 100+ MSSQL databases
- 100+ Sybase databases
- Oracle databases (expanding)
- Manual scans take weeks
- Inconsistent execution
- Audit trail gaps

**Goal:** 90% reduction in manual effort

---

### Slide 4: The Solution

**Automated Compliance Framework**

```
+-------------+     +---------------+     +----------------+
|             |     |               |     |                |
|   AAP2      | --> |  Delegate     | --> |  Databases     |
|   Controller|     |  Host         |     |  (MSSQL/Oracle/|
|             |     |  + InSpec     |     |   Sybase)      |
+-------------+     +---------------+     +----------------+
```

Key Components:
- Ansible Automation Platform 2 (AAP2)
- InSpec compliance controls
- Delegate host pattern
- JSON results output

---

### Slide 5: Success Metrics

**What Success Looks Like**

| Metric | Before | After |
|--------|--------|-------|
| Manual Effort | Weeks | Hours |
| Time to Report | Days | < 1 hour |
| Scan Frequency | Quarterly | Monthly |
| Database Coverage | ~60% | 100% |
| Audit Readiness | Manual | Automated |

---

## SECTION 2: Architecture (6 slides)

---

### Slide 6: Why Delegate Host Pattern?

**Enterprise Network Reality**

Challenges:
- Databases in isolated network zones
- No direct connectivity from AAP2
- Firewall changes require months of approval
- Existing bastion/jump server infrastructure

Solution: **Delegate Host Pattern**
- Use existing approved access paths
- No new firewall rules required
- Leverage bastion host capabilities

---

### Slide 7: Architecture Diagram

**Delegate Host Architecture**

```
    +------------------+
    |                  |
    |   AAP2           |
    |   Controller     |
    |                  |
    +--------+---------+
             |
             | SSH (Existing Access)
             |
             v
    +--------+---------+
    |                  |
    |  Delegate Host   |
    |  +-----------+   |
    |  | InSpec    |   |
    |  | sqlcmd    |   |
    |  | sqlplus   |   |
    |  | isql      |   |
    |  +-----------+   |
    +--------+---------+
             |
    +--------+--------+--------+
    |        |        |        |
    v        v        v        v
 +-----+  +-----+  +-----+  +-----+
 |MSSQL|  |MSSQL|  |Oracle| |Sybase|
 |  01 |  |  02 |  |  01  | |  01  |
 +-----+  +-----+  +-----+  +-----+
```

---

### Slide 8: One-Line Mode Switch

**Switching Execution Modes**

Delegate Mode:
```yaml
inspec_delegate_host: "bastion01.internal"
```

Local Mode:
```yaml
inspec_delegate_host: ""
```

That's it! One variable controls the entire execution path.

---

### Slide 9: Credential Separation

**Two Credential Layers**

| Layer | Purpose | Credentials |
|-------|---------|-------------|
| SSH | Ansible to Delegate | Machine Credential |
| Database | InSpec to Database | Custom Credential |

```
AAP2 --[SSH Cred]--> Delegate --[DB Cred]--> Database
```

Never mix these credentials!

---

### Slide 10: Connection Flow

**Execution Flow**

```
1. User launches job in AAP2
         |
         v
2. AAP2 SSHs to delegate host
         |
         v
3. Ansible deploys control files
         |
         v
4. InSpec executes against database
         |
         v
5. Results collected as JSON
         |
         v
6. Summary report generated
```

---

### Slide 11: Why This Works

**Pattern Benefits**

| Challenge | How Delegate Pattern Solves It |
|-----------|-------------------------------|
| Firewall restrictions | Uses existing approved paths |
| Network segmentation | Bastion already has access |
| Infrastructure cost | Uses existing hosts |
| Audit requirements | Single execution point |
| Client tool management | Centralized on delegate |

---

## SECTION 3: Multi-Platform Support (6 slides)

---

### Slide 12: Platform Overview

**Supported Database Platforms**

| Platform | Versions | Scan Level |
|----------|----------|------------|
| MSSQL | 2008-2022 | Server (all DBs) |
| Oracle | 11g-19c | Database |
| Sybase | 15, 16 | Database |

Each platform has its own:
- Ansible role
- Connection method
- InSpec controls

---

### Slide 13: MSSQL Implementation

**MSSQL: Server-Level Scanning**

Key Characteristics:
- One scan per server
- Discovers all databases automatically
- Uses `sqlcmd` client

```yaml
mssql_databases:
  hosts:
    sqlserver01_1433:
      mssql_server: sqlserver01.internal
      mssql_port: 1433
      mssql_version: "2019"
```

Connection: `sqlcmd -S server,port -U user -P $PASSWORD`

---

### Slide 14: Oracle Implementation

**Oracle: Multiple Connection Types**

| Connection Type | When to Use |
|-----------------|-------------|
| Easy Connect | Simple environments (default) |
| TNS Names | Complex environments |
| TCPS | Encrypted connections |
| Wallet | Certificate authentication |

Challenge Solved: Remote Environment Variables
```yaml
oracle_environment:
  PATH: "{{ ORACLE_HOME }}/bin:{{ existing_path }}"
  LD_LIBRARY_PATH: "{{ ORACLE_HOME }}/lib"
  ORACLE_HOME: "/tools/ver/oracle-client"
```

---

### Slide 15: Oracle Connection Examples

**Oracle Connection Configurations**

Easy Connect:
```yaml
oracle_server: oracledb.internal
oracle_port: 1521
oracle_service: ORCLPRD
```

TNS Names:
```yaml
oracle_use_tns: true
oracle_tns_alias: ORCLPRD
oracle_tns_admin: /opt/oracle/network/admin
```

TCPS (Future):
```yaml
oracle_connection_type: tcps
oracle_tcps_port: 2484
```

---

### Slide 16: Sybase Implementation

**Sybase: SSH Transport Pattern**

Unique Requirement:
- Original scripts used SSH to Sybase host
- InSpec runs ON the Sybase host
- Then connects to local database

Three Authentication Layers:
```
1. AAP2 --> SSH --> Delegate (ansible_user)
2. Delegate --> SSH --> Sybase Host (sybase_ssh_user)
3. InSpec --> isql --> Database (sybase_username)
```

---

### Slide 17: Control File Management

**InSpec Controls Deployment**

Repository Structure:
```
roles/
  mssql_inspec/
    files/
      MSSQL2019_ruby/
        trusted.rb
        audit.rb
  oracle_inspec/
    files/
      ORACLE19c_ruby/
        trusted.rb
```

Ansible automatically:
1. Discovers version-specific controls
2. Deploys to delegate host
3. Executes against database
4. Collects results

---

## SECTION 4: Password Management (5 slides)

---

### Slide 18: Security Golden Rule

**Password Security: The Golden Rule**

Passwords are NEVER exposed in:
- Command-line arguments
- Ansible logs
- Process listings (`ps aux`)
- AAP2 job output

How? **Environment Variables**

---

### Slide 19: Secure Implementation

**Secure vs Insecure**

INSECURE (Never do this):
```yaml
shell: |
  inspec exec control.rb \
    --input passwd='{{ mssql_password }}'
```

SECURE (Always do this):
```yaml
shell: |
  inspec exec control.rb \
    --input passwd="$INSPEC_DB_PASSWORD"
environment:
  INSPEC_DB_PASSWORD: "{{ mssql_password }}"
no_log: true
```

---

### Slide 20: AAP2 Credential Injection

**Current State: AAP2 Credentials**

```
+------------------+
|                  |
|  AAP2 Vault      |  (Encrypted Storage)
|                  |
+--------+---------+
         |
         | Custom Credential Type
         v
+--------+---------+
|                  |
|  Job Template    |  (Credential Attached)
|                  |
+--------+---------+
         |
         | Injector (extra_vars)
         v
+--------+---------+
|                  |
|  Playbook        |  mssql_password available
|                  |
+------------------+
```

---

### Slide 21: Target State - CyberArk

**Target State: CyberArk CCP Integration**

Benefits:
- Automatic password rotation
- Zero exposure in AAP2
- Full audit trail
- Dual control policies

```
AAP2 Job --> CyberArk API --> Password --> InSpec
   ^                                          |
   |                                          |
   +---- Audit Log <----- Audit Log ----------+
```

---

### Slide 22: Alternative Tools

**Password Management Options**

| Tool | Best For |
|------|----------|
| AAP2 Vault | Simple deployments |
| CyberArk CCP | Enterprise banking |
| HashiCorp Vault | Multi-cloud |

All integrate with AAP2 via:
- Custom Credential Types
- Credential Plugins
- External Lookups

---

## SECTION 5: AAP2 Integration (4 slides)

---

### Slide 23: AAP2 Components

**AAP2 Configuration**

| Component | Purpose |
|-----------|---------|
| Execution Environment | Container with InSpec, DB clients |
| Credential Types | MSSQL, Oracle, Sybase definitions |
| Credentials | Actual username/password pairs |
| Job Templates | Playbook + Inventory + Credentials |
| Workflows | Multi-platform orchestration |

---

### Slide 24: Job Template Setup

**Creating a Job Template**

1. **Playbook:** `test_playbooks/run_mssql_inspec.yml`
2. **Inventory:** Database Compliance Inventory
3. **Credentials:**
   - Machine (SSH to delegate)
   - MSSQL Database (custom)
4. **Limit:** `mssql_databases`
5. **Execution Environment:** db-compliance-ee

---

### Slide 25: Workflow Orchestration

**Enterprise Workflow**

```
        START
          |
    +-----+-----+-----+
    |     |     |     |
    v     v     v     v
  MSSQL Oracle Sybase PostgreSQL
    |     |     |     |
    +-----+-----+-----+
          |
          v
    Generate Report
          |
          v
       COMPLETE
```

Parallel execution for efficiency.

---

### Slide 26: Scheduling

**Automated Compliance**

Schedule Options:
- Monthly full scans
- Weekly critical databases
- On-demand for remediation validation

AAP2 Schedules:
```
Name: Monthly MSSQL Compliance
Schedule: 0 2 1 * *  (2 AM, 1st of month)
Template: MSSQL Compliance Scan
```

---

## SECTION 6: GitHub Integration (3 slides)

---

### Slide 27: Repository Structure

**Git Repository Layout**

```
linux-inspec/
+-- roles/
|   +-- mssql_inspec/
|   +-- oracle_inspec/
|   +-- sybase_inspec/
+-- test_playbooks/
+-- inventory_converter/
+-- docs/
+-- .gitignore
```

AAP2 Project syncs from GitHub automatically.

---

### Slide 28: What Never Goes in Git

**Security Exclusions**

NEVER commit:
- Real server names
- IP addresses
- Credentials (even encrypted)
- Production inventory files
- Terraform state files

.gitignore:
```
*vault*.yml
*inventory*.yml
*.tfstate
credentials/
```

---

### Slide 29: Branching Strategy

**Git Workflow**

```
main (production)
  |
  +-- develop (integration)
        |
        +-- feat/new-oracle-control
        +-- feat/tcps-support
        +-- fix/sybase-timeout
```

All changes via Pull Request with:
- Code review
- Testing in sandbox
- Documentation update

---

## SECTION 7: Hands-On Exercises (3 slides)

---

### Slide 30: Exercise 1

**Exercise 1: Configure Delegate Mode**

Steps:
1. Edit inventory file
2. Add: `inspec_delegate_host: "delegate01"`
3. Run playbook
4. Verify execution on delegate

Validation:
```bash
ssh delegate01 "ps aux | grep inspec"
```

Time: 15 minutes

---

### Slide 31: Exercise 2

**Exercise 2: Add New Oracle Database**

Steps:
1. Add host to `oracle_databases` group
2. Configure TNS variables
3. Test connectivity
4. Run compliance scan

New Host:
```yaml
new_oracle_db:
  oracle_server: newdb.internal
  oracle_use_tns: true
  oracle_tns_alias: NEWDB
```

Time: 20 minutes

---

### Slide 32: Exercise 3

**Exercise 3: Create AAP2 Job Template**

Steps:
1. Create Custom Credential Type
2. Create Credential Instance
3. Create Job Template
4. Attach both credentials
5. Execute and review results

Time: 25 minutes

---

## SECTION 8: Summary (3 slides)

---

### Slide 33: Key Takeaways

**What We Covered**

1. **Delegate Pattern** - Bypass firewall restrictions
2. **Multi-Platform** - MSSQL, Oracle, Sybase
3. **Secure Passwords** - Environment variables only
4. **AAP2 Integration** - Enterprise automation
5. **Git Workflow** - Version-controlled compliance

---

### Slide 34: Architecture Decision Summary

**Why We Made These Choices**

| Decision | Rationale |
|----------|-----------|
| Delegate Host | No new firewall rules |
| Environment Variables | Password protection |
| Platform-Specific Roles | Clean separation |
| InSpec | Industry standard |
| AAP2 | Enterprise RBAC/audit |

---

### Slide 35: Next Steps

**Your Action Items**

1. Deploy to test environment
2. Onboard service accounts
3. Configure AAP2 templates
4. Pilot on non-production
5. Scale to production

Questions?

Contact: Platform Engineering Team

---

## APPENDIX: Speaker Notes

---

### Notes for Slide 6 (Why Delegate Host?)

- Emphasize that this pattern was driven by real enterprise constraints
- Mention typical firewall approval timelines (3-6 months)
- Highlight that we're using existing infrastructure investment

### Notes for Slide 18 (Security Golden Rule)

- Ask audience: "Has anyone ever seen a password in `ps aux`?"
- Demonstrate live if possible (safely)
- Stress that `no_log: true` must ALWAYS be set, never conditional

### Notes for Slide 20 (AAP2 Credential Injection)

- Walk through the Custom Credential Type JSON
- Show how injectors work
- Demonstrate in AAP2 UI if available

### Notes for Slides 30-32 (Exercises)

- Have pre-configured sandbox environments ready
- Ensure network connectivity is tested before workshop
- Have fallback demo if connectivity issues arise

---

## Presentation Tips

1. **Diagrams**: Use ASCII art for compatibility, or convert to visual diagrams
2. **Code Blocks**: Ensure syntax highlighting in presentation tool
3. **Timing**: Leave buffer for questions during hands-on sections
4. **Backup**: Have screenshots of successful runs ready
5. **Audience Engagement**: Ask questions about their current processes

---

## Conversion Instructions

### For PowerPoint:
1. Each `### Slide N:` becomes a new slide
2. Use bullet points from the content
3. Code blocks go in monospace font boxes
4. Tables can be inserted as PowerPoint tables
5. ASCII diagrams can be replaced with SmartArt

### For Google Slides:
1. Same structure as PowerPoint
2. Use "Courier New" for code
3. Consider using draw.io for architecture diagrams

### For reveal.js (HTML):
1. Each slide becomes a `<section>`
2. Use `<pre><code>` for code blocks
3. Supports Markdown natively

---

**End of Presentation Outline**
