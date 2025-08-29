import 'package:flutter/material.dart';
import '../../../data/models/user.dart';
import '../../../data/models/working_hours.dart';
import '../../../data/repositories/working_hours_repository.dart';
import '../../../config/service_locator.dart';
import 'log_hours_screen.dart';

class HoursDashboardScreen extends StatefulWidget {
  final User user;

  const HoursDashboardScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HoursDashboardScreen> createState() => _HoursDashboardScreenState();
}

class _HoursDashboardScreenState extends State<HoursDashboardScreen> {
  final WorkingHoursRepository _workingHoursRepository =
      serviceLocator<WorkingHoursRepository>();
  List<WorkingHours> _workingHours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  Future<void> _loadWorkingHours() async {
    print("DEBUG: Loading working hours for user: ${widget.user.id}");
    setState(() => _isLoading = true);

    try {
      final hours = await _workingHoursRepository.getWorkingHoursForMentor(
        widget.user.id,
      );
      print("DEBUG: Loaded ${hours.length} working hours");

      if (mounted) {
        setState(() {
          _workingHours = hours;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error loading working hours: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: const Text(
          'שעות עבודה',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              _navigateToLogHours();
              _loadWorkingHours(); // Add this line
            },
            icon: const Icon(Icons.add, color: Color(0xFF8b5cf6)),
          ),
          // ADD THIS NEW REFRESH BUTTON:
          IconButton(
            onPressed: _loadWorkingHours,
            icon: const Icon(Icons.refresh, color: Color(0xFF8b5cf6)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workingHours.isEmpty
          ? _buildEmptyState()
          : _buildHoursList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _navigateToLogHours();
          _loadWorkingHours(); // Add this line
        },
        backgroundColor: const Color(0xFF8b5cf6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time, size: 64, color: Color(0xFF8b5cf6)),
          const SizedBox(height: 16),
          const Text(
            'אין שעות עבודה רשומות',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'התחל לרשום שעות עבודה כדי לעקוב אחר הזמן שלך',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToLogHours,
            icon: const Icon(Icons.add),
            label: const Text('רשום שעות עבודה'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8b5cf6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursList() {
    return RefreshIndicator(
      onRefresh: _loadWorkingHours,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _workingHours.length,
        itemBuilder: (context, index) {
          final hours = _workingHours[index];
          return _buildWorkingHoursCard(hours);
        },
      ),
    );
  }

  Widget _buildWorkingHoursCard(WorkingHours hours) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hours.getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: hours.getStatusColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hours.getDisciplineDisplayName(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      Text(
                        '${hours.hours.toStringAsFixed(1)} שעות',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hours.getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hours.getStatusText(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hours.getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF6b7280),
                ),
                const SizedBox(width: 4),
                Text(
                  '${hours.date.day}/${hours.date.month}/${hours.date.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6b7280),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.people, size: 16, color: Color(0xFF6b7280)),
                const SizedBox(width: 4),
                Text(
                  '${hours.numberOfStudents} תלמידים',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
            if (hours.notes != null && hours.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                hours.notes!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToLogHours() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogHoursScreen(user: widget.user),
      ),
    );

    // ADD THESE LINES:
    if (result == true) {
      _loadWorkingHours();
    }
  }
}
