---
description: Run the project verification suite defined in .claude/smart-dev.json
allowed-tools: Bash(*)
---

Read `.claude/smart-dev.json` (or the plugin's `profiles/default.json` fallback) and extract the `verification` array.

Each entry has `{ "name": "...", "cmd": "...", "label": "..." }`.

Execute this canonical loop via a single Bash call:

```bash
CONFIG=".claude/smart-dev.json"
[ ! -f "$CONFIG" ] && echo "No config found" && exit 1
STEPS=$(jq -c '.verification[]' "$CONFIG")
FAILED=0
echo "| Step | Result | Duration |"
echo "|------|--------|----------|"
while IFS= read -r step; do
  LABEL=$(echo "$step" | jq -r '.label')
  CMD=$(echo "$step" | jq -r '.cmd')
  START=$(date +%s)
  if eval "$CMD" > /dev/null 2>&1; then
    RESULT="PASS"
  else
    RESULT="FAIL"; FAILED=1
  fi
  END=$(date +%s)
  DUR=$(( END - START ))
  echo "| $LABEL | $RESULT | ${DUR}s |"
  [ "$FAILED" -eq 1 ] && break
done <<< "$STEPS"
[ "$FAILED" -eq 1 ] && echo "Stopped on first failure." && exit 1
echo "All steps passed."
```

If no config file is found or the `verification` array is empty, tell the user:
> No verification steps configured. Create `.claude/smart-dev.json` with a `verification` array, or copy a profile from the plugin's `profiles/` directory.
