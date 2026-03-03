---
name: visual-ui-critique
description: "Use when the user provides a screenshot, image, or UI mockup and wants design feedback. Triggers on: 'critique this UI', 'review my design', 'what's wrong with this layout', 'give feedback on my screenshot', 'this looks too AI', 'how can I improve this page'. Applies systematic anti-pattern detection and references design system alternatives. Outputs structured critique only — no code."
---

# Visual UI Critique

Analyzes UI screenshots for anti-patterns, layout problems, and aesthetic weaknesses. Outputs a structured critique with directional recommendations grounded in the ui-ux-pro-max design database and frontend-design aesthetic principles.

**This skill produces critique only — no code, no implementation.**

## Workflow

### Step 1: Confirm Screenshot

If no image is attached, ask the user to paste or provide the file path. Do not proceed without it.

### Step 2: Extract Context

Identify from the screenshot before analyzing:
- **Product type**: SaaS, dashboard, marketing, mobile, e-commerce, etc.
- **Apparent audience**: Consumer, enterprise, developer
- **Stack hints**: Any visible framework or component library (shadcn, Material, etc.)

### Step 3: Anti-Pattern Detection (All 4 Required)

| # | Anti-Pattern | What to Look For |
|---|-------------|-----------------|
| 1 | **Generic card layout** | Icon + title + description, rounded shadow cards uniformly tiled |
| 2 | **Purple/blue gradients** | Hero sections or backgrounds using purple-to-blue or teal-to-purple fades |
| 3 | **Uniform spacing** | All sections share identical padding/gap — no visual rhythm or hierarchy |
| 4 | **Generic fonts** | Inter, Roboto, Space Grotesk, Arial, system-ui as display or heading fonts |

Additional checks:
- Emoji used as UI icons (instead of SVG)
- Missing hover/interactive feedback cues
- Low text contrast (suspect if body text is gray-400 or lighter in light mode)
- Inconsistent container widths across sections

### Step 4: Query ui-ux-pro-max

Run against the detected product type + visible style keywords:

```bash
# Design system baseline
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<product_type> <style_keywords>" --design-system

# Typography alternatives (always run — fonts are the #1 anti-pattern)
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "distinctive unexpected typography" --domain typography

# UX issues if layout problems found
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "spacing hierarchy visual rhythm" --domain ux

# Stack-specific guidance (if user mentions framework)
# Available stacks: html-tailwind, react, nextjs, vue, nuxtjs, nuxt-ui, svelte, shadcn, etc.
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<layout_keyword>" --stack <detected_stack>
```

If the user does not mention a stack, skip the stack-specific query.

### Step 5: Invoke frontend-design Skill

Use the `frontend-design` skill to determine bold aesthetic direction for the recommendations:
- What tone fits the product? (editorial, brutalist, soft, utilitarian, etc.)
- What makes this UI forgettable, and what would make it memorable?
- Font direction alternatives (must avoid the 4 flagged generics)

### Step 6: Deliver Structured Critique

---

## Output Format

```
## UI Critique — [Product/Component name if identifiable]

### 🔴 Anti-Patterns Found
- [Pattern name] — [Specific element where spotted, e.g. "Hero section uses purple-to-blue gradient overlay on the CTA block"]
- ...

### 🟡 UX / Layout Opportunities
- [Issue]: [Why it matters + directional fix]
- ...

### 🟢 Strengths to Preserve
- [What is working — skip section if nothing stands out]

### 💡 Directional Recommendations
**Aesthetic direction**: [1-sentence bold direction from frontend-design — pick a clear tone]
**Font alternatives**: [2-3 concrete font names from ui-ux-pro-max typography search]
**Color direction**: [Palette name or direction from ui-ux-pro-max — name what to avoid]
**Layout approach**: [How to break from card uniformity — specific structural idea]
**One thing to make it memorable**: [Single highest-impact change]
```

---

## Rules

- Every observation must be **specific to this screenshot** — no generic boilerplate
- Every 🔴 must name the exact element where the anti-pattern appears
- 💡 recommendations must cite output from ui-ux-pro-max (font names, palette names, style names)
- If a check finds nothing, write "None detected" — don't omit the category
- Do not suggest or write code
