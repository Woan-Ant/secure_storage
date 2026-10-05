import 'package:secure_storage/src/core/error/app_failure.dart';

/// {@template hive_write_failure}
/// Writing an entry into a Hive box failed. `HIVE-001`.
/// {@endtemplate}
class HiveWriteFailure extends Failure {
  /// {@macro hive_write_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      HiveWriteFailure(prefix: prefix, code: code, message: message);
}

/// {@template hive_wipe_failure}
/// Data was already wiped from Hive and a second wipe was attempted.
/// `HIVE-002`.
/// {@endtemplate}
class HiveWipeFailure extends Failure {
  /// {@macro hive_wipe_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      HiveWipeFailure(prefix: prefix, code: code, message: message);
}

/// {@template hive_read_failure}
/// Reading an entry from a Hive box failed. `HIVE-003`.
/// {@endtemplate}
class HiveReadFailure extends Failure {
  /// {@macro hive_read_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      HiveReadFailure(prefix: prefix, code: code, message: message);
}

/// {@template open_failure}
/// A Hive box could not be opened. `HIVE-004`.
///
/// For an encrypted box this usually means the key in the platform keystore is
/// missing or does not match the box on disk.
/// {@endtemplate}
class OpenFailure extends Failure {
  /// {@macro open_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      OpenFailure(prefix: prefix, code: code, message: message);
}

/// {@template close_failure}
/// A Hive box could not be closed. `HIVE-005`.
/// {@endtemplate}
class CloseFailure extends Failure {
  /// {@macro close_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      CloseFailure(prefix: prefix, code: code, message: message);
}

/// {@template hive_delete_box_failure}
/// A Hive box could not be deleted from disk. `HIVE-006`.
/// {@endtemplate}
class HiveDeleteBoxFailure extends Failure {
  /// {@macro hive_delete_box_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      HiveDeleteBoxFailure(prefix: prefix, code: code, message: message);
}

/// {@template hive_delete_data_failure}
/// An entry could not be deleted from a Hive box. `HIVE-007`.
/// {@endtemplate}
class HiveDeleteDataFailure extends Failure {
  /// {@macro hive_delete_data_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      HiveDeleteDataFailure(prefix: prefix, code: code, message: message);
}

/// {@template hive_box_not_empty_failure}
/// A box was expected to be empty but still holds entries. `HIVE-008`.
/// {@endtemplate}
class HiveBoxNotEmptyFailure extends Failure {
  /// {@macro hive_box_not_empty_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      HiveBoxNotEmptyFailure(prefix: prefix, code: code, message: message);
}

/// {@template box_encrypted_failure}
/// An encrypted box was about to be opened without its key. `HIVE-009`.
/// {@endtemplate}
class BoxEncryptedFailure extends Failure {
  /// {@macro box_encrypted_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      BoxEncryptedFailure(prefix: prefix, code: code, message: message);
}

/// {@template data_does_not_exist_failure}
/// The requested entry is not present. `SECURE STORAGE-001`.
/// {@endtemplate}
class DataDoesNotExistFailure extends Failure {
  /// {@macro data_does_not_exist_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      DataDoesNotExistFailure(prefix: prefix, code: code, message: message);
}

/// {@template fss_write_failure}
/// Writing a box key to Flutter Secure Storage failed.
/// `FLUTTER SECURE STORAGE-001`.
/// {@endtemplate}
class FSSWriteFailure extends Failure {
  /// {@macro fss_write_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      FSSWriteFailure(prefix: prefix, code: code, message: message);
}

/// {@template fss_read_failure}
/// Reading a box key from Flutter Secure Storage failed.
/// `FLUTTER SECURE STORAGE-002`.
/// {@endtemplate}
class FSSReadFailure extends Failure {
  /// {@macro fss_read_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      FSSReadFailure(prefix: prefix, code: code, message: message);
}

/// {@template fss_not_found_failure}
/// No key for the box exists on this device.
/// `FLUTTER SECURE STORAGE-003`.
/// {@endtemplate}
class FSSNotFoundFailure extends Failure {
  /// {@macro fss_not_found_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      FSSNotFoundFailure(prefix: prefix, code: code, message: message);
}

/// {@template fss_delete_failure}
/// Deleting a box key from Flutter Secure Storage failed.
/// `FLUTTER SECURE STORAGE-004`.
/// {@endtemplate}
class FSSDeleteFailure extends Failure {
  /// {@macro fss_delete_failure}
  const new({
    required super.prefix,
    required super.code,
    required super.message,
  });

  @override
  Failure updateMessage({required String message}) =>
      FSSDeleteFailure(prefix: prefix, code: code, message: message);
}
