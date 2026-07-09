import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/overall_balance_card.dart';
import '../widgets/group_card.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../../domain/entities/balance_summary.dart';
import '../../domain/entities/group_summary.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeBloc>().add(const LoadHome());
      }
    });
  }

  Future<void> _openAddExpense() async {
    await context.pushNamed(RouteConstants.addExpenseName);
    if (mounted) {
      context.read<HomeBloc>().add(const RefreshHome());
    }
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final homeBloc = context.read<HomeBloc>();
    final homeState = homeBloc.state;
    if (homeState is HomeLoaded) {
      final direction = _scrollController.position.userScrollDirection;
      if (direction == ScrollDirection.reverse) {
        if (homeState.isFabExtended) {
          homeBloc.add(const ChangeFabExtension(false));
        }
      } else if (direction == ScrollDirection.forward) {
        if (!homeState.isFabExtended) {
          homeBloc.add(const ChangeFabExtension(true));
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(String currentFilter) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg.r),
        ),
      ),
      builder: (bottomSheetContext) {
        return FilterBottomSheet(
          selectedFilter: currentFilter,
          onFilterSelected: (filter) {
            context.read<HomeBloc>().add(ChangeFilter(filter));
          },
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    final theme = context.theme;

    if (state is HomeInitial || state is HomeLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w),
        child: Column(
          children: [
            SizedBox(height: AppDimensions.md.h),
            const SkeletonBalanceCard(),
            SizedBox(height: AppDimensions.lg.h),
            Expanded(
              child: ListView.builder(
                itemCount: 4,
                itemBuilder: (context, index) => const SkeletonGroupCard(),
              ),
            ),
          ],
        ),
      );
    }

    if (state is HomeError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.xl.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64.r,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: AppDimensions.lg.h),
              Text(
                'Oops, something went wrong!',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppDimensions.sm.h),
              Text(
                state.message,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.xl.h),
              SizedBox(
                width: 150.w,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<HomeBloc>().add(const LoadHome());
                  },
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is HomeLoaded) {
      final summary = state.summary;

      final filteredGroups = summary.groups.where((group) {
        if (group.groupType == GroupSummary.directGroupType) return false;
        if (state.selectedFilter == 'all') return true;
        if (state.selectedFilter == 'owe') {
          return group.balanceType == BalanceType.owe;
        }
        if (state.selectedFilter == 'owed') {
          return group.balanceType == BalanceType.owed;
        }
        if (state.selectedFilter == 'settled') {
          return group.balanceType == BalanceType.settled;
        }
        return true;
      }).toList();

      return RefreshIndicator(
        onRefresh: () async {
          context.read<HomeBloc>().add(const RefreshHome());
          await context.read<HomeBloc>().stream.firstWhere(
                (s) => s is! HomeRefreshing,
              );
        },
        child: Column(
          children: [
            if (state.isOffline)
              Container(
                width: double.infinity,
                color: theme.colorScheme.errorContainer,
                padding: EdgeInsets.symmetric(
                  vertical: 6.h,
                  horizontal: 16.w,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 16.r,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Offline mode. Showing cached data.',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: filteredGroups.isEmpty && state.selectedFilter == 'all'
                  ? SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: 500.h,
                        alignment: Alignment.center,
                        child: EmptyStateWidget(
                          title: 'No Groups Yet',
                          description: 'Create your first group to start splitting expenses.',
                          icon: Icons.group_add_outlined,
                          actionText: 'Create Group',
                          onAction: () => context.push('/create-group'),
                          secondaryActionText: 'Add Friend',
                          onSecondaryAction: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Add Friend coming soon!'),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: [
                        OverallBalanceCard(
                          balance: summary.overallBalance,
                          selectedFilter: state.selectedFilter,
                          onFilterTap: () => _showFilterBottomSheet(state.selectedFilter),
                        ),
                        const Divider(height: 1),
                        SizedBox(height: AppDimensions.sm.h),

                        if (filteredGroups.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            child: Center(
                              child: Text(
                                'No groups match this filter.',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                          )
                        else
                          ...filteredGroups.map(
                            (group) => GroupCard(
                              group: group,
                              onTap: () {
                                context.push(
                                  '/group-detail/${group.groupId}',
                                );
                              },
                            ),
                          ),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 32.h,
                            horizontal: 24.w,
                          ),
                          child: Text(
                            'Hiding groups that have been inactive for more than one month.',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final isFabExtended = state is HomeLoaded ? state.isFabExtended : true;

        return AppScaffold(
          appBar: AppBar(
            title: null,
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search is coming soon!')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.group_add_outlined),
                tooltip: 'Create a group',
                onPressed: () => context.push('/create-group'),
              ),
            ],
          ),
          body: _buildBody(context, state),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildAnimatedFab(
                isFabExtended: isFabExtended,
                heroTag: 'scan_fab',
                icon: Icons.photo_camera_outlined,
                label: 'Scan',
                backgroundColor: context.appColors.elevatedSurface,
                foregroundColor: context.appColors.onImageColor,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receipt scanning coming soon!')),
                  );
                },
              ),
              SizedBox(height: 12.h),
              _buildAnimatedFab(
                isFabExtended: isFabExtended,
                heroTag: 'add_expense_fab',
                icon: Icons.receipt,
                label: 'Add expense',
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                onPressed: _openAddExpense,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedFab({
    required bool isFabExtended,
    required String heroTag,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    Color? foregroundColor,
    required VoidCallback onPressed,
  }) {
    final textWidth = label.length * 8.0.w;
    final width = isFabExtended ? (48.0.w + textWidth + 8.w) : 48.0.w;
    const durationTimeInMilliSeconds = 500;
    final contentColor = foregroundColor ?? context.appColors.onImageColor;

    return Hero(
      tag: heroTag,
      child: Material(
        elevation: 4,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24.0.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: durationTimeInMilliSeconds),
            curve: Curves.easeInOut,
            width: width,
            height: 48.0.h,
            alignment: Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: contentColor, size: 22.0.r),
                  AnimatedContainer(
                    duration: const Duration(
                      milliseconds: durationTimeInMilliSeconds,
                    ),
                    curve: Curves.easeInOut,
                    width: isFabExtended ? 8.0.w : 0.0,
                  ),
                  AnimatedContainer(
                    duration: const Duration(
                      milliseconds: durationTimeInMilliSeconds,
                    ),
                    curve: Curves.easeInOut,
                    width: isFabExtended ? textWidth : 0.0,
                    child: AnimatedOpacity(
                      duration: const Duration(
                        milliseconds: durationTimeInMilliSeconds,
                      ),
                      curve: Curves.easeInOut,
                      opacity: isFabExtended ? 1.0 : 0.0,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: contentColor,
                          fontSize: 14.0.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
