# Stack detection

| Signal | Default `stack` | Default verify command |
|--------|-----------------|------------------------|
| `Gemfile` contains `gem "rails"` | `rails8` | `bin/ci` |
| `package.json` dependencies include `express` or `fastify` | `node-api` | `npm test` |
| Neither | `generic` | (human fills in TECH_STACK) |

Read repo root only. Do not guess beyond this table.
