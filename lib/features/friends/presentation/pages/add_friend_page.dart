import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/context_extension.dart';
import 'package:splitwise/features/home/presentation/bloc/home_bloc.dart';
import 'package:splitwise/features/home/presentation/bloc/home_event.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty && _contactController.text.trim().isNotEmpty;

  void _saveContact() {
    if (!_isValid || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    context.read<HomeBloc>().add(AddContactRequested(
      name: _nameController.text.trim(),
      emailOrPhone: _contactController.text.trim(),
    ));

    // Listen once for next state change
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact added successfully!')),
        );
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add friend',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
              color: _isValid ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            onPressed: _isValid ? _saveContact : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      style: TextStyle(fontSize: 16.sp, color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        alignLabelWithHint: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: 20.h),
                    TextField(
                      controller: _contactController,
                      style: TextStyle(fontSize: 16.sp, color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Phone number or email address',
                        labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        alignLabelWithHint: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Don't worry, nothing sends just yet. You will have another chance to review before sending.",
                      style: context.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isValid
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.08),
                        foregroundColor: _isValid
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                        elevation: 0,
                      ),
                      onPressed: _isValid ? _saveContact : null,
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
