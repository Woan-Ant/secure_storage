import 'package:fpdart/fpdart.dart';
import 'package:secure_storage/src/core/error/app_failure.dart';
import 'package:secure_storage/src/core/param/param_secure_storage.dart';
import 'package:secure_storage/src/core/use_case/use_case.dart';
import 'package:secure_storage/src/domain/repositories/storage_repository.dart';

/// {@template store_data_use_case}
/// Writes a value into storage.
///
/// Takes a record of the value and its destination, because a use case has a
/// single parameter slot:
///
/// ```dart
/// await storeDataUseCase(
///   param: (data: 'token', param: ParamStoreData(...)),
/// );
/// ```
/// {@endtemplate}
class StoreDataUseCase
    implements UseCase<String, ({Object data, ParamStoreData param})> {
  /// {@macro store_data_use_case}
  const StoreDataUseCase({required StorageRepository storageRepository})
    : _storageRepository = storageRepository;

  final StorageRepository _storageRepository;

  @override
  Future<Either<Failure, String>> call({
    required ({Object data, ParamStoreData param}) param,
  }) => _storageRepository.storeData(param: param.param, data: param.data);
}
