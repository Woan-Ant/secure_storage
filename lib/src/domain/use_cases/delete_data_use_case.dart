import 'package:dartz/dartz.dart';
import 'package:secure_storage/src/core/error/app_failure.dart';
import 'package:secure_storage/src/core/param/param_secure_storage.dart';
import 'package:secure_storage/src/core/use_case/use_case.dart';
import 'package:secure_storage/src/domain/repositories/storage_repository.dart';

/// {@template delete_data_use_case}
/// Deletes the entry addressed by the parameter, and the box with it when that
/// leaves the box empty.
/// {@endtemplate}
class DeleteDataUseCase implements UseCase<String, ParamDeleteData> {
  /// {@macro delete_data_use_case}
  const DeleteDataUseCase({required StorageRepository storageRepository})
    : _storageRepository = storageRepository;

  final StorageRepository _storageRepository;

  @override
  Future<Either<Failure, String>> call({required ParamDeleteData param}) =>
      _storageRepository.deleteData(param: param);
}
