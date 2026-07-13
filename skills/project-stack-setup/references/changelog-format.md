# Stack Document Changelog Format

Append one entry per change. Most recent entry at the bottom.

## Entry structure

```
## YYYY-MM-DD — <Human Name>
**Action:** <Initial setup | Added <item> | Removed <item> | Flagged deviation: <item>>
**Drift type:** <N/A | Approved addition | Intentional deviation>
**Detected at:** <N/A | finishing-a-development-branch | verification-before-completion>
**Notes:** <optional context, or — if none>
```

## Examples

```
## 2026-07-13 — Jane Smith
**Action:** Initial setup
**Drift type:** N/A
**Detected at:** N/A
**Notes:** Rails 8, Pragmatic DDD, 3 bounded contexts

## 2026-07-15 — Jane Smith
**Action:** Added `sidekiq` to Libraries & tools
**Drift type:** Approved addition
**Detected at:** finishing-a-development-branch
**Notes:** Background job processing for async report generation

## 2026-07-18 — Jane Smith
**Action:** Flagged deviation: `faraday` (used but not in stack doc)
**Drift type:** Intentional deviation
**Detected at:** verification-before-completion
**Notes:** One-off external call in spike; will revisit in next iteration
```
