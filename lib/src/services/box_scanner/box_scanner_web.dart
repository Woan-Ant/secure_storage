/// Always returns an empty list.
///
/// On web Hive keeps its boxes in IndexedDB rather than in files, so there is
/// no directory to scan and `directoryPath` is ignored.
List<String> listBoxFileNames(String directoryPath) => const [];
