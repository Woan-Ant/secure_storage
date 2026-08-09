import 'package:dartz/dartz.dart';
import 'package:secure_storage/src/core/error/app_failure.dart';
import 'package:secure_storage/src/core/param/param_secure_storage.dart';

/// {@template storage_repository}
/// Exception-free view over `SecureStorage`.
///
/// Every method returns an `Either<Failure, T>`: `Left` carries a [Failure]
/// value, `Right` carries the result. Nothing thrown by the service layer
/// escapes this boundary.
/// {@endtemplate}
abstract class StorageRepository {
  /// Reports whether an entry exists, and whether its box is encrypted.
  Future<Either<Failure, ({bool exist, bool? encrypted})>> checkData({
    required ParamCheckData param,
  });

  /// Writes [data] under `param.dataKey`, returning a confirmation message.
  Future<Either<Failure, String>> storeData({
    required ParamStoreData param,
    required Object data,
  });

  /// Reads the entry addressed by [param].
  Future<Either<Failure, Object>> getData({required ParamGetData param});

  /// Deletes the entry addressed by [param], returning a confirmation message.
  Future<Either<Failure, String>> deleteData({required ParamDeleteData param});

  /// Returns every encrypted box name mapped to its stored key.
  Future<Either<Failure, Map<String, String>>> listEncryptedKeys();

  /// Returns the names of the boxes on disk that have no encryption key.
  Future<Either<Failure, List<dynamic>>> listUnencryptedKeys();
}
