import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/di.dart';
import '../../../../core/routing/route_constants.dart';
import '../../../../core/utils/friend_code_parser.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/friend_invite_resolution.dart';
import '../../domain/entities/user_preview.dart';
import '../../domain/repositories/friends_repository.dart';
import '../widgets/add_friend_confirm_dialog.dart';

/// Shared scan / manual-code / deep-link flow for adding friends instantly.
class AddFriendFlow {
  AddFriendFlow._();

  static Future<void> handleCode(
    BuildContext context,
    String rawCode, {
    bool leaveScanScreenOnSuccess = true,
  }) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final code = FriendCodeParser.parse(rawCode);
    if (code == null) {
      _showMessage(context, 'Invalid friend code');
      return;
    }

    final repository = getIt<FriendsRepository>();
    final previewResult = await repository.resolveInvitePreview(
      currentUserId: authState.user.id,
      friendCode: code,
    );

    if (!context.mounted) return;

    if (previewResult.isFailure) {
      _showMessage(context, 'Could not look up that friend code');
      return;
    }

    final preview = previewResult.dataOrThrow;
    final user = preview.user;

    switch (preview.resolution) {
      case FriendInviteResolution.userNotFound:
        _showMessage(context, 'No user found for this code');
        return;
      case FriendInviteResolution.self:
        _showMessage(context, 'This is your own friend code');
        return;
      case FriendInviteResolution.alreadyFriends:
        if (user != null) {
          _openFriendDetail(
            context,
            user.id,
            leaveScanScreen: leaveScanScreenOnSuccess,
          );
        }
        return;
      case FriendInviteResolution.canSendRequest:
      case FriendInviteResolution.outgoingPending:
      case FriendInviteResolution.incomingPending:
        if (user == null) return;
        await _showAddDialogAndCreateFriendship(
          context,
          user: user,
          currentUserId: authState.user.id,
          leaveScanScreen: leaveScanScreenOnSuccess,
        );
    }
  }

  static Future<void> _showAddDialogAndCreateFriendship(
    BuildContext context, {
    required UserPreview user,
    required String currentUserId,
    required bool leaveScanScreen,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => AddFriendConfirmDialog(user: user),
    );

    if (confirmed != true || !context.mounted) return;

    final repository = getIt<FriendsRepository>();
    final result = await repository.addFriendDirectly(
      currentUserId: currentUserId,
      friendUserId: user.id,
    );

    if (!context.mounted) return;

    if (result.isFailure) {
      _showMessage(context, 'Could not add friend. Please try again.');
      return;
    }

    _openFriendDetail(
      context,
      user.id,
      leaveScanScreen: leaveScanScreen,
    );
  }

  static void _openFriendDetail(
    BuildContext context,
    String friendId, {
    required bool leaveScanScreen,
  }) {
    final location = GoRouterState.of(context).uri.toString();

    if (leaveScanScreen && location.contains(RouteConstants.friendCodePath)) {
      context.pop();
    }

    context.pushNamed(
      RouteConstants.friendDetailName,
      pathParameters: {'friendId': friendId},
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
