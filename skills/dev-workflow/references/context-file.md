---
purpose: context.md format, updates, and parsing
topics:
  - canonical_format
  - update_responsibilities
  - update_protocol
  - parsing
  - hook_integration
---

# Context File Management

Single source of truth for context.md format, updates, and parsing.

## Location

```
{FeatureDocsPath}/doing/{feature-name}/context.md   # During development
{FeatureDocsPath}/done/{feature-name}/context.md    # After completion (Phase 8)
```

## Canonical Format

```markdown
# Feature: {feature-name}

**OpenSpec Change:** openspec/changes/{change-name}

**Status:** In Progress | Blocked | Complete
**Current Phase:** Phase {N} - {Name}
**Last Updated:** YYYY-MM-DD HH:MM:SS AM/PM TZ

---

## Current Progress

### What's Been Completed
- [x] Phase 0: Context Setup
- [x] Phase 1: Planning
- [ ] Phase 2: Convention & Readiness Review
- [ ] Phase 3: Implementation

### Next Todo
- {Next action to take}

---

## Key Decisions
- {Approval or decision with date}

---

## Blockers & Issues
- {Current blockers if any}

---

## Learnings
- {Insights discovered}
```

## Update Responsibilities

| Field/Section | Updated By | When |
|---------------|-----------|------|
| **Status** | Skill | Status changes |
| **Current Phase** | Skill | Phase transitions |
| **Last Updated** | Skill | After every step |
| **What's Been Completed** | Hook | On stop |
| **Next Todo** | Hook | On stop |
| **Key Decisions** | User/Skill | When decisions made or approvals obtained |
| **Blockers & Issues** | User | When blockers arise |
| **Learnings** | User | When insights discovered |

## Update Protocol

**Update header after every step:**

```markdown
**Status:** In Progress
**Current Phase:** Phase 3 - Implementation
**Last Updated:** 2025-12-25 03:00:00 PM CST
```

**Update triggers:**
- Starting new activity
- Completing activity
- Receiving approval
- Phase transition
- Encountering blocker

**Always update**: `Last Updated` timestamp after every activity

## Parsing (Resume Mode)

### Extract Current Phase

```
Parse: **Current Phase:** Phase {N}
Extract: N (integer 0-8)
```

### Extract Status

```
Parse: **Status:** {value}
Values: "In Progress" | "Blocked" | "Complete"
```

### Extract Completed Phases

```
Parse: ## Current Progress → ### What's Been Completed
Look for: - [x] Phase {N}:
Extract: List of completed phase numbers
```

### Extract Approvals

```
Parse: ## Key Decisions
Look for: "approved" keyword
Extract: Which documents were approved
```

### Extract OpenSpec Change Path

```
Parse: **OpenSpec Change:** {path}
Extract: path (relative to project root, e.g., openspec/changes/add-user-auth)
```

### Extract Blockers

```
Parse: ## Blockers & Issues
If non-empty and not placeholder text → hasBlockers = true
```

## Hook Integration

The stop hook (`.claude/hooks/update-context-on-stop.sh`) updates:
- "What's Been Completed" section
- "Next Todo" section

**Skill should NOT update these sections** to avoid conflicts.

## Resume Flow

1. Read context.md
2. Parse current phase and status
3. Present summary to user:
   ```
   Resuming: {feature-name}
   Current Phase: Phase {N} - {Name}
   Last Updated: {timestamp}

   Continue?
   ```
4. Proceed from current phase
