import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeBloc>().add(const LoadHome());
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg.r),
        ),
      ),
      builder: (bottomSheetContext) {
        return FilterBottomSheet(
          selectedFilter: _selectedFilter,
          onFilterSelected: (filter) {
            setState(() {
              _selectedFilter = filter;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return AppScaffold(
      appBar: AppBar(
        title: null, // Title hidden to match user design layout
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
      
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
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
              if (_selectedFilter == 'all') return true;
              if (_selectedFilter == 'owe') return group.balanceType == BalanceType.owe;
              if (_selectedFilter == 'owed') return group.balanceType == BalanceType.owed;
              if (_selectedFilter == 'settled') return group.balanceType == BalanceType.settled;
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
                      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.w),
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
                    child: filteredGroups.isEmpty && _selectedFilter == 'all'
                        ? SingleChildScrollView(
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
                                    const SnackBar(content: Text('Add Friend coming soon!')),
                                  );
                                },
                              ),
                            ),
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            children: [
                              OverallBalanceCard(
                                balance: summary.overallBalance,
                                selectedFilter: _selectedFilter,
                                onFilterTap: _showFilterBottomSheet,
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
                                      context.push('/group-detail/${group.groupId}');
                                    },
                                  ),
                                ),

                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
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
        },
      ),
      
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'scan_fab',
            elevation: 4,
            backgroundColor: const Color(0xFF2C2C2E),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt scanning coming soon!')),
              );
            },
            icon: const Icon(Icons.photo_camera_outlined, color: Colors.white),
            label: Text(
              'Scan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          FloatingActionButton.extended(
            heroTag: 'add_expense_fab',
            elevation: 4,
            backgroundColor: theme.colorScheme.primary,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Expense is coming soon!')),
              );
            },
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
            label: Text(
              'Add expense',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
