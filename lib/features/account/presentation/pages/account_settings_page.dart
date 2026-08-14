import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/account_settings_cubit.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  static const _pageBg = Color(0xFFFFFFFF);
  static const _appBarBg = Color(0xFF1C1C1E);
  static const _labelColor = Color(0xFF757575);
  static const _valueColor = Color(0xFF111111);
  static const _editBlue = Color(0xFF1E88E5);
  static const _orange = Color(0xFFFF652C);
  static const _borderColor = Color(0xFFCCCCCC);
  static const _buttonFill = Color(0xFFF3F3F3);

  static const _timeZones = [
    '(GMT+05:30) Chennai',
    '(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi',
    '(GMT+00:00) London',
    '(GMT-05:00) Eastern Time (US & Canada)',
    '(GMT-05:00) New York',
    '(GMT+09:00) Tokyo',
  ];

  static const _currencies = ['USD', 'INR', 'EUR', 'GBP', 'CAD'];
  static const _languages = ['English', 'Spanish', 'French', 'Japanese'];

  static ThemeData get _forcedLightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: _pageBg,
      colorScheme: const ColorScheme.light(
        primary: _editBlue,
        onPrimary: Colors.white,
        surface: _pageBg,
        onSurface: _valueColor,
        onSurfaceVariant: _labelColor,
        outline: _borderColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _appBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _editBlue;
          return Colors.white;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: _labelColor, width: 1.5),
      ),
      dividerColor: const Color(0xFFE6E6E6),
    );
  }

  String _timeZoneValue(String stored) {
    if (_timeZones.contains(stored)) return stored;
    if (stored.contains('Chennai')) return _timeZones.first;
    return _timeZones.first;
  }

  String _currencyValue(String stored) {
    if (_currencies.contains(stored)) return stored;
    if (stored.startsWith('USD')) return 'USD';
    if (stored.startsWith('INR')) return 'INR';
    if (stored.startsWith('EUR')) return 'EUR';
    if (stored.startsWith('GBP')) return 'GBP';
    if (stored.startsWith('CAD')) return 'CAD';
    return stored;
  }

  void _showEditDialog(
    BuildContext context, {
    required String title,
    required String currentValue,
    required void Function(String) onSave,
    bool isPassword = false,
  }) {
    final controller = TextEditingController(text: isPassword ? '' : currentValue);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: _pageBg,
          title: Text(title, style: const TextStyle(color: _valueColor)),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: isPassword,
            style: const TextStyle(color: _valueColor),
            keyboardType: title.toLowerCase().contains('email')
                ? TextInputType.emailAddress
                : title.toLowerCase().contains('phone')
                    ? TextInputType.phone
                    : TextInputType.text,
            decoration: InputDecoration(
              hintText: isPassword ? 'Enter new password' : 'Enter $title',
              hintStyle: const TextStyle(color: _labelColor),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _editBlue),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: _labelColor)),
            ),
            TextButton(
              onPressed: () {
                final newValue = controller.text.trim();
                if (newValue.isNotEmpty) onSave(newValue);
                Navigator.of(dialogCtx).pop();
              },
              child: const Text('OK', style: TextStyle(color: _editBlue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickOption({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String selected,
    required void Function(String) onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _pageBg,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: _valueColor,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.5,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((option) {
                    final isSelected = option == selected;
                    return ListTile(
                      title: Text(
                        option,
                        style: const TextStyle(color: _valueColor),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: _editBlue)
                          : null,
                      onTap: () {
                        onSelected(option);
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 13.sp, color: _labelColor),
    );
  }

  Widget _editAction(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 14.sp, color: _editBlue),
            SizedBox(width: 4.w),
            Text(
              'Edit',
              style: TextStyle(
                fontSize: 14.sp,
                color: _editBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editableRow({
    required BuildContext context,
    required String label,
    required String value,
    required void Function(String) onEdit,
    bool isPassword = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: _valueColor,
                  ),
                ),
              ),
              _editAction(
                () => _showEditDialog(
                  context,
                  title: label,
                  currentValue: isPassword ? '' : value,
                  onSave: onEdit,
                  isPassword: isPassword,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownBox({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          SizedBox(height: 6.h),
          InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
              decoration: BoxDecoration(
                color: _pageBg,
                border: Border.all(color: _borderColor),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: _valueColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: _labelColor,
                    size: 28.r,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlinedAction({
    required String caption,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(caption),
          SizedBox(height: 8.h),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: _valueColor,
              backgroundColor: _buttonFill,
              side: const BorderSide(color: _borderColor),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            child: Text(
              buttonLabel,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.id : '';
    final defaultName = authState is Authenticated ? authState.user.name : '';
    final defaultEmail = authState is Authenticated ? authState.user.email : '';

    return Theme(
      data: _forcedLightTheme,
      child: BlocProvider<AccountSettingsCubit>(
        create: (context) =>
            AccountSettingsCubit()..loadSettings(userId, defaultName, defaultEmail),
        child: BlocConsumer<AccountSettingsCubit, AccountSettingsState>(
          listener: (context, state) {
            if (state.isSuccess) {
              AppToast.show(context, 'Account settings saved!', type: ToastType.success);
              context.pop();
            } else if (state.errorMessage != null) {
              AppToast.show(context, 'Error: ${state.errorMessage!}', type: ToastType.error);
            }
          },
          builder: (context, state) {
            final cubit = context.read<AccountSettingsCubit>();
            final phoneDisplay =
                state.phone.trim().isEmpty || state.phone == 'None' ? 'None' : state.phone;

            return Scaffold(
              backgroundColor: _pageBg,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  'Account settings',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              body: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _editBlue),
                    )
                  : SafeArea(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _editableRow(
                              context: context,
                              label: 'Full name',
                              value: state.name,
                              onEdit: cubit.updateName,
                            ),
                            _editableRow(
                              context: context,
                              label: 'Email address',
                              value: state.email,
                              onEdit: cubit.updateEmail,
                            ),
                            _editableRow(
                              context: context,
                              label: 'Phone number',
                              value: phoneDisplay,
                              onEdit: cubit.updatePhone,
                            ),
                            _editableRow(
                              context: context,
                              label: 'Password',
                              value: '••••••••',
                              isPassword: true,
                              onEdit: (newValue) async {
                                await cubit.updatePassword(newValue);
                                if (!context.mounted) return;
                                if (context
                                        .read<AccountSettingsCubit>()
                                        .state
                                        .errorMessage ==
                                    null) {
                                  AppToast.show(
                                    context,
                                    'Password changed successfully!',
                                    type: ToastType.success,
                                  );
                                }
                              },
                            ),
                            SizedBox(height: 8.h),
                            _dropdownBox(
                              label: 'Time zone',
                              value: _timeZoneValue(state.timeZone),
                              onTap: () => _pickOption(
                                context: context,
                                title: 'Time zone',
                                options: _timeZones,
                                selected: _timeZoneValue(state.timeZone),
                                onSelected: cubit.updateTimeZone,
                              ),
                            ),
                            _dropdownBox(
                              label: 'Default currency',
                              value: _currencyValue(state.currency),
                              onTap: () => _pickOption(
                                context: context,
                                title: 'Default currency',
                                options: _currencies,
                                selected: _currencyValue(state.currency),
                                onSelected: cubit.updateCurrency,
                              ),
                            ),
                            _dropdownBox(
                              label: 'Language (for emails and notifications)',
                              value: state.language,
                              onTap: () => _pickOption(
                                context: context,
                                title: 'Language',
                                options: _languages,
                                selected: state.language,
                                onSelected: cubit.updateLanguage,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                'Privacy settings',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _valueColor,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4.w, 4.h, 16.w, 8.h),
                              child: CheckboxListTile(
                                value: state.allowSuggest,
                                contentPadding: EdgeInsets.only(left: 8.w, right: 8.w),
                                title: Text(
                                  'Allow Splitwise to suggest me as a friend to other users',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _valueColor,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: EdgeInsets.only(top: 4.h),
                                  child: Text(
                                    'Splitwise will only recommend you to users who already have your email address or phone number in their phone\'s contact book',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: _labelColor,
                                      fontStyle: FontStyle.italic,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                controlAffinity: ListTileControlAffinity.leading,
                                onChanged: (val) =>
                                    cubit.updateAllowSuggest(val ?? state.allowSuggest),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                              child: SizedBox(
                                width: double.infinity,
                                height: 48.h,
                                child: ElevatedButton(
                                  onPressed: () => cubit.saveChanges(userId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _orange,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                  ),
                                  child: Text(
                                    'Save changes',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 28.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                'Advanced features',
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w800,
                                  color: _valueColor,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _outlinedAction(
                                    caption: 'Block other users',
                                    buttonLabel: 'Manage your blocklist',
                                    onPressed: () => context.pushNamed(
                                      RouteConstants.blocklistName,
                                    ),
                                  ),
                                  _outlinedAction(
                                    caption: 'Log out on all devices',
                                    buttonLabel: 'Log out on all devices',
                                    onPressed: () {
                                      context.read<AuthBloc>().add(
                                            const LogoutRequested(),
                                          );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: AppDimensions.xl.h),
                          ],
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}
