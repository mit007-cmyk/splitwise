import 'package:injectable/injectable.dart';
import '../../../../core/errors/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
  }) async {
    return _repository.login(email: email, password: password);
  }
}
