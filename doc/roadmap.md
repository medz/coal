# Coal Shape

Coal is a small Dart toolkit for building Dart CLIs. It is not a command
framework. Each module must stay independently useful, small enough to audit,
and easy to test without a real terminal unless the feature truly needs one.

## Layers

| Layer | Modules | Rule |
| --- | --- | --- |
| Core | Args, Utils, Tab | Supported now. Keep API stable and dependency-light. |
| Terminal input | Keypass, Readline | Supported as small parsing and editing primitives without global side effects. |
| Prompt | Prompt, Prompt Utils | Build on Keypass/Readline after their contracts are clear. |
| Coal CLI | `coal` executable | Only maintenance/setup commands, not a general app framework. |

## Current Public Surface

| Module | Public entrypoint | Status | Supported use |
| --- | --- | --- | --- |
| Args | `package:coal/args.dart` | Supported | Lightweight parsing for scripts and custom CLI plumbing. |
| Utils | `package:coal/utils.dart` | Supported | ANSI escape helpers, VT stripping, text width, wrapping, and styling. |
| Tab | `package:coal/tab.dart` | Supported | Completion definitions and shell script generation for Bash, Zsh, Fish, and PowerShell. |
| Args adapter | `package:coal/tab/args.dart` | Supported | Completion wiring for `package:args` `CommandRunner` apps. |
| Keypass | `package:coal/keypass.dart` | Supported | Terminal key decoding, stateful byte parsing, and binding dispatch without owning stdin. |
| Readline | `package:coal/readline.dart` | Supported | Line buffer, cursor editing, history navigation, and Keypass input application without owning stdin. |

## Issue Map

| Issue | Decision |
| --- | --- |
| #11 Tab maintenance docs | Implement as a short maintainer guide. |
| #16 Dart CLI completion setup | Implement through the Coal CLI. Start with script generation before shell-specific install automation. |
| #12 Keypass | Implemented as small key decoding, stateful parsing, and binding dispatch primitives. No raw-mode or stdin ownership in the core API. |
| #13 Readline | Implemented as a testable line editing core built on Keypass input types. No stdin/raw-mode ownership. |
| #14 Prompt | Defer until Readline has a stable editing contract. |
| #15 Prompt Utils | Defer until Prompt exists; utilities must prove repeated real use. |
| #2 Dependency dashboard | Keep Renovate-managed; no product work unless dependencies are stale or blocking. |

## Coal CLI

The `coal` executable should stay narrow:

- `coal complete <shell>` prints completion for the `coal` executable.
- `coal dart-complete <shell>` prints completion for the `dart` command.
- `coal doctor` reports local shell support for completion/runtime tests.

It should not create project scaffolds, own command routing for user apps, or
duplicate package managers.

## Readiness Gates

Run these before publishing or merging release-oriented changes:

```bash
dart format --output=none --set-exit-if-changed .
dart analyze
dart test --exclude-tags=script-runtime
dart test --tags=script-runtime
dart pub publish --dry-run
```

Feature slices need focused tests at their layer boundary. Do not add a module
without a public entrypoint, README/example coverage, and regression tests for
the terminal behavior it claims to support.
