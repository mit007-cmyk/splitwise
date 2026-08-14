import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../activity/presentation/bloc/activity_bloc.dart';
import '../../../activity/presentation/bloc/activity_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../friends/domain/entities/user_preview.dart';
import '../../../friends/domain/repositories/friends_repository.dart';
import '../../../friends/presentation/bloc/friends_list_cubit.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';

class BlocklistPage extends StatefulWidget {
  const BlocklistPage({super.key});

  @override
  State<BlocklistPage> createState() => _BlocklistPageState();
}

class _BlocklistPageState extends State<BlocklistPage> {
  static const _bg = Color(0xFF1C1C1E);
  static const _card = Color(0xFF2C2C2E);
  static const _text = Color(0xFFFFFFFF);
  static const _muted = Color(0xFFD1D1D6);
  static const _divider = Color(0xFF3A3A3C);
  static const _rowBorder = Color(0xFF48484A);
  static const _orange = Color(0xFFFF652C);
  static const _removeRed = Color(0xFFE57373);
  static const _fieldFill = Color(0xFFFFFFFF);
  static const _fieldText = Color(0xFF111111);
  static const _hint = Color(0xFF9E9E9E);

  final _emailController = TextEditingController();
  List<UserPreview> _blocked = [];
  bool _isLoading = true;
  bool _isBlocking = false;
  String? _busyUserId;

  String? get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.id;
    return null;
  }

  String? get _currentUserEmail {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.email;
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = _currentUserId;
    if (userId == null) {
      setState(() {
        _blocked = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final result = await getIt<FriendsRepository>().getBlockedUsers(userId);
    if (!mounted) return;
    setState(() {
      _blocked = result.isSuccess ? result.dataOrThrow : [];
      _isLoading = false;
    });
  }

  void _refreshRelatedFeeds() {
    if (!mounted) return;
    context.read<HomeBloc>().add(const RefreshHome());
    context.read<ActivityBloc>().add(const RefreshActivity());
    final userId = _currentUserId;
    if (userId != null) {
      getIt<FriendsListCubit>().load(userId);
    }
  }

  String _displayLabel(UserPreview user) {
    final phone = user.phone?.trim() ?? '';
    if (phone.isNotEmpty) return phone;
    final email = user.email?.trim() ?? '';
    if (email.isNotEmpty) return email;
    return user.name;
  }

  Future<void> _blockByEmail() async {
    final currentUserId = _currentUserId;
    final email = _emailController.text.trim().toLowerCase();
    if (currentUserId == null || _isBlocking) return;

    if (email.isEmpty) {
      AppToast.show(context, 'Enter an email address to block.', type: ToastType.error);
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      AppToast.show(context, 'Enter a valid email address.', type: ToastType.error);
      return;
    }

    if (email == (_currentUserEmail ?? '').trim().toLowerCase()) {
      AppToast.show(context, 'You cannot block yourself.', type: ToastType.error);
      return;
    }

    setState(() => _isBlocking = true);
    final lookup = await getIt<FriendsRepository>().findUserByEmailOrPhone(
      email: email,
    );
    if (!mounted) return;

    if (lookup.isFailure || lookup.dataOrThrow == null) {
      setState(() => _isBlocking = false);
      AppToast.show(
        context,
        'No Splitwise user found with that email.',
        type: ToastType.error,
      );
      return;
    }

    final target = lookup.dataOrThrow!;
    if (_blocked.any((user) => user.id == target.id)) {
      setState(() => _isBlocking = false);
      AppToast.show(context, '${target.name} is already blocked.', type: ToastType.info);
      return;
    }

    final result = await getIt<FriendsRepository>().blockUser(
      currentUserId: currentUserId,
      blockedUserId: target.id,
    );
    if (!mounted) return;

    setState(() => _isBlocking = false);
    if (result.isFailure) {
      AppToast.show(context, 'Could not block this user.', type: ToastType.error);
      return;
    }

    _emailController.clear();
    AppToast.show(context, '${target.name} has been blocked.', type: ToastType.success);
    _refreshRelatedFeeds();
    await _load();
  }

  Future<void> _unblock(UserPreview user) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null || _busyUserId != null) return;

    setState(() => _busyUserId = user.id);
    final result = await getIt<FriendsRepository>().unblockUser(
      currentUserId: currentUserId,
      blockedUserId: user.id,
    );
    if (!mounted) return;

    if (result.isFailure) {
      setState(() => _busyUserId = null);
      AppToast.show(context, 'Could not unblock ${user.name}.', type: ToastType.error);
      return;
    }

    setState(() {
      _blocked = _blocked.where((item) => item.id != user.id).toList();
      _busyUserId = null;
    });
    AppToast.show(context, '${user.name} was unblocked.', type: ToastType.success);
    _refreshRelatedFeeds();
  }

  TextStyle get _bodyStyle => TextStyle(
        fontSize: 14.sp,
        color: _muted,
        height: 1.45,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Account settings',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: _text,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : SafeArea(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, AppDimensions.xl.h),
                children: [
                  Text(
                    'Manage your blocklist',
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'When you block someone, that person is automatically removed from your list of friends and balances. Additionally, the following kinds of information are also hidden:',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 10.h),
                  _bullet('Any groups that involve the blocked person'),
                  _bullet('Any future notifications from that person'),
                  _bullet(
                    'Any future \'recent activity\' entries caused by that person\'s actions',
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Blocking another person does not notify that person about the block in any way. The blocked person can continue to add you to new expenses, groups, and more, but those new items will not appear in your account. If you choose to unblock the person later, then any items that they added you to will become visible at that time.',
                    style: _bodyStyle,
                  ),
                  SizedBox(height: 20.h),
                  const Divider(height: 1, color: _divider),
                  SizedBox(height: 16.h),
                  if (_blocked.isEmpty)
                    Text(
                      'You have not blocked any other users.',
                      style: TextStyle(fontSize: 15.sp, color: _text),
                    )
                  else ...[
                    Text(
                      'You have blocked the following people:',
                      style: TextStyle(fontSize: 15.sp, color: _text),
                    ),
                    SizedBox(height: 12.h),
                    ..._blocked.map(_blockedUserRow),
                  ],
                  SizedBox(height: 20.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter an email address to block:',
                          style: TextStyle(fontSize: 15.sp, color: _text),
                        ),
                        SizedBox(height: 10.h),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _blockByEmail(),
                          style: TextStyle(fontSize: 15.sp, color: _fieldText),
                          cursorColor: _orange,
                          decoration: InputDecoration(
                            hintText: 'Email address',
                            hintStyle: TextStyle(fontSize: 15.sp, color: _hint),
                            filled: true,
                            fillColor: _fieldFill,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.r),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.r),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          height: 42.h,
                          child: ElevatedButton(
                            onPressed: _isBlocking ? null : _blockByEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _orange,
                              foregroundColor: _text,
                              disabledBackgroundColor: _orange.withValues(alpha: 0.6),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 22.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                            child: _isBlocking
                                ? SizedBox(
                                    width: 18.w,
                                    height: 18.h,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _text,
                                    ),
                                  )
                                : Text(
                                    'Block',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: _bodyStyle),
          Expanded(child: Text(text, style: _bodyStyle)),
        ],
      ),
    );
  }

  Widget _blockedUserRow(UserPreview user) {
    final busy = _busyUserId == user.id;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _rowBorder),
          borderRadius: BorderRadius.circular(2.r),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  child: Text(
                    _displayLabel(user),
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: _text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: _rowBorder),
              InkWell(
                onTap: busy ? null : () => _unblock(user),
                child: SizedBox(
                  width: 48.w,
                  child: Center(
                    child: busy
                        ? SizedBox(
                            width: 18.w,
                            height: 18.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _orange,
                            ),
                          )
                        : Icon(Icons.close, color: _removeRed, size: 22.r),
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
