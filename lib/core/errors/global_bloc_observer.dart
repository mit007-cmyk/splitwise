import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../services/app_logger.dart';

class GlobalBlocObserver extends BlocObserver {
  final AppLogger _logger;

  GlobalBlocObserver(this._logger);

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _logger.d('Bloc Created: ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _logger.d('Bloc Changed: ${bloc.runtimeType} -> $change');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _logger.d('Bloc Transition: ${bloc.runtimeType} -> $transition');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _logger.e('Bloc Error: ${bloc.runtimeType} -> $error', error, stackTrace);
    
    // Log to Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: 'Bloc Error in ${bloc.runtimeType}',
      printDetails: false,
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _logger.d('Bloc Closed: ${bloc.runtimeType}');
  }
}
