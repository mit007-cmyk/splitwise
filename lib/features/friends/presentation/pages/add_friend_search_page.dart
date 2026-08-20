import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/phone_contact.dart';
import '../../domain/entities/user_preview.dart';
import '../bloc/add_friend_search_cubit.dart';
import '../bloc/friends_list_cubit.dart';

class AddFriendSearchPage extends StatefulWidget {
  const AddFriendSearchPage({super.key});

  @override
  State<AddFriendSearchPage> createState() => _AddFriendSearchPageState();
}

class _AddFriendSearchPageState extends State<AddFriendSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late final AddFriendSearchCubit _cubit;

  @override
  void initState() {
    super.initState();
    final userId = _currentUserId();
    _cubit = getIt<AddFriendSearchCubit>()
      ..loadContacts(currentUserId: userId ?? '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  String? _currentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.id;
    return null;
  }

  void _openAddSomeoneNew() {
    context.pushNamed(RouteConstants.addFriendNewName);
  }

  void _openContact(PhoneContact contact) {
    final params = <String, String>{
      if (contact.displayName.isNotEmpty) 'name': contact.displayName,
      if (contact.phone != null) 'phone': contact.phone!,
      if (contact.email != null) 'email': contact.email!,
    };
    context.pushNamed(
      RouteConstants.addFriendNewName,
      queryParameters: params,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: context.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Enter name, email, or phone #',
                          hintStyle: context.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                        ),
                        onChanged: _cubit.filter,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              InkWell(
                onTap: _openAddSomeoneNew,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg.w,
                    vertical: AppDimensions.lg.h,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22.r,
                        backgroundColor:
                            scheme.onSurface.withValues(alpha: 0.06),
                        child: Icon(
                          Icons.person_add_alt_1_outlined,
                          color: scheme.onSurface,
                          size: 22.r,
                        ),
                      ),
                      SizedBox(width: AppDimensions.lg.w),
                      Text(
                        'Add someone new',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: BlocConsumer<AddFriendSearchCubit, AddFriendSearchState>(
                  listener: (context, state) {
                    if (state.addedFriendName != null) {
                      AppToast.show(
                        context,
                        '${state.addedFriendName} added as a friend.',
                        type: ToastType.success,
                      );
                      final uid = _currentUserId();
                      if (uid != null) getIt<FriendsListCubit>().load(uid);
                    } else if (state.errorMessage != null) {
                      AppToast.show(
                        context,
                        state.errorMessage!,
                        type: ToastType.error,
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.permissionDenied) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppDimensions.xl.w),
                          child: Text(
                            'Contacts permission is required to show your contacts. '
                            'Enable it in app settings.',
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }

                    if (state.filteredContacts.isEmpty) {
                      return Center(
                        child: Text(
                          state.query.isEmpty
                              ? 'No contacts found.'
                              : 'No matching contacts.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return ListView(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppDimensions.lg.w,
                            AppDimensions.sm.h,
                            AppDimensions.lg.w,
                            AppDimensions.sm.h,
                          ),
                          child: Text(
                            'From your contacts',
                            style: context.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                        ...state.filteredContacts.map(
                          (contact) => _ContactTile(
                            contact: contact,
                            registered: state.registeredMatches[contact.id],
                            isFriend: () {
                              final user = state.registeredMatches[contact.id];
                              return user != null &&
                                  state.friendIds.contains(user.id);
                            }(),
                            isInvited: state.invitedContactIds.contains(contact.id),
                            isAdding: state.addingContactIds.contains(contact.id),
                            onAdd: () {
                              final uid = _currentUserId();
                              if (uid == null) return;
                              _cubit.addRegisteredContact(
                                currentUserId: uid,
                                contact: contact,
                              );
                            },
                            onInvite: () => _openContact(contact),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final PhoneContact contact;
  final UserPreview? registered;
  final bool isFriend;
  final bool isInvited;
  final bool isAdding;
  final VoidCallback onAdd;
  final VoidCallback onInvite;

  const _ContactTile({
    required this.contact,
    required this.registered,
    required this.isFriend,
    required this.isInvited,
    required this.isAdding,
    required this.onAdd,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final onSplitwise = registered != null;
    final subtitle = onSplitwise
        ? (isFriend ? 'Already friends' : 'On Splitwise')
        : (isInvited ? 'Invite sent' : (contact.subtitle.isNotEmpty
            ? contact.subtitle
            : 'Not on Splitwise'));

    return ListTile(
      leading: onSplitwise
          ? AvatarWidget(
              name: registered!.name,
              imageUrl: registered!.photoUrl,
              size: 44.w,
            )
          : CircleAvatar(
              radius: 22.r,
              backgroundColor: scheme.surfaceContainerHighest,
              child: Icon(
                contact.phone != null ? Icons.phone : Icons.email_outlined,
                color: scheme.onSurfaceVariant,
                size: 20.r,
              ),
            ),
      title: Text(
        contact.displayName,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: context.textTheme.bodySmall?.copyWith(
          color: onSplitwise && !isFriend
              ? scheme.primary
              : scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      trailing: _trailing(context),
      onTap: onSplitwise
          ? (isFriend || isAdding ? null : onAdd)
          : (isInvited ? null : onInvite),
    );
  }

  Widget? _trailing(BuildContext context) {
    final scheme = context.colorScheme;
    if (isAdding) {
      return SizedBox(
        width: 22.w,
        height: 22.w,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (isFriend || isInvited) {
      return Icon(Icons.check, color: scheme.primary);
    }
    if (registered != null) {
      return TextButton(
        onPressed: onAdd,
        child: const Text('Add'),
      );
    }
    return TextButton(
      onPressed: onInvite,
      child: const Text('Invite'),
    );
  }
}
