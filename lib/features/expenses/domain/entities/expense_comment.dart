import 'package:equatable/equatable.dart';

/// One comment on an expense, stored under that expense's `comments` map.
class ExpenseComment extends Equatable {
  final String id;
  final String createdBy;
  final String text;
  final DateTime createdAt;

  const ExpenseComment({
    required this.id,
    required this.createdBy,
    required this.text,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, createdBy, text, createdAt];
}
