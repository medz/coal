import 'scripts/bash.dart';
import 'scripts/powershell.dart';
import 'scripts/zsh.dart';

enum Shell {
  bash(bashScript),
  zsh(zshScript),
  powershell(powershellScript);

  const Shell(this.generate);
  final String Function(String name, String exec) generate;

  void setup(String name, String exec) => print(generate(name, exec));
}
