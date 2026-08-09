import 'package:fpdart/fpdart.dart';
import 'package:secure_storage/src/core/error/app_failure.dart';
import 'package:secure_storage/src/core/use_case/use_case.dart';
import 'package:secure_storage/src/domain/repositories/storage_repository.dart';

/// {@template list_unencrypted_keys_use_case}
/// Lists the names of the boxes on disk that have no encryption key.
///
/// Takes a [NoParam]. Always returns an empty list on web.
/// {@endtemplate}
class ListUnencryptedKeysUseCase implements UseCase<List<dynamic>, Param> {
  /// {@macro list_unencrypted_keys_use_case}
  const ListUnencryptedKeysUseCase({
    required StorageRepository storageRepository,
  }) : _storageRepository = storageRepository;

  final StorageRepository _storageRepository;

  @override
  Future<Either<Failure, List<dynamic>>> call({
    Param param = const NoParam(),
  }) => _storageRepository.listUnencryptedKeys();
}
