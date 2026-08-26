import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/app_toast.dart';
import 'package:splitwise/features/activity/presentation/bloc/activity_bloc.dart';
import 'package:splitwise/features/activity/presentation/bloc/activity_event.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_event.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedType = 'trip';
  
  bool _addSettleUpReminders = false;
  bool _addTripDates = false;
  
  DateTime? _startDate;
  DateTime? _endDate;

  DateTime get _today => _dateOnly(DateTime.now());

  DateTime get _minSelectableDate =>
      _today.subtract(const Duration(days: 365));

  DateTime get _maxSelectableDate =>
      _today.add(const Duration(days: 365 * 5));

  bool get _hasInvalidTripDateRange {
    if (_startDate == null || _endDate == null) return false;
    return _dateOnly(_startDate!).isAfter(_dateOnly(_endDate!));
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _clampDate(DateTime date, DateTime first, DateTime last) {
    final value = _dateOnly(date);
    if (value.isBefore(first)) return first;
    if (value.isAfter(last)) return last;
    return value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final overallFirst = _minSelectableDate;
    final overallLast = _maxSelectableDate;

    var firstDate = isStart
        ? overallFirst
        : (_startDate != null ? _dateOnly(_startDate!) : overallFirst);
    var lastDate = isStart
        ? (_endDate != null ? _dateOnly(_endDate!) : overallLast)
        : overallLast;

    if (firstDate.isAfter(lastDate)) {
      firstDate = overallFirst;
      lastDate = overallLast;
    }

    final preferredInitial = isStart
        ? (_startDate ?? _today)
        : (_endDate ?? _startDate ?? _today);

    final selected = await showDatePicker(
      context: context,
      initialDate: _clampDate(preferredInitial, firstDate, lastDate),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (!mounted || selected == null) return;

    setState(() {
      final picked = _dateOnly(selected);
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _dateOnly(_endDate!).isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
        if (_startDate != null && _dateOnly(_startDate!).isAfter(picked)) {
          _startDate = picked;
        }
      }
    });
  }

  void _validateAndSubmit() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    if (_addTripDates && _hasInvalidTripDateRange) {
      AppToast.show(
        context,
        context.loc.tripDateRangeInvalid,
        type: ToastType.error,
      );
      return;
    }

    context.read<HomeBloc>().add(
      CreateGroupRequested(
        name: _nameController.text,
        type: _selectedType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    
    final List<Map<String, dynamic>> types = [
      {'id': 'trip', 'label': 'Trip', 'icon': Icons.flight_takeoff_rounded},
      {'id': 'home', 'label': 'Home', 'icon': Icons.home_outlined},
      {'id': 'couple', 'label': 'Couple', 'icon': Icons.favorite_border_rounded},
      {'id': 'other', 'label': 'Other', 'icon': Icons.list_alt_rounded},
    ];

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create a group',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _validateAndSubmit,
            child: Text(
              'Done',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeLoaded) {
            context.read<ActivityBloc>().add(const RefreshActivity());
            AppToast.show(context, 'Group created successfully!', type: ToastType.success);
            context.pop();
          } else if (state is HomeError) {
            AppToast.show(context, state.message, type: ToastType.error);
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppDimensions.lg.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64.w,
                      height: 64.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg.r),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withOpacity(0.12),
                        ),
                      ),
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        color: theme.colorScheme.primary,
                        size: 28.r,
                      ),
                    ),
                    SizedBox(width: AppDimensions.lg.w),
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Group name',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a group name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.xl.h),
                Text(
                  'Type',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimensions.sm.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppDimensions.md.w,
                    mainAxisSpacing: AppDimensions.md.h,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: types.length,
                  itemBuilder: (context, index) {
                    final item = types[index];
                    final id = item['id'] as String;
                    final label = item['label'] as String;
                    final icon = item['icon'] as IconData;
                    final isSelected = _selectedType == id;
                    
                    return OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.12)
                            : Colors.transparent,
                        side: BorderSide(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.12),
                          width: isSelected ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLg.r),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedType = id;
                        });
                      },
                      icon: Icon(
                        icon,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        label,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: AppDimensions.xl.h),
                if (_selectedType == 'home') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Add settle up reminders',
                            style: context.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.purpleAccent,
                            size: 18.r,
                          ),
                        ],
                      ),
                      AppSwitch(
                        value: _addSettleUpReminders,
                        onChanged: (val) {
                          setState(() {
                            _addSettleUpReminders = val;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: AppDimensions.xs.h),
                  Text(
                    'When on, Splitwise will remind group members to settle up.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ] else if (_selectedType == 'trip') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add trip dates',
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSwitch(
                        value: _addTripDates,
                        onChanged: (val) {
                          setState(() {
                            _addTripDates = val;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: AppDimensions.xs.h),
                  Text(
                    'Splitwise will remind friends to join, add expenses, and settle up.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  if (_addTripDates) ...[
                    SizedBox(height: AppDimensions.lg.h),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Start',
                                suffixIcon:
                                    const Icon(Icons.calendar_today_rounded),
                                errorText: _hasInvalidTripDateRange
                                    ? ''
                                    : null,
                                errorStyle: const TextStyle(height: 0),
                              ),
                              child: Text(
                                _startDate != null
                                    ? DateFormat('yMMMd').format(_startDate!)
                                    : 'Today',
                                style: context.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppDimensions.md.w),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End',
                                suffixIcon:
                                    const Icon(Icons.calendar_today_rounded),
                                errorText: _hasInvalidTripDateRange
                                    ? ''
                                    : null,
                                errorStyle: const TextStyle(height: 0),
                              ),
                              child: Text(
                                _endDate != null
                                    ? DateFormat('yMMMd').format(_endDate!)
                                    : 'Choose date',
                                style: context.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_hasInvalidTripDateRange) ...[
                      SizedBox(height: AppDimensions.xs.h),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          context.loc.tripDateRangeInvalid,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
