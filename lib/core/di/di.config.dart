// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/auth/data/datasources/auth_local_datasource.dart'
    as _i992;
import '../../features/auth/data/datasources/auth_remote_datasource.dart'
    as _i161;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/get_current_user_usecase.dart'
    as _i17;
import '../../features/auth/domain/usecases/login_usecase.dart' as _i188;
import '../../features/auth/domain/usecases/login_with_google_usecase.dart'
    as _i57;
import '../../features/auth/domain/usecases/logout_usecase.dart' as _i48;
import '../../features/auth/domain/usecases/register_usecase.dart' as _i941;
import '../../features/auth/domain/usecases/watch_auth_status_usecase.dart'
    as _i281;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/expenses/data/datasources/expense_remote_datasource.dart'
    as _i848;
import '../../features/expenses/data/repositories/expense_repository_impl.dart'
    as _i786;
import '../../features/expenses/domain/repositories/expense_repository.dart'
    as _i939;
import '../../features/friends/data/datasources/friends_remote_datasource.dart'
    as _i252;
import '../../features/friends/data/datasources/friends_remote_datasource_impl.dart'
    as _i808;
import '../../features/friends/data/repositories/friends_repository_impl.dart'
    as _i120;
import '../../features/friends/domain/repositories/friends_repository.dart'
    as _i30;
import '../../features/friends/presentation/bloc/add_friend_search_cubit.dart'
    as _i437;
import '../../features/friends/presentation/bloc/friend_detail_cubit.dart'
    as _i866;
import '../../features/friends/presentation/bloc/friend_invite_cubit.dart'
    as _i427;
import '../../features/friends/presentation/bloc/friends_list_cubit.dart'
    as _i787;
import '../../features/friends/presentation/bloc/my_code_cubit.dart' as _i938;
import '../../features/home/data/datasources/home_local_datasource.dart'
    as _i314;
import '../../features/home/data/datasources/home_remote_datasource.dart'
    as _i278;
import '../../features/home/data/repositories/home_repository_impl.dart'
    as _i76;
import '../../features/home/domain/repositories/home_repository.dart' as _i0;
import '../../features/home/presentation/bloc/home_bloc.dart' as _i202;
import '../helpers/permission_helper.dart' as _i650;
import '../services/analytics_service.dart' as _i222;
import '../services/app_logger.dart' as _i1019;
import '../services/biometric_lock_service.dart' as _i600;
import '../services/connectivity_service.dart' as _i47;
import '../services/contacts_service.dart' as _i1008;
import '../services/firestore_service.dart' as _i52;
import '../services/hive_service.dart' as _i1047;
import '../services/image_picker_service.dart' as _i644;
import '../services/notification_service.dart' as _i941;
import '../services/remote_config_service.dart' as _i858;
import '../services/storage_service.dart' as _i306;
import '../services/support_email_service.dart' as _i820;
import '../theme/theme_cubit.dart' as _i611;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i1019.AppLogger>(() => _i1019.AppLogger());
    gh.singleton<_i650.PermissionHelper>(
        () => _i650.PermissionHelper(gh<_i1019.AppLogger>()));
    gh.singleton<_i222.AnalyticsService>(
        () => _i222.AnalyticsService(gh<_i1019.AppLogger>()));
    gh.singleton<_i47.ConnectivityService>(
        () => _i47.ConnectivityService(gh<_i1019.AppLogger>()));
    gh.singleton<_i52.FirestoreService>(
        () => _i52.FirestoreService(gh<_i1019.AppLogger>()));
    gh.singleton<_i1047.HiveService>(
        () => _i1047.HiveService(gh<_i1019.AppLogger>()));
    gh.singleton<_i644.ImagePickerService>(
        () => _i644.ImagePickerService(gh<_i1019.AppLogger>()));
    gh.singleton<_i941.NotificationService>(
        () => _i941.NotificationService(gh<_i1019.AppLogger>()));
    gh.singleton<_i858.RemoteConfigService>(
        () => _i858.RemoteConfigService(gh<_i1019.AppLogger>()));
    gh.singleton<_i306.StorageService>(
        () => _i306.StorageService(gh<_i1019.AppLogger>()));
    gh.lazySingleton<_i1008.ContactsService>(
        () => _i1008.ContactsService(gh<_i1019.AppLogger>()));
    gh.lazySingleton<_i314.HomeLocalDataSource>(
        () => _i314.HomeLocalDataSourceImpl(gh<_i1047.HiveService>()));
    gh.lazySingleton<_i252.FriendsRemoteDataSource>(
        () => _i808.FriendsRemoteDataSourceImpl(
              gh<_i52.FirestoreService>(),
              gh<_i1019.AppLogger>(),
            ));
    gh.lazySingleton<_i992.AuthLocalDataSource>(
        () => _i992.AuthLocalDataSourceImpl(gh<_i1047.HiveService>()));
    gh.lazySingleton<_i611.ThemeCubit>(
        () => _i611.ThemeCubit(gh<_i1047.HiveService>()));
    gh.lazySingleton<_i30.FriendsRepository>(
        () => _i120.FriendsRepositoryImpl(gh<_i252.FriendsRemoteDataSource>()));
    gh.lazySingleton<_i161.AuthRemoteDataSource>(
        () => _i161.AuthRemoteDataSourceImpl(
              gh<_i1047.HiveService>(),
              gh<_i1019.AppLogger>(),
              gh<_i52.FirestoreService>(),
              gh<_i252.FriendsRemoteDataSource>(),
            ));
    gh.lazySingleton<_i278.HomeRemoteDataSource>(
        () => _i278.HomeRemoteDataSourceImpl(gh<_i52.FirestoreService>()));
    gh.lazySingleton<_i600.BiometricLockService>(
        () => _i600.BiometricLockService(
              gh<_i1047.HiveService>(),
              gh<_i1019.AppLogger>(),
            ));
    gh.lazySingleton<_i820.SupportEmailService>(() => _i820.SupportEmailService(
          gh<_i1047.HiveService>(),
          gh<_i1019.AppLogger>(),
        ));
    gh.lazySingleton<_i848.ExpenseRemoteDataSource>(
        () => _i848.ExpenseRemoteDataSourceImpl(gh<_i52.FirestoreService>()));
    gh.factory<_i437.AddFriendSearchCubit>(
        () => _i437.AddFriendSearchCubit(gh<_i1008.ContactsService>()));
    gh.lazySingleton<_i0.HomeRepository>(() => _i76.HomeRepositoryImpl(
          gh<_i278.HomeRemoteDataSource>(),
          gh<_i314.HomeLocalDataSource>(),
          gh<_i47.ConnectivityService>(),
        ));
    gh.lazySingleton<_i787.AuthRepository>(() => _i153.AuthRepositoryImpl(
          gh<_i161.AuthRemoteDataSource>(),
          gh<_i992.AuthLocalDataSource>(),
        ));
    gh.factory<_i427.FriendInviteCubit>(
        () => _i427.FriendInviteCubit(gh<_i30.FriendsRepository>()));
    gh.factory<_i938.MyCodeCubit>(
        () => _i938.MyCodeCubit(gh<_i30.FriendsRepository>()));
    gh.factory<_i202.HomeBloc>(() => _i202.HomeBloc(
          gh<_i0.HomeRepository>(),
          gh<_i787.AuthRepository>(),
          gh<_i47.ConnectivityService>(),
        ));
    gh.lazySingleton<_i17.GetCurrentUserUseCase>(
        () => _i17.GetCurrentUserUseCase(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i188.LoginUseCase>(
        () => _i188.LoginUseCase(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i57.LoginWithGoogleUseCase>(
        () => _i57.LoginWithGoogleUseCase(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i48.LogoutUseCase>(
        () => _i48.LogoutUseCase(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i941.RegisterUseCase>(
        () => _i941.RegisterUseCase(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i281.WatchAuthStatusUseCase>(
        () => _i281.WatchAuthStatusUseCase(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i939.ExpenseRepository>(
        () => _i786.ExpenseRepositoryImpl(gh<_i848.ExpenseRemoteDataSource>()));
    gh.factory<_i797.AuthBloc>(() => _i797.AuthBloc(
          gh<_i188.LoginUseCase>(),
          gh<_i941.RegisterUseCase>(),
          gh<_i48.LogoutUseCase>(),
          gh<_i17.GetCurrentUserUseCase>(),
          gh<_i281.WatchAuthStatusUseCase>(),
          gh<_i57.LoginWithGoogleUseCase>(),
        ));
    gh.factory<_i787.FriendsListCubit>(() => _i787.FriendsListCubit(
          gh<_i30.FriendsRepository>(),
          gh<_i0.HomeRepository>(),
          gh<_i939.ExpenseRepository>(),
        ));
    gh.factory<_i866.FriendDetailCubit>(() => _i866.FriendDetailCubit(
          gh<_i30.FriendsRepository>(),
          gh<_i0.HomeRepository>(),
          gh<_i939.ExpenseRepository>(),
        ));
    return this;
  }
}
