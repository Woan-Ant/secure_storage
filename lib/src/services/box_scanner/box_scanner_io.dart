import 'dart:io';

/// Returns the name of every Hive box file directly inside [directoryPath].
///
/// The `.hive` suffix is stripped, so `auth.hive` comes back as `auth`. A
/// directory that does not exist yields an empty list rather than throwing.
List<String> listBoxFileNames(String directoryPath) {
  final directory = Directory(directoryPath);
  if (!directory.existsSync()) return const [];

  return <String>[
    for (final entity in directory.listSync())
      if (entity is File && entity.path.endsWith('.hive'))
        entity.path.split(Platform.pathSeparator).last.replaceAll('.hive', ''),
  ];
}
