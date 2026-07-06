import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/email_settings_cubit.dart';

class EmailSettingsPage extends StatelessWidget {
  const EmailSettingsPage({super.key});

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: 8.h, left: 16.w, right: 16.w),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingRow(BuildContext context, EmailSettingsCubit cubit, Map<String, bool> settings, String key, String title) {
    return CheckboxListTile(
      value: settings[key] ?? true,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          color: context.theme.colorScheme.onSurface,
        ),
      ),
      activeColor: Colors.blue[600],
      controlAffinity: ListTileControlAffinity.trailing,
      onChanged: (val) {
        if (val != null) {
          cubit.toggleSetting(key, val);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.id : '';

    return BlocProvider<EmailSettingsCubit>(
      create: (context) => EmailSettingsCubit()..loadSettings(userId),
      child: BlocConsumer<EmailSettingsCubit, EmailSettingsState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings saved successfully!')),
            );
            context.pop();
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage!}')),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<EmailSettingsCubit>();

          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Email settings',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSectionHeader('Groups and Friends'),
                                _buildSettingRow(context, cubit, state.settings, 'addsMeToGroup', 'When someone adds me to a group'),
                                _buildSettingRow(context, cubit, state.settings, 'addsMeAsFriend', 'When someone adds me as a friend'),
                                
                                _buildSectionHeader('Expenses'),
                                _buildSettingRow(context, cubit, state.settings, 'expenseAdded', 'When an expense is added'),
                                _buildSettingRow(context, cubit, state.settings, 'expenseEditedDeleted', 'When an expense is edited/deleted'),
                                _buildSettingRow(context, cubit, state.settings, 'expenseCommented', 'When someone comments on an expense'),
                                _buildSettingRow(context, cubit, state.settings, 'expenseDue', 'When an expense is due'),
                                _buildSettingRow(context, cubit, state.settings, 'paysMe', 'When someone pays me'),
                                
                                _buildSectionHeader('News and Updates'),
                                _buildSettingRow(context, cubit, state.settings, 'monthlyActivitySummary', 'Monthly summary of my activity'),
                                _buildSettingRow(context, cubit, state.settings, 'majorNewsUpdates', 'Major Splitwise news and updates'),
                                SizedBox(height: 24.h),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE55C35), // brand orange
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () => cubit.saveSettings(userId),
                              child: Text(
                                'Save changes',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
