import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../di/di.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import 'package:splitwise/features/groups/presentation/pages/create_group_page.dart';
import 'package:splitwise/features/navigation/presentation/pages/main_navigation_page.dart';
import 'package:splitwise/features/groups/presentation/pages/group_detail_page.dart';
import 'package:splitwise/features/groups/presentation/pages/add_group_members_page.dart';
import 'package:splitwise/features/friends/presentation/pages/add_friend_page.dart';
import 'package:splitwise/features/friends/presentation/pages/add_friend_search_page.dart';
import 'package:splitwise/features/groups/presentation/pages/group_settings_page.dart';
import 'package:splitwise/features/groups/presentation/pages/edit_group_page.dart';
import 'package:splitwise/features/friends/presentation/pages/friends_page.dart';
import 'package:splitwise/features/activity/presentation/pages/activity_page.dart';
import 'package:splitwise/features/account/presentation/pages/account_page.dart';
import 'package:splitwise/features/account/presentation/pages/account_settings_page.dart';
import 'package:splitwise/features/account/presentation/pages/email_settings_page.dart';
import 'package:splitwise/features/account/presentation/pages/security_page.dart';
import 'package:splitwise/features/account/presentation/pages/appearance_page.dart';
import 'package:splitwise/features/friends/presentation/pages/friend_invite_page.dart';
import 'package:splitwise/features/friends/presentation/pages/friend_detail_page.dart';
import 'package:splitwise/features/friends/presentation/pages/friend_settings_page.dart';
import 'package:splitwise/features/friends/presentation/pages/friend_code_page.dart';
import 'package:splitwise/features/account/presentation/pages/use_biometrics_page.dart';
import 'package:splitwise/features/expenses/presentation/pages/add_expense_page.dart';
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
        redirect: (context, state) => RouteConstants.groupsPath,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.groupsPath,
                name: RouteConstants.groupsName,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.friendsPath,
                name: RouteConstants.friendsName,
                builder: (context, state) => const FriendsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.activityPath,
                name: RouteConstants.activityName,
                builder: (context, state) => const ActivityPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.accountPath,
                name: RouteConstants.accountName,
                builder: (context, state) => const AccountPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteConstants.createGroupPath,
        name: RouteConstants.createGroupName,
        builder: (context, state) => const CreateGroupPage(),
      ),
      GoRoute(
        path: RouteConstants.groupDetailPath,
        name: RouteConstants.groupDetailName,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId'] ?? '';
          return GroupDetailPage(groupId: groupId);
        },
      ),
      GoRoute(
        path: RouteConstants.addGroupMembersPath,
        name: RouteConstants.addGroupMembersName,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId'] ?? '';
          return AddGroupMembersPage(groupId: groupId);
        },
      ),
      GoRoute(
        path: RouteConstants.addFriendPath,
        name: RouteConstants.addFriendName,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          if (code != null && code.trim().isNotEmpty) {
            return FriendInvitePage(friendCode: code.trim());
          }
          return const AddFriendSearchPage();
        },
      ),
      GoRoute(
        path: RouteConstants.addFriendSearchPath,
        name: RouteConstants.addFriendSearchName,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddFriendSearchPage(),
      ),
      GoRoute(
        path: RouteConstants.addFriendNewPath,
        name: RouteConstants.addFriendNewName,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final name = state.uri.queryParameters['name'];
          final phone = state.uri.queryParameters['phone'];
          final email = state.uri.queryParameters['email'];
          return AddFriendPage(
            initialName: name,
            initialPhone: phone,
            initialEmail: email,
          );
        },
      ),
      GoRoute(
        path: RouteConstants.groupSettingsPath,
        name: RouteConstants.groupSettingsName,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId'] ?? '';
          return GroupSettingsPage(groupId: groupId);
        },
      ),
      GoRoute(
        path: RouteConstants.editGroupPath,
        name: RouteConstants.editGroupName,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId'] ?? '';
          return EditGroupPage(groupId: groupId);
        },
      ),
      GoRoute(
        path: RouteConstants.accountSettingsPath,
        name: RouteConstants.accountSettingsName,
        builder: (context, state) => const AccountSettingsPage(),
      ),
      GoRoute(
        path: RouteConstants.emailSettingsPath,
        name: RouteConstants.emailSettingsName,
        builder: (context, state) => const EmailSettingsPage(),
      ),
      GoRoute(
        path: RouteConstants.accountSecurityPath,
        name: RouteConstants.accountSecurityName,
        builder: (context, state) => const SecurityPage(),
      ),
      GoRoute(
        path: RouteConstants.useBiometricsPath,
        name: RouteConstants.useBiometricsName,
        builder: (context, state) => const UseBiometricsPage(),
      ),
      GoRoute(
        path: '/account/friend-code',
        redirect: (context, state) => RouteConstants.friendCodePath,
      ),
      GoRoute(
        path: RouteConstants.appearancePath,
        name: RouteConstants.appearanceName,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AppearancePage(),
      ),
      GoRoute(
        path: RouteConstants.friendCodePath,
        name: RouteConstants.friendCodeName,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FriendCodePage(),
      ),
      GoRoute(
        path: RouteConstants.friendDetailPath,
        name: RouteConstants.friendDetailName,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final friendId = state.pathParameters['friendId'] ?? '';
          return FriendDetailPage(friendId: friendId);
        },
      ),
      GoRoute(
        path: RouteConstants.friendSettingsPath,
        name: RouteConstants.friendSettingsName,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final friendId = state.pathParameters['friendId'] ?? '';
          return FriendSettingsPage(friendId: friendId);
        },
      ),
      GoRoute(
        path: RouteConstants.addExpensePath,
        name: RouteConstants.addExpenseName,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final groupId = state.uri.queryParameters['groupId'];
          final friendId = state.uri.queryParameters['friendId'];
          return AddExpensePage(groupId: groupId, friendId: friendId);
        },
      ),
      GoRoute(
        path: RouteConstants.unknownPath,
        name: RouteConstants.unknownName,
        builder: (context, state) => const UnknownScreen(),
      ),
    ],
  );
}
