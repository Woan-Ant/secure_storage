import 'package:dartz/dartz.dart';
import 'package:secure_storage/src/core/error/app_failure.dart';
import 'package:secure_storage/src/core/param/param_secure_storage.dart';
import 'package:secure_storage/src/core/use_case/use_case.dart';
import 'package:secure_storage/src/domain/repositories/storage_repository.dart';

/// {@template check_data_use_case}
/// Reports whether an entry exists, and whether its box is encrypted.
/// {@endtemplate}
class CheckDataUseCase
    implements UseCase<({bool exist, bool? encrypted}), ParamCheckData> {
  /// {@macro check_data_use_case}
  const new({required StorageRepository storageRepository})
    : _storageRepository = storageRepository;

  final StorageRepository _storageRepository;

  @override
  Future<Either<Failure, ({bool exist, bool? encrypted})>> call({
    required ParamCheckData param,
  }) => _storageRepository.checkData(param: param);
}
