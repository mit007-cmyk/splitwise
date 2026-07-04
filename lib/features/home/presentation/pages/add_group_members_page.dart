import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/repositories/home_repository.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';

class AddGroupMembersPage extends StatefulWidget {
  final String groupId;

  const AddGroupMembersPage({
    super.key,
    required this.groupId,
  });

  @override
  State<AddGroupMembersPage> createState() => _AddGroupMembersPageState();
}

class _AddGroupMembersPageState extends State<AddGroupMembersPage> {
  final _searchController = TextEditingController();
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFriends() async {
    final result = await getIt<HomeRepository>().getAllUsers();
    if (mounted) {
      setState(() {
        _allUsers = result.isSuccess ? result.dataOrThrow : [];
        _filteredUsers = _allUsers;
        _isLoading = false;
      });
    }
  }

  void _filterFriends(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          final nameMatch = user.name.toLowerCase().contains(query.toLowerCase());
          final emailMatch = user.email.toLowerCase().contains(query.toLowerCase());
          return nameMatch || emailMatch;
        }).toList();
      }
    });
  }

  void _addMember(String userId, String userName) {
    context.read<HomeBloc>().add(AddGroupMembersRequested(
      groupId: widget.groupId,
      memberIds: [userId],
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$userName added to the group!')),
    );
    context.pop();
  }

  Widget _buildUserAvatar(UserModel user) {
    final colors = [
      const Color(0xFF0F766E), // teal
      const Color(0xFF1E3A8A), // deep blue
      const Color(0xFF065F46), // deep green
      const Color(0xFF9D174D), // pink
      const Color(0xFF374151), // slate grey
    ];
    final index = user.name.length % colors.length;
    final color = colors[index];
    final initial = user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U';

    return CircleAvatar(
      radius: 22.r,
      backgroundColor: color,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom Search AppBar
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
                      style: TextStyle(fontSize: 16.sp, color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Enter name, email, or phone #',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                      ),
                      onChanged: _filterFriends,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),

            // Trigger to go to Add Friend
            InkWell(
              onTap: () async {
                await context.push('/add-friend');
                _fetchFriends(); // Refresh lists when returning
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22.r,
                      backgroundColor: theme.colorScheme.onSurface.withOpacity(0.06),
                      child: Icon(
                        Icons.person_add_alt_1_outlined,
                        color: theme.colorScheme.onSurface,
                        size: 22.r,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      'Add a new contact to Splitwise',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                'Friends on Splitwise',
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? Center(
                          child: Text(
                            'No contacts found.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return ListTile(
                              leading: _buildUserAvatar(user),
                              title: Text(
                                user.name,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 4.h,
                              ),
                              onTap: () => _addMember(user.id, user.name),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
