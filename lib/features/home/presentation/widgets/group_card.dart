import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/context_extension.dart';
import '../../domain/entities/balance_summary.dart';
import '../../domain/entities/group_summary.dart';

class GroupCard extends StatelessWidget {
  final GroupSummary group;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  Color _getPlaceholderBgColor(String name) {
    final colors = [
      const Color(0xFF0F766E), // dark teal
      const Color(0xFF1E3A8A), // deep blue
      const Color(0xFF065F46), // deep green
      const Color(0xFF9D174D), // deep pink
      const Color(0xFF374151), // dark grey
    ];
    final index = name.length % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final Color balanceColor;
    final String balanceLabel;
    switch (group.balanceType) {
      case BalanceType.owed:
        balanceColor = const Color(0xFF26E09C);
        balanceLabel = 'you are owed ₹${group.totalBalance.toStringAsFixed(2)}';
        break;
      case BalanceType.owe:
        balanceColor = const Color(0xFFDD6B20);
        balanceLabel = 'you owe ₹${group.totalBalance.toStringAsFixed(2)}';
        break;
      case BalanceType.settled:
        balanceColor = theme.colorScheme.onSurfaceVariant.withOpacity(0.6);
        balanceLabel = 'settled up';
        break;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'group-img-${group.groupId}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: group.groupImage != null && group.groupImage!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: group.groupImage!,
                        width: 56.w,
                        height: 56.h,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: _getPlaceholderBgColor(group.groupName),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            SizedBox(width: 14.w),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.groupName,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    balanceLabel,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: balanceColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  if (group.memberBalances.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    ...group.memberBalances.take(3).map((split) {
                      final String splitText;
                      final Color splitColor;
                      if (split.type == BalanceType.owed) {
                        splitText = '${split.userName} owes you ₹${split.amount.toStringAsFixed(2)}';
                        splitColor = const Color(0xFF26E09C);
                      } else {
                        splitText = 'You owe ${split.userName} ₹${split.amount.toStringAsFixed(2)}';
                        splitColor = const Color(0xFFDD6B20);
                      }

                      return Padding(
                        padding: EdgeInsets.only(bottom: 2.h),
                        child: Text(
                          splitText,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: splitColor.withOpacity(0.8),
                          ),
                        ),
                      );
                    }),
                    if (group.memberBalances.length > 3) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'Plus ${group.memberBalances.length - 3} other balances',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 56.w,
      height: 56.h,
      color: _getPlaceholderBgColor(group.groupName),
      child: const Icon(
        Icons.list_alt_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }
}
