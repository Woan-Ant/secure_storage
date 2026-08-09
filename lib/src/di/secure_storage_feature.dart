import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
// HiveImpl is not exported by hive_ce, but it is what lets this package build
// an isolated Hive instance instead of mutating the global `Hive` singleton.
// ignore: implementation_imports
import 'package:hive_ce/src/hive_impl.dart';
import 'package:secure_storage/src/core/logger/secure_storage_logger.dart';
import 'package:secure_storage/src/data/repositories/storage_repository_impl.dart';
import 'package:secure_storage/src/domain/repositories/storage_repository.dart';
import 'package:secure_storage/src/domain/use_cases/check_data_use_case.dart';
import 'package:secure_storage/src/domain/use_cases/delete_data_use_case.dart';
import 'package:secure_storage/src/domain/use_cases/get_data_use_case.dart';
import 'package:secure_storage/src/domain/use_cases/list_encrypted_keys_use_case.dart';
import 'package:secure_storage/src/domain/use_cases/list_unencrypted_keys_use_case.dart';
import 'package:secure_storage/src/domain/use_cases/store_data_use_case.dart';
import 'package:secure_storage/src/services/secure_storage.dart';
import 'package:secure_storage/src/services/secure_storage_impl.dart';

/// Registers everything this package provides into [sl].
///
/// Call once during app start up, before the first storage access:
///
/// ```dart
/// initSecureStorageFeature(
///   sl: GetIt.instance,
///   // On web Hive uses IndexedDB and this is ignored; elsewhere pass a
///   // writable directory, typically from package:path_provider.
///   storagePath: kIsWeb
///       ? null
///       : (await getApplicationDocumentsDirectory()).path,
/// );
/// final storage = GetIt.instance<SecureStorage>();
/// ```
///
/// [storagePath] is where Hive keeps its box files and where
/// [SecureStorage.listUnencryptedKeys] looks for them. This package does not
/// depend on `path_provider`, so that it can also run on web — resolving the
/// directory is the app's job.
///
/// Registered under their abstract types: [HiveInterface],
/// [FlutterSecureStorage], [SecureStorage], [StorageRepository], and the six
/// use cases.
///
/// Pass [registerAdapters] to register your own Hive [TypeAdapter]s so that
/// boxes can hold your model types. It takes a callback rather than a list so
/// each adapter keeps its static type — registering a `TypeAdapter<dynamic>`
/// would make Hive route every write through it:
///
/// ```dart
/// initSecureStorageFeature(
///   sl: sl,
///   registerAdapters: (hive) => hive.registerAdapter(UserModelAdapter()),
/// );
/// ```
///
/// [secureStorage] and [logger] let you substitute the platform-facing pieces,
/// which is what the tests do.
///
/// This creates a private Hive instance rather than touching the global `Hive`
/// singleton, so it will not interfere with other Hive usage in the same app.
void initSecureStorageFeature({
  required GetIt sl,
  String? storagePath,
  void Function(HiveInterface hive)? registerAdapters,
  FlutterSecureStorage? secureStorage,
  SecureStorageLogger logger = const SilentSecureStorageLogger(),
}) {
  sl
    ..registerLazySingleton<HiveInterface>(() {
      final hive = HiveImpl()..init(storagePath);
      registerAdapters?.call(hive);
      return hive;
    })
    ..registerLazySingleton<FlutterSecureStorage>(
      () => secureStorage ?? const FlutterSecureStorage(),
    )
    ..registerLazySingleton<SecureStorage>(
      () => SecureStorageImpl(
        hiveInterface: sl(),
        fSS: sl(),
        boxDirectoryPath: storagePath,
        logger: logger,
      ),
    )
    ..registerLazySingleton<StorageRepository>(
      () => StorageRepositoryImpl(secureStorage: sl()),
    )
    ..registerLazySingleton(() => CheckDataUseCase(storageRepository: sl()))
    ..registerLazySingleton(() => StoreDataUseCase(storageRepository: sl()))
    ..registerLazySingleton(() => GetDataUseCase(storageRepository: sl()))
    ..registerLazySingleton(() => DeleteDataUseCase(storageRepository: sl()))
    ..registerLazySingleton(
      () => ListEncryptedKeysUseCase(storageRepository: sl()),
    )
    ..registerLazySingleton(
      () => ListUnencryptedKeysUseCase(storageRepository: sl()),
    );
}
