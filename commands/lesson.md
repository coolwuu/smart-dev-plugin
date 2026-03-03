---
description: Append a tagged learning to the project's lesson file with domain and severity tags
allowed-tools: Read(*), Edit(*), Write(*)
---

Read `.claude/smart-dev.json` and extract `lessonFilePath` (default: `learnings.md`).

Ask the user:
1. What did you learn?
2. What domain? [backend / frontend / db / e2e / workflow / tooling / shell]
3. What severity? [one-off / recurring / spiral]

Then append a timestamped, tagged entry to the configured file:

```
## [YYYY-MM-DD] domain:backend severity:recurring
<learning text>
```

If the file does not exist, create it with a `# Learnings` header first.
