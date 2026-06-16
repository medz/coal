import 'dart:io';

import 'package:coal/src/cli/cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCoal(args);
}
