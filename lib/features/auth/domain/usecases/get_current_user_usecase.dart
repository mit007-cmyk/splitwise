import 'package:injectable/injectable.dart';
import '../../../../core/errors/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  Future<Result<UserEntity>> call() async {
    return _repository.getCurrentUser();
  }
}
