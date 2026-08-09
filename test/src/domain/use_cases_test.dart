import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:secure_storage/secure_storage.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

class FakeParamCheckData extends Fake implements ParamCheckData {}

class FakeParamGetData extends Fake implements ParamGetData {}

class FakeParamStoreData extends Fake implements ParamStoreData {}

class FakeParamDeleteData extends Fake implements ParamDeleteData {}

void main() {
  late MockStorageRepository repository;

  final checkParam = ParamCheckData(boxName: 'auth', dataKey: 'token');
  final getParam = ParamGetData(boxName: 'auth', dataKey: 'token');
  final storeParam = ParamStoreData(boxName: 'auth', dataKey: 'token');
  final deleteParam = ParamDeleteData(boxName: 'auth', dataKey: 'token');

  const failure = HiveReadFailure(
    prefix: 'HIVE',
    code: '003',
    message: 'nope',
  );

  setUpAll(() {
    registerFallbackValue(FakeParamCheckData());
    registerFallbackValue(FakeParamGetData());
    registerFallbackValue(FakeParamStoreData());
    registerFallbackValue(FakeParamDeleteData());
  });

  setUp(() => repository = MockStorageRepository());

  group('CheckDataUseCase', () {
    test('forwards the param to the repository', () async {
      when(() => repository.checkData(param: any(named: 'param'))).thenAnswer(
        (_) async => const Right((exist: true, encrypted: false)),
      );

      final result = await CheckDataUseCase(
        storageRepository: repository,
      )(param: checkParam);

      expect(result.isRight(), isTrue);
      verify(() => repository.checkData(param: checkParam)).called(1);
    });

    test('passes a failure straight through', () async {
      when(() => repository.checkData(param: any(named: 'param')))
          .thenAnswer((_) async => const Left(failure));

      final result = await CheckDataUseCase(
        storageRepository: repository,
      )(param: checkParam);

      expect(result.getLeft().toNullable(), failure);
    });
  });

  group('GetDataUseCase', () {
    test('forwards the param to the repository', () async {
      when(() => repository.getData(param: any(named: 'param')))
          .thenAnswer((_) async => const Right<Failure, Object>('value'));

      final result = await GetDataUseCase(
        storageRepository: repository,
      )(param: getParam);

      expect(result.getOrElse((_) => ''), 'value');
      verify(() => repository.getData(param: getParam)).called(1);
    });
  });

  group('StoreDataUseCase', () {
    test('unpacks the record into param and data', () async {
      when(
        () => repository.storeData(
          param: any(named: 'param'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => const Right<Failure, String>('stored'));

      final result = await StoreDataUseCase(
        storageRepository: repository,
      )(param: (data: 'value', param: storeParam));

      expect(result.getOrElse((_) => ''), 'stored');
      verify(
        () => repository.storeData(param: storeParam, data: 'value'),
      ).called(1);
    });
  });

  group('DeleteDataUseCase', () {
    test('forwards the param to the repository', () async {
      when(() => repository.deleteData(param: any(named: 'param')))
          .thenAnswer((_) async => const Right<Failure, String>('deleted'));

      final result = await DeleteDataUseCase(
        storageRepository: repository,
      )(param: deleteParam);

      expect(result.getOrElse((_) => ''), 'deleted');
      verify(() => repository.deleteData(param: deleteParam)).called(1);
    });
  });

  group('ListEncryptedKeysUseCase', () {
    test('needs no param', () async {
      when(repository.listEncryptedKeys)
          .thenAnswer((_) async => const Right({'auth': 'k'}));

      final result =
          await ListEncryptedKeysUseCase(storageRepository: repository)();

      expect(result.getOrElse((_) => {}), {'auth': 'k'});
    });

    test('accepts being invoked twice', () async {
      when(repository.listEncryptedKeys)
          .thenAnswer((_) async => const Right({'auth': 'k'}));

      final result = await ListEncryptedKeysUseCase(
        storageRepository: repository,
      )();

      expect(result.isRight(), isTrue);
    });
  });

  group('ListUnencryptedKeysUseCase', () {
    test('needs no param', () async {
      when(repository.listUnencryptedKeys)
          .thenAnswer((_) async => const Right(['profile']));

      final result =
          await ListUnencryptedKeysUseCase(storageRepository: repository)();

      expect(result.getOrElse((_) => []), ['profile']);
    });
  });

  group('NoParam', () {
    test('all instances are equal', () {
      expect(const NoParam(), const NoParam());
      expect(const NoParam().props, isEmpty);
    });
  });
}
