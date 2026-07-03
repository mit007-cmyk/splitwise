import 'package:injectable/injectable.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class WatchAuthStatusUseCase {
  final AuthRepository _repository;

  WatchAuthStatusUseCase(this._repository);

  Stream<UserEntity> call() {
    return _repository.watchAuthStatus();
  }
}
