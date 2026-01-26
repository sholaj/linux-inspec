# Business Unit Questionnaires - Getting Started

**Northstar Business Unit Infrastructure & Database Discovery Program**

---

## Quick Overview

This folder contains **standardized questionnaire templates and guidance materials** for conducting **first-engagement infrastructure discovery** with new Northstar Business Units.

The questionnaires are designed to:
- ✅ Capture comprehensive current-state infrastructure, database, and compliance posture
- ✅ Identify regulatory drivers and audit requirements
- ✅ Surface blockers and dependencies early (before POC planning)
- ✅ Establish realistic timelines and success criteria
- ✅ Guide business units through a structured engagement workflow

---

## What's in This Folder

### Core Templates

1. **[NORTHSTAR_BU_DISCOVERY_QUESTIONNAIRE_TEMPLATE.md](NORTHSTAR_BU_DISCOVERY_QUESTIONNAIRE_TEMPLATE.md)** ⭐ **START HERE**
   - **9 sections (A–I):** Business unit context, environment landscape, database estate, inventory/CMDB, access & connectivity, security & compliance scanning, constraints & risks, readiness & engagement, additional context
   - **Target completion time:** 45–60 minutes
   - **Format:** Markdown with inline guidance, tables, examples
   - **Customization:** Replace `[PLACEHOLDER]` fields with BU-specific info before sending to respondent

2. **[BU_QUESTIONNAIRE_INTAKE_CHECKLIST.md](BU_QUESTIONNAIRE_INTAKE_CHECKLIST.md)**
   - **Pre-discovery validation** before questionnaire distribution
   - **8 steps:** Contact identification, regulatory drivers, infrastructure assessment, blocker identification, timeline estimation, questionnaire prep, quick-win identification
   - **Use this:** Before sending questionnaire to BU (identify key contacts, unblock critical path items)

3. **[BU_RESPONSE_GUIDE.md](BU_RESPONSE_GUIDE.md)** 📖 **Attach to Questionnaire**
   - **Role-specific instructions** (for Technology Owner, DBA Lead, Security Sponsor)
   - **Per-section guidance:** What we're looking for, common pitfalls, example answers
   - **Clarification Q&As:** Common questions like "What's a database instance?" "What's network isolation?"
   - **Distribute alongside questionnaire** to help respondents complete sections accurately

4. **[BU_ENGAGEMENT_WORKFLOW.md](BU_ENGAGEMENT_WORKFLOW.md)** 📋 **Governance & Timeline**
   - **Complete lifecycle:** Discovery → POC Planning → POC Execution → Findings → MVP Onboarding → BAU Profile
   - **6 stages** with detailed activities, success criteria, go/no-go gates
   - **Typical 6-month timeline** with key milestones and decision points
   - **Reference:** Share with BU stakeholders to set expectations about engagement flow

---

## How to Use These Templates

### Scenario 1: Starting Discovery with a New Business Unit

**Timeline: 1–2 weeks**

1. **Week 1 – Intake:**
   - Complete [BU_QUESTIONNAIRE_INTAKE_CHECKLIST.md](BU_QUESTIONNAIRE_INTAKE_CHECKLIST.md)
   - Identify primary contact, regulatory drivers, blockers
   - Schedule intake call with BU Technology Owner

2. **Week 1 – Questionnaire Distribution:**
   - Customize [NORTHSTAR_BU_DISCOVERY_QUESTIONNAIRE_TEMPLATE.md](NORTHSTAR_BU_DISCOVERY_QUESTIONNAIRE_TEMPLATE.md) with BU details (name, date, contacts)
   - Send questionnaire + [BU_RESPONSE_GUIDE.md](BU_RESPONSE_GUIDE.md) + [BU_ENGAGEMENT_WORKFLOW.md](BU_ENGAGEMENT_WORKFLOW.md) to BU primary contact
   - Request completion within 1–2 weeks

3. **Week 2–3 – Discovery Meeting:**
   - Review completed questionnaire
   - Schedule 60-minute discovery meeting to validate findings, clarify gaps, align on timeline
   - Document decision: Proceed to POC Planning (yes/no/conditional)

### Scenario 2: Planning a POC (Post-Discovery)

**Timeline: 2–4 weeks**

1. **Reference [BU_ENGAGEMENT_WORKFLOW.md](BU_ENGAGEMENT_WORKFLOW.md) – Stage 2: POC Planning**
   - Define POC scope (platforms, environments, instance count)
   - Identify blockers and assign owners
   - Track blocker resolution in parallel

2. **Pre-POC Readiness Check:**
   - Verify all Critical blockers resolved
   - Confirm service accounts, scanning host, firewall rules in place
   - Schedule POC kickoff

3. **POC Execution:**
   - Follow [BU_ENGAGEMENT_WORKFLOW.md](BU_ENGAGEMENT_WORKFLOW.md) – Stage 3 for 4–6 week POC phases
   - Weekly status updates, DBA team support
   - Document findings & recommendation

---

## File Organization (Per Business Unit)

After completing discovery, create a folder for each business unit:

```
/docs/BU_Questionnaires/
├── [SHARED TEMPLATES]
│   ├── NORTHSTAR_BU_DISCOVERY_QUESTIONNAIRE_TEMPLATE.md     (master template)
│   ├── BU_QUESTIONNAIRE_INTAKE_CHECKLIST.md
│   ├── BU_RESPONSE_GUIDE.md
│   ├── BU_ENGAGEMENT_WORKFLOW.md
│   └── README.md                                             (this file)
│
├── [BU_NAME_1]                                               (e.g., "GlobalMarkets")
│   ├── INTAKE_CHECKLIST_[BU_NAME_1].md                      (copy of checklist, completed)
│   ├── [BU_NAME_1]_DISCOVERY_QUESTIONNAIRE.md               (completed discovery Q)
│   ├── DISCOVERY_MEETING_NOTES_[BU_NAME_1].md               (meeting notes & decisions)
│   ├── [BU_NAME_1]_POC_SCOPE.md                             (POC scope & timeline)
│   ├── [BU_NAME_1]_POC_ASSESSMENT.md                        (POC findings & recommendation)
│   └── [BU_NAME_1]_PROFILE.md                               (BAU infrastructure profile)
│
├── [BU_NAME_2]
│   ├── INTAKE_CHECKLIST_[BU_NAME_2].md
│   ├── [BU_NAME_2]_DISCOVERY_QUESTIONNAIRE.md
│   └── ... (etc.)
```

**Naming convention:** Use BU name consistently across all documents (e.g., "GlobalMarkets", "TradingPlatform", "RiskManagement").

---

## Quick Reference: Engagement Phases

| Phase | Duration | Key Deliverable | Template/Checklist |
|---|---|---|---|
| **Intake** | 1–2 weeks | Identified contacts, regulatory drivers, timeline | [BU_QUESTIONNAIRE_INTAKE_CHECKLIST.md](BU_QUESTIONNAIRE_INTAKE_CHECKLIST.md) |
| **Discovery** | 1–2 weeks | Completed questionnaire, validated findings | [NORTHSTAR_BU_DISCOVERY_QUESTIONNAIRE_TEMPLATE.md](NORTHSTAR_BU_DISCOVERY_QUESTIONNAIRE_TEMPLATE.md) |
| **POC Planning** | 2–4 weeks | POC scope, blocker removal tracking, kickoff scheduled | [BU_ENGAGEMENT_WORKFLOW.md](BU_ENGAGEMENT_WORKFLOW.md) – Stage 2 |
| **POC Execution** | 4–6 weeks | Scanning validation, findings, DBA team trained | [BU_ENGAGEMENT_WORKFLOW.md](BU_ENGAGEMENT_WORKFLOW.md) – Stage 3 |
| **POC Assessment** | 1–2 weeks | Go/No-Go recommendation for MVP | [BU_ENGAGEMENT_WORKFLOW.md](BU_ENGAGEMENT_WORKFLOW.md) – Stage 4 |
| **MVP Onboarding** | 4–8 weeks | All prod instances scanned monthly, BAU operational | [BU_ENGAGEMENT_WORKFLOW.md](BU_ENGAGEMENT_WORKFLOW.md) – Stage 5 |
| **Profile & BAU** | 2–4 weeks | Infrastructure profile published, ownership clear | [BU_ENGAGEMENT_WORKFLOW.md](BU_ENGAGEMENT_WORKFLOW.md) – Stage 6 |

---

## Key Success Factors

✅ **Questionnaire Completion:**
- Assign different sections to different responders (Tech Owner ≠ DBA ≠ Security)
- Quantify all estimates (instance counts, timelines, team capacity)
- Be honest about unknowns; follow up later instead of guessing

✅ **Intake & Blocker Removal:**
- Identify Critical/High blockers **early**
- Assign owners and target dates **now**
- Start blocker removal **in parallel** with questionnaire completion (don't wait for discovery meeting)

✅ **POC Planning:**
- Phase scope (don't try to scan all instances in week 1)
- Prioritize by complexity & impact (MSSQL first, Sybase last)
- Reserve 10–15% DBA team FTE for POC support

✅ **Engagement Sustainability:**
- Weekly syncs (30 min), not daily interruptions
- Clear escalation path (who decides if we pivot or stop)
- Document lessons learned and reuse across BUs

---

## Customization Guidelines

### Per-BU Template Customization

When preparing questionnaire for a specific BU:

1. **Header customization:**
   ```
   | Field | Value |
   |-------|-------|
   | **Business Unit Name** | `[INSERT_BU_NAME]` → Change to e.g., "Global Markets Trading Platform" |
   | **Completed by** | `[TEAM_MEMBER_NAME]` → Pre-fill with identified primary contact name (optional) |
   | **Date Completed** | `[YYYY-MM-DD]` → Add due date expectation (e.g., "Due: 2026-02-28") |
   ```

2. **Context-specific pre-fills (optional):**
   - If you know the BU uses certain platforms (e.g., "Oracle 19c + MSSQL 2019"), you can pre-fill Section D to speed completion
   - Add notes in Section H about known blockers (e.g., "We understand you have network segmentation challenges with Sybase; please describe")

3. **Regulatory focus (if known):**
   - If BU is SOX-regulated, emphasize Section G (compliance scanning requirements)
   - If GDPR-relevant, emphasize Section A.3 (regulatory drivers)

4. **Do NOT modify:**
   - Structure (sections A–I must remain consistent for internal tracking)
   - Core questions (these are validated through Global Markets Trading Platform example)
   - Response format (tables, yes/no fields) – consistency enables comparison across BUs

---

## FAQ: Common Questions About Questionnaires

**Q: Should we send the full questionnaire, or can respondents skip sections?**  
A: Send the full questionnaire but note which sections are required vs. optional. Sections A–I are required for discovery completeness. Section J is optional.

**Q: How do we handle BUs with no database infrastructure (e.g., pure SaaS)?**  
A: Questionnaire is designed for BUs with managed databases (on-prem or cloud). For pure SaaS (no databases), conduct a shorter intake call instead. Not applicable to current Northstar BU engagement.

**Q: Can multiple BUs use the same questionnaire instance count?**  
A: No. Each BU must complete a **separate questionnaire** customized with their name, contacts, and context. Use the template as a baseline; create unique per-BU versions.

**Q: What if we discover new blockers after questionnaire completion?**  
A: Update [BU_QUESTIONNAIRE_INTAKE_CHECKLIST.md](BU_QUESTIONNAIRE_INTAKE_CHECKLIST.md) Section 4.1 with new blockers, reassign ownership, and include in weekly blocker status tracking. This is normal.

**Q: How do we prioritize which BU to engage first?**  
A: Use intake checklist findings (regulatory urgency, instance count, blocker count, team readiness) to score BUs. High urgency + low blockers = engage first.

---

## Feedback & Iteration

As you complete the first 2–3 BU discoveries, **collect feedback** on questionnaire clarity:

1. **Ask respondents:** "Which sections were unclear or took too long to complete?"
2. **Track completion time:** How long did it actually take? Adjust time estimate if needed.
3. **Note ambiguities:** If multiple BUs asked the same clarification question (e.g., "What's 'instance count'?"), update Response Guide with better examples.
4. **Iterate quarterly:** Update templates based on lessons learned; version control in git.

---

## Contact & Support

**Questions about questionnaires?** Contact the Northstar Engagement Team.

**Want to adapt templates for a different program?** These templates are modular. You can:
- Use questionnaire as-is for different engagement types (compliance scanning, database assessment, cloud migration prep)
- Extend with platform-specific sections (Oracle-only, cloud-native databases, etc.)
- Adapt for different audiences (app dev teams, infra leads, C-suite)

---

## Document Control

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 2026-01-26 | Northstar Engagement Team | Initial README for BU questionnaire collection; links to 4 core templates |

---

**Last updated:** 2026-01-26  
**Status:** ✅ Ready for first BU engagement  
**Next step:** Complete intake checklist for first pilot BU(s)
