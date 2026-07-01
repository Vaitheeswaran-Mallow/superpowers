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
cp "<fork>/templates/project/docs/contexts/_template.md" "docs/contexts/${CONTEXT}.md"
```

`<fork>` = superpowers plugin/fork root on disk (same source used for standards and rules copy).

## Zeitwerk

If `config/initializers/zeitwerk.rb` missing, copy from `<fork>/templates/project/config/initializers/zeitwerk.rb`.

## Glossary

For each bounded context, create `docs/contexts/<context>.md`:

1. **Preferred:** copy from `<fork>/templates/project/docs/contexts/_template.md` (see command above).
2. **Fallback:** if the fork path is unavailable in the app repo, create the file with the same section headings as that template (Overview, Terms, Aggregates, Published events, Relationships).

Replace the `# <Context name>` placeholder with the actual context name.
