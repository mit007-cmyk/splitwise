import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/account_settings_cubit.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  final List<String> _timeZones = const [
    '(GMT+05:30) Chennai',
    '(GMT+00:00) London',
    '(GMT-05:00) New York',
    '(GMT+09:00) Tokyo',
  ];

  final List<String> _currencies = const ['USD', 'INR', 'EUR', 'GBP', 'CAD'];
  final List<String> _languages = const ['English', 'Spanish', 'French', 'Japanese'];

  void _showEditDialog(
    BuildContext context, {
    required String title,
    required String currentValue,
    required Function(String) onSave,
    bool isPassword = false,
  }) {
    final controller = TextEditingController(text: isPassword ? '' : currentValue);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: 'Enter new $title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newValue = controller.text.trim();
                if (newValue.isNotEmpty) {
                  onSave(newValue);
                }
                Navigator.of(dialogCtx).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditableRow(
    BuildContext context,
    String label,
    String value,
    Function(String) onEdit, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: context.theme.colorScheme.onSurface,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showEditDialog(
                  context,
                  title: label,
                  currentValue: value,
                  onSave: onEdit,
                  isPassword: isPassword,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 14.sp, color: Colors.blue[600]),
                    SizedBox(width: 4.w),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow<T>(
    BuildContext context,
    String label,
    T currentValue,
    List<T> items,
    Function(T?) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
          style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          DropdownButton<T>(
            value: currentValue,
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Colors.grey[300],
            ),
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  item.toString(),
                  style: TextStyle(fontSize: 16.sp, color: context.theme.colorScheme.onSurface),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.id : '';
    final defaultName = authState is Authenticated ? authState.user.name : '';
    final defaultEmail = authState is Authenticated ? authState.user.email : '';

    return BlocProvider<AccountSettingsCubit>(
      create: (context) => AccountSettingsCubit()..loadSettings(userId, defaultName, defaultEmail),
      child: BlocConsumer<AccountSettingsCubit, AccountSettingsState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account settings saved!')),
            );
            context.pop();
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage!}')),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<AccountSettingsCubit>();

          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Account settings',
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildEditableRow(context, 'Full name', state.name, cubit.updateName),
                                const Divider(height: 1),
                                _buildEditableRow(context, 'Email address', state.email, cubit.updateEmail),
                                const Divider(height: 1),
                                _buildEditableRow(context, 'Phone number', state.phone, cubit.updatePhone),
                                const Divider(height: 1),
                                _buildEditableRow(
                                  context,
                                  'Password',
                                  state.password,
                                  (newValue) => cubit.updatePassword(newValue).then((_) {
                                    if (state.errorMessage == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Password changed successfully!')),
                                      );
                                    }
                                  }),
                                  isPassword: true,
                                ),
                                const Divider(height: 1),
                                
                                _buildDropdownRow(
                                  context,
                                  'Time zone',
                                  state.timeZone,
                                  _timeZones,
                                  (val) => cubit.updateTimeZone(val ?? state.timeZone),
                                ),
                                _buildDropdownRow(
                                  context,
                                  'Default currency',
                                  state.currency,
                                  _currencies,
                                  (val) => cubit.updateCurrency(val ?? state.currency),
                                ),
                                _buildDropdownRow(
                                  context,
                                  'Language (for emails and notifications)',
                                  state.language,
                                  _languages,
                                  (val) => cubit.updateLanguage(val ?? state.language),
                                ),
                                
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
                                  child: CheckboxListTile(
                                    value: state.allowSuggest,
                                    title: Text(
                                      'Allow Splitwise to suggest me as a friend to other users',
                                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                    ),
                                    subtitle: Text(
                                      'Splitwise will only recommend you to users who already have your email address or phone number in their phone\'s contact book',
                                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                                    ),
                                    activeColor: Colors.blue[600],
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (val) => cubit.updateAllowSuggest(val ?? state.allowSuggest),
                                  ),
                                ),
                                
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE55C35), // Brand orange
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 12.h),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () => cubit.saveChanges(userId),
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
                                
                                SizedBox(height: 24.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                                  child: Text(
                                    'Advanced features',
                                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Block other users', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                                      SizedBox(height: 4.h),
                                      OutlinedButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Blocklist is empty.')),
                                          );
                                        },
                                        child: const Text('Manage your blocklist'),
                                      ),
                                      SizedBox(height: 16.h),
                                      Text('Log out on all devices', style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                                      SizedBox(height: 4.h),
                                      OutlinedButton(
                                        onPressed: () {
                                          context.read<AuthBloc>().add(LogoutRequested());
                                        },
                                        child: const Text('Log out on all devices'),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 32.h),
                              ],
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
