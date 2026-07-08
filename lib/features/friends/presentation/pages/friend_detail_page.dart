import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../domain/entities/user_preview.dart';
import '../../domain/repositories/friends_repository.dart';
import '../widgets/add_expense_extended_fab.dart';
import '../widgets/friend_action_pill.dart';
import '../widgets/friend_expenses_empty_state.dart';

class FriendDetailPage extends StatefulWidget {
  final String friendId;

  const FriendDetailPage({
    super.key,
    required this.friendId,
  });

  @override
  State<FriendDetailPage> createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends State<FriendDetailPage> {
  UserPreview? _friend;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFriend();
  }

  Future<void> _loadFriend() async {
    final result =
        await getIt<FriendsRepository>().getUserById(widget.friendId);

    if (!mounted) return;

    if (result.isSuccess && result.dataOrThrow != null) {
      setState(() {
        _friend = result.dataOrThrow;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = 'Friend not found';
    });
  }

  Color _heroColor(String name) {
    return AppColors.avatarPlaceholders[
        name.length % AppColors.avatarPlaceholders.length];
  }

  Color _heroColorDark(String name) {
    return Color.lerp(_heroColor(name), AppColors.shadow, 0.35)!;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildBody(context, _friend!),
      floatingActionButton: _friend == null
          ? null
          : const AddExpenseExtendedFab(),
    );
  }

  Widget _buildBody(
    BuildContext context,
    UserPreview friend,
  ) {
    final scheme = context.colorScheme;
    final appColors = context.appColors;
    final heroColor = _heroColor(friend.name);
    final heroColorDark = _heroColorDark(friend.name);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: 148.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [heroColor, heroColorDark],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: appColors.onImageColor,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                appColors.overlayColor.withValues(alpha: 0.3),
                            shape: const CircleBorder(),
                          ),
                          onPressed: () => context.pop(),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.settings_outlined,
                            color: appColors.onImageColor,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                appColors.overlayColor.withValues(alpha: 0.3),
                            shape: const CircleBorder(),
                          ),
                          onPressed: () async {
                            await context.pushNamed(
                              RouteConstants.friendSettingsName,
                              pathParameters: {'friendId': widget.friendId},
                            );
                            if (mounted) {
                              _loadFriend();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 108.h,
                child: AvatarWidget(
                  name: friend.name,
                  imageUrl: friend.photoUrl,
                  size: 88.w,
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.lg.w,
              52.h,
              AppDimensions.lg.w,
              0,
            ),
            child: Column(
              children: [
                Text(
                  friend.name,
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'No expenses here yet.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
                SizedBox(height: AppDimensions.lg.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FriendActionPill(
                        label: 'Settle up',
                        onTap: () => _showComingSoon(context),
                      ),
                      FriendActionPill(
                        label: 'Remind...',
                        onTap: () => _showComingSoon(context),
                      ),
                      FriendActionPill(
                        label: 'Charts',
                        icon: Icons.diamond_rounded,
                        onTap: () => _showComingSoon(context),
                      ),
                      FriendActionPill(
                        label: 'Balances',
                        onTap: () => _showComingSoon(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: FriendExpensesEmptyState(),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon!')),
    );
  }
}
