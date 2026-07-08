import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../domain/entities/phone_contact.dart';
import '../bloc/add_friend_search_cubit.dart';

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
    _cubit = getIt<AddFriendSearchCubit>()..loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
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
                child: BlocBuilder<AddFriendSearchCubit, AddFriendSearchState>(
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
                          (contact) => ListTile(
                            leading: contact.phone != null
                                ? CircleAvatar(
                                    radius: 22.r,
                                    backgroundColor: scheme
                                        .surfaceContainerHighest,
                                    child: Icon(
                                      Icons.phone,
                                      color: scheme.onSurfaceVariant,
                                      size: 20.r,
                                    ),
                                  )
                                : AvatarWidget(
                                    name: contact.displayName,
                                    size: 44.w,
                                  ),
                            title: Text(
                              contact.displayName,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: contact.subtitle.isNotEmpty
                                ? Text(
                                    contact.subtitle,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                      color: scheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                    ),
                                  )
                                : null,
                            onTap: () => _openContact(contact),
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
