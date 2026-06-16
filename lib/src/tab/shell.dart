import 'scripts/bash.dart';
import 'scripts/fish.dart';
import 'scripts/powershell.dart';
import 'scripts/zsh.dart';

enum Shell {
  bash(bashScript),
  fish(fishScript),
  powershell(powershellScript),
  zsh(zshScript);

  const Shell(this.generate);

  /// Generates a completion script for [name].
  ///
  /// [exec] is the command used to invoke the completion provider.
  /// [completionCommand] is appended after [exec] before the active shell words.
  /// The default matches Coal's completion protocol: `$exec complete -- ...`.
  final String Function(String name, String exec, {String completionCommand})
  generate;
}
