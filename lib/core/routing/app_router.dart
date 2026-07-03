import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../di/di.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import 'route_constants.dart';
import 'placeholder_screens.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteConstants.splashPath,
    refreshListenable: GoRouterRefreshStream(getIt<AuthRepository>().watchAuthStatus()),
    errorBuilder: (context, state) => const UnknownScreen(),
    redirect: (context, state) async {
      final authRepo = getIt<AuthRepository>();
      final userResult = await authRepo.getCurrentUser();
      
      final isLoggingIn = state.matchedLocation == RouteConstants.loginPath || 
                          state.matchedLocation == RouteConstants.registerPath;
                          
      final isSplash = state.matchedLocation == RouteConstants.splashPath;

      if (userResult.isSuccess) {
        final user = userResult.dataOrThrow;
        final isLoggedIn = user.isNotEmpty;
        
        if (!isLoggedIn) {
          // If not logged in and not on login/register/splash, redirect to login
          if (!isLoggingIn && !isSplash) {
            return RouteConstants.loginPath;
          }
        } else {
          // If logged in and trying to access login/register/splash, redirect to home
          if (isLoggingIn || isSplash) {
            return RouteConstants.homePath;
          }
        }
      } else {
        // Fallback for check session failures
        if (!isLoggingIn && !isSplash) {
          return RouteConstants.loginPath;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RouteConstants.splashPath,
        name: RouteConstants.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteConstants.loginPath,
        name: RouteConstants.loginName,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteConstants.registerPath,
        name: RouteConstants.registerName,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteConstants.homePath,
        name: RouteConstants.homeName,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: RouteConstants.maintenancePath,
        name: RouteConstants.maintenanceName,
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: RouteConstants.updateRequiredPath,
        name: RouteConstants.updateRequiredName,
        builder: (context, state) => const UpdateRequiredScreen(),
      ),
      GoRoute(
        path: RouteConstants.unknownPath,
        name: RouteConstants.unknownName,
        builder: (context, state) => const UnknownScreen(),
      ),
    ],
  );
}
