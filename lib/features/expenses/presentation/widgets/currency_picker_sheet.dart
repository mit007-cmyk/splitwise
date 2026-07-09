import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../bloc/add_expense_bloc.dart';
import '../bloc/add_expense_event.dart';
import '../bloc/add_expense_state.dart';

/// Searchable currency picker, shown as a modal bottom sheet. All state
/// (search query, filtered results, selection) lives in [AddExpenseBloc].
class CurrencyPickerSheet extends StatelessWidget {
  const CurrencyPickerSheet({super.key});

  static Future<void> show(BuildContext context, AddExpenseBloc bloc) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl.r)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: const CurrencyPickerSheet(),
      ),
    ).whenComplete(() => bloc.add(const CurrencySearchChanged('')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return BlocBuilder<AddExpenseBloc, AddExpenseState>(
          builder: (context, state) {
            final results = state.filteredCurrencies;

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimensions.lg.w,
                    AppDimensions.md.h,
                    AppDimensions.lg.w,
                    AppDimensions.sm.h,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Search or select a currency',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg.w),
                  child: TextField(
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Search currencies',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: AppDimensions.md.w),
                    ),
                    onChanged: (value) =>
                        context.read<AddExpenseBloc>().add(CurrencySearchChanged(value)),
                  ),
                ),
                SizedBox(height: AppDimensions.sm.h),
                Expanded(
                  child: results.isEmpty
                      ? Center(
                          child: Text(
                            'No currencies found',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final currency = results[index];
                            final isSelected = currency.code == state.currency.code;

                            return ListTile(
                              leading: SizedBox(
                                width: 32.w,
                                child: Text(
                                  currency.symbol,
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.titleMedium,
                                ),
                              ),
                              title: Text(currency.name),
                              subtitle: Text(currency.code),
                              trailing: isSelected
                                  ? Icon(Icons.check, color: scheme.primary)
                                  : null,
                              onTap: () {
                                context.read<AddExpenseBloc>().add(CurrencySelected(currency));
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
