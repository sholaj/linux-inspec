---
marp: true
theme: gaia
paginate: true
backgroundColor: #fff
style: |
  section {
    font-size: 24px;
    padding: 40px;
  }
  h1 {
    font-size: 48px;
    color: #0056b3;
  }
  h2 {
    font-size: 36px;
    color: #444;
  }
  h3 {
    font-size: 30px;
    color: #666;
  }
  table {
    font-size: 20px;
    width: 100%;
  }
  th {
    background-color: #f0f0f0;
  }
  pre {
    background: #f4f4f4;
    border: 1px solid #ddd;
    border-radius: 4px;
    padding: 10px;
  }
  /* Specific class for ASCII art to ensure it fits */
  .ascii-art {
    font-family: 'Courier New', monospace;
    font-size: 14px;
    line-height: 1.1;
    white-space: pre;
    overflow-x: auto;
    background: #fafafa;
    padding: 10px;
    border: 1px solid #eee;
  }
---

<!-- _class: lead -->
# Database Compliance Scanning
## Presentation Slides

**Format:** Demonstration + Discussion | **Time:** 11:15 | **Presenter:** Shola

---

## Slide Deck Overview

This presentation supports a **demo + discussion** format:

1. **Demo** (15 min) — Show the capability
2. **Pain Points** (15 min) — The four blockers
3. **Discussion** (15 min) — Capabilities, challenges, gaps
4. **Next Steps** (5 min) — What we need from you

---

<!-- _class: lead -->
## SECTION 1: Introduction (2 slides)

---

### Slide 1: Title

# Database Compliance Scanning

From POC to Production: What's Working, What's Blocking Us

*Demonstration + Group Discussion*

---

### Slide 2: What We'll Cover

**Agenda**

| Time | Topic |
|------|-------|
| 11:15 | **Demo** — Live compliance scan |
| 11:30 | **Pain Points** — The four blockers |
| 11:45 | **Discussion** — What we need from you |
| 12:00 | **Next Steps** — Action items |

**Goal:** Shared understanding of where we are and what's needed to move forward

---

<!-- _class: lead -->
## SECTION 2: The Demo (3 slides)

---

### Slide 3: What You'll See

**The Capability Exists**

1. Inventory-driven scanning (databases defined in YAML)
2. Multi-platform support (MSSQL, Oracle, Sybase)
3. Delegate host pattern (no new firewall rules)
4. Standardized JSON output

*Live demo follows...*

---

### Slide 4: Demo Steps

**Live Demonstration**

```
1. Show inventory file
2. Launch scan
3. Watch execution on delegate host
4. Review JSON results
5. Show compliance summary
```

---

### Slide 5: Key Takeaway

**The Technical Capability Exists**

<div class="ascii-art">
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│   The challenge is not building it.                           │
│   The challenge is operationalizing it across affiliates.     │
│                                                                │
└────────────────────────────────────────────────────────────────┘
</div>

Let's talk about what's blocking us...

---

<!-- _class: lead -->
## SECTION 3: The Four Pain Points (8 slides)

---

### Slide 6: Pain Point Overview

**What's Blocking Enterprise Rollout?**

<div class="ascii-art">
    ┌─────────────────┐
    │  1. Discovery   │  "We can't scan databases we don't know about"
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │  2. Passwords   │  "Different affiliates, different tools"
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │  3. Network     │  "Every affiliate has different architecture"
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │  4. RBAC        │  "Connection methods vary everywhere"
    └─────────────────┘
</div>

---

### Slide 7: Pain Point 1 — Discovery

**We Can't Scan Databases We Don't Know About**

| What We Need | What We Get |
|--------------|-------------|
| Server, port, version | Outdated spreadsheets |
| Service account | "We'll get back to you" |
| Network path | "Check with infrastructure" |
| Contact person | Rotating team members |

**Why it's hard:**
- No single source of truth (SNOW, Server Guru, local CMDBs)
- Affiliate autonomy — each BU manages inventory differently
- Data staleness — databases added/removed without notification

---

### Slide 8: Pain Point 2 — Password Management

**Different Affiliates Use Different Tools**

| Affiliate | Tool | Integration |
|-----------|------|-------------|
| BU-1 | CyberArk | API lookup (CCP) |
| BU-2 | Cloakware | File-based retrieval |
| BU-3 | USM | Manual rotation tracking |
| Others | AAP2 Vault | Direct injection |

**Why it's hard:**
- No single integration for all affiliates
- Rotation schedules vary (weekly to quarterly)
- Ownership unclear (who provisions? who rotates?)

---

### Slide 9: Pain Point 3 — Network Connectivity

**Every Affiliate Has Different Network Architecture**

<div class="ascii-art">
                    AAP2 Controller
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │  BU-1    │    │  BU-2    │    │  BU-3    │
    │ Jump Box │    │ Jump Box │    │ Jump Box │
    │ (Linux)  │    │ (Windows)│    │ (???)    │
    └────┬─────┘    └────┬─────┘    └────┬─────┘
         │               │               │
    ┌────┴────┐     ┌────┴────┐     ┌────┴────┐
    │ DBs     │     │ DBs     │     │ DBs     │
    │(reachable)    │(partial)│     │(unknown)│
    └─────────┘     └─────────┘     └─────────┘
</div>

**Why it's hard:**
- Different delegate hosts per affiliate
- SSH vs WinRM (Linux vs Windows)
- Firewall rules vary — some paths exist, others need requests

---

### Slide 10: Pain Point 4 — RBAC & Connection Posture

**Connection Methods Vary by Platform, Environment, and Policy**

| Platform | Options | Complexity |
|----------|---------|------------|
| **MSSQL** | SQL Auth, Windows Auth, WinRM | Domain trust for Windows Auth |
| **Oracle** | Easy Connect, TNS, TCPS, Wallet | TNS needs tnsnames.ora; TCPS needs certs |
| **Sybase** | Direct isql, SSH tunnel | Three authentication layers |

**Example:**
```
BU-1: sqlcmd -S server,1433 -U scanuser -P $PASSWORD
BU-2: WinRM to Windows host, then trusted connection (Kerberos)
BU-3: sqlplus user/pass@//server:1521/service
BU-4: TNS alias via tnsnames.ora (requires TNS_ADMIN)
```

---

### Slide 11: The Real Problem

**This Is Not a Technical Problem**

<div class="ascii-art">
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│   The framework works.                                         │
│   We've proven it in POC.                                     │
│                                                                │
│   The blockers are:                                           │
│   - Getting accurate information from affiliates              │
│   - Coordinating access and credentials                       │
│   - Navigating different tools and policies per BU            │
│                                                                │
│   This is a COORDINATION problem, not a coding problem.       │
│                                                                │
└────────────────────────────────────────────────────────────────┘
</div>

---

### Slide 12: Where We Are

**Project Phases**

<div class="ascii-art">
  Discovery ──▶ POC ──▶ Onboarding ──▶ MVP ──▶ Rollout
      ✓           ✓          ●           ○         ○
                             ▲
                             │
                       WE ARE HERE
                      (Most Problematic)
</div>

| Phase | Status |
|-------|--------|
| Discovery | ✓ Requirements gathered |
| POC | ✓ Pattern proven (Windows & Linux) |
| **Onboarding** | ● **Current — Blocked on access & credentials** |
| MVP | ○ Pending onboarding |
| Rollout | ○ Future |

---

### Slide 13: Why Onboarding Is the Bottleneck

**What's Needed vs What We Have**

| Requirement | Status |
|-------------|--------|
| SSH access to delegate hosts | Partial |
| Service account ownership | Unclear |
| Credential retrieval method | Varies by affiliate |
| Compliance profile mapping | TBD |
| Security policy exceptions | TBD |

**We can't move to MVP until onboarding completes for at least one affiliate.**

---

<!-- _class: lead -->
## SECTION 4: Discussion (3 slides)

---

### Slide 14: Discussion Questions — Discovery

**Getting Database Information**

1. What's the best source of database inventory for your affiliate?
   - SNOW? Server Guru? Local CMDB? Manual list?

2. How do we stay current when databases are added/removed?

3. Who should we contact for database information?

---

### Slide 15: Discussion Questions — Credentials & Network

**Passwords and Connectivity**

**Password Management:**
1. Which credential tool does your affiliate use? (CyberArk, Cloakware, USM, other)
2. Who owns the service accounts for scanning?
3. What happens when passwords rotate?

**Network:**
1. Do you have a designated "scanning host" / jump server?
2. What firewall/access requests would be needed?
3. SSH or WinRM to reach your environment?

---

### Slide 16: Discussion Questions — Connection Posture

**RBAC and Authentication**

1. SQL Auth vs Windows Auth — what does your environment use?

2. Easy Connect vs TNS — which does Oracle require?

3. Are there encryption requirements (TCPS, etc.)?

4. What permissions does the scan service account need?

---

<!-- _class: lead -->
## SECTION 5: What We Need (3 slides)

---

### Slide 17: What We Need From Each Affiliate

**To Move Forward**

| Item | Who Provides |
|------|-------------|
| Database inventory (server, port, version, platform) | DBA Team |
| Delegate host (Linux/Windows we can scan from) | Infrastructure |
| Service account with scan permissions | DBA + Security |
| Credential tool access (how we get passwords) | Security Team |
| Connection details (auth method, ports, TNS/Easy Connect) | DBA Team |
| Point of contact (who to call when scans fail) | Operations |

---

### Slide 18: What We Need From Security/Compliance

**Standards and Exceptions**

| Item | Why We Need It |
|------|---------------|
| Minimum scan permissions | What DB privileges does the scan account need? |
| Compliance profile mapping | Which NIST controls apply to which database tiers? |
| Exception handling | Process when databases can't be scanned |

---

### Slide 19: Next Steps

**Action Items**

| Action | Owner | Timeline |
|--------|-------|----------|
| Share discovery questionnaire | Workshop facilitator | This week |
| Identify delegate hosts | Infrastructure leads | 2 weeks |
| Provision service accounts | DBA teams | 2 weeks |
| Document credential retrieval | Security teams | 2 weeks |

**MVP Success Criteria:**
- At least one affiliate fully onboarded
- Working scan against real (non-prod) databases
- Credential retrieval working (not manual)
- Results flowing to compliance reporting

---

### Slide 20: Questions?

**Let's Discuss**

- What did you see in the demo that would work for your environment?
- What challenges do you anticipate for your affiliate?
- What's the first step we can take together?

---

<!-- _class: lead -->
## APPENDIX: Speaker Notes

---

### Notes for Slide 5 (Key Takeaway)

**Pause here.**

Emphasize: "We've built the technical solution. The demo you just saw works. But technology alone doesn't solve this problem."

This sets up the pivot to discussing coordination challenges.

---

### Notes for Slides 7-10 (Pain Points)

**Invite examples:**
- "Has anyone experienced this in your affiliate?"
- "What tools do you use for X?"

The goal is to surface affiliate-specific information, not lecture.

---

### Notes for Slide 11 (The Real Problem)

**This is the key slide.**

Make it clear: We're not asking for help building the technical solution. We're asking for help with the operational coordination needed to deploy it.

---

### Notes for Slides 14-16 (Discussion)

**Facilitate, don't lecture.**

Capture answers on whiteboard or shared doc. This is the information we need to move forward.

Expected time: 15 minutes. Don't rush through — this is where we get the information we need.

---

### Notes for Slide 19 (Next Steps)

**Make the asks concrete.**

If specific people are in the room, assign actions directly:
- "John, can your team identify the delegate host by next Friday?"
- "Sarah, who on your side owns service accounts?"

---

## Conversion Instructions

**For PowerPoint/Google Slides:**
- Each `### Slide N:` = one slide
- Tables → native table format
- ASCII diagrams → SmartArt or screenshots
- Code blocks → monospace text boxes

**For the demo:**
- Have the scan ready to run before the meeting
- Test connectivity the day before
- Have backup screenshots if live demo fails

---

**End of Presentation**
