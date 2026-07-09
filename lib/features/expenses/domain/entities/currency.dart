import 'package:equatable/equatable.dart';

class Currency extends Equatable {
  final String code;
  final String symbol;
  final String name;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  @override
  List<Object?> get props => [code, symbol, name];
}
