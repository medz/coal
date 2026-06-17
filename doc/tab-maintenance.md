# TAB Maintenance

This page documents how Coal tracks upstream Cobra completion behavior and how
maintainers validate changes to `package:coal/tab.dart`.

## Upstream Sync Policy

Coal's shell completion scripts are Dart ports of Cobra completion scripts. The
tracked upstream source is recorded at the top of each script file:

| Coal file | Upstream source |
| --- | --- |
| `lib/src/tab/scripts/bash.dart` | `bash_completionsV2.go` |
| `lib/src/tab/scripts/zsh.dart` | `zsh_completions.go` |
| `lib/src/tab/scripts/fish.dart` | `fish_completions.go` |
| `lib/src/tab/scripts/powershell.dart` | `powershell_completions.go` |

Sync only from upstream Cobra release tags. Do not sync from `main` or
development branches. When a script is updated, keep its metadata comment in
sync with the reviewed upstream release tag, release date, tag commit, source
file, and sync time.

The weekly `Upstream Cobra Watch` workflow compares the local tracked release
tag in `lib/src/tab/scripts/bash.dart` with the latest Cobra release. When a
newer release exists, it opens or updates an issue labeled
`upstream-cobra-watch`.

Recommended sync flow:

1. Review the upstream release notes and the four source files listed above.
2. Port only the completion behavior that applies to Coal's script model.
3. Preserve Coal's command execution safety guarantees: generated scripts must
   treat executable paths, completion words, and flag values as data.
4. Update the metadata comments in every touched script file.
5. Update script goldens only after inspecting the generated diff.
6. Run the local test matrix below before opening a PR.

## Local Test Matrix

Run the full non-runtime gate for ordinary changes:

```bash
dart format --output=none --set-exit-if-changed .
dart analyze
dart test --exclude-tags=script-runtime
```

Run TAB contract coverage when `lib/src/tab`, `lib/tab`, or `test/tab` changes:

```bash
dart test --exclude-tags=script-runtime test/tab
```

Run shell runtime tests when script generation changes:

```bash
dart test --tags=script-runtime
```

Runtime tests execute only shells available on the current machine. To require
specific shells and fail if one is missing:

```bash
COAL_REQUIRED_SHELLS=bash,zsh,fish,pwsh dart test --tags=script-runtime
```

If script output intentionally changes, regenerate goldens and inspect the diff:

```bash
COAL_UPDATE_GOLDENS=true dart test test/tab/golden_test.dart
git diff -- test/tab/goldens
```

Before publishing a release, run:

```bash
dart pub publish --dry-run
```

## CI Coverage

The CI workflows split TAB validation by risk:

| Workflow | Purpose |
| --- | --- |
| `CI` | Formatting, analysis, and non-runtime tests for every PR and main push. |
| `Tab Contract` | Path-filtered non-runtime TAB tests for script contracts, parser behavior, and goldens. |
| `Tab Script Runtime` | Runtime shell checks on Linux and Windows for PRs and main pushes; weekly macOS runtime coverage. |
| `Upstream Cobra Watch` | Weekly upstream Cobra release detection and issue management. |

The default runtime matrix requires `bash,zsh,fish,pwsh` on Ubuntu and `pwsh` on
Windows. The scheduled macOS job requires `bash,zsh`.

## Troubleshooting

- Golden mismatch: inspect the failing `test/tab/goldens` diff. Regenerate with
  `COAL_UPDATE_GOLDENS=true` only when the script behavior change is intended.
- Missing runtime shell: install the shell locally, or set
  `COAL_REQUIRED_SHELLS` to the shells that must be present for the run.
- Bash completion errors: verify the generated script can access
  `_get_comp_words_by_ref`. Interactive Bash users normally get it from
  `bash-completion`; tests provide their own harness where needed.
- Zsh completion errors: initialize completion with `autoload -Uz compinit` and
  `compinit` before sourcing generated scripts in a shell session.
- PowerShell parser errors: run the generated script with
  `pwsh -NoProfile -NonInteractive -File <script>` before debugging completion
  behavior.
- Upstream watch cannot find the local tag: check the `release tag:` metadata in
  `lib/src/tab/scripts/bash.dart`; the workflow reads that file as the local
  source of truth.
