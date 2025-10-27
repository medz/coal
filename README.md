# Coal

A suite for easily building beautiful command-line apps.

> [!WARNING]
> **Coal is still in development and may not be fully functional.**
>
> Coal is not a CLI framework! It's intended to provide convenient and easy-to-use utilities for existing CLI frameworks and developers.
>
> **Coal also doesn't plan to add command functionality. Its purpose is to enhance existing CLI packages.**

## Modules

| Entry | Status | Description |
|:----:|:----:|:----|
| [`package:coal/args.dart`](#args-parser) | ✅ | Provides command-line argument parsing functionality. |
| [`package:coal/utils.dart`](#ansi-utility) | ✅ | Provides utility functions for ANSI escape codes and text manipulation. |
| [`package:coal/tab.dart`](#tab) | 🚧 | Provides shell command completion and command-line app adapters. |

## Roadmap

- [x] [Args: Command-line argument parsing](#args-parser)
- [x] [Utils: ANSI utility functions](#ansi-utility)
- [ ] Keypass: Key input binding
- [ ] Readline: Input handling
- [ ] Prompt: Basic prompt process support and CLI frame handling
- [ ] Prompt Utils: Advanced commonly used prompt utilities
- [x] Tab: Shell command autocompletion
- [ ] Tab Adapters: Tab completion adapters for popular Dart CLI packages
- [ ] Dart CLI setup: Add completion to `dart` command


## Installation

To install the Coal suite, run the following command:

```bash
dart pub add coal
```

## \<TAB\>

<video src="https://github.com/user-attachments/assets/3a298e80-a3d9-4d26-82f5-349eee4650f5" width="640"></video>

### Core

Coal's core \<TAB\> completion implementation allows you to add completion functionality to any Dart command-line app:

```dart
final tab = Tab();
final complete = tab.command('complete', '<TAB> autocompletion');

complete.argument('shell', (complete, _) {
  complete('bash', 'Setup bash shell completion');
  complete('zsh', 'Setup zsh shell completion');
  complete('fish', 'Setup fish shell completion');
  complete('powershell', 'Setup powershell shell completion');
});
```

There is a simple TAB demo → [\<TAB\> example](example/README.md#tab)

> Thanks to [Cobra](https://github.com/spf13/cobra)! for the script and some of the <TAB> implementation references!

<TAB> completion functionality

## Args Parser

Coal provides a powerful argument parser that allows you to define and parse command-line arguments easily:

```dart
import 'package:coal/args.dart';

const input = ['--a=1','-b','--bool','--no-boop','--multi=foo','--multi=baz','-xyz'];
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

Coal provides a series of convenient utilities for generating ANSI escape codes:

- **[Clear](#clear)**: Clear screen utilities.
- **[Cursor](#cursor)**: Cursor manipulation utilities.
- **[Erase](#erase)**: Text erasing utilities.
- **[Scroll](#scroll)**: Screen scrolling utilities.
- **[Text](#text)**: Text styling and manipulation utilities.

### Clear

| Name | Description |
|:----:|:----|
| `clearScreen()` | Clear the terminal screen. |

### Cursor

| Name | Description |
|:----:|:----|
| `cursorUp()` | Move the cursor up by `count` lines. |
| `cursorDown()` | Move the cursor down by `count` lines. |
| `cursorForward()` | Move the cursor forward by `count` columns. |
| `cursorBackward()` | Move the cursor backward by `count` columns. |
| `cursorNextLine()` | Move the cursor to the next line by `count` lines. |
| `cursorPrevLine()` | Move the cursor to the previous line by `count` lines. |
| `cursorTo()` | Move the cursor to the specified position. |
| `cursorMove()` | Move the cursor by `x` columns and `y` lines. |
| `cursorShow` | Show the cursor. |
| `cursorHide` | Hide the cursor. |
| `cursorSave` | Save the cursor position. |
| `cursorRestore` | Restore the cursor position. |
| `cursorLeft` | Move the cursor left by one column. |

### Erase

| Name | Description |
|:----:|:----|
| `eraseScreen` | Erase the entire screen. |
| `eraseLine` | Erase the current line. |
| `eraseLineStart` | Erase from the current cursor position to the beginning of the line. |
| `eraseLineEnd` | Erase from the current cursor position to the end of the line. |
| `eraseUp()` | Erase `count` lines above the current cursor position. |
| `eraseDown()` | Erase `count` lines below the current cursor position. |
| `eraseLines()` | Erase `count` lines above and below the current cursor position. |

### Scroll

| Name | Description |
|:----:|:----|
| `scrollUp()` | Scroll the screen up by `count` lines. |
| `scrollDown()` | Scroll the screen down by `count` lines. |
| `scrollLeft()` | Scroll the screen left by `count` columns. |
| `scrollRight()` | Scroll the screen right by `count` columns. |

### Text

- `stripVTControlCharacters()`: Remove all VT control characters. Use to estimate displayed string width.
- `getTextTruncatedWidth()`: Get the width of a string when truncated to fit within a given width.
- `getTextWidth()`: Get the width of a string.
- `wrapAnsi()`: Wrap a string to fit within a given width.
- `styleText()`: Generate a string with ANSI escape codes for styling.

#### Style Text

```dart
// Dart SDK >= 3.10.0
final text = styleText('Hello, World!', [.red]);
// <= 3.10.0
final text = styleText('Hello, World!', [TextStyle.red]);
```

## License

[MIT License](LICENSE)
