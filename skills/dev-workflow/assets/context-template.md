---
template: context
phase: 0
purpose: Track feature progress and state
sections:
  - hook_status (auto-updated)
  - key_decisions
  - blockers
  - learnings
notes:
  - "CRITICAL: The HTML comment markers (CURRENT_PHASE, PHASE_STATUS) are required by the stop hook"
  - "The hook reads these markers to determine current state and update the progress section"
  - "Update these markers when changing phases: CURRENT_PHASE: 0-8, PHASE_STATUS: in_progress|complete|blocked|paused"
  - "Phase definitions are in schema/phases.txt (single source of truth)"
---

# Feature: {feature-name}

**Worktree:** {worktree-path}
**OpenSpec Change:** openspec/changes/{feature-name}

<!-- CURRENT_PHASE: 0 -->
<!-- PHASE_STATUS: in_progress -->

<!-- HOOK_STATUS_START -->
## Status (Updated by Hook)

**Last Updated**: {timestamp}
**Current Phase**: Phase 0 - Context Setup

### What's Been Completed
<!-- Auto-generated -->

### Next Todo
<!-- Auto-generated -->
<!-- HOOK_STATUS_END -->

---

## Key Decisions

{Record approvals and decisions here}

---

## Blockers & Issues

{Record blockers here}

---

## Learnings

{Record insights here}
