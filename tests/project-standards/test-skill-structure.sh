#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $1"; exit 1; }

# New skill exists with valid frontmatter
grep -q '^name: using-project-standards' skills/using-project-standards/SKILL.md || fail "missing using-project-standards name"
grep -q '^description: Use when' skills/using-project-standards/SKILL.md || fail "bad description"

# References exist
test -f skills/using-project-standards/references/stack-detection.md || fail "stack-detection"
test -f skills/using-project-standards/references/tech-stack-template.md || fail "tech-stack-template"
test -f skills/using-project-standards/references/project-stack-template.md || fail "project-stack-template"
test -f skills/brainstorming/references/entity-impact.md || fail "entity-impact"
test -f skills/writing-plans/references/stack-placement.md || fail "stack-placement"
test -f skills/writing-plans/references/ddd-applicability-template.md || fail "ddd template"
test -f skills/verification-before-completion/references/stack-verify.md || fail "stack-verify"

# Templates
test -f templates/project/docs/TECH_STACK.md || fail "TECH_STACK template"
test -f templates/project/docs/PROJECT_STACK.md || fail "PROJECT_STACK template"

# Rails8 pack
test -f docs/standards/stacks/rails8/technical-guideline.md || fail "rails8 guideline"
test -f docs/standards/stacks/rails8/ddd/adoption-profiles.md || fail "ddd adoption"

# using-superpowers wires bootstrap
grep -q 'using-project-standards' skills/using-superpowers/SKILL.md || fail "using-superpowers missing bootstrap wiring"

echo "PASS: project-standards structure"
