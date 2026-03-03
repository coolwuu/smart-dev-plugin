![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-blueviolet)

# smart-dev

**One plugin. Your entire dev workflow. Configured per-project.**

> 42 skills | 59 agents | 11 hooks | 3 commands | 2 profiles
>
> Project-specific conventions, build commands, and features — all opt-in via config.

&nbsp;

## Why smart-dev?

| | Feature | What it does |
|---|---------|-------------|
| :shield: | **Safety hooks** | Block `rm -rf`, `git push --force`, `DROP TABLE` — before they execute |
| :gear: | **Config-driven conventions** | Drop a JSON file, get project-specific rules injected every session |
| :repeat: | **9-phase dev workflow** | Brainstorm → Plan → Implement → Review → Verify — enforced, not suggested |
| :busts_in_silhouette: | **59 specialist agents** | Right model, right task — 51 sonnet, 7 opus, 1 haiku, all pre-configured |
| :floppy_disk: | **Session continuity** | Auto-handover saves state; resume picks up exactly where you left off |
| :zap: | **Zero config start** | Install and go — safety guards work immediately, no setup required |

&nbsp;

---

## Quick Start

```bash
# Clone the repo (or use as a submodule)
git clone https://github.com/coolwuu/smart-dev-plugin.git

# Install the plugin
claude plugin install ./smart-dev-plugin/

# (Optional) Add project config
cp smart-dev-plugin/profiles/tts.json .claude/smart-dev.json

# Verify
claude plugin list   # → smart-dev
```

That's it. Skills, agents, and hooks are available immediately.

---

## What's Inside

```
smart-dev-plugin/
├── .claude-plugin/
│   └── plugin.json            # Plugin manifest
├── skills/                    # 42 skills
│   ├── dev-workflow           #   9-phase feature workflow enforcer
│   ├── auto-handover          #   Session state persistence
│   ├── resume-handover        #   Session resumption
│   ├── openspec-*             #   20 OpenSpec skills (explore, apply, archive…)
│   └── ...                    #   + 19 more (TDD, parallel exec, codex, etc.)
├── agents/                    # 59 agents (51 sonnet, 7 opus, 1 haiku)
│   ├── code-reviewer.md       #   Code quality + plan compliance
│   ├── architect-review.md    #   Architecture consistency (opus)
│   ├── security-auditor.md    #   OWASP, auth, injection
│   └── ...                    #   + 56 more specialists
├── commands/                  # 3 slash commands
│   ├── verify                 #   /smart-dev:verify
│   ├── lesson                 #   /smart-dev:lesson
│   └── dev-status             #   /smart-dev:dev-status
├── hooks/                     # 11 scripts across 5 event types
│   ├── hooks.json             #   Hook registration
│   ├── pre-tool-use.sh        #   Block rm -rf, force-push, DROP TABLE
│   ├── agent-model-guard.sh   #   Enforce model param on Agent calls
│   ├── context-gate.sh        #   Warn 75% / block 85% context
│   └── ...                    #   + 7 more automation hooks
└── profiles/                  # 2 shipped profiles
    ├── default.json           #   Safe defaults (no conventions)
    └── tts.json               #   .NET/Vue — dotnet/vitest, openspec+mssql
```

---

## Installation

### Prerequisites

Required for all projects:

```bash
git --version      # 2.5+ (worktree support)
jq --version       # config loader — brew install jq
python3 --version  # project-insights — brew install python3
```

<details>
<summary>Additional tools (depends on your profile)</summary>

| Tool | Required by | Install |
|------|------------|---------|
| `dotnet 8` SDK | `verify`, `mssql-dev` | [dotnet.microsoft.com](https://dotnet.microsoft.com) |
| `node` / `npm` | `verify` | [nodejs.org](https://nodejs.org) |
| Docker | `verify`, `mssql-dev` | [docker.com](https://docker.com) |
| `openspec` CLI | all `openspec-*` skills | see openspec install docs |

</details>

### Install the plugin

```bash
# Option 1: Clone directly
git clone https://github.com/coolwuu/smart-dev-plugin.git
claude plugin install ./smart-dev-plugin/

# Option 2: Symlink for convenience
git clone https://github.com/coolwuu/smart-dev-plugin.git ~/projects/smart-dev
claude plugin install ~/projects/smart-dev/
```

### Remove duplicate hooks

If you previously had hooks in `~/.claude/settings.json`, remove these entries to prevent double-firing:

- **PreToolUse**: `agent-model-guard.sh`, `worktree-guard.sh`, `context-gate.sh`
- **SessionStart**: `inject-handover-reminder.sh`, `insights-reminder.sh`
- **UserPromptSubmit**: `check-context-threshold.sh`
- **PreCompact**: `pre-compact-save.sh`

Skip this step on a fresh machine.

---

## Configuration

### How config is resolved

1. `<git-root>/.claude/smart-dev.json` — project-local config
2. `$PLUGIN_ROOT/profiles/default.json` — plugin fallback
3. No config found → safe generic defaults

### Option A — Use a shipped profile

```bash
cp ~/projects/smart-dev/profiles/tts.json .claude/smart-dev.json
```

### Option B — Create your own

```json
{
  "schemaVersion": 1,
  "profile": "my-project",
  "conventions": [
    { "id": "backend", "path": "docs/conventions/backend.md", "title": "Backend" },
    { "id": "frontend", "path": "docs/conventions/frontend.md", "title": "Frontend" }
  ],
  "commitFormat": "type(scope): description",
  "verification": [
    { "name": "build", "cmd": "npm run build", "label": "Build" },
    { "name": "test", "cmd": "npm test", "label": "Tests" },
    { "name": "lint", "cmd": "npm run lint", "label": "Lint" }
  ],
  "testHint": "npm test",
  "lessonFilePath": "docs/learnings.md",
  "features": {
    "openspec": false,
    "mssql": false
  }
}
```

### Option C — No config

Works out-of-the-box. Generic hooks and safety guards fire, but no project conventions or test hints are injected.

<details>
<summary>Config schema reference</summary>

| Key | Type | Description |
|-----|------|-------------|
| `schemaVersion` | `number` | Config version (currently `1`) |
| `profile` | `string` | Profile name (informational) |
| `conventions` | `array` | `[{id, path, title}]` — convention files to inject |
| `commitFormat` | `string` | Commit message format |
| `verification` | `array` | `[{name, cmd, label}]` — steps for `/smart-dev:verify` |
| `testHint` | `string` | Test command shown after file edits |
| `lessonFilePath` | `string` | Path for `/smart-dev:lesson` output |
| `features` | `object` | `{openspec: bool, mssql: bool}` — opt-in features |

</details>

---

## Skills (42)

### Custom Skills (12)

| Skill | Purpose |
|-------|---------|
| `dev-workflow` | 9-phase feature development workflow enforcer |
| `mssql-dev` | SQL Server stored procedure development |
| `e2e-troubleshoot` | E2E test 6-layer diagnostic ladder |
| `lesson` | Append tagged learnings to configured path |
| `parallel-execution` | Execute tasks in parallel via subagents |
| `auto-handover` | Save session state for seamless continuation |
| `resume-handover` | Resume from a handover document |
| `agent-browser` | Browser automation via Playwright |
| `codex` | Delegate tasks to OpenAI Codex CLI |
| `project-insights` | Cross-session JSONL analytics and pattern detection |
| `ui-ux-pro-max` | UI/UX design with 50 styles and 21 palettes |
| `visual-ui-critique` | Critique UI screenshots systematically |

### OpenSpec Skills (20)

| Skill | Purpose |
|-------|---------|
| `openspec-explore` | Explore mode — think before implementing |
| `openspec-new` / `openspec-new-change` | Start a new change |
| `openspec-continue` / `openspec-continue-change` | Continue an in-progress change |
| `openspec-apply` / `openspec-apply-change` | Apply change tasks to codebase |
| `openspec-archive` / `openspec-archive-change` | Archive a completed change |
| `openspec-bulk-archive` / `openspec-bulk-archive-change` | Archive multiple changes |
| `openspec-sync` / `openspec-sync-specs` | Sync delta specs to main |
| `openspec-ff` / `openspec-ff-change` | Fast-forward artifact creation |
| `openspec-ask` | Query OpenSpec documents |
| `openspec-analyze` | Analyze a change |
| `openspec-clarify` | Clarify requirements |
| `openspec-feedback` | Submit feedback |
| `openspec-onboard` | Onboarding guide |

> Requires `openspec` CLI installed separately. Always callable, but only auto-suggested when `features.openspec: true`.

<details>
<summary>Superpowers Skills (10) — orchestrated by dev-workflow</summary>

| Skill | Phase |
|-------|-------|
| `brainstorming` | Phase 0 — creative exploration |
| `using-git-worktrees` | Phase 0 — workspace isolation |
| `test-driven-development` | Phase 3 — TDD discipline |
| `subagent-driven-development` | Phase 3 — per-task delegation |
| `executing-plans` | Phase 3 — batch execution |
| `dispatching-parallel-agents` | Phase 3 — parallel task streams |
| `requesting-code-review` | Phase 4 — dispatch review |
| `receiving-code-review` | Phase 5 — review response |
| `verification-before-completion` | Phase 8 — evidence before done |
| `finishing-a-development-branch` | Phase 8 — merge / PR / discard |

</details>

---

## Commands (3)

| Command | Description |
|---------|-------------|
| `/smart-dev:verify` | Run project verification suite from config |
| `/smart-dev:lesson` | Append a tagged learning to configured path |
| `/smart-dev:dev-status` | Show git branch, uncommitted files, last commit |

> OpenSpec operations are invoked as skills: `/smart-dev:openspec-explore`, `/smart-dev:openspec-new`, etc.

---

## Agents (59)

All agents have explicit model set — no `inherit`. Descriptions use generic terminology instead of project-specific references.

### Core workflow agents

| Agent | Role | Model |
|-------|------|-------|
| `code-reviewer` | Plan compliance + code quality | sonnet |
| `security-auditor` | OWASP, auth, injection | sonnet |
| `performance-engineer` | N+1, query perf, blocking | sonnet |
| `test-automator` | Project test frameworks | sonnet |
| `database-optimizer` | Database conventions | sonnet |
| `backend-architect` | API and service design | sonnet |
| `architect-review` | Architecture consistency | opus |
| `csharp-developer` | .NET 8 implementation | sonnet |
| `vue-expert` | Vue 3 / frontend | sonnet |
| `typescript-pro` | TypeScript / type safety | sonnet |
| `frontend-developer` | React / UI components | sonnet |

<details>
<summary>Full agent roster (59)</summary>

**sonnet (51)**
`ai-engineer` `api-troubleshooter` `backend-architect` `backend-developer` `backend-security-coder` `business-analyst` `cicd-troubleshooter` `cloud-architect` `code-architect` `code-explorer` `code-reviewer` `code-simplifier` `context-manager` `csharp-developer` `data-engineer` `database-admin` `database-optimizer` `db-troubleshooter` `debugger` `devops-engineer` `devops-troubleshooter` `dictation-engine` `docs-architect` `dotnet-core-expert` `dotnet-framework-4.8-expert` `dx-optimizer` `electron-app-troubleshooter` `electron-pro` `error-detective` `event-sourcing-architect` `frontend-developer` `frontend-troubleshooter` `fullstack-developer` `graphql-architect` `infra-troubleshooter` `legacy-modernizer` `monorepo-architect` `performance-engineer` `prompt-engineer` `security-auditor` `sql-pro` `swift-expert` `tdd-orchestrator` `temporal-python-pro` `test-automator` `tutorial-engineer` `typescript-pro` `ui-designer` `ux-researcher` `vector-database-engineer` `vue-expert`

**opus (7)** — high-reasoning specialists
`architect-review` `database-architect` `hybrid-cloud-architect` `kubernetes-architect` `network-engineer` `service-mesh-expert` `terraform-specialist`

**haiku (1)** — lightweight tasks
`deployment-engineer`

</details>

---

## Hooks (11 scripts, 5 events)

### SessionStart

| Script | Matcher | Purpose |
|--------|---------|---------|
| `session-start` | `startup\|resume\|clear\|compact` | Inject config-driven conventions |
| `inject-handover-reminder.sh` | `compact\|clear` | Relay handover flag file |
| `insights-reminder.sh` | all | Remind `/project-insights` (7-day cadence) |

### PreToolUse

| Script | Matcher | Purpose |
|--------|---------|---------|
| `pre-tool-use.sh` | `Bash` | Block `rm -rf`, `git push --force`, `DROP TABLE` |
| `agent-model-guard.sh` | `Agent` | Block Agent calls missing `model` param |
| `worktree-guard.sh` | `Write\|Edit\|MultiEdit` | Warn when writing to main repo with active worktrees |
| `context-gate.sh` | all | Warn 75% / block 85% context usage |

### PostToolUse

| Script | Matcher | Purpose |
|--------|---------|---------|
| `post-tool-use.sh` | `Edit\|Write\|MultiEdit` | Config-driven test reminder after edits |

### UserPromptSubmit

| Script | Matcher | Purpose |
|--------|---------|---------|
| `check-context-threshold.sh` | all | Context % warning + handover flag relay |
| `user-prompt-submit.sh` | all | Inject git branch + status into context |

### PreCompact

| Script | Matcher | Purpose |
|--------|---------|---------|
| `pre-compact-save.sh` | `auto` | Save handover metadata before compaction |

---

## Known Limitations

- **Unix only** — hook scripts use `/tmp/` paths; no Windows support
- **`jq` required** — `brew install jq` (macOS) or `apt install jq` (Linux)
- **`openspec` CLI** — `openspec-*` skills require separate installation
- **`openspec-verify`** — not found in source project; excluded from bundle

---

## Verification Checklist

After installing, confirm these work:

**Config system**
- [ ] No config → session starts with only context threshold reminder
- [ ] Shipped profile → `cp profiles/tts.json .claude/smart-dev.json` → conventions injected
- [ ] Custom config → create `.claude/smart-dev.json` → values injected
- [ ] `/smart-dev:verify` → runs verification steps from config

**Safety hooks**
- [ ] `rm -rf /tmp/test` via Bash → PreToolUse blocks with exit 2
- [ ] Edit any source file → PostToolUse injects test reminder
- [ ] `claude plugin list` shows `smart-dev`
- [ ] Each hook fires exactly once per event (no double-firing)
