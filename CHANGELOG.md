## Unreleased

- feat(readline): add interactive line input handling.
- feat(keypass): add terminal key binding dispatch.
- feat(tab): add Dart SDK command completion setup.
- docs(tab): document upstream sync and test strategy.

## 0.0.7 - 2026-06-17

- fix(args): preserve dotted siblings, dotted lists, and empty-input defaults
- fix(utils): correct erase-line and horizontal scroll ANSI sequences
- test(utils): remove network dependency from text-width coverage
- docs: align README and examples with the current public API

## 0.0.6 - 2026-02-06

- fix(tab): harden completion behavior and add regression tests
- chore(tab): sync shell completion scripts from upstream cobra v1.10.2
- ci: add dedicated runtime script workflow and weekly upstream release watcher
- chore(deps): upgrade `oxy` to ^0.1.0

## 0.0.5 - 2026-01-24

- chore: relax characters constraint to ^1.4.0
- chore: move args to dependencies for tab/args.dart
- fix: restore emoji regex in text width
- refactor: rename `coerceRest` to `args`

## 0.0.4

- fix: option handler boolean flag logic
- feat: add `args` package TAB adapter

## 0.0.3

- Coal's core \<TAB\> completion implementation!

## 0.0.2

- Update readme

## 0.0.1

- Args parser
- ANSI utils
