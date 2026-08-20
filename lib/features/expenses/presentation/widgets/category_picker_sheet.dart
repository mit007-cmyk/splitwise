import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/context_extension.dart';
import '../bloc/add_expense_bloc.dart';
import '../bloc/add_expense_event.dart';
import '../bloc/add_expense_state.dart';
import '../../domain/entities/app_category.dart';
import '../../domain/entities/default_categories.dart';
import 'category_icons.dart';

enum _ExpenseCategoryKind {
  general,
  food,
  groceries,
  home,
  utilities,
  transportation,
  entertainment,
  health,
  shopping,
  travel,
  settlement,
}

class ExpenseCategory {
  final String name;
  final IconData icon;

  const ExpenseCategory(this.name, this.icon);

  /// Filled icon for list tiles and badges.
  static IconData iconFor(String? name, {String? iconKey}) {
    if (iconKey != null && iconKey.trim().isNotEmpty) {
      return CategoryIcons.dataFor(iconKey);
    }
    switch (_kindFor(name)) {
      case _ExpenseCategoryKind.food:
        return Icons.restaurant_rounded;
      case _ExpenseCategoryKind.groceries:
        return Icons.local_grocery_store_rounded;
      case _ExpenseCategoryKind.home:
        return Icons.home_rounded;
      case _ExpenseCategoryKind.utilities:
        return Icons.bolt_rounded;
      case _ExpenseCategoryKind.transportation:
        return Icons.directions_car_rounded;
      case _ExpenseCategoryKind.entertainment:
        return Icons.movie_rounded;
      case _ExpenseCategoryKind.health:
        return Icons.local_hospital_rounded;
      case _ExpenseCategoryKind.shopping:
        return Icons.shopping_bag_rounded;
      case _ExpenseCategoryKind.travel:
        return Icons.flight_takeoff_rounded;
      case _ExpenseCategoryKind.settlement:
        return Icons.payments_rounded;
      case _ExpenseCategoryKind.general:
        return Icons.receipt_long_rounded;
    }
  }

  /// Saturated tile colour behind [iconFor], with white glyphs.
  static Color backgroundFor(String? name, {String? iconKey}) {
    final kind = _kindFor(name);
    if (kind == _ExpenseCategoryKind.general) {
      final needle = name?.trim().toLowerCase() ?? '';
      if (needle.isNotEmpty && needle != 'general') {
        return _hashedColor(iconKey ?? name ?? 'general');
      }
    }
    switch (kind) {
      case _ExpenseCategoryKind.food:
        return AppColors.categoryFood;
      case _ExpenseCategoryKind.groceries:
        return AppColors.categoryGroceries;
      case _ExpenseCategoryKind.home:
        return AppColors.categoryHome;
      case _ExpenseCategoryKind.utilities:
        return AppColors.categoryUtilities;
      case _ExpenseCategoryKind.transportation:
        return AppColors.categoryTransportation;
      case _ExpenseCategoryKind.entertainment:
        return AppColors.categoryEntertainment;
      case _ExpenseCategoryKind.health:
        return AppColors.categoryHealth;
      case _ExpenseCategoryKind.shopping:
        return AppColors.categoryShopping;
      case _ExpenseCategoryKind.travel:
        return AppColors.categoryTravel;
      case _ExpenseCategoryKind.settlement:
        return AppColors.categorySettlement;
      case _ExpenseCategoryKind.general:
        return AppColors.categoryGeneral;
    }
  }

  static Color _hashedColor(String seed) {
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return AppColors.chartCategories[hash % AppColors.chartCategories.length];
  }

  static _ExpenseCategoryKind _kindFor(String? name) {
    final needle = name?.trim().toLowerCase() ?? '';
    if (needle.isEmpty) return _ExpenseCategoryKind.general;
    if (needle == 'settlement') return _ExpenseCategoryKind.settlement;
    for (final category in kExpenseCategories) {
      if (category.name.toLowerCase() == needle) {
        return _kindFromPickerName(category.name);
      }
    }
    if (_containsAny(needle, const ['food', 'dining', 'restaurant', 'meal'])) {
      return _ExpenseCategoryKind.food;
    }
    if (_containsAny(needle, const ['grocery', 'groceries'])) {
      return _ExpenseCategoryKind.groceries;
    }
    if (_containsAny(needle, const ['home', 'house', 'rent'])) {
      return _ExpenseCategoryKind.home;
    }
    if (_containsAny(needle, const ['utilit', 'electric', 'internet'])) {
      return _ExpenseCategoryKind.utilities;
    }
    if (_containsAny(needle, const ['transport', 'car', 'uber', 'taxi'])) {
      return _ExpenseCategoryKind.transportation;
    }
    if (_containsAny(needle, const ['entertain', 'movie'])) {
      return _ExpenseCategoryKind.entertainment;
    }
    if (_containsAny(needle, const ['health', 'medical', 'hospital'])) {
      return _ExpenseCategoryKind.health;
    }
    if (_containsAny(needle, const ['shop'])) {
      return _ExpenseCategoryKind.shopping;
    }
    if (_containsAny(needle, const ['travel', 'trip', 'flight'])) {
      return _ExpenseCategoryKind.travel;
    }
    return _ExpenseCategoryKind.general;
  }

  static _ExpenseCategoryKind _kindFromPickerName(String name) {
    switch (name) {
      case 'Food & Dining':
        return _ExpenseCategoryKind.food;
      case 'Groceries':
        return _ExpenseCategoryKind.groceries;
      case 'Home':
        return _ExpenseCategoryKind.home;
      case 'Utilities':
        return _ExpenseCategoryKind.utilities;
      case 'Transportation':
        return _ExpenseCategoryKind.transportation;
      case 'Entertainment':
        return _ExpenseCategoryKind.entertainment;
      case 'Health':
        return _ExpenseCategoryKind.health;
      case 'Shopping':
        return _ExpenseCategoryKind.shopping;
      case 'Travel':
        return _ExpenseCategoryKind.travel;
      default:
        return _ExpenseCategoryKind.general;
    }
  }

  static bool _containsAny(String needle, List<String> tokens) {
    return tokens.any((token) => needle.contains(token));
  }
}

const List<ExpenseCategory> kExpenseCategories = [
  ExpenseCategory('General', Icons.receipt_long_rounded),
  ExpenseCategory('Food & Dining', Icons.restaurant_rounded),
  ExpenseCategory('Groceries', Icons.local_grocery_store_rounded),
  ExpenseCategory('Home', Icons.home_rounded),
  ExpenseCategory('Utilities', Icons.bolt_rounded),
  ExpenseCategory('Transportation', Icons.directions_car_rounded),
  ExpenseCategory('Entertainment', Icons.movie_rounded),
  ExpenseCategory('Health', Icons.local_hospital_rounded),
  ExpenseCategory('Shopping', Icons.shopping_bag_rounded),
  ExpenseCategory('Travel', Icons.flight_takeoff_rounded),
];

class ExpenseCategoryGlyph extends StatelessWidget {
  final String category;
  final String? iconKey;
  final double size;

  const ExpenseCategoryGlyph({
    super.key,
    required this.category,
    this.iconKey,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ExpenseCategory.backgroundFor(category, iconKey: iconKey),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        ExpenseCategory.iconFor(category, iconKey: iconKey),
        size: size * 0.55,
        color: AppColors.onImageLight,
      ),
    );
  }
}

class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({super.key});

  static Future<void> show(BuildContext context, AddExpenseBloc bloc) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl.r)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: const CategoryPickerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocBuilder<AddExpenseBloc, AddExpenseState>(
      builder: (context, state) {
        final defaults = state.defaultCategories.isEmpty
            ? DefaultCategories.forPicker
            : state.defaultCategories;
        final canAddCustom = state.groupId != null && state.groupId!.isNotEmpty;

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.all(AppDimensions.lg.w),
                  child: Text(
                    'Choose a category',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _sectionLabel(context, 'Default'),
                ...defaults.map(
                  (category) => _CategoryTile(
                    category: category,
                    selected: _isSelected(state, category),
                    onTap: () {
                      context.read<AddExpenseBloc>().add(CategoryChanged(category));
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                if (canAddCustom) ...[
                  SizedBox(height: AppDimensions.sm.h),
                  _sectionLabel(context, 'Custom Categories'),
                  if (state.customCategories.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.lg.w,
                        vertical: AppDimensions.sm.h,
                      ),
                      child: Text(
                        'No custom categories yet',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ...state.customCategories.map(
                    (category) => _CategoryTile(
                      category: category,
                      selected: _isSelected(state, category),
                      onTap: () {
                        context.read<AddExpenseBloc>().add(CategoryChanged(category));
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.add, color: scheme.primary),
                    title: Text(
                      'Add category',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    enabled: !state.isSavingCategory,
                    onTap: () => _AddCategorySheet.show(context),
                  ),
                ],
                SizedBox(height: AppDimensions.sm.h),
              ],
            ),
          ),
        );
      },
    );
  }

  static bool _isSelected(AddExpenseState state, AppCategory category) {
    return state.categoryId == category.id &&
        state.categorySource == category.source;
  }

  static Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.lg.w,
        AppDimensions.sm.h,
        AppDimensions.lg.w,
        AppDimensions.xs.h,
      ),
      child: Text(
        label.toUpperCase(),
        style: context.textTheme.labelSmall?.copyWith(
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final AppCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ExpenseCategoryGlyph(
        category: category.name,
        iconKey: category.iconKey,
        size: 32.w,
      ),
      title: Text(category.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) Icon(Icons.check, color: context.colorScheme.primary),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet();

  static Future<void> show(BuildContext context) {
    final bloc = context.read<AddExpenseBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl.r),
        ),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: const _AddCategorySheet(),
        ),
      ),
    );
  }

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameController = TextEditingController();
  String _iconKey = 'pets';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add category',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppDimensions.lg.h),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Pet Supplies',
              ),
            ),
            SizedBox(height: AppDimensions.lg.h),
            Text(
              'Icon',
              style: context.textTheme.labelLarge,
            ),
            SizedBox(height: AppDimensions.sm.h),
            Wrap(
              spacing: AppDimensions.sm.w,
              runSpacing: AppDimensions.sm.h,
              children: [
                for (final key in CategoryIcons.pickerKeys)
                  InkWell(
                    onTap: () => setState(() => _iconKey = key),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd.r),
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: _iconKey == key
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd.r),
                        border: Border.all(
                          color: _iconKey == key
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                      child: Icon(
                        CategoryIcons.dataFor(key),
                        color: _iconKey == key
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppDimensions.xl.h),
            FilledButton(
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;
                context.read<AddExpenseBloc>().add(
                      CreateCustomCategoryRequested(
                        name: name,
                        iconKey: _iconKey,
                      ),
                    );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
