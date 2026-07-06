import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_scaffold.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectDate(BuildContext context, bool isStart) async {
    final initialDate = DateTime.now();
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now().add(const Duration(days: 365 * 5));

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selected != null) {
      setState(() {
        if (isStart) {
          _startDate = selected;
        } else {
          _endDate = selected;
        }
      });
    }
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
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                context.read<HomeBloc>().add(
                  CreateGroupRequested(
                    name: _nameController.text,
                    type: _selectedType,
                  ),
                );
              }
            },
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Group created successfully!')),
            );
            context.pop();
          } else if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
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
                      Switch.adaptive(
                        value: _addSettleUpReminders,
                        activeColor: theme.colorScheme.primary,
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
                      Switch.adaptive(
                        value: _addTripDates,
                        activeColor: theme.colorScheme.primary,
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
                              decoration: const InputDecoration(
                                labelText: 'Start',
                                suffixIcon: Icon(Icons.calendar_today_rounded),
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
                              decoration: const InputDecoration(
                                labelText: 'End',
                                suffixIcon: Icon(Icons.calendar_today_rounded),
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
