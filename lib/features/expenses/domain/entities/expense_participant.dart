import 'package:equatable/equatable.dart';

/// A lightweight person reference used across the Add Expense flow for
/// participant/payer selection (avoids depending on feature-specific user
/// models from other modules).
class ExpenseParticipant extends Equatable {
  final String id;
  final String name;
  final String? photoUrl;

  const ExpenseParticipant({
    required this.id,
    required this.name,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id, name, photoUrl];
}
