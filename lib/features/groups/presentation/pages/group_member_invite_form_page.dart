import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/context_extension.dart';
import '../../domain/entities/group_member_invite.dart';

class GroupMemberInviteFormPage extends StatefulWidget {
  final String title;
  final GroupMemberInvite? initial;

  const GroupMemberInviteFormPage({
    super.key,
    this.title = 'Add friend',
    this.initial,
  });

  @override
  State<GroupMemberInviteFormPage> createState() =>
      _GroupMemberInviteFormPageState();
}

class _GroupMemberInviteFormPageState extends State<GroupMemberInviteFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.displayName ?? '');
    _phoneController = TextEditingController(text: widget.initial?.phone ?? '');
    _emailController = TextEditingController(text: widget.initial?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_nameController.text.trim().isEmpty) return false;
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final email = _emailController.text.trim();
    if (phoneDigits.isEmpty && email.isEmpty) return false;
    if (phoneDigits.isNotEmpty && phoneDigits.length < 10) return false;
    if (email.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
      if (!emailRegex.hasMatch(email)) return false;
    }
    return true;
  }

  void _submit() {
    if (!_isValid) return;
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final initial = widget.initial;
    final invite = initial == null
        ? GroupMemberInvite.manual(
            displayName: name,
            phone: phone.isEmpty ? null : phone,
            email: email.isEmpty ? null : email,
          )
        : GroupMemberInvite(
            key: initial.key,
            displayName: name,
            phone: phone.isEmpty ? null : phone,
            email: email.isEmpty ? null : email,
            photoUrl: initial.photoUrl,
            userId: initial.userId,
          );
    context.pop(invite);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isValid = _isValid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
              color: isValid
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            onPressed: isValid ? _submit : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        alignLabelWithHint: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: 24.h),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Phone number',
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        alignLabelWithHint: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email address',
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        alignLabelWithHint: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      "Don't worry, nothing sends just yet. You will have another chance to review before sending.",
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    foregroundColor: isValid
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: isValid ? _submit : null,
                  child: Text(
                    'Next',
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
  }
}
