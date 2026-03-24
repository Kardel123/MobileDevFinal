import 'package:flutter/material.dart';

class College {
  const College({
    required this.id,
    required this.slug,
    required this.name,
    required this.primaryHex,
    required this.accentHex,
    required this.sortOrder,
  });

  final String id;
  final String slug;
  final String name;
  final String primaryHex;
  final String accentHex;
  final int sortOrder;

  Color get primaryColor => hexToColor(primaryHex);
  Color get accentColor => hexToColor(accentHex);

  static Color hexToColor(String hex) {
    var h = hex.replaceFirst('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  factory College.fromMap(Map<String, dynamic> m) {
    return College(
      id: m['id'] as String,
      slug: m['slug'] as String,
      name: m['name'] as String,
      primaryHex: m['primary_hex'] as String,
      accentHex: m['accent_hex'] as String,
      sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
