import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../activity/presentation/bloc/activity_bloc.dart';
import '../../../activity/presentation/bloc/activity_event.dart';

class MainNavigationPage extends StatelessWidget {
  static const int activityTabIndex = 2;

  final StatefulNavigationShell navigationShell;

  const MainNavigationPage({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    if (index == activityTabIndex) {
      context.read<ActivityBloc>().add(const RefreshActivity());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: theme.colorScheme.background,
        indicatorColor: Colors.transparent, // flat active icon style
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group, color: theme.colorScheme.primary),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: theme.colorScheme.primary),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart_rounded),
            selectedIcon: Icon(Icons.show_chart_rounded, color: theme.colorScheme.primary),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle, color: theme.colorScheme.primary),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
