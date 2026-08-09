import 'package:secure_storage/src/core/error/app_failure.dart';

/// {@template app_exception}
/// Base type for every exception thrown by the service layer.
///
/// Exceptions travel up from `SecureStorageImpl` and are converted into a
/// [Failure] by the repository layer via [toFailure], so callers of the
/// repository and use cases never have to catch anything.
/// {@endtemplate}
abstract class AppException implements Exception {
  /// {@macro app_exception}
  AppException({
    this.prefix = 'APP',
    this.code = '000',
    this.message = 'An unexpected error occurred.',
  });

  /// The subsystem that produced this exception, such as `HIVE`.
  final String prefix;

  /// Identifier of this exception, unique within [prefix].
  final String code;

  /// Human readable description of what went wrong.
  final String message;

  /// Converts this exception into its matching [Failure] value.
  Failure toFailure();

  @override
  String toString() => '$prefix-$code: $message';
}

/// {@template unhandled_exception}
/// Wraps an error this package does not model explicitly so it can still be
/// converted into a [Failure] instead of escaping to the caller.
/// {@endtemplate}
class UnhandledException extends AppException {
  /// {@macro unhandled_exception}
  UnhandledException({
    super.prefix = 'UNHANDLED',
    super.code = '000',
    super.message,
  });

  @override
  Failure toFailure() => UnhandledFailure(message: message);
}
