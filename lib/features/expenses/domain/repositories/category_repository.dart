import '../../../../core/errors/result.dart';
import '../entities/app_category.dart';

abstract class CategoryRepository {
  /// Active default categories plus this group's active custom categories.
  Future<Result<CategoryPickerLists>> getPickerCategories({String? groupId});

  Future<Result<AppCategory>> createCustomCategory({
    required String groupId,
    required String name,
    required String iconKey,
    required String createdBy,
  });
}
