# Coal

A suite for easily building beautiful command-line apps.

> [!WARNING]
> The Coal is still in development and may not be fully functional.

## Modules

| Entry | Description |
|:----:|:----|
| `package:coal/coal.dart` | [**WIP**] Provides functionality for building command-line apps. |
| [`package:coal/args.dart`)(#args-parser) | Provides command-line argument parsing functionality. |
| [`package:coal/utils.dart`](#) | Provides utility functions for ANSI escape codes. |

## Installation

To install the Coal suite, run the following command:

```bash
dart pub add coal
```

## Args Parser

Coal provides a powerful argument parser that allows you to define and parse command-line arguments easily:

```dart
import 'package:coal/args.dart';

final input = const input = ['--a=1','-b','--bool','--no-boop','--multi=foo','--multi=baz','-xyz'];
final args = Args.parse(input);

print(args.toJson());
```
```json
{
  "a": 1,
  "b": true,
  "bool": true,
  "boop": false,
  "multi": ["foo", "baz"],
  "x": true,
  "y": true,
  "z": true
}
```

> [!WARNING]
> Coal is currently under development and documentation is not yet ready.

## ANSI Utility

Coal has prepared a series of convenient tools for generating ANSI:

- **[Cursor](#cursor)**: Generate cursor operation

### Cursor

| Name | Description |
|:----:|:----|
| `cursorUp([int count = 1])` | Move the cursor up by `count` lines. |
| `cursorDown([int count = 1])` | Move the cursor down by `count` lines. |
| `cursorForward([int count = 1])` | Move the cursor forward by `count` columns. |
| `cursorBackward([int count = 1])` | Move the cursor backward by `count` columns. |
| `cursorNextLine([int count = 1])` | Move the cursor to the next line by `count` lines. |
| `cursorPrevLine([int count = 1])` | Move the cursor to the previous line by `count` lines. |
| `cursorTo(int x, [int? y])` | Move the cursor to the specified position. |
| `cursorMove(int x, int y)` | Move the cursor by `x` columns and `y` lines. |
| `cursorShow` | Show the cursor. |
| `cursorHide` | Hide the cursor. |
| `cursorSave` | Save the cursor position. |
| `cursorRestore` | Restore the cursor position. |
| `cursorLeft` | Move the cursor left by one column. |
