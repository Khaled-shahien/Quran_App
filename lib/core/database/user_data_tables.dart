/// A group of user tables that export, import and erase carry. Each
/// repository that owns user rows implements it once.
abstract interface class UserDataTables {
  /// Every row, by table name.
  Future<Map<String, List<Map<String, Object?>>>> exportRows();

  /// Replaces this group's tables with [rows] (other tables in the map are
  /// ignored). Invalid rows are skipped; returns the rows kept.
  Future<int> replaceAll(Map<String, List<Map<String, Object?>>> rows);

  Future<void> clear();
}
