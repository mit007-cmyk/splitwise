import 'package:injectable/injectable.dart';
import '../../../../core/errors/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<Result<UserEntity>> call({
    required String name,
    required String email,
    required String password,
  }) async {
    return _repository.signUp(name: name, email: email, password: password);
  }
}
