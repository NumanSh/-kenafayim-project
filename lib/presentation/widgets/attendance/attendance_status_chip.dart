import 'package:flutter/material.dart';

class AttendanceStatusChip extends StatelessWidget {
  final String status;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;

  const AttendanceStatusChip({
    Key? key,
    required this.status,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isCompact ? 6 : 8,
          horizontal: isCompact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFe5e7eb),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isCompact ? 14 : 16,
              color: isSelected ? color : const Color(0xFF6b7280),
            ),
            if (!isCompact) const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 9 : 10,
                color: isSelected ? color : const Color(0xFF6b7280),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xFF10b981);
      case 'absent':
        return const Color(0xFFef4444);
      case 'late':
        return const Color(0xFFf59e0b);
      case 'excused':
        return const Color(0xFF8b5cf6);
      case 'pending':
      default:
        return const Color(0xFF6b7280);
    }
  }
}
