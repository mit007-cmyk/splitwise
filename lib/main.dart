import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/di/di.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/localization/app_localizations.dart';
import 'core/errors/global_bloc_observer.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/services/app_logger.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/home/presentation/bloc/home_event.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialize Firebase safely
    // (Prevents startup crashes on systems that don't have google-services files configured yet)
    try {
      await Firebase.initializeApp();
      
      // Hook Flutter error handler to Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      
      // Hook asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      debugPrint('Firebase initialization warning: missing configurations -> $e');
    }

    // 2. Configure Dependency Injection
    await configureDependencies();

    final logger = getIt<AppLogger>();
    logger.i('Dependency Injection configured.');

    // 3. Initialize Hive local databases
    try {
      await getIt<HiveService>().init();
    } catch (e, stack) {
      logger.e('Failed to initialize HiveService', e, stack);
    }

    // 4. Initialize FCM messaging infrastructure
    try {
      await getIt<NotificationService>().init();
    } catch (e, stack) {
      logger.e('Failed to initialize FCM NotificationService', e, stack);
    }

    // 5. Initialize Firebase Remote Config
    try {
      await getIt<RemoteConfigService>().init();
    } catch (e, stack) {
      logger.e('Failed to initialize RemoteConfigService', e, stack);
    }

    // 6. Set Bloc observer
    Bloc.observer = GlobalBlocObserver(logger);

    runApp(const MyApp());
  }, (error, stackTrace) {
    // Catch-all block for errors escaping zoning
    debugPrint('Zoned error caught: $error');
    try {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    } catch (_) {}
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(const CheckAuthStatus()),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => getIt<HomeBloc>()..add(const LoadHome()),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'Splitwise',
            debugShowCheckedModeBanner: false,
            
            // Theme settings
            themeMode: ThemeMode.system,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,

            // Routing configuration
            routerConfig: AppRouter.router,

            // Localization config
            supportedLocales: const [
              Locale('en'),
              Locale('es'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
