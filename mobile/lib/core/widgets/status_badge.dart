import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case VisitorStatus.pending: return AppColors.pending;
      case VisitorStatus.approved: return AppColors.approved;
      case VisitorStatus.denied: return AppColors.denied;
      case VisitorStatus.checkedOut: return AppColors.checkedOut;
      default: return AppColors.textSecondary;
    }
  }

  IconData get _icon {
    switch (status) {
      case VisitorStatus.pending: return Icons.hourglass_top_rounded;
      case VisitorStatus.approved: return Icons.check_circle_rounded;
      case VisitorStatus.denied: return Icons.cancel_rounded;
      case VisitorStatus.checkedOut: return Icons.logout_rounded;
      default: return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            VisitorStatus.label(status),
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
