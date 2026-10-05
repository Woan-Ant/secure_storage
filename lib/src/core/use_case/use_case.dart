import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:secure_storage/src/core/error/app_failure.dart';

/// {@template use_case}
/// A single application operation.
///
/// [T] is what the operation produces on success and [P] is the parameter
/// object it consumes. Implementations never throw: everything is reported
/// through the [Failure] side of the returned [Either].
/// {@endtemplate}
// This is an interface implemented by every use case, not a helper waiting to
// become a function.
abstract class UseCase<T, P> {
  /// {@macro use_case}
  Future<Either<Failure, T>> call({required P param});
}

/// {@template param}
/// Base type for use case parameters.
/// {@endtemplate}
abstract class Param extends Equatable {
  /// {@macro param}
  const new();

  @override
  List<Object?> get props => [];
}

/// {@template no_param}
/// Parameter for use cases that take no input, such as
/// `ListEncryptedKeysUseCase`.
/// {@endtemplate}
class NoParam extends Param {
  /// {@macro no_param}
  const new();
}
