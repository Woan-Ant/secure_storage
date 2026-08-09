/// Encrypted key-value storage for Flutter, layering Hive CE boxes on top of
/// Flutter Secure Storage.
///
/// Use `SecureStorage` directly if you want a plain service that throws, or
/// `StorageRepository` and the use cases if you prefer `Either<Failure, T>`.
/// `initSecureStorageFeature` wires all of it into a `GetIt` container.
library;

export 'package:fpdart/fpdart.dart' show Either, Left, Right;

export 'src/core/error/app_exception.dart';
export 'src/core/error/app_failure.dart';
export 'src/core/error/exception/secure_storage_exception.dart';
export 'src/core/error/failure/secure_storage_failure.dart';
export 'src/core/logger/secure_storage_logger.dart';
export 'src/core/param/param_secure_storage.dart';
export 'src/core/use_case/use_case.dart';
export 'src/data/repositories/storage_repository_impl.dart';
export 'src/di/secure_storage_feature.dart';
export 'src/domain/repositories/storage_repository.dart';
export 'src/domain/use_cases/check_data_use_case.dart';
export 'src/domain/use_cases/delete_data_use_case.dart';
export 'src/domain/use_cases/get_data_use_case.dart';
export 'src/domain/use_cases/list_encrypted_keys_use_case.dart';
export 'src/domain/use_cases/list_unencrypted_keys_use_case.dart';
export 'src/domain/use_cases/store_data_use_case.dart';
export 'src/services/secure_storage.dart';
export 'src/services/secure_storage_impl.dart';
