extension type const ShellCompDirective._(int _) {
  static const none = ShellCompDirective._(0);
  static const error = ShellCompDirective._(1 << 0);
  static const noSpace = ShellCompDirective._(1 << 1);
  static const noFileComp = ShellCompDirective._(1 << 2);
  static const filterFileExt = ShellCompDirective._(1 << 3);
  static const filterDirs = ShellCompDirective._(1 << 4);
  static const keepOrder = ShellCompDirective._(1 << 5);
  static const maxValue = ShellCompDirective._(1 << 6);
}
