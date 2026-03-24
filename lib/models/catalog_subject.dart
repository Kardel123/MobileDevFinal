class CatalogSubject {
  const CatalogSubject({
    required this.id,
    required this.collegeId,
    required this.name,
    required this.code,
  });

  final String id;
  final String collegeId;
  final String name;
  final String code;

  factory CatalogSubject.fromMap(Map<String, dynamic> m) {
    return CatalogSubject(
      id: m['id'] as String,
      collegeId: m['college_id'] as String,
      name: m['name'] as String,
      code: m['code'] as String,
    );
  }
}
