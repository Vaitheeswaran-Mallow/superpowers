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
4. **Rules** — copy `generic/`; then per [mode-standards-copy.md](references/mode-standards-copy.md) copy rails8 rules for the architecture mode
5. **Standards** — per [mode-standards-copy.md](references/mode-standards-copy.md); normalize legacy `architecture mode: ddd` to `ddd-companion`
6. **DDD scaffold** — when mode is `ddd-companion` or `ddd-first`, follow [ddd-bootstrap-scaffold.md](references/ddd-bootstrap-scaffold.md) for each qualifying bounded context
7. **Interactive fill** — product summary, entity catalog (2–5 rows), architecture mode; bounded contexts table when DDD mode on
8. **Human approval** — present `PROJECT_STACK.md`; hard stop until approved
9. **Hand off** — brainstorming for first feature, or wait

## When NOT to use

- Both `docs/TECH_STACK.md` and `docs/PROJECT_STACK.md` exist and are current
- Pure questions with no implementation intent

## Common mistakes

- Skipping human approval on PROJECT_STACK
- Copying DDD references when architecture mode is `none`
- Invoking brainstorming before bootstrap completes
- Copying full `ddd/` pack when mode is `ddd-first` (only two files)
- Scaffolding packages for Omakase-profile contexts in ddd-companion mode
- Skipping `config/initializers/zeitwerk.rb`
