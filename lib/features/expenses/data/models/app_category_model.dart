import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_category.dart';
import '../../domain/entities/category_source.dart';

class AppCategoryModel extends AppCategory {
  const AppCategoryModel({
    required super.id,
    required super.name,
    required super.iconKey,
    required super.source,
    super.isActive,
    super.createdBy,
    super.createdAt,
  });

  factory AppCategoryModel.fromEntity(AppCategory category) {
    return AppCategoryModel(
      id: category.id,
      name: category.name,
      iconKey: category.iconKey,
      source: category.source,
      isActive: category.isActive,
      createdBy: category.createdBy,
      createdAt: category.createdAt,
    );
  }

  factory AppCategoryModel.fromMap(String id, Map<String, dynamic> map) {
    final rawType = (map['type'] as String?) ?? (map['source'] as String?);
    final name = (map['name'] as String?)?.trim();
    final icon = (map['icon'] as String?)?.trim();
    return AppCategoryModel(
      id: id,
      name: name != null && name.isNotEmpty ? name : id,
      iconKey: icon != null && icon.isNotEmpty ? icon : 'receipt',
      source: CategorySource.fromValue(rawType),
      isActive: (map['isActive'] as bool?) ?? true,
      createdBy: map['createdBy'] as String?,
      createdAt: _dateFrom(map['createdAt']),
    );
  }

  static DateTime? _dateFrom(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
