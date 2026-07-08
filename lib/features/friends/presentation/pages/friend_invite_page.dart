import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/friend_code_parser.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../utils/add_friend_flow.dart';

/// Deep-link entry point for `/add-friend?code=...`.
/// Shows the Splitwise-style add dialog, then navigates to the friend.
class FriendInvitePage extends StatefulWidget {
  final String friendCode;

  const FriendInvitePage({
    super.key,
    required this.friendCode,
  });

  @override
  State<FriendInvitePage> createState() => _FriendInvitePageState();
}

class _FriendInvitePageState extends State<FriendInvitePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInvite());
  }

  Future<void> _handleInvite() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      if (mounted) context.pop();
      return;
    }

    final code = FriendCodeParser.parse(widget.friendCode) ?? widget.friendCode;

    await AddFriendFlow.handleCode(
      context,
      code,
      leaveScanScreenOnSuccess: false,
    );

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
