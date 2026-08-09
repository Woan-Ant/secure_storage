import 'package:flutter/foundation.dart';

/// {@template secure_storage_logger}
/// Sink for the diagnostic output of this package.
///
/// The default is [SilentSecureStorageLogger], which discards everything. Pass
/// [DebugPrintSecureStorageLogger] while developing, or implement this
/// interface to forward the messages to your app's own logger:
///
/// ```dart
/// class MyLogger implements SecureStorageLogger {
///   @override
///   void d(String message) => myLogger.debug(message);
///   // ...
/// }
/// ```
///
/// Implementations must never log secret material. This package deliberately
/// keeps encryption keys and stored values out of every message it emits.
/// {@endtemplate}
abstract class SecureStorageLogger {
  /// {@macro secure_storage_logger}
  const SecureStorageLogger();

  /// Logs a debug message describing an internal step.
  void d(String message);

  /// Logs an informational message about a completed operation.
  void i(String message);

  /// Logs a warning about a degraded or unsupported operation.
  void w(String message);

  /// Logs an error, optionally with the [error] that caused it.
  void e(String message, {Object? error});
}

/// {@template silent_secure_storage_logger}
/// A [SecureStorageLogger] that discards every message.
///
/// This is the default so that the package stays quiet in production.
/// {@endtemplate}
class SilentSecureStorageLogger extends SecureStorageLogger {
  /// {@macro silent_secure_storage_logger}
  const SilentSecureStorageLogger();

  @override
  void d(String message) {}

  @override
  void i(String message) {}

  @override
  void w(String message) {}

  @override
  void e(String message, {Object? error}) {}
}

/// {@template debug_print_secure_storage_logger}
/// A [SecureStorageLogger] that forwards to [debugPrint] in debug builds only.
/// {@endtemplate}
class DebugPrintSecureStorageLogger extends SecureStorageLogger {
  /// {@macro debug_print_secure_storage_logger}
  const DebugPrintSecureStorageLogger();

  void _log(String level, String message) {
    if (kDebugMode) {
      debugPrint('[secure_storage] $level $message');
    }
  }

  @override
  void d(String message) => _log('DEBUG', message);

  @override
  void i(String message) => _log('INFO ', message);

  @override
  void w(String message) => _log('WARN ', message);

  @override
  void e(String message, {Object? error}) =>
      _log('ERROR', error == null ? message : '$message => $error');
}
