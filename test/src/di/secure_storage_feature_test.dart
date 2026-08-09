import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:secure_storage/secure_storage.dart';

class MockFSS extends Mock implements FlutterSecureStorage {}

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '/tmp/secure_storage';
}

class _Model {
  const _Model(this.value);
  final String value;
}

class _ModelAdapter extends TypeAdapter<_Model> {
  @override
  int get typeId => 42;

  @override
  _Model read(BinaryReader reader) => _Model(reader.readString());

  @override
  void write(BinaryWriter writer, _Model obj) => writer.writeString(obj.value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetIt sl;

  setUp(() {
    PathProviderPlatform.instance = _FakePathProvider();
    sl = GetIt.asNewInstance();
  });

  tearDown(() => sl.reset());

  test('registers the service, the repository and every use case', () async {
    await initSecureStorageFeature(sl: sl, secureStorage: MockFSS());

    expect(sl.isRegistered<HiveInterface>(), isTrue);
    expect(sl.isRegistered<FlutterSecureStorage>(), isTrue);
    expect(sl<SecureStorage>(), isA<SecureStorageImpl>());
    expect(sl<StorageRepository>(), isA<StorageRepositoryImpl>());
    expect(sl<CheckDataUseCase>(), isNotNull);
    expect(sl<StoreDataUseCase>(), isNotNull);
    expect(sl<GetDataUseCase>(), isNotNull);
    expect(sl<DeleteDataUseCase>(), isNotNull);
    expect(sl<ListEncryptedKeysUseCase>(), isNotNull);
    expect(sl<ListUnencryptedKeysUseCase>(), isNotNull);
  });

  test('resolves the service as a singleton', () async {
    await initSecureStorageFeature(sl: sl, secureStorage: MockFSS());

    expect(identical(sl<SecureStorage>(), sl<SecureStorage>()), isTrue);
  });

  test('uses the injected FlutterSecureStorage instance', () async {
    final fss = MockFSS();

    await initSecureStorageFeature(sl: sl, secureStorage: fss);

    expect(identical(sl<FlutterSecureStorage>(), fss), isTrue);
  });

  test('builds a Hive instance separate from the global singleton', () async {
    await initSecureStorageFeature(sl: sl, secureStorage: MockFSS());

    expect(identical(sl<HiveInterface>(), Hive), isFalse);
  });

  test('runs the adapter callback against the Hive instance it built',
      () async {
    final adapter = _ModelAdapter();

    await initSecureStorageFeature(
      sl: sl,
      secureStorage: MockFSS(),
      registerAdapters: (hive) => hive.registerAdapter(adapter),
    );

    expect(sl<HiveInterface>().isAdapterRegistered(adapter.typeId), isTrue);
  });

  test('registers no adapters when the callback is omitted', () async {
    await initSecureStorageFeature(sl: sl, secureStorage: MockFSS());

    expect(sl<HiveInterface>().isAdapterRegistered(42), isFalse);
  });

  test('passes the logger through to the service', () async {
    await initSecureStorageFeature(
      sl: sl,
      secureStorage: MockFSS(),
      logger: const DebugPrintSecureStorageLogger(),
    );

    expect(sl<SecureStorage>(), isA<SecureStorageImpl>());
  });
}
