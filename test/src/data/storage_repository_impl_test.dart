import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:secure_storage/secure_storage.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

class FakeParamCheckData extends Fake implements ParamCheckData {}

class FakeParamGetData extends Fake implements ParamGetData {}

class FakeParamStoreData extends Fake implements ParamStoreData {}

class FakeParamDeleteData extends Fake implements ParamDeleteData {}

void main() {
  late MockSecureStorage service;
  late StorageRepositoryImpl repository;

  final checkParam = ParamCheckData(boxName: 'auth', dataKey: 'token');
  final getParam = ParamGetData(boxName: 'auth', dataKey: 'token');
  final storeParam = ParamStoreData(boxName: 'auth', dataKey: 'token');
  final deleteParam = ParamDeleteData(boxName: 'auth', dataKey: 'token');

  setUpAll(() {
    registerFallbackValue(FakeParamCheckData());
    registerFallbackValue(FakeParamGetData());
    registerFallbackValue(FakeParamStoreData());
    registerFallbackValue(FakeParamDeleteData());
  });

  setUp(() {
    service = MockSecureStorage();
    repository = StorageRepositoryImpl(secureStorage: service);
  });

  group('checkData', () {
    test('returns the service result on the right', () async {
      when(() => service.isDataExist(param: any(named: 'param')))
          .thenAnswer((_) async => (exist: true, encrypted: true));

      final result = await repository.checkData(param: checkParam);

      expect(result.isRight(), isTrue);
      expect(
        result.getOrElse((_) => (exist: false, encrypted: null)).exist,
        isTrue,
      );
    });

    test('converts an AppException into its matching Failure', () async {
      when(() => service.isDataExist(param: any(named: 'param')))
          .thenThrow(HiveOpenBoxException());

      final result = await repository.checkData(param: checkParam);

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<OpenFailure>().having((f) => f.code, 'code', '004'),
      );
    });

    test('wraps an unmodelled exception in an UnhandledFailure', () async {
      when(() => service.isDataExist(param: any(named: 'param')))
          .thenThrow(const FormatException('bad input'));

      final result = await repository.checkData(param: checkParam);

      expect(result.getLeft().toNullable(), isA<UnhandledFailure>());
    });
  });

  group('storeData', () {
    test('reports the stored type on success', () async {
      when(
        () => service.storeData<Object>(
          data: any(named: 'data'),
          param: any(named: 'param'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.storeData(
        param: storeParam,
        data: 'token-value',
      );

      expect(result.getOrElse((_) => ''), contains('String'));
    });

    test('converts a write failure', () async {
      when(
        () => service.storeData<Object>(
          data: any(named: 'data'),
          param: any(named: 'param'),
        ),
      ).thenThrow(HiveWriteException());

      final result = await repository.storeData(param: storeParam, data: 'x');

      expect(result.getLeft().toNullable(), isA<HiveWriteFailure>());
    });
  });

  group('getData', () {
    test('returns the stored value', () async {
      when(() => service.getData<Object>(param: any(named: 'param')))
          .thenAnswer((_) async => 'token-value');

      final result = await repository.getData(param: getParam);

      expect(result.getOrElse((_) => ''), 'token-value');
    });

    test('reports a null value as DataDoesNotExistFailure', () async {
      when(() => service.getData<Object>(param: any(named: 'param')))
          .thenAnswer((_) async => null);

      final result = await repository.getData(param: getParam);

      expect(result.getLeft().toNullable(), isA<DataDoesNotExistFailure>());
    });

    test('converts a missing entry', () async {
      when(() => service.getData<Object>(param: any(named: 'param')))
          .thenThrow(DataDoesNotExistException());

      final result = await repository.getData(param: getParam);

      expect(result.getLeft().toNullable(), isA<DataDoesNotExistFailure>());
    });
  });

  group('deleteData', () {
    test('names the deleted key on success', () async {
      when(() => service.deleteData<Object>(param: any(named: 'param')))
          .thenAnswer((_) async {});

      final result = await repository.deleteData(param: deleteParam);

      expect(result.getOrElse((_) => ''), contains('auth_token'));
    });

    test('converts a delete failure', () async {
      when(() => service.deleteData<Object>(param: any(named: 'param')))
          .thenThrow(HiveDeleteBoxException());

      final result = await repository.deleteData(param: deleteParam);

      expect(result.getLeft().toNullable(), isA<HiveDeleteBoxFailure>());
    });
  });

  group('listing', () {
    test('returns the encrypted keys', () async {
      when(service.listEncryptedKeys).thenAnswer((_) async => {'auth': 'k'});

      final result = await repository.listEncryptedKeys();

      expect(result.getOrElse((_) => {}), {'auth': 'k'});
    });

    test('converts a keystore read failure', () async {
      when(service.listEncryptedKeys).thenThrow(FSSReadException());

      final result = await repository.listEncryptedKeys();

      expect(result.getLeft().toNullable(), isA<FSSReadFailure>());
    });

    test('returns the unencrypted box names', () async {
      when(() => service.listUnencryptedKeys())
          .thenAnswer((_) async => ['profile']);

      final result = await repository.listUnencryptedKeys();

      expect(result.getOrElse((_) => []), ['profile']);
    });

    test('converts a hive read failure', () async {
      when(() => service.listUnencryptedKeys()).thenThrow(HiveReadException());

      final result = await repository.listUnencryptedKeys();

      expect(result.getLeft().toNullable(), isA<HiveReadFailure>());
    });
  });
}
