part of 'demo_storage_bloc.dart';

/// Base type for every state the demo page renders.
sealed class DemoStorageState extends Equatable {
  const DemoStorageState();

  @override
  List<Object?> get props => [];
}

/// Nothing has been asked of storage yet.
final class DemoStorageInitial extends DemoStorageState {
  /// Creates a [DemoStorageInitial].
  const DemoStorageInitial();
}

/// An operation is in flight.
final class DemoStorageLoading extends DemoStorageState {
  /// Creates a [DemoStorageLoading].
  const DemoStorageLoading();
}

/// The existence check completed.
final class DemoCheckDataSuccess extends DemoStorageState {
  /// Creates a [DemoCheckDataSuccess].
  const DemoCheckDataSuccess({required this.checker});

  /// Whether the entry exists, and whether its box is encrypted.
  final ({bool exist, bool? encrypted}) checker;

  @override
  List<Object?> get props => [checker.exist, checker.encrypted];
}

/// A value was written.
final class DemoStoreDataSuccess extends DemoStorageState {
  /// Creates a [DemoStoreDataSuccess].
  const DemoStoreDataSuccess({required this.message});

  /// Confirmation text from the repository.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// A value was read.
final class DemoGetDataSuccess extends DemoStorageState {
  /// Creates a [DemoGetDataSuccess].
  const DemoGetDataSuccess({required this.data});

  /// The value that was stored.
  final Object data;

  @override
  List<Object?> get props => [data];
}

/// A value was deleted.
final class DemoDeleteDataSuccess extends DemoStorageState {
  /// Creates a [DemoDeleteDataSuccess].
  const DemoDeleteDataSuccess({required this.message});

  /// Confirmation text from the repository.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// The encrypted box names were listed.
final class DemoListEncryptedKeysSuccess extends DemoStorageState {
  /// Creates a [DemoListEncryptedKeysSuccess].
  const DemoListEncryptedKeysSuccess({required this.keys});

  /// Box name to stored encryption key. Never render these values.
  final Map<String, String> keys;

  @override
  List<Object?> get props => [keys];
}

/// The unencrypted box names were listed.
final class DemoListUnencryptedKeysSuccess extends DemoStorageState {
  /// Creates a [DemoListUnencryptedKeysSuccess].
  const DemoListUnencryptedKeysSuccess({required this.keys});

  /// Names of the boxes on disk with no encryption key.
  final List<dynamic> keys;

  @override
  List<Object?> get props => [keys];
}

/// An operation failed.
final class DemoStorageError extends DemoStorageState {
  /// Creates a [DemoStorageError].
  ///
  /// Takes [failure] positionally so it can be used as a tear-off when folding
  /// an `Either`.
  const DemoStorageError(this.failure);

  /// What went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
