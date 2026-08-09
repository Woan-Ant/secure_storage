import 'package:dartz/dartz.dart';
import 'package:secure_storage/src/core/error/app_exception.dart';
import 'package:secure_storage/src/core/error/app_failure.dart';
import 'package:secure_storage/src/core/error/exception/secure_storage_exception.dart';
import 'package:secure_storage/src/core/param/param_secure_storage.dart';
import 'package:secure_storage/src/domain/repositories/storage_repository.dart';
import 'package:secure_storage/src/services/secure_storage.dart';

/// {@template storage_repository_impl}
/// The default [StorageRepository], turning every [AppException] thrown by
/// [SecureStorage] into its matching [Failure].
/// {@endtemplate}
class StorageRepositoryImpl implements StorageRepository {
  /// {@macro storage_repository_impl}
  const StorageRepositoryImpl({required SecureStorage secureStorage})
    : _secureStorage = secureStorage;

  final SecureStorage _secureStorage;

  @override
  Future<Either<Failure, ({bool exist, bool? encrypted})>> checkData({
    required ParamCheckData param,
  }) => _guard(() => _secureStorage.isDataExist(param: param));

  @override
  Future<Either<Failure, String>> storeData({
    required ParamStoreData param,
    required Object data,
  }) => _guard(() async {
    await _secureStorage.storeData(data: data, param: param);
    return 'data type: ${data.runtimeType} successful stored';
  });

  @override
  Future<Either<Failure, Object>> getData({required ParamGetData param}) =>
      _guard(() async {
        final result = await _secureStorage.getData<Object>(param: param);
        if (result == null) {
          throw DataDoesNotExistException();
        }
        return result;
      });

  @override
  Future<Either<Failure, String>> deleteData({
    required ParamDeleteData param,
  }) => _guard(() async {
    await _secureStorage.deleteData<Object>(param: param);
    return 'data with key: ${param.dataKey} successful deleted';
  });

  @override
  Future<Either<Failure, Map<String, String>>> listEncryptedKeys() =>
      _guard(_secureStorage.listEncryptedKeys);

  @override
  Future<Either<Failure, List<dynamic>>> listUnencryptedKeys() =>
      _guard(_secureStorage.listUnencryptedKeys);

  /// Runs [operation], mapping anything it throws onto the [Left] side.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Right(await operation());
    } on AppException catch (e) {
      return Left(e.toFailure());
    } on Exception catch (e) {
      return Left(UnhandledException(message: e.toString()).toFailure());
    }
  }
}
