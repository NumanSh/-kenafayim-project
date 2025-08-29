import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/working_hours.dart';

class HourApprovalCard extends StatelessWidget {
  final WorkingHours workingHours;
  final bool isSelected;
  final bool isSelectionMode;
  final Function(bool) onSelectionChanged;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;

  const HourApprovalCard({
    Key? key,
    required this.workingHours,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onSelectionChanged,
    required this.onApprove,
    required this.onReject,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        final isVerySmallScreen = constraints.maxWidth < 350;

        return Container(
          margin: EdgeInsets.only(
            bottom: 12,
            left: isSmallScreen ? 8 : 16,
            right: isSmallScreen ? 8 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: const Color(0xFF3b82f6), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isSelectionMode
                  ? () => onSelectionChanged(!isSelected)
                  : onViewDetails,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with mentor info and status
                    _buildHeader(isSmallScreen),

                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // Hours and date info - Responsive layout
                    _buildInfoSection(isSmallScreen, isVerySmallScreen),

                    // Notes section
                    if (workingHours.notes != null &&
                        workingHours.notes!.isNotEmpty)
                      _buildNotesSection(isSmallScreen),

                    // Photo evidence indicator
                    if (workingHours.photoEvidenceUrl != null)
                      _buildPhotoIndicator(),

                    // Action buttons for pending hours
                    if (workingHours.status == WorkingHoursStatus.pending &&
                        !isSelectionMode)
                      _buildActionButtons(isSmallScreen),

                    // Show rejection reason if rejected
                    if (workingHours.status == WorkingHoursStatus.rejected &&
                        workingHours.rejectionReason != null)
                      _buildRejectionReason(isSmallScreen),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Row(
      children: [
        if (isSelectionMode)
          Container(
            margin: const EdgeInsets.only(left: 12),
            child: Checkbox(
              value: isSelected,
              onChanged: (value) => onSelectionChanged(value ?? false),
              activeColor: const Color(0xFF3b82f6),
            ),
          ),
        CircleAvatar(
          radius: isSmallScreen ? 20 : 24,
          backgroundColor: workingHours.getStatusColor().withOpacity(0.1),
          child: Text(
            workingHours.mentorName.isNotEmpty
                ? workingHours.mentorName[0].toUpperCase()
                : 'M',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: workingHours.getStatusColor(),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workingHours.mentorName,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1f2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                workingHours.getDisciplineDisplayName(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: const Color(0xFF6b7280),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 6 : 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: workingHours.getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            workingHours.getStatusText(),
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: workingHours.getStatusColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(bool isSmallScreen, bool isVerySmallScreen) {
    if (isVerySmallScreen) {
      // Stack info chips vertically on very small screens
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  Icons.access_time,
                  '${workingHours.hours.toStringAsFixed(1)} שעות',
                  const Color(0xFF3b82f6),
                  isSmallScreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  Icons.calendar_today,
                  DateFormat('dd/MM').format(workingHours.date),
                  const Color(0xFF10b981),
                  isSmallScreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  Icons.people,
                  '${workingHours.numberOfStudents} תלמידים',
                  const Color(0xFF8b5cf6),
                  isSmallScreen,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Horizontal layout for larger screens
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildInfoChip(
            Icons.access_time,
            '${workingHours.hours.toStringAsFixed(1)} שעות',
            const Color(0xFF3b82f6),
            isSmallScreen,
          ),
          _buildInfoChip(
            Icons.calendar_today,
            DateFormat('dd/MM/yyyy').format(workingHours.date),
            const Color(0xFF10b981),
            isSmallScreen,
          ),
          _buildInfoChip(
            Icons.people,
            '${workingHours.numberOfStudents} תלמידים',
            const Color(0xFF8b5cf6),
            isSmallScreen,
          ),
        ],
      );
    }
  }

  Widget _buildNotesSection(bool isSmallScreen) {
    return Column(
      children: [
        SizedBox(height: isSmallScreen ? 8 : 12),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          decoration: BoxDecoration(
            color: const Color(0xFFf8fafc),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.note,
                size: isSmallScreen ? 14 : 16,
                color: const Color(0xFF6b7280),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  workingHours.notes!,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: const Color(0xFF374151),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoIndicator() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.photo_camera, size: 14, color: Color(0xFF10b981)),
            const SizedBox(width: 4),
            const Text(
              'תמונת אישור מצורפת',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF10b981),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isSmallScreen) {
    return Column(
      children: [
        SizedBox(height: isSmallScreen ? 12 : 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: Icon(Icons.close, size: isSmallScreen ? 14 : 16),
                label: Text(
                  'דחה',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFef4444),
                  side: const BorderSide(color: Color(0xFFef4444)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 8 : 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: Icon(Icons.check, size: isSmallScreen ? 14 : 16),
                label: Text(
                  'אשר',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10b981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 8 : 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRejectionReason(bool isSmallScreen) {
    return Column(
      children: [
        SizedBox(height: isSmallScreen ? 8 : 12),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          decoration: BoxDecoration(
            color: const Color(0xFFef4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFef4444).withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: isSmallScreen ? 14 : 16,
                color: const Color(0xFFef4444),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'סיבת דחייה:',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFef4444),
                      ),
                    ),
                    Text(
                      workingHours.rejectionReason!,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: const Color(0xFFef4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text,
    Color color,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
