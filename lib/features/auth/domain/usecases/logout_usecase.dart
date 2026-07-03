import 'package:injectable/injectable.dart';
import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  Future<Result<void>> call() async {
    return _repository.logout();
  }
}
