import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/context_extension.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../bloc/add_friend_cubit.dart';

class AddFriendPage extends StatelessWidget {
  const AddFriendPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocProvider<AddFriendCubit>(
      create: (context) => AddFriendCubit(),
      child: BlocConsumer<AddFriendCubit, AddFriendState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact added successfully!')),
            );
            context.pop();
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<AddFriendCubit>();
          final homeBloc = context.read<HomeBloc>();
          final isValid = state.isValid;

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
                    color: isValid ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  onPressed: isValid && !state.isLoading ? () => cubit.saveContact(homeBloc) : null,
                ),
              ],
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            style: TextStyle(fontSize: 16.sp, color: theme.colorScheme.onSurface),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Name',
                              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              alignLabelWithHint: true,
                              hintText: 'Enter name (letters only)',
                              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                            ),
                            onChanged: cubit.updateName,
                          ),
                          SizedBox(height: 24.h),
                          TextField(
                            keyboardType: TextInputType.phone,
                            style: TextStyle(fontSize: 16.sp, color: theme.colorScheme.onSurface),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Mobile number',
                              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              alignLabelWithHint: true,
                              hintText: 'Enter 10-digit number',
                              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                            ),
                            onChanged: cubit.updatePhone,
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Expanded(child: Divider(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2))),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          TextField(
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(fontSize: 16.sp, color: theme.colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Email address',
                              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              alignLabelWithHint: true,
                              hintText: 'Enter email address',
                              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                            ),
                            onChanged: cubit.updateEmail,
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            "Don't worry, nothing sends just yet. You will have another chance to review before sending.",
                            style: context.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 48.h),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isValid
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                              foregroundColor: isValid
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                              elevation: 0,
                            ),
                            onPressed: isValid && !state.isLoading ? () => cubit.saveContact(homeBloc) : null,
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
        },
      ),
    );
  }
}
