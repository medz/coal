# Tab Script Maintenance Guide

This guide describes how to sync upstream completion scripts and validate TAB behavior safely.

## Sync Policy

- Only sync completion scripts from **upstream released tags**.
- Do not sync from upstream `main`/development branches.
- Keep upstream metadata comments in each script file:
  - repository
  - source file
  - release tag/date
  - tag commit
  - sync time (UTC)

Current script files:
- `lib/src/tab/scripts/bash.dart`
- `lib/src/tab/scripts/zsh.dart`
- `lib/src/tab/scripts/fish.dart`
- `lib/src/tab/scripts/powershell.dart`

## Sync Workflow

1. Check latest released upstream version (`spf13/cobra`).
2. Compare upstream script sources against local script templates.
3. Port upstream changes into local Dart script generators.
4. Update upstream metadata comment block in each script file.
5. Run local checks (see next section).
6. Open a PR with only script + test/CI updates for review.

## Local Validation Commands

Run these before opening or merging a TAB sync PR:

```bash
dart analyze
dart test --exclude-tags=script-runtime
COAL_REQUIRED_SHELLS=bash,zsh dart test --tags=script-runtime
```

Optional strict runtime checks (if local environment supports all shells):

```bash
COAL_REQUIRED_SHELLS=bash,zsh,fish,pwsh dart test --tags=script-runtime
```

## CI Workflows

- `ci.yml`: formatting, static analysis, default tests (excluding `script-runtime`).
- `tab-script-runtime.yml`: runtime/script checks on CI runners.
  - Ubuntu + Windows run on PR/push.
  - macOS runs on weekly schedule.
- `upstream-cobra-watch.yml`: weekly upstream release watch and issue update/create.

## Troubleshooting

- Formatting check fails:
  - Run `dart format --output=none --set-exit-if-changed .` locally and commit formatting updates.
- `script-runtime` fails on CI due missing shell:
  - Verify `COAL_REQUIRED_SHELLS` matches the runner's intended shell matrix.
- PowerShell parser errors:
  - Validate generated script syntax with:
    - `pwsh -NoProfile -NonInteractive -File <script.ps1>`
  - Re-check upstream parity for powershell template blocks.
- Duplicate upstream watch issues:
  - Confirm `upstream-cobra-watch.yml` marker and issue title logic remain unchanged.
