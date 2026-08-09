import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:secure_storage/secure_storage.dart';
import 'package:secure_storage_example/bloc/demo_storage_bloc.dart';
import 'package:secure_storage_example/pages/secure_storage_demo_page.dart';

/// Service locator holding everything `initSecureStorageFeature` registers.
final GetIt sl = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One call registers the service, the repository and all six use cases.
  await initSecureStorageFeature(
    sl: sl,
    logger: const DebugPrintSecureStorageLogger(),
  );

  runApp(const SecureStorageExampleApp());
}

/// Demo application for the `secure_storage` package.
class SecureStorageExampleApp extends StatelessWidget {
  /// Creates a [SecureStorageExampleApp].
  const SecureStorageExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Storage Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
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
    );
  }
}
