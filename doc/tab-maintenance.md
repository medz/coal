# Tab Maintenance

Coal's shell completion templates are adapted from released Cobra sources.
Only sync from upstream release tags, not from main or development branches.

## Sync Steps

1. Compare the tracked Cobra release in `lib/src/tab/scripts/*.dart` with the
   latest upstream Cobra release.
2. Port only relevant changes into the Dart script generators.
3. Update each script file's upstream metadata comment.
4. Run the validation commands below.

## Validation

```bash
dart format --output=none --set-exit-if-changed .
dart analyze
dart test --exclude-tags=script-runtime test/tab
COAL_REQUIRED_SHELLS=bash,zsh dart test --tags=script-runtime
```

Use `COAL_REQUIRED_SHELLS=bash,zsh,fish,pwsh` when all shells are installed.

## CI

- `.github/workflows/tab-contract.yml` checks deterministic script and parse contracts.
- `.github/workflows/tab-script-runtime.yml` checks shell runtime behavior.
- `.github/workflows/upstream-cobra-watch.yml` opens or updates the upstream watch issue.
