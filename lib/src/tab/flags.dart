extension type const ShellCompleteDirective._(int _) {
  static const none = ShellCompleteDirective._(0);
  static const error = ShellCompleteDirective._(1 << 0);
  static const noSpace = ShellCompleteDirective._(1 << 1);
  static const noFileCompletion = ShellCompleteDirective._(1 << 2);
  static const filterFileExtension = ShellCompleteDirective._(1 << 3);
  static const filterDirectory = ShellCompleteDirective._(1 << 4);
  static const keepOrder = ShellCompleteDirective._(1 << 5);
  static const maxValue = ShellCompleteDirective._(1 << 6);
}
