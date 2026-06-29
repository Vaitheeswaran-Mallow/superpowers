---
name: using-project-standards
description: Use when starting work in a project, scaffolding a new MVP, or when docs/TECH_STACK.md or docs/PROJECT_STACK.md is missing — before brainstorming or writing code.
---

# Using Project Standards

## Overview

Bootstrap `TECH_STACK.md`, `PROJECT_STACK.md`, Cursor rules, and stack reference docs. Hard gate before feature work.

**Announce at start:** "I'm using the using-project-standards skill to verify this project is ready."

<HARD-GATE>
Do NOT invoke brainstorming, writing-plans, or test-driven-development until this skill completes and the human approves PROJECT_STACK.md.
</HARD-GATE>

## Checklist

Create a todo per item:

1. **Detect stack** — [stack-detection.md](references/stack-detection.md)
2. **TECH_STACK** — if missing, copy [tech-stack-template.md](references/tech-stack-template.md) to `docs/TECH_STACK.md`; set stack and verify command
3. **PROJECT_STACK** — if missing, copy [project-stack-template.md](references/project-stack-template.md) to `docs/PROJECT_STACK.md`
4. **Rules** — copy `templates/project/.cursor/rules/generic/` to `.cursor/rules/`; if stack is `rails8`, also copy `templates/project/.cursor/rules/stacks/rails8/`
5. **Standards** — if stack pack exists in fork at `docs/standards/stacks/<stack>/`, copy to app `docs/standards/stacks/<stack>/` (technical guideline only unless architecture mode is `ddd`)
6. **DDD pack** — only when `architecture mode: ddd` in TECH_STACK, copy `ddd/` subfolder
7. **Interactive fill** — product summary, seed entity catalog (2–5 rows), architecture mode; if `ddd`, bounded contexts table
8. **Human approval** — present `PROJECT_STACK.md`; hard stop until approved
9. **Hand off** — brainstorming for first feature, or wait

## When NOT to use

- Both `docs/TECH_STACK.md` and `docs/PROJECT_STACK.md` exist and are current
- Pure questions with no implementation intent

## Common mistakes

- Skipping human approval on PROJECT_STACK
- Copying DDD references when architecture mode is `none`
- Invoking brainstorming before bootstrap completes
