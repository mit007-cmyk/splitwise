import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHome extends HomeEvent {
  const LoadHome();
}

class RefreshHome extends HomeEvent {
  const RefreshHome();
}

class SearchTapped extends HomeEvent {
  const SearchTapped();
}

class FilterTapped extends HomeEvent {
  const FilterTapped();
}

class GroupTapped extends HomeEvent {
  final String groupId;
  const GroupTapped(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class AddExpenseTapped extends HomeEvent {
  const AddExpenseTapped();
}

class CreateGroupRequested extends HomeEvent {
  final String name;
  final String type;

  const CreateGroupRequested({
    required this.name,
    required this.type,
  });

  @override
  List<Object?> get props => [name, type];
}

class AddContactRequested extends HomeEvent {
  final String name;
  final String emailOrPhone;

  const AddContactRequested({
    required this.name,
    required this.emailOrPhone,
  });

  @override
  List<Object?> get props => [name, emailOrPhone];
}

class AddGroupMembersRequested extends HomeEvent {
  final String groupId;
  final List<String> memberIds;

  const AddGroupMembersRequested({
    required this.groupId,
    required this.memberIds,
  });

  @override
  List<Object?> get props => [groupId, memberIds];
}

class EditGroupRequested extends HomeEvent {
  final String groupId;
  final String name;
  final String type;

  const EditGroupRequested({
    required this.groupId,
    required this.name,
    required this.type,
  });

  @override
  List<Object?> get props => [groupId, name, type];
}

class LeaveGroupRequested extends HomeEvent {
  final String groupId;

  const LeaveGroupRequested({
    required this.groupId,
  });

  @override
  List<Object?> get props => [groupId];
}

class ChangeFilter extends HomeEvent {
  final String filter;
  const ChangeFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

class ChangeFabExtension extends HomeEvent {
  final bool isExtended;
  const ChangeFabExtension(this.isExtended);

  @override
  List<Object?> get props => [isExtended];
}
