---
description: Show current git branch, uncommitted files, and recent commits
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git branch:*), Bash(git diff:*)
---

Display:
1. !`git branch --show-current`
2. !`git status --short`
3. !`git log --oneline -5`

Report any obvious broken state (merge conflicts, detached HEAD, etc.).
