import 'package:injectable/injectable.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/repositories/base_repository.dart';
import '../../domain/entities/app_category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl extends BaseRepository
    implements CategoryRepository {
  final CategoryRemoteDataSource _remoteDataSource;

  CategoryRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<CategoryPickerLists>> getPickerCategories({String? groupId}) {
    return safeCall(
      () => _remoteDataSource.getPickerCategories(groupId: groupId),
    );
  }

  @override
  Future<Result<AppCategory>> createCustomCategory({
    required String groupId,
    required String name,
    required String iconKey,
    required String createdBy,
  }) {
    return safeCall(
      () => _remoteDataSource.createCustomCategory(
        groupId: groupId,
        name: name,
        iconKey: iconKey,
        createdBy: createdBy,
      ),
    );
  }
}
