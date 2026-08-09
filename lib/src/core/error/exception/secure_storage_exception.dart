import 'package:secure_storage/src/core/error/app_exception.dart';
import 'package:secure_storage/src/core/error/app_failure.dart';
import 'package:secure_storage/src/core/error/failure/secure_storage_failure.dart';

const String _prefixHive = 'HIVE';
const String _prefixFSS = 'FLUTTER SECURE STORAGE';
const String _prefixSS = 'SECURE STORAGE';

/// {@template hive_write_exception}
/// Thrown when writing an entry into a Hive box fails.
/// {@endtemplate}
class HiveWriteException extends AppException {
  /// {@macro hive_write_exception}
  HiveWriteException({
    super.prefix = _prefixHive,
    super.code = '001',
    super.message = 'Error while storing/writing data in Hive.',
  });

  @override
  Failure toFailure() =>
      HiveWriteFailure(prefix: prefix, code: code, message: message);
}

/// {@template hive_wipe_exception}
/// Thrown when data has already been wiped from Hive and a second wipe is
/// attempted.
/// {@endtemplate}
class HiveWipeException extends AppException {
  /// {@macro hive_wipe_exception}
  HiveWipeException({
    super.prefix = _prefixHive,
    super.code = '002',
    super.message = 'Data already wiped from Hive.',
  });

  @override
  Failure toFailure() =>
      HiveWipeFailure(prefix: prefix, code: code, message: message);
}

/// {@template hive_read_exception}
/// Thrown when reading an entry from a Hive box fails.
/// {@endtemplate}
class HiveReadException extends AppException {
  /// {@macro hive_read_exception}
  HiveReadException({
    super.prefix = _prefixHive,
    super.code = '003',
    super.message = 'Error while reading data from Hive.',
  });

  @override
  Failure toFailure() =>
      HiveReadFailure(prefix: prefix, code: code, message: message);
}

/// {@template hive_open_box_exception}
/// Thrown when a Hive box cannot be opened.
/// {@endtemplate}
class HiveOpenBoxException extends AppException {
  /// {@macro hive_open_box_exception}
  HiveOpenBoxException({
    super.prefix = _prefixHive,
    super.code = '004',
    super.message = 'Error while opening hive box.',
  });

  @override
  Failure toFailure() =>
      OpenFailure(prefix: prefix, code: code, message: message);
}

/// {@template hive_close_box_exception}
/// Thrown when a Hive box cannot be closed.
/// {@endtemplate}
class HiveCloseBoxException extends AppException {
  /// {@macro hive_close_box_exception}
  HiveCloseBoxException({
    super.prefix = _prefixHive,
    super.code = '005',
    super.message = 'Error while closing hive box.',
  });

  @override
  Failure toFailure() =>
      CloseFailure(prefix: prefix, code: code, message: message);
}

/// {@template hive_delete_box_exception}
/// Thrown when a Hive box cannot be deleted from disk.
/// {@endtemplate}
class HiveDeleteBoxException extends AppException {
  /// {@macro hive_delete_box_exception}
  HiveDeleteBoxException({
    super.prefix = _prefixHive,
    super.code = '006',
    super.message = 'Error while deleting hive box from disk.',
  });

  @override
  Failure toFailure() =>
      HiveDeleteBoxFailure(prefix: prefix, code: code, message: message);
}

/// {@template hive_delete_data_exception}
/// Thrown when an entry cannot be deleted from a Hive box.
/// {@endtemplate}
class HiveDeleteDataException extends AppException {
  /// {@macro hive_delete_data_exception}
  HiveDeleteDataException({
    super.prefix = _prefixHive,
    super.code = '007',
    super.message = 'Error while deleting hive data from disk.',
  });

  @override
  Failure toFailure() =>
      HiveDeleteDataFailure(prefix: prefix, code: code, message: message);
}

/// {@template hive_box_not_empty_exception}
/// Thrown when a box was expected to be empty but still holds entries.
/// {@endtemplate}
class HiveBoxNotEmptyException extends AppException {
  /// {@macro hive_box_not_empty_exception}
  HiveBoxNotEmptyException({
    super.prefix = _prefixHive,
    super.code = '008',
    super.message = 'Box is not empty.',
  });

  @override
  Failure toFailure() =>
      HiveBoxNotEmptyFailure(prefix: prefix, code: code, message: message);
}

/// {@template box_encrypted_exception}
/// Thrown when an encrypted box would be opened without its encryption key.
/// {@endtemplate}
class BoxEncryptedException extends AppException {
  /// {@macro box_encrypted_exception}
  BoxEncryptedException({
    super.prefix = _prefixHive,
    super.code = '009',
    super.message =
        '''The box already exists and is encrypted. It cannot be opened without the correct encryption key. Attempting to open it without the key could corrupt the box and result in the loss of all data within it.''',
  });

  @override
  Failure toFailure() =>
      BoxEncryptedFailure(prefix: prefix, code: code, message: message);
}

/// {@template data_does_not_exist_exception}
/// Thrown when neither Hive nor Flutter Secure Storage holds the requested
/// entry.
/// {@endtemplate}
class DataDoesNotExistException extends AppException {
  /// {@macro data_does_not_exist_exception}
  DataDoesNotExistException({
    super.prefix = _prefixSS,
    super.code = '001',
    super.message = 'Data does not exist.',
  });

  @override
  Failure toFailure() =>
      DataDoesNotExistFailure(prefix: prefix, code: code, message: message);
}

/// {@template fss_write_exception}
/// Thrown when a box key cannot be written to Flutter Secure Storage.
/// {@endtemplate}
class FSSWriteException extends AppException {
  /// {@macro fss_write_exception}
  FSSWriteException({
    super.prefix = _prefixFSS,
    super.code = '001',
    super.message =
        'Error while storing/writing data in flutter secure storage.',
  });

  @override
  Failure toFailure() =>
      FSSWriteFailure(prefix: prefix, code: code, message: message);
}

/// {@template fss_read_exception}
/// Thrown when a box key cannot be read from Flutter Secure Storage.
/// {@endtemplate}
class FSSReadException extends AppException {
  /// {@macro fss_read_exception}
  FSSReadException({
    super.prefix = _prefixFSS,
    super.code = '002',
    super.message =
        'Error while getting/reading data from flutter secure storage.',
  });

  @override
  Failure toFailure() =>
      FSSReadFailure(prefix: prefix, code: code, message: message);
}

/// {@template fss_not_found_exception}
/// Thrown when no key for the box exists on this device.
/// {@endtemplate}
class FSSNotFoundException extends AppException {
  /// {@macro fss_not_found_exception}
  FSSNotFoundException({
    super.prefix = _prefixFSS,
    super.code = '003',
    super.message = 'There is no data found in the device.',
  });

  @override
  Failure toFailure() =>
      FSSNotFoundFailure(prefix: prefix, code: code, message: message);
}

/// {@template fss_delete_exception}
/// Thrown when a box key cannot be deleted from Flutter Secure Storage.
/// {@endtemplate}
class FSSDeleteException extends AppException {
  /// {@macro fss_delete_exception}
  FSSDeleteException({
    super.prefix = _prefixFSS,
    super.code = '004',
    super.message = 'Unable to delete data from Flutter Secure Storage.',
  });

  @override
  Failure toFailure() =>
      FSSDeleteFailure(prefix: prefix, code: code, message: message);
}
