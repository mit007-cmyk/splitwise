import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../utils/context_extension.dart';

class FilterOption {
  final String id;
  final String label;

  const FilterOption({required this.id, required this.label});
}

class FilterPopupButton extends StatelessWidget {
  static const List<FilterOption> groupFilters = [
    FilterOption(id: 'all', label: 'All groups'),
    FilterOption(id: 'owe', label: 'Groups you owe'),
    FilterOption(id: 'owed', label: 'Groups that owe you'),
    FilterOption(id: 'settled', label: 'Settled up'),
  ];

  static const List<FilterOption> friendFilters = [
    FilterOption(id: 'all', label: 'All friends'),
    FilterOption(id: 'outstanding', label: 'Outstanding balances'),
    FilterOption(id: 'owe', label: 'Friends you owe'),
    FilterOption(id: 'owed', label: 'Friends who owe you'),
  ];

  final String selectedFilter;
  final List<FilterOption> options;
  final ValueChanged<String> onSelected;

  const FilterPopupButton({
    super.key,
    required this.selectedFilter,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isFiltered = selectedFilter != 'all';

    return PopupMenuButton<String>(
      tooltip: 'Filter',
      offset: Offset(0, 8.h),
      position: PopupMenuPosition.under,
      color: scheme.surfaceContainerHigh,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: 240.w, maxWidth: 300.w),
      icon: Icon(
        Icons.tune,
        color: isFiltered ? scheme.primary : scheme.onSurfaceVariant,
      ),
      onSelected: onSelected,
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem<String>(
          value: option.id,
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: _FilterPopupItem(
            label: option.label,
            isSelected: option.id == selectedFilter,
          ),
        );
      }).toList(),
    );
  }
}

class _FilterPopupItem extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterPopupItem({
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final selectedColor = scheme.primary;

    return Row(
      children: [
        _RadioDot(isSelected: isSelected, selectedColor: selectedColor),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: context.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool isSelected;
  final Color selectedColor;

  const _RadioDot({
    required this.isSelected,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final borderColor = isSelected ? selectedColor : scheme.onSurface;

    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selectedColor,
              ),
            )
          : null,
    );
  }
}
