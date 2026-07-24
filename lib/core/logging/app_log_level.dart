enum AppLogLevel {
  trace,
  debug,
  info,
  warning,
  error;

  bool allows(AppLogLevel level) => level.index >= index;
}
