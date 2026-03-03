---
purpose: Error scenarios and recovery strategies
topics:
  - context_not_found
  - validation_failed
  - invalid_skip
  - config_missing
  - parse_error
---

# Error Handling

Error scenarios and recovery strategies.

## Context.md Not Found

**Scenario:** Resume mode but context.md doesn't exist

**Response:**
```
context.md not found for feature: {feature-name}
Expected: {FeatureDocsPath}/doing/{feature-name}/context.md

Options:
A) Start fresh with Phase 0
B) Check done/ directory
C) Try different feature name
```

## Phase Validation Failed

**Scenario:** Transition attempted but phase incomplete

**Response:**
```
Phase {X} not complete. Missing:

Files:
- {missing files}

Approvals:
- {missing approvals}

Complete these before proceeding.
```

## Invalid Phase Skip

**Scenario:** User tries to skip phases

**Response:**
```
Cannot skip from Phase {X} to Phase {Y}.
Configured phases: {list}
Next allowed phase: {next}
```

## Configuration Missing

**Scenario:** No workflow config in CLAUDE.md

**Response:**
```
No configuration found. Using defaults:
- Phases: 0,1,2,3,8
- TDD: optional
- FeatureDocsPath: Documentation/Requirements/Feature
```

## Context.md Parse Error

**Scenario:** context.md corrupted or malformed

**Response:**
```
Failed to parse context.md.

Options:
A) View current content
B) Start fresh (backup existing)
C) Manually fix
```

## OpenSpec Change Not Found

**Scenario:** Phase 1 but no OpenSpec change exists

**Response:**
```
No OpenSpec change found for feature: {feature-name}

Options:
A) Create new change: openspec-new-change "{feature-name}"
B) Link existing change (update context.md)
C) Use fast-forward: openspec-ff-change "{feature-name}"
```

## OpenSpec Artifacts Incomplete

**Scenario:** Phase 1→2 transition but artifacts missing

**Response:**
```
OpenSpec artifacts incomplete. Missing:
- {missing artifacts}

Run openspec-continue-change to create remaining artifacts.
```

## Best Practices

1. **Be specific** - Explain exactly what's wrong
2. **Offer options** - Multiple paths forward
3. **Preserve state** - Don't lose user work
4. **Allow retry** - Let user try again
