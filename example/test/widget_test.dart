import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:secure_storage/secure_storage.dart';
import 'package:secure_storage_example/bloc/demo_storage_bloc.dart';
import 'package:secure_storage_example/pages/secure_storage_demo_page.dart';

void main() {
  late GetIt sl;

  setUp(() {
    sl = GetIt.asNewInstance();
    // No storagePath: the registrations under test never touch the disk.
    initSecureStorageFeature(sl: sl);
  });

  tearDown(() => sl.reset());

  testWidgets('the demo page renders every storage action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => DemoStorageBloc(
            checkDataUseCase: sl<CheckDataUseCase>(),
            storeDataUseCase: sl<StoreDataUseCase>(),
            getDataUseCase: sl<GetDataUseCase>(),
            deleteDataUseCase: sl<DeleteDataUseCase>(),
            listEncryptedKeysUseCase: sl<ListEncryptedKeysUseCase>(),
            listUnencryptedKeysUseCase: sl<ListUnencryptedKeysUseCase>(),
          ),
          child: const SecureStorageDemoPage(),
        ),
      ),
    );

    expect(find.text('Secure Storage Demo'), findsOneWidget);
    expect(find.text('isDataExist'), findsOneWidget);
    expect(find.text('store'), findsOneWidget);
    expect(find.text('get'), findsOneWidget);
    expect(find.text('delete'), findsOneWidget);
    expect(find.text('listEncryptedKeys'), findsOneWidget);
    expect(find.text('listUnencryptedKeys'), findsOneWidget);
  });

  testWidgets('rejects box and key names the params would assert on',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => DemoStorageBloc(
            checkDataUseCase: sl<CheckDataUseCase>(),
            storeDataUseCase: sl<StoreDataUseCase>(),
            getDataUseCase: sl<GetDataUseCase>(),
            deleteDataUseCase: sl<DeleteDataUseCase>(),
            listEncryptedKeysUseCase: sl<ListEncryptedKeysUseCase>(),
            listUnencryptedKeysUseCase: sl<ListUnencryptedKeysUseCase>(),
          ),
          child: const SecureStorageDemoPage(),
        ),
      ),
    );

    // Both fields are empty, which StorageParam would assert on.
    await tester.tap(find.text('isDataExist'));
    await tester.pump();

    expect(
      find.text('Box and key must be non-empty letters, digits, spaces or _'),
      findsOneWidget,
    );
  });
}
