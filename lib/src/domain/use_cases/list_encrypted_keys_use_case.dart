import 'package:dartz/dartz.dart';
import 'package:secure_storage/src/core/error/app_failure.dart';
import 'package:secure_storage/src/core/use_case/use_case.dart';
import 'package:secure_storage/src/domain/repositories/storage_repository.dart';

/// {@template list_encrypted_keys_use_case}
/// Lists every encrypted box name mapped to its stored encryption key.
///
/// Takes a [NoParam]. The returned values are live encryption keys — do not
/// log or transmit them.
/// {@endtemplate}
class ListEncryptedKeysUseCase implements UseCase<Map<String, String>, Param> {
  /// {@macro list_encrypted_keys_use_case}
  const ListEncryptedKeysUseCase({required StorageRepository storageRepository})
    : _storageRepository = storageRepository;

  final StorageRepository _storageRepository;

  @override
  Future<Either<Failure, Map<String, String>>> call({
    Param param = const NoParam(),
  }) => _storageRepository.listEncryptedKeys();
}
