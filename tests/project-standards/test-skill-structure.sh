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

test -f docs/standards/stacks/rails8/ddd/architecture-and-ddd-standard.md || fail "architecture-and-ddd-standard"
test -f docs/standards/stacks/rails8/ddd/rails-package-layout.md || fail "rails-package-layout"
test -f templates/project/config/initializers/zeitwerk.rb || fail "zeitwerk template"
test -f templates/project/docs/contexts/_template.md || fail "context template"
test -f skills/using-project-standards/references/mode-standards-copy.md || fail "mode-standards-copy"
test -f skills/using-project-standards/references/ddd-bootstrap-scaffold.md || fail "ddd-bootstrap-scaffold"
ls templates/project/.cursor/rules/stacks/rails8/rails8-ddd-*.mdc 2>/dev/null | grep -q . || fail "ddd cursor rules"
grep -q 'ddd-companion' skills/using-project-standards/SKILL.md || fail "three modes in skill"

# mode-standards-copy: explicit file lists (not entire ddd/ folder)
grep 'ddd-first' skills/using-project-standards/references/mode-standards-copy.md | grep -q 'ddd-first-reference.md' || fail "ddd-first lists ddd-first-reference.md"
grep 'ddd-first' skills/using-project-standards/references/mode-standards-copy.md | grep -q 'rails-package-layout.md' || fail "ddd-first lists rails-package-layout.md"
grep 'ddd-first' skills/using-project-standards/references/mode-standards-copy.md | grep -q 'technical-guideline' && fail "ddd-first must not copy technical-guideline"
grep -qE 'entire [`]?ddd/' skills/using-project-standards/references/mode-standards-copy.md && fail "mode-standards-copy must not say entire ddd/"

echo "PASS: project-standards structure"
