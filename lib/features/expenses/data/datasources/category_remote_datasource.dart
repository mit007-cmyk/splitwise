import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/app_category.dart';
import '../../domain/entities/category_source.dart';
import '../../domain/entities/default_categories.dart';
import '../models/app_category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<CategoryPickerLists> getPickerCategories({String? groupId});

  Future<AppCategory> createCustomCategory({
    required String groupId,
    required String name,
    required String iconKey,
    required String createdBy,
  });
}

@LazySingleton(as: CategoryRemoteDataSource)
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final FirestoreService _firestoreService;

  CategoryRemoteDataSourceImpl(this._firestoreService);

  @override
  Future<CategoryPickerLists> getPickerCategories({String? groupId}) async {
    final defaults = await _loadDefaults();
    final custom = groupId == null || groupId.isEmpty
        ? const <AppCategory>[]
        : await _loadCustom(groupId);
    return CategoryPickerLists(
      defaults: defaults.where((c) => c.isActive && c.id != 'settlement').toList(),
      custom: custom.where((c) => c.isActive).toList(),
    );
  }

  @override
  Future<AppCategory> createCustomCategory({
    required String groupId,
    required String name,
    required String iconKey,
    required String createdBy,
  }) async {
    final trimmed = name.trim();
    final existing = await _loadCustom(groupId);
    final id = _uniqueId(trimmed, existing);
    final category = AppCategory(
      id: id,
      name: trimmed,
      iconKey: iconKey,
      source: CategorySource.custom,
      isActive: true,
      createdBy: createdBy,
    );

    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.groups,
      {
        groupId: {
          'categories': {
            id: {
              'name': category.name,
              'icon': category.iconKey,
              'type': CategorySource.custom.value,
              'createdBy': createdBy,
              'createdAt': FieldValue.serverTimestamp(),
              'isActive': true,
            },
          },
        },
      },
      merge: true,
    );
    return category;
  }

  Future<List<AppCategory>> _loadDefaults() async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.categories,
    );
    final data = doc.data() ?? <String, dynamic>{};
    final missing = <String, dynamic>{};
    for (final category in DefaultCategories.all) {
      if (!data.containsKey(category.id)) {
        missing[category.id] = {
          'name': category.name,
          'icon': category.iconKey,
          'type': CategorySource.defaultSource.value,
          'isActive': true,
        };
      }
    }
    if (missing.isNotEmpty) {
      await _firestoreService.setDocument(
        FirestorePaths.root,
        FirestorePaths.categories,
        missing,
        merge: true,
      );
      data.addAll(missing);
    }

    final loaded = <AppCategory>[];
    final seen = <String>{};
    for (final entry in data.entries) {
      final raw = entry.value;
      if (raw is! Map) continue;
      final category = AppCategoryModel.fromMap(
        entry.key,
        Map<String, dynamic>.from(raw),
      );
      loaded.add(category);
      seen.add(category.id);
    }
    for (final category in DefaultCategories.forPicker) {
      if (!seen.contains(category.id)) loaded.add(category);
    }
    loaded.sort((a, b) {
      final aIndex = _defaultOrder(a.id);
      final bIndex = _defaultOrder(b.id);
      if (aIndex != bIndex) return aIndex.compareTo(bIndex);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return loaded;
  }

  Future<List<AppCategory>> _loadCustom(String groupId) async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.groups,
    );
    final groups = doc.data();
    final group = groups?[groupId];
    if (group is! Map) return const [];
    final rawCategories = group['categories'];
    if (rawCategories is! Map) return const [];

    final loaded = <AppCategory>[];
    for (final entry in rawCategories.entries) {
      final raw = entry.value;
      if (raw is! Map) continue;
      loaded.add(
        AppCategoryModel.fromMap(
          entry.key.toString(),
          Map<String, dynamic>.from(raw),
        ).copyWith(source: CategorySource.custom),
      );
    }
    loaded.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return loaded;
  }

  String _uniqueId(String name, List<AppCategory> existing) {
    var slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    slug = slug.replaceAll(RegExp(r'^_+|_+$'), '');
    if (slug.isEmpty) slug = 'custom';
    final taken = {
      ...DefaultCategories.ids,
      for (final category in existing) category.id,
    };
    if (!taken.contains(slug)) return slug;
    var index = 2;
    while (taken.contains('${slug}_$index')) {
      index += 1;
    }
    return '${slug}_$index';
  }

  int _defaultOrder(String id) {
    final index = DefaultCategories.all.indexWhere((c) => c.id == id);
    return index < 0 ? 1000 : index;
  }
}
