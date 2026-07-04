import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';

class FilterBottomSheet extends StatefulWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const FilterBottomSheet({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _currentFilter;

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'All Groups', 'icon': Icons.group_rounded},
    {'id': 'owe', 'label': 'You Owe', 'icon': Icons.arrow_outward_rounded},
    {'id': 'owed', 'label': 'You Are Owed', 'icon': Icons.call_received_rounded},
    {'id': 'settled', 'label': 'Settled', 'icon': Icons.check_circle_outline_rounded},
    {'id': 'archived', 'label': 'Archived', 'icon': Icons.archive_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.selectedFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            child: Text(
              'Filter Groups',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          ..._filters.map((filter) {
            final id = filter['id'] as String;
            final label = filter['label'] as String;
            final icon = filter['icon'] as IconData;
            final isSelected = _currentFilter == id;

            return ListTile(
              leading: Icon(
                icon,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(
                label,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                setState(() {
                  _currentFilter = id;
                });
                widget.onFilterSelected(id);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
