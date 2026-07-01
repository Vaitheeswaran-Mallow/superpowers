# DDD package scaffold (after bounded contexts filled)

Run when architecture mode is `ddd-companion` or `ddd-first` and `PROJECT_STACK.md` has context rows.

## Which contexts get a package

| Mode | Scaffold when |
|------|----------------|
| `ddd-first` | Every context row |
| `ddd-companion` | Profile is Pragmatic or Full DDD (not Omakase) |

## Commands (CONTEXT = lowercase context name, e.g. billing)

```bash
mkdir -p "app/domains/${CONTEXT}/domain"
mkdir -p "app/domains/${CONTEXT}/application"
mkdir -p "app/domains/${CONTEXT}/infrastructure/adapters"
mkdir -p "app/domains/${CONTEXT}/interface"
touch "app/domains/${CONTEXT}/domain/.keep"
touch "app/domains/${CONTEXT}/application/.keep"
touch "app/domains/${CONTEXT}/infrastructure/adapters/.keep"
touch "app/domains/${CONTEXT}/interface/.keep"
mkdir -p docs/contexts
cp templates/project/docs/contexts/_template.md "docs/contexts/${CONTEXT}.md"  # from fork paths when in app repo, use fork template at bootstrap
```

## Zeitwerk

If `config/initializers/zeitwerk.rb` missing, copy from `templates/project/config/initializers/zeitwerk.rb`.

## Glossary

Edit each `docs/contexts/<context>.md` — replace placeholder title with context name.
