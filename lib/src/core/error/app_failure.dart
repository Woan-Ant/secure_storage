import 'package:equatable/equatable.dart';

/// {@template failure}
/// Base type for every recoverable error surfaced by this package.
///
/// A [Failure] is what a `Left` value carries out of the repository and
/// use case layers. It is a plain value object — it is never thrown — so it can
/// be pattern matched, compared and rendered by the presentation layer.
///
/// Each failure is identified by a [prefix] (the subsystem that produced it,
/// such as `HIVE`) and a [code] that is unique within that subsystem.
/// {@endtemplate}
abstract class Failure extends Equatable {
  /// {@macro failure}
  const Failure({
    required this.prefix,
    required this.code,
    required this.message,
  });

  /// The subsystem that produced this failure, such as `HIVE`.
  final String prefix;

  /// Identifier of this failure, unique within [prefix].
  final String code;

  /// Human readable description of what went wrong.
  final String message;

  /// Returns a copy of this failure carrying a different [message].
  ///
  /// Useful for localising or contextualising a failure without losing its
  /// type, [prefix] or [code].
  Failure updateMessage({required String message});

  @override
  List<Object?> get props => [prefix, code, message];

  @override
  String toString() => '$prefix-$code: $message';
}

/// {@template unhandled_failure}
/// Fallback failure for errors this package does not model explicitly.
/// {@endtemplate}
class UnhandledFailure extends Failure {
  /// {@macro unhandled_failure}
  const UnhandledFailure({
    required super.message,
    super.prefix = 'UNHANDLED',
    super.code = '000',
  });

  @override
  Failure updateMessage({required String message}) =>
      UnhandledFailure(prefix: prefix, code: code, message: message);
}
