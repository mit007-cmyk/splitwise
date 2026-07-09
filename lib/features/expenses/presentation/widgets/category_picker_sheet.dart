import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../bloc/add_expense_bloc.dart';
import '../bloc/add_expense_event.dart';
import '../bloc/add_expense_state.dart';

class ExpenseCategory {
  final String name;
  final IconData icon;

  const ExpenseCategory(this.name, this.icon);
}

const List<ExpenseCategory> kExpenseCategories = [
  ExpenseCategory('General', Icons.receipt_long_outlined),
  ExpenseCategory('Food & Dining', Icons.restaurant_outlined),
  ExpenseCategory('Groceries', Icons.local_grocery_store_outlined),
  ExpenseCategory('Home', Icons.home_outlined),
  ExpenseCategory('Utilities', Icons.bolt_outlined),
  ExpenseCategory('Transportation', Icons.directions_car_outlined),
  ExpenseCategory('Entertainment', Icons.movie_outlined),
  ExpenseCategory('Health', Icons.local_hospital_outlined),
  ExpenseCategory('Shopping', Icons.shopping_bag_outlined),
  ExpenseCategory('Travel', Icons.flight_takeoff_outlined),
];

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
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(AppDimensions.lg.w),
                child: Text(
                  'Choose a category',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              ...kExpenseCategories.map(
                (category) => ListTile(
                  leading: Icon(category.icon, color: scheme.onSurface),
                  title: Text(category.name),
                  trailing: state.category == category.name
                      ? Icon(Icons.check, color: scheme.primary)
                      : null,
                  onTap: () {
                    context.read<AddExpenseBloc>().add(CategoryChanged(category.name));
                    Navigator.of(context).pop();
                  },
                ),
              ),
              SizedBox(height: AppDimensions.sm.h),
            ],
          ),
        );
      },
    );
  }
}
