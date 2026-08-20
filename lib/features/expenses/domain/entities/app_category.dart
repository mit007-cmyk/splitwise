import 'package:equatable/equatable.dart';
import 'category_source.dart';

/// A selectable spend category — either a global default or a group custom.
class AppCategory extends Equatable {
  final String id;
  final String name;
  final String iconKey;
  final CategorySource source;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;

  const AppCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.source,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
  });

  bool get isCustom => source == CategorySource.custom;

  /// Stable chart/aggregation key that does not depend on the display name.
  String get chartKey => '${source.value}:$id';

  AppCategory copyWith({
    String? id,
    String? name,
    String? iconKey,
    CategorySource? source,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return AppCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      source: source ?? this.source,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        iconKey,
        source,
        isActive,
        createdBy,
        createdAt,
      ];
}

class CategoryPickerLists extends Equatable {
  final List<AppCategory> defaults;
  final List<AppCategory> custom;

  const CategoryPickerLists({
    this.defaults = const [],
    this.custom = const [],
  });

  @override
  List<Object?> get props => [defaults, custom];
}
