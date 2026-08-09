part of 'demo_storage_bloc.dart';

/// Base type for everything the demo page can ask the bloc to do.
sealed class DemoStorageEvent extends Equatable {
  const DemoStorageEvent();

  @override
  List<Object> get props => [];
}

/// Asks whether an entry exists and whether its box is encrypted.
final class DemoCheckDataEvent extends DemoStorageEvent {
  /// {@macro demo_check_data_event}
  const DemoCheckDataEvent({required this.param});

  /// Addresses the entry to test.
  final ParamCheckData param;

  @override
  List<Object> get props => [param];
}

/// Writes [data] into storage.
final class DemoStoreDataEvent extends DemoStorageEvent {
  /// Creates a [DemoStoreDataEvent].
  const DemoStoreDataEvent({required this.param, required this.data});

  /// Addresses where to write, and whether to encrypt a new box.
  final ParamStoreData param;

  /// The value to write.
  final Object data;

  @override
  List<Object> get props => [param, data];
}

/// Reads an entry from storage.
final class DemoGetDataEvent extends DemoStorageEvent {
  /// Creates a [DemoGetDataEvent].
  const DemoGetDataEvent({required this.param});

  /// Addresses the entry to read.
  final ParamGetData param;

  @override
  List<Object> get props => [param];
}

/// Deletes an entry from storage.
final class DemoDeleteDataEvent extends DemoStorageEvent {
  /// Creates a [DemoDeleteDataEvent].
  const DemoDeleteDataEvent({required this.param});

  /// Addresses the entry to delete.
  final ParamDeleteData param;

  @override
  List<Object> get props => [param];
}

/// Lists every encrypted box name held in the platform keystore.
final class DemoListEncryptedKeysEvent extends DemoStorageEvent {
  /// Creates a [DemoListEncryptedKeysEvent].
  const DemoListEncryptedKeysEvent();
}

/// Lists the box names on disk that have no encryption key.
final class DemoListUnencryptedKeysEvent extends DemoStorageEvent {
  /// Creates a [DemoListUnencryptedKeysEvent].
  const DemoListUnencryptedKeysEvent();
}
