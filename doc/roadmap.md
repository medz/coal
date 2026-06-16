# Coal Roadmap

Coal is a small Dart package for CLI utility layers, not a command framework.
The planning boundary is intentionally narrow: keep the current package useful
for existing CLI applications before adding new product areas.

## Real-Use Baseline

Coal is considered usable when these modules are documented, tested, and
publishable together:

| Module | Public entrypoint | Status | Supported use |
| --- | --- | --- | --- |
| Args | `package:coal/args.dart` | Supported | Lightweight parsing for scripts and custom CLI plumbing. |
| Utils | `package:coal/utils.dart` | Supported | ANSI escape helpers, VT stripping, text width, wrapping, and styling. |
| Tab | `package:coal/tab.dart` | Supported | Completion definitions and shell script generation for Bash, Zsh, Fish, and PowerShell. |
| Args adapter | `package:coal/tab/args.dart` | Supported | Completion wiring for `package:args` `CommandRunner` apps. |

## Current Release Goal

The next usable release should focus on stability rather than breadth:

1. Keep public entrypoints small and explicit.
2. Keep shell completion scripts synced with the tracked Cobra release.
3. Keep generated examples reproducible from source instead of checked in as
   binaries.
4. Keep CI green for format, analysis, unit tests, tab contract tests, and
   publish dry-run.
5. Document every public module in the README and examples.

## Deferred Product Areas

These areas remain outside the current package contract until they have a
separate design and test plan:

| Area | Decision |
| --- | --- |
| Key input binding | Defer. It needs terminal mode handling and cross-platform input tests. |
| Readline | Defer. It overlaps with line editing, history, signals, and terminal state. |
| Prompt flows | Defer. It should not be added until Coal has a clear frame-rendering model. |
| Dart CLI setup automation | Defer. Completion for `dart run` and compiled executables needs a precise install story. |

## Readiness Gates

Run these commands before publishing or merging a release-oriented change:

```bash
dart format --output=none --set-exit-if-changed .
dart analyze
dart test --exclude-tags=script-runtime
dart test --tags=script-runtime
dart pub publish --dry-run
```
