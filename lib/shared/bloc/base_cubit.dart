import 'package:flutter_bloc/flutter_bloc.dart';
import 'base_state.dart';

abstract class BaseCubit<S extends BaseState> extends Cubit<S> {
  BaseCubit(super.initialState);
}
