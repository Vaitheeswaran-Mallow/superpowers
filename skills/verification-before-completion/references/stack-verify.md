# Stack verify command

If `docs/TECH_STACK.md` exists in the project repo, read the **Verify command** field and run that command as the primary done gate.

| stack | Typical command |
|-------|-----------------|
| rails8 | `bin/ci` |
| node-api | `npm test` |
| generic | value from TECH_STACK |

Profile-scaled fitness tests are optional; default gates still apply.
