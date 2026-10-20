# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`lutaml-jsonschema` parses JSON Schema documents into lutaml-model objects and generates a single-file SPA documentation site from them. It has two halves that must stay in sync:

1. **Ruby gem** (`lib/lutaml/jsonschema/`) — the JSON Schema model and documentation generator.
2. **Vue 3 frontend** (`frontend/`) — the SPA itself. The built bundle (`frontend/dist/app.iife.js` + `style.css`) gets inlined into a standalone `index.html`.

## Commands

```sh
bundle exec rspec                          # full suite
bundle exec rspec spec/lutaml/cli_spec.rb  # one file
bundle exec rspec spec/lutaml/cli_spec.rb:76  # one example
bundle exec rubocop                        # lint (-a to autofix; .rubocop_todo.yml holds baselined offenses)
bundle exec rake                           # spec + rubocop (what CI runs)

bundle exec rake frontend:build            # npm install + vite build → frontend/dist
cd frontend && npm test                    # vitest (frontend unit tests)

bundle exec exe/lutaml-jsonschema spa SCHEMA_FILES... [--diff BASELINE...]
bundle exec exe/lutaml-jsonschema combine|validate SCHEMA_FILES...
bundle exec exe/lutaml-jsonschema export SCHEMA_FILES... -f cddl|openapi|xsd|adoc
bundle exec exe/lutaml-jsonschema diff OLD NEW [--format json]
```

`frontend/dist/` and `Gemfile.lock` are gitignored. `frontend/dist/` must exist (run `rake frontend:build`) for the `spa` command and for packaging — the gemspec ships it via `Dir.glob("frontend/dist/*")`.

## Architecture

Data flow: schema files → `SchemaSet.load_from_files` → `Spa::SpaBuilder` → `Spa::SpaDocument` → `to_json` → `Spa::VueInlinedStrategy` (embeds `window.SCHEMA_DATA` + inlined JS/CSS into `index.html`).

- **`Base`** — everything inherits from `Lutaml::Model::Serializable`. `Base` also forward-declares `Schema` to break the circular `Schema ↔ PropertyEntry ↔ Link` references.
- **`Schema`** — the central model of a JSON Schema document. Every `$`-prefixed keyword is a `dollar_`-prefixed attribute (`$schema` → `dollar_schema`) via json mappings. `Schema.from_json` / `to_json` are lutaml-model serialization.
- **`SchemaSet`** — in-memory named collection of schemas plus `$ref` resolution (local `#/...` pointers and relative `./file.json` refs through `ReferenceResolver`) and validation.
- **`SchemaStore`** — `SchemaSet` subclass that adds on-disk persistence through **lutaml-store** (`PackageStore`, package shape from `LjrPackageDefinition`).
- **`Combiner`** — compatibility facade; bundling lives in `SchemaSet#bundle` (hoists definitions, adds a top-level `$ref` property per source schema, rewrites `#/definitions/` → `#/$defs/`).
- **`Spa::*`** — `SpaBuilder` flattens a `SchemaSet` into a `SpaDocument` (metadata, `SpaSchema` list, flat `search_index` for FlexSearch). `Spa::Generator` renders through an `OutputStrategy`; `VueInlinedStrategy` is the only implementation.
- **`Configuration`** — YAML config for the SPA (title, theme, appearance…), loaded by `Cli#spa -c`.
- **`Cli`** — Thor commands: `spa` (generate docs; `--diff` embeds a classified change set), `combine` (merge schemas), `export` (cddl/openapi/xsd/adoc), `diff` (exits 1 on breaking changes), `validate` (meta-schema checks), `version`.
- **`TupleItem`** — schema-or-boolean wrapper used by `items`/`prefixItems` arrays and composition collections; models that accept `true`/`false` store booleans in companion `*_boolean` attributes and expose `*_value` helpers.

## JSON engine: yeptris

Two distinct paths, both engine-backed:

- **Direct parsing** in this gem (`Cli#combine`, `Cli#validate`, `Schema.serialize_additional_properties`) uses `Yeptris::JSON.load` — strict RFC 8259, exact-`JSON.parse` semantics, raises `Yeptris::JSON::ParseError`. JSON **generation** stays on the stdlib `json` gem (`JSON.pretty_generate`); yeptris's JSON surface is load-only.
- **Model serialization** (`Schema.from_json`/`to_json`, `Configuration.from_yaml`, lutaml-store I/O) goes through lutaml-model, whose `AdapterResolver` auto-detects yeptris from the bundle and routes both `:json` and `:yaml` to its `YeptrisAdapter`. That adapter re-raises parse failures as `JSON::ParserError`, so error handling must cover **both** exception types — see the rescue in `Cli#validate`.
- Raw-parse speed depends on the resolved yeptris build shipping a **native materializer for the running Ruby version**; without one it falls back to a pure-Ruby tape engine that is several times slower than `JSON.parse` on large documents (yeptris-ruby#278). Check with `defined?(Yeptris::Native)` (0.6.28.x shipped only Ruby 3.3; 3.4-native starts at 0.6.29.1).
- The GC-pressure SIGSEGV in the native JSON materializer (yeptris-ruby#279) is fixed in the yeptris **0.6.34 line** (staged pairs made GC-visible); the gemspec floors at `~> 0.6.34`, excluding the crashy 0.6.29.x–0.6.33.x native builds. Env-gated canary: yeptris-ruby#280.

## Repo notes

- `README.md` is unreplaced gem-template boilerplate — don't treat it as documentation.
- `TODO.redoc/`, `TODO.refactor/`, `TODO.store/` are untracked, numbered working notes (known gaps and planned refactors), not code. `TODO.sota/` holds the SOTA program (purpose, per-area tasks with done-when criteria, and the goal prompt).
- CI is metanorma/ci's `generic-rake` workflow; releases run through `.github/workflows/release.yml`.
