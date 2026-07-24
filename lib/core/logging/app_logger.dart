abstract interface class AppLogger {
  void trace(String message, {Map<String, Object?> context = const {}});

  void debug(String message, {Map<String, Object?> context = const {}});

  void info(String message, {Map<String, Object?> context = const {}});

  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  });

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  });
}

class NoopAppLogger implements AppLogger {
  const NoopAppLogger();

  @override
  void trace(String message, {Map<String, Object?> context = const {}}) {}

  @override
  void debug(String message, {Map<String, Object?> context = const {}}) {}

  @override
  void info(String message, {Map<String, Object?> context = const {}}) {}

  @override
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}
}
