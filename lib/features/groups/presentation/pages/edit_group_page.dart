import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../../core/widgets/app_scaffold.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_event.dart';
import 'package:splitwise/features/home/presentation/bloc/home_state.dart';

class EditGroupPage extends StatefulWidget {
  final String groupId;

  const EditGroupPage({
    super.key,
    required this.groupId,
  });

  @override
  State<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedType;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoaded) {
          final groupIndex = state.summary.groups.indexWhere((g) => g.groupId == widget.groupId);
          if (groupIndex == -1) {
            return const Scaffold(
              body: Center(child: Text('Group not found.')),
            );
          }
          final group = state.summary.groups[groupIndex];

          if (!_initialized) {
            _nameController = TextEditingController(text: group.groupName);
            _selectedType = group.groupType.toLowerCase();
            _initialized = true;
          }

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
                'Edit group',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      context.read<HomeBloc>().add(
                            EditGroupRequested(
                              groupId: widget.groupId,
                              name: _nameController.text.trim(),
                              type: _selectedType,
                            ),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Group updated successfully!')),
                      );
                      context.pop();
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
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64.w,
                          height: 64.h,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.12)),
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 28.r,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Group name',
                              labelStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                              hintText: 'Enter group name',
                              contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                              ),
                              filled: false,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Group name cannot be empty';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),

                    Text(
                      'Type',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10.w,
                        mainAxisSpacing: 10.h,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: types.length,
                      itemBuilder: (context, index) {
                        final type = types[index];
                        final isSelected = _selectedType == type['id'];

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedType = type['id'] as String;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.12)
                                  : theme.colorScheme.onSurface.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  type['icon'] as IconData,
                                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                  size: 24.r,
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  type['label'] as String,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
