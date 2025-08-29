import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/data/repositories/working_hours_repository.dart';
import '../../../data/models/user.dart';
import '../../../data/models/working_hours.dart';
import '../../providers/working_hours_providers.dart';
import 'hour_approval_card.dart';
import 'bulk_approval_bottom_sheet.dart';

class StaffHoursApprovalScreen extends ConsumerStatefulWidget {
  final User user;

  const StaffHoursApprovalScreen({super.key, required this.user});

  @override
  ConsumerState<StaffHoursApprovalScreen> createState() =>
      _StaffHoursApprovalScreenState();
}

class _StaffHoursApprovalScreenState
    extends ConsumerState<StaffHoursApprovalScreen> {
  final Set<String> _selectedHourIds = {};
  bool _isSelectionMode = false;
  String _filterStatus = 'all'; // all, pending, approved, rejected
  @override
  void initState() {
    super.initState();
    _debugWorkingHours();
  }

  void _debugWorkingHours() async {
    print('🔍 STAFF DEBUG: Starting working hours debug...');

    try {
      // Test repository directly
      final repository = WorkingHoursRepository();
      final allHours = await repository.getAllWorkingHours();
      print(
        '🔍 STAFF DEBUG: Direct repository call returned ${allHours.length} hours',
      );

      for (var hour in allHours) {
        print(
          '🔍 STAFF DEBUG: Hour - ID: ${hour.id}, Mentor: ${hour.mentorName}, Status: ${hour.status}',
        );
      }

      // Test provider
      final providerHours = ref.read(allWorkingHoursProvider);
      print('🔍 STAFF DEBUG: Provider state: ${providerHours.runtimeType}');
    } catch (e) {
      print('🔍 STAFF DEBUG: Error: $e');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final allHoursAsync = ref.watch(allWorkingHoursProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: Text(
          _isSelectionMode
              ? '${_selectedHourIds.length} נבחרו'
              : 'אישור שעות עבודה',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
        actions: [
          // Add manual refresh button
          IconButton(
            onPressed: () {
              print('🔄 MANUAL REFRESH: Refreshing working hours...');
              ref.invalidate(allWorkingHoursProvider);
            },
            icon: const Icon(Icons.refresh, color: Color(0xFF6b7280)),
          ),
          if (_isSelectionMode) ...[
            IconButton(
              onPressed: _selectedHourIds.isEmpty
                  ? null
                  : _showBulkApprovalSheet,
              icon: const Icon(Icons.check_circle, color: Color(0xFF10b981)),
            ),
            IconButton(
              onPressed: _exitSelectionMode,
              icon: const Icon(Icons.close, color: Color(0xFF6b7280)),
            ),
          ] else ...[
            PopupMenuButton<String>(
              onSelected: (value) => setState(() => _filterStatus = value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('הכל')),
                const PopupMenuItem(
                  value: 'pending',
                  child: Text('ממתין לאישור'),
                ),
                const PopupMenuItem(value: 'approved', child: Text('אושר')),
                const PopupMenuItem(value: 'rejected', child: Text('נדחה')),
              ],
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.filter_list, color: Color(0xFF6b7280)),
              ),
            ),
          ],
        ],
      ),
      body: allHoursAsync.when(
        data: (allHours) {
          print('📊 UI BUILD: Received ${allHours.length} working hours');
          return _buildHoursList(allHours);
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('טוען שעות עבודה...'),
            ],
          ),
        ),
        error: (error, stack) {
          print('❌ UI ERROR: $error');
          return _buildErrorState(error);
        },
      ),
      // Add floating action button for debugging
      floatingActionButton: FloatingActionButton(
        onPressed: _debugWorkingHours,
        child: const Icon(Icons.bug_report),
        backgroundColor: const Color(0xFF8b5cf6),
      ),
    );
  }

  Widget _buildHoursList(List<WorkingHours> allHours) {
    final filteredHours = _filterHours(allHours);

    if (filteredHours.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Filter chips
        _buildFilterChips(allHours),

        // Hours list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allWorkingHoursProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredHours.length,
              itemBuilder: (context, index) {
                final hours = filteredHours[index];
                return HourApprovalCard(
                  workingHours: hours,
                  isSelected: _selectedHourIds.contains(hours.id),
                  isSelectionMode: _isSelectionMode,
                  onSelectionChanged: (selected) =>
                      _toggleSelection(hours.id, selected),
                  onApprove: () => _approveHours(hours),
                  onReject: () => _showRejectDialog(hours),
                  onViewDetails: () => _showHoursDetails(hours),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(List<WorkingHours> allHours) {
    final pendingCount = allHours
        .where((h) => h.status == WorkingHoursStatus.pending)
        .length;
    final approvedCount = allHours
        .where((h) => h.status == WorkingHoursStatus.approved)
        .length;
    final rejectedCount = allHours
        .where((h) => h.status == WorkingHoursStatus.rejected)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'הכל',
              'all',
              allHours.length,
              const Color(0xFF6b7280),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'ממתין',
              'pending',
              pendingCount,
              const Color(0xFFf59e0b),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'אושר',
              'approved',
              approvedCount,
              const Color(0xFF10b981),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'נדחה',
              'rejected',
              rejectedCount,
              const Color(0xFFef4444),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count, Color color) {
    final isSelected = _filterStatus == value;

    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) => setState(() => _filterStatus = value),
      backgroundColor: Colors.white,
      selectedColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? color : const Color(0xFF6b7280),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? color : const Color(0xFFe5e7eb)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 64,
            color: const Color(0xFF6b7280).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateText(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'שעות עבודה יופיעו כאן כשיירשמו',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFef4444)),
          const SizedBox(height: 16),
          const Text(
            'שגיאה בטעינת שעות העבודה',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(allWorkingHoursProvider),
            child: const Text('נסה שוב'),
          ),
        ],
      ),
    );
  }

  List<WorkingHours> _filterHours(List<WorkingHours> allHours) {
    switch (_filterStatus) {
      case 'pending':
        return allHours
            .where((h) => h.status == WorkingHoursStatus.pending)
            .toList();
      case 'approved':
        return allHours
            .where((h) => h.status == WorkingHoursStatus.approved)
            .toList();
      case 'rejected':
        return allHours
            .where((h) => h.status == WorkingHoursStatus.rejected)
            .toList();
      default:
        return allHours;
    }
  }

  String _getEmptyStateText() {
    switch (_filterStatus) {
      case 'pending':
        return 'אין שעות ממתינות לאישור';
      case 'approved':
        return 'אין שעות מאושרות';
      case 'rejected':
        return 'אין שעות נדחות';
      default:
        return 'אין שעות עבודה';
    }
  }

  void _toggleSelection(String hourId, bool selected) {
    setState(() {
      if (selected) {
        _selectedHourIds.add(hourId);
        if (!_isSelectionMode) _isSelectionMode = true;
      } else {
        _selectedHourIds.remove(hourId);
        if (_selectedHourIds.isEmpty) _isSelectionMode = false;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedHourIds.clear();
    });
  }

  void _showBulkApprovalSheet() {
    final allHours = ref.read(allWorkingHoursProvider).value ?? [];
    final selectedHours = allHours
        .where((h) => _selectedHourIds.contains(h.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BulkApprovalBottomSheet(
        selectedHourIds: _selectedHourIds.toList(),
        workingHours: selectedHours,
        onApprove: _bulkApproveHours,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _bulkApproveHours(List<String> hourIds) async {
    final actions = ref.read(workingHoursActionsProvider);

    try {
      final success = await actions.bulkApproveWorkingHours(
        hourIds,
        widget.user.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${hourIds.length} שעות עבודה אושרו בהצלחה'),
            backgroundColor: const Color(0xFF10b981),
          ),
        );
        _exitSelectionMode();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה באישור שעות: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    }
  }

  Future<void> _approveHours(WorkingHours hours) async {
    final actions = ref.read(workingHoursActionsProvider);

    try {
      final success = await actions.approveWorkingHours(
        hours.id,
        widget.user.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שעות העבודה אושרו בהצלחה'),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה באישור שעות: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    }
  }

  void _showRejectDialog(WorkingHours hours) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('דחיית שעות עבודה'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('מנחה: ${hours.mentorName}'),
            Text('שעות: ${hours.hours.toStringAsFixed(1)}'),
            const SizedBox(height: 16),
            const Text('סיבת דחייה:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'הכנס סיבת דחייה...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;

              Navigator.pop(context);
              await _rejectHours(hours, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
            ),
            child: const Text('דחה', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectHours(WorkingHours hours, String reason) async {
    final actions = ref.read(workingHoursActionsProvider);

    try {
      final success = await actions.rejectWorkingHours(
        hours.id,
        widget.user.id,
        reason,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שעות העבודה נדחו'),
            backgroundColor: Color(0xFFef4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בדחיית שעות: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    }
  }

  void _showHoursDetails(WorkingHours hours) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFe5e7eb),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'פרטי שעות עבודה',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details
                  _buildDetailRow('מנחה', hours.mentorName),
                  _buildDetailRow('תחום', hours.getDisciplineDisplayName()),
                  _buildDetailRow(
                    'תאריך',
                    '${hours.date.day}/${hours.date.month}/${hours.date.year}',
                  ),
                  _buildDetailRow(
                    'שעות',
                    '${hours.hours.toStringAsFixed(1)} שעות',
                  ),
                  _buildDetailRow('תלמידים', '${hours.numberOfStudents}'),
                  _buildDetailRow('סטטוס', hours.getStatusText()),

                  if (hours.notes != null && hours.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'הערות:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hours.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6b7280),
                      ),
                    ),
                  ],

                  if (hours.rejectionReason != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'סיבת דחייה:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFef4444),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hours.rejectionReason!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFef4444),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6b7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1f2937)),
            ),
          ),
        ],
      ),
    );
  }

  // Add this to test the repository directly
}
