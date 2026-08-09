import 'package:fpdart/fpdart.dart';
import 'package:secure_storage/src/core/error/app_failure.dart';
import 'package:secure_storage/src/core/param/param_secure_storage.dart';
import 'package:secure_storage/src/core/use_case/use_case.dart';
import 'package:secure_storage/src/domain/repositories/storage_repository.dart';

/// {@template get_data_use_case}
/// Reads the entry addressed by the parameter.
/// {@endtemplate}
class GetDataUseCase implements UseCase<Object, ParamGetData> {
  /// {@macro get_data_use_case}
  const GetDataUseCase({required StorageRepository storageRepository})
    : _storageRepository = storageRepository;

  final StorageRepository _storageRepository;

  @override
  Future<Either<Failure, Object>> call({required ParamGetData param}) =>
      _storageRepository.getData(param: param);
}
