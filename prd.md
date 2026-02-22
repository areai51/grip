# Savoy CRM - Product Requirements Document

## Overview

**Tagline:** A markdown-based Personal CRM for executives who value control, simplicity, and portability.

**Problem:** Busy leaders need to maintain meaningful relationships with their network (investors, mentors, clients, team members) but existing CRM solutions are:
- Over-engineered for personal use
- Expensive SaaS subscriptions
- Data locked in proprietary formats
- Complex to adopt and maintain

**Solution:** A git-native, markdown-based personal CRM that stores all relationship data as human-readable files, version-controlled, portable, and fully owned by the user.

---

## Target Audience

**Primary:**
- CEOs and founders managing investor relations, board contacts, key hires
- CXOs (C-level executives) with networks across companies and industries
- Business leaders maintaining mentor, advisor, and strategic partner relationships

**Secondary:**
- Board members
- Venture capitalists and angel investors
- Consultants and advisors
- High-net-worth individuals managing personal networks

---

## Core Concepts

### Data Model (Markdown Files)

All data stored as markdown files with YAML frontmatter for structured fields.

```
savoy-crm/
├── people/
│   ├── alice-smith.md
│   ├── bob-jones.md
│   └── index.md (directory index with quick-filter views)
├── companies/
│   ├── acme-corp.md
│   └── index.md
├── interactions/
│   ├── 2024-02-15-coffee-with-alice.md
│   └── 2024-02-20-board-meeting.md
├── reminders/
│   ├── follow-up-with-bob-2024-03-01.md
│   └── alices-birthday-2024-05-12.md
├── dashboard.md (auto-generated or hand-maintained)
└── config.yaml (settings, defaults, integrations)
```

### Person File Structure

```yaml
---
name: Alice Smith
title: VP of Engineering
company: Acme Corp
email: alice@acme.com
phone: +1-555-123-4567
social:
  linkedin: https://linkedin.com/in/alicesmith
  twitter: @alicesmith
  github: alicesmith
tags: [investor, mentor, b2b, tech]
relationship: A  # A (strong) to E (weak)
last_contact: 2024-02-15
next_followup: 2024-03-15
notes:
  - Met at TechCrunch Disrupt 2024
  - Former Google engineer, now building AI startup
  - Spouse: John, kids: 2
  - Birthday: May 12
  - Introduced by Bob Jones
  - Preferred communication: WhatsApp
  - Timezone: PST
  - Family: Married, 2 kids
  - Interests: sailing, classical music
---

## Recent Interactions

- 2024-02-15: Coffee at Blue Bottle — discussed their Series A raise. Interested in intro to our CTO. [x] Send follow-up email
- 2024-01-10: Lunch after conference — great alignment on product vision.

## Open Items
- [ ] Review their term sheet by March 1
- [ ] Intro to SecFi by end of month
```

---

## Feature Prioritization

### MVP (Phase 1) - Must Have

1. **File-based storage** with YAML frontmatter + markdown body
2. **CLI tool** (`savoy`) with commands:
   - `savoy add person` — create a new person file
   - `savoy search <query>` — full-text search across all files
   - `savoy show <name/company>` — render person/company view
   - `savoy remind <date> <note>` — create a reminder
   - `savoy log <date> <people...>` — record an interaction
   - `savoy dashboard` — render interactive dashboard (terminal or HTML)
3. **Dashboard** displaying:
   - Upcoming reminders (next 7 days, sorted by date)
   - Recent interactions (last 10)
   - People due for follow-up
   - Quick stats: total contacts, relationship strength distribution
4. **Tag-based filtering** in CLI and dashboard
5. **Git integration awareness** — detect changes, show "uncommitted" warnings

### Phase 2 - Important

1. **Import tools**
   - CSV import (from other CRMs, address books)
   - vCard (.vcf) import/export
   - LinkedIn connections export parser
2. **Meeting prep generator**
   - Given a list of attendees, compile their notes, last contact, preferences, open items
   - Output markdown or print-ready format
3. **Advanced search**
   - Filter by tags, company, relationship strength, date ranges
   - Save searches as "views" (virtual index pages)
4. **Reminder system**
   - Daily/weekly digest email (via GitHub Action or local script)
   - iCal feed generation (read-only calendar for birthdays/followups)
5. **Relationship graph**
   - Generate mermaid.js graph of connections (who knows whom)
   - Pathfinding: "How is Alice connected to Bob?"

### Phase 3 - Nice-to-Have

1. **Web interface** (static site generator approach)
   - Browse/search contacts in browser
   - Mobile-responsive design
2. **VS Code extension** with snippets and autocomplete for fields
3. **Obsidian plugin** for seamless integration with existing vaults
4. **Mobile apps** (using GitHub as backend, or Git sync)
5. **AI-assisted note summarization** (optional, local LLM)
6. **Encryption module** for sensitive fields (PGP-style, optional)

---

## User Workflows

### Daily Startup
1. Run `savoy dashboard` or check digest email
2. See who needs attention today
3. Log interactions after calls
4. Update notes immediately post-meeting

### Meeting Preparation
1. `savoy prep --attendees "Alice, Bob, Carol" > prep.md`
2. Review compiled notes, open items, relationship strengths
3. Add custom agenda items
4. After meeting: `savoy log --date today --people Alice,Bob --notes "agreed to X, follow-up Y"`

### Network Maintenance
1. Weekly: review "people not contacted in 60+ days"
2. Set reminders for birthdays, anniversaries
3. Add new contacts from business cards via CLI

### Sharing
1. Export contact to vCard: `savoy export vcard Alice > alice.vcf`
2. Send to someone, or import to phone
3. Keep sensitive notes private (never export)

---

## Technical Decisions

### Tech Stack
- **CLI:** Node.js (TypeScript) or Python (argparse/click)
- **Data format:** Markdown + YAML frontmatter (existing libraries for parsing)
- **Dashboard:** Terminal UI (blessed/ink) or generate HTML with embedded JS
- **Search:** ripgrep (rg) integration or embedded full-text
- **Git detection:** simple `git status` checks for uncommitted changes

### Storage Layout
- All files under a single root directory (e.g., `~/savoy/` or project dir)
- People files in `people/` with normalized filenames (kebab-case)
- Interactions dated YYYY-MM-DD prefix for sorting
- Config in `config.yaml` with optional defaults for tags, relationship scales

### Extensibility
- Plugin architecture for importers/exporters
- Hooks system: post-log, pre-reminder, etc. (scripts to call)
- Template engine for dashboard and prep output

---

## Success Metrics

- **Adoption:** User logs at least 1 interaction per day within first week
- **Retention:** Continued use after 30 days (measure via git commit frequency)
- **Network health:** % of contacts with interaction in last 90 days > 60%
- **User satisfaction:** "I no longer forget important details" (survey)
- **Zero data lock-in:** Can migrate all data to another tool within 1 hour

---

## Competitive Landscape

| Tool          | Pros                              | Cons (that Savoy solves)             |
|---------------|-----------------------------------|--------------------------------------|
| Salesforce    | Powerful, enterprise-grade       | Overkill, expensive, data silo      |
| HubSpot       | Free tier, easy                  | Locked in, markdown unsupported     |
| Notion/Airtable | Flexible, collaborative        | Cloud lock-in, search limitations   |
| Excel/Sheets  | Familiar                         | Not human-readable, schema issues   |
| Obsidian      | Markdown-based, great UX        | No built-in CRM schema, needs plugins |
| Monolith (e.g., Rox) | Purpose-built             | Proprietary, paid, closed format    |

**Savoy's differentiator:** Git-native markdown = maximum portability, version history, no lock-in, human-auditable.

---

## Roadmap

### Week 1-2: MVP CLI
- Scaffold project (choose language)
- Implement file CRUD operations
- Basic search (ripgrep wrapper)
- Simple dashboard (terminal)

### Week 3-4: Refinement
- Tag filtering, advanced search
- Import tools (CSV, vCard)
- Git change detection
- Documentation + installation guide

### Week 5-6: Polish
- Bug fixes, UX improvements
- Template customization
- Publish to npm (if Node) or PyPI (if Python)
- First public release v0.1.0

### Month 2-3: Extensions
- Meeting prep generator
- Graph view (mermaid)
- Weekly digest action (GitHub Actions sample)
- Import from LinkedIn

### Month 4-6: Ecosystem
- VS Code extension
- Obsidian plugin
- Web viewer (static site)
- Mobile app (React Native, sync via Git)

---

## Risks & Mitigations

| Risk                         | Mitigation                                      |
|------------------------------|-------------------------------------------------|
| Low adoption (perceived as too "raw") | Excellent docs, templates, video demos      |
| Data quality issues (bad frontmatter) | Validation layer in CLI, lint command        |
| Git confusion (merge conflicts) | Simple advisory: "Commit after each session" |
| Performance with large networks | Use ripgrep, paginate results, add indexes  |
| Cross-platform issues        | Write pure Node.js/Python, avoid OS-specific  |

---

## Open Questions

- Should we embed a tiny graphing DB (like lowdb) for faster queries, or always parse markdown on demand?
- Template customization: how much without becoming a framework?
- Encryption: who needs it? Is it a blocker for execs?
- Mobile strategy: dedicated app or just GitHub mobile + web viewer?
- Should we support multiple "networks" (separate repos) or just one per user?

---

## Appendix: Example Use Cases

**CEO tracking investor relations:**
- Each investor gets a person file with tags: investor, lead, board
- Track last touch (board meeting, email intro, coffee)
- Set reminders for follow-ups and report deadlines
- Dashboard shows "Investor touches this month"

**CXO maintaining mentor network:**
- Tag mentors, log advice given, track reciprocity
- Pre-meeting prep shows all past advice to avoid repetition
- Birthday reminders to maintain goodwill

**Founder building biz dev pipeline:**
- Track prospective partners, interaction history, pipeline stage
- Search by keyword to recall past conversations
- Generate intro emails with context from notes

---

*PRD v0.1 — Created 2026-02-19*
