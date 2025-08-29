import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:knafayim_app/data/models/lesson.dart';
import 'package:knafayim_app/data/repositories/user_repository.dart';
import 'package:knafayim_app/presentation/widgets/reports/advanced_filter_panel.dart';
import '../../../data/models/report.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../services/report_generation_service.dart';
import '../../../config/service_locator.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  final User user;
  final ReportType reportType;

  const AnalyticsDashboardScreen({
    super.key,
    required this.user,
    required this.reportType,
  });

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  final ReportRepository _reportRepository = serviceLocator<ReportRepository>();
  final ReportGenerationService _reportService =
      serviceLocator<ReportGenerationService>();

  late TabController _tabController;
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;
  String _selectedMetric = 'hours';

  FilterCriteria _currentFilters = const FilterCriteria();
  List<User> _availableInstructors = [];
  List<User> _availableArtists = [];

  // Data state
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _timeSeriesData = [];
  List<Map<String, dynamic>> _distributionData = [];
  bool _isLoading = true;
  String _selectedPeriod = 'month';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Chart interaction state
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOutCubic,
    );

    _setDefaultMetric();
    _loadAnalyticsData();
    _loadUsersForFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUsersForFilters() async {
    try {
      final userRepo = serviceLocator<UserRepository>();
      final allUsers = await userRepo.getAllUsers();

      if (mounted) {
        setState(() {
          _availableInstructors = allUsers
              .where((u) => u.role == UserRole.mentor)
              .toList();
          _availableArtists = allUsers
              .where((u) => u.role == UserRole.client)
              .toList();
        });
      }
    } catch (e) {
      print('Error loading users for filters: $e');
    }
  }

  void _setDefaultMetric() {
    switch (widget.reportType) {
      case ReportType.attendance:
      case ReportType.workingHours:
        _selectedMetric = 'hours';
        break;
      case ReportType.userActivity:
        _selectedMetric = 'users';
        break;
      default:
        _selectedMetric = 'general';
    }
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> data;
      List<Map<String, dynamic>> timeSeries = [];
      List<Map<String, dynamic>> distribution = [];

      switch (widget.reportType) {
        case ReportType.attendance:
          data = await _reportRepository.generateAttendanceAnalytics(
            startDate: _startDate,
            endDate: _endDate,
          );
          timeSeries = await _generateTimeSeriesData('attendance');
          distribution = await _generateDistributionData('attendance');
          break;

        case ReportType.workingHours:
          data = await _reportRepository.generateWorkingHoursAnalytics(
            startDate: _startDate,
            endDate: _endDate,
          );
          timeSeries = await _generateTimeSeriesData('workingHours');
          distribution = await _generateDistributionData('workingHours');
          break;

        case ReportType.userActivity:
          data = await _reportRepository.generateUserActivityAnalytics(
            startDate: _startDate,
            endDate: _endDate,
          );
          timeSeries = await _generateTimeSeriesData('userActivity');
          distribution = await _generateDistributionData('userActivity');
          break;

        default:
          data = {};
      }

      if (mounted) {
        setState(() {
          _analyticsData = data;
          _timeSeriesData = timeSeries;
          _distributionData = distribution;
          _isLoading = false;
        });
        _chartAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת נתונים: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _generateTimeSeriesData(
    String dataType,
  ) async {
    try {
      final List<Map<String, dynamic>> data = [];
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      final lessons = await _reportRepository.getAllLessons(
        startDate: startDate,
        endDate: now,
      );

      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final dayLessons = lessons
            .where(
              (lesson) =>
                  lesson.date.isAfter(dayStart) && lesson.date.isBefore(dayEnd),
            )
            .toList();

        double value = 0;

        switch (dataType) {
          case 'workingHours':
            value = dayLessons.fold(
              0.0,
              (sum, lesson) => sum + (lesson.durationMinutes / 60.0),
            );
            break;
          case 'attendance':
            value = dayLessons.fold(
              0.0,
              (sum, lesson) =>
                  sum +
                  lesson.attendanceRecords
                      .where((r) => r.status == 'present' || r.status == 'late')
                      .length,
            );
            break;
          case 'userActivity':
            final uniqueAttendees = <String>{};
            for (final lesson in dayLessons) {
              for (final record in lesson.attendanceRecords) {
                if (record.status == 'present' || record.status == 'late') {
                  uniqueAttendees.add(record.artistId);
                }
              }
            }
            value = uniqueAttendees.length.toDouble();
            break;
        }

        data.add({
          'date': date,
          'value': value,
          'label': DateFormat('dd/MM').format(date),
        });
      }

      return data;
    } catch (e) {
      print('Error generating time series data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _generateDistributionData(
    String dataType,
  ) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));

      switch (dataType) {
        case 'workingHours':
          return await _generateWorkingHoursDistribution(startDate, now);
        case 'attendance':
          return await _generateAttendanceDistribution(startDate, now);
        case 'userActivity':
          return await _generateUserActivityDistribution(startDate, now);
        default:
          return [];
      }
    } catch (e) {
      print('Error generating distribution data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _generateWorkingHoursDistribution(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final lessons = await _reportRepository.getAllLessons(
        startDate: startDate,
        endDate: endDate,
      );

      double artistHours = 0;
      double mentorHours = 0;

      for (final lesson in lessons) {
        final hours = lesson.durationMinutes / 60.0;

        if (lesson.assignedInstructorId != null) {
          mentorHours += hours;
        }

        final attendedCount = lesson.attendanceRecords
            .where((r) => r.status == 'present' || r.status == 'late')
            .length;
        artistHours += hours * attendedCount;
      }

      final total = artistHours + mentorHours;
      if (total == 0) return [];

      return [
        {
          'name': 'אמנים',
          'value': ((artistHours / total) * 100).round(),
          'color': const Color(0xFF10b981),
        },
        {
          'name': 'מנחים',
          'value': ((mentorHours / total) * 100).round(),
          'color': const Color(0xFF3b82f6),
        },
      ];
    } catch (e) {
      print('Error generating working hours distribution: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _generateAttendanceDistribution(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final lessons = await _reportRepository.getAllLessons(
        startDate: startDate,
        endDate: endDate,
      );

      int presentCount = 0;
      int absentCount = 0;
      int lateCount = 0;
      int excusedCount = 0;

      for (final lesson in lessons) {
        for (final record in lesson.attendanceRecords) {
          switch (record.status) {
            case 'present':
              presentCount++;
              break;
            case 'absent':
              absentCount++;
              break;
            case 'late':
              lateCount++;
              break;
            case 'excused':
              excusedCount++;
              break;
          }
        }
      }

      final total = presentCount + absentCount + lateCount + excusedCount;
      if (total == 0) return [];

      return [
        {
          'name': 'נוכח',
          'value': ((presentCount / total) * 100).round(),
          'color': const Color(0xFF10b981),
        },
        {
          'name': 'איחור',
          'value': ((lateCount / total) * 100).round(),
          'color': const Color(0xFFf59e0b),
        },
        {
          'name': 'נעדר',
          'value': ((absentCount / total) * 100).round(),
          'color': const Color(0xFFef4444),
        },
        {
          'name': 'מוצדק',
          'value': ((excusedCount / total) * 100).round(),
          'color': const Color(0xFF8b5cf6),
        },
      ];
    } catch (e) {
      print('Error generating attendance distribution: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _generateUserActivityDistribution(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userRepo = serviceLocator<UserRepository>();
      final allUsers = await userRepo.getAllUsers();
      final artists = allUsers.where((u) => u.role == UserRole.client).toList();

      final lessons = await _reportRepository.getAllLessons(
        startDate: startDate,
        endDate: endDate,
      );

      Map<String, int> userActivity = {};

      for (final artist in artists) {
        int attendanceCount = 0;
        for (final lesson in lessons) {
          final attended = lesson.attendanceRecords.any(
            (record) =>
                record.artistId == artist.id &&
                (record.status == 'present' || record.status == 'late'),
          );
          if (attended) attendanceCount++;
        }

        if (attendanceCount >= 8) {
          userActivity['פעילים'] = (userActivity['פעילים'] ?? 0) + 1;
        } else if (attendanceCount >= 3) {
          userActivity['בינוניים'] = (userActivity['בינוניים'] ?? 0) + 1;
        } else {
          userActivity['לא פעילים'] = (userActivity['לא פעילים'] ?? 0) + 1;
        }
      }

      if (userActivity.isEmpty) return [];

      final total = userActivity.values.reduce((a, b) => a + b);

      return [
        {
          'name': 'פעילים',
          'value': ((userActivity['פעילים'] ?? 0) / total * 100).round(),
          'color': const Color(0xFF10b981),
        },
        {
          'name': 'בינוניים',
          'value': ((userActivity['בינוניים'] ?? 0) / total * 100).round(),
          'color': const Color(0xFFf59e0b),
        },
        {
          'name': 'לא פעילים',
          'value': ((userActivity['לא פעילים'] ?? 0) / total * 100).round(),
          'color': const Color(0xFFef4444),
        },
      ];
    } catch (e) {
      print('Error generating user activity distribution: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildOverviewTab(), _buildChartsTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      title: Text(
        'ניתוח ${_getReportTypeDisplayName(widget.reportType)}',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1f2937),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _exportAnalytics,
          icon: const Icon(Icons.download, color: Color(0xFF3b82f6)),
          tooltip: 'ייצא נתונים',
        ),
        IconButton(
          onPressed: _loadAnalyticsData,
          icon: const Icon(Icons.refresh, color: Color(0xFF3b82f6)),
          tooltip: 'רענן נתונים',
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('שבוע', 'week'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('חודש', 'month'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('רבעון', 'quarter'),
                  const SizedBox(width: 16),
                  // NEW: Advanced filters button
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentFilters.hasActiveFilters
                            ? const Color(0xFF10b981)
                            : const Color(0xFFe5e7eb),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      color: _currentFilters.hasActiveFilters
                          ? const Color(0xFF10b981).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _showAdvancedFiltersPanel,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune,
                                size: 16,
                                color: _currentFilters.hasActiveFilters
                                    ? const Color(0xFF10b981)
                                    : const Color(0xFF6b7280),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'מסננים',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _currentFilters.hasActiveFilters
                                      ? const Color(0xFF10b981)
                                      : const Color(0xFF6b7280),
                                ),
                              ),
                              if (_currentFilters.hasActiveFilters) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10b981),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_currentFilters.activeFilterCount}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildMetricSelector(),
        ],
      ),
    );
  }

  void _showAdvancedFiltersPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AdvancedFilterPanel(
          initialFilters: _currentFilters,
          availableInstructors: _availableInstructors,
          availableArtists: _availableArtists,
          onFiltersChanged: (filters) {
            setState(() => _currentFilters = filters);
            _loadAnalyticsData();
          },
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = value;
            _updateDateRange(value);
          });
          _loadAnalyticsData();
        }
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF3b82f6).withOpacity(0.1),
      checkmarkColor: const Color(0xFF3b82f6),
      side: BorderSide(
        color: isSelected ? const Color(0xFF3b82f6) : const Color(0xFFe5e7eb),
      ),
    );
  }

  Widget _buildMetricSelector() {
    final metrics = _getMetricOptions();
    return DropdownButton<String>(
      value: _selectedMetric,
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedMetric = value);
          _loadAnalyticsData();
        }
      },
      items: metrics.map((metric) {
        return DropdownMenuItem(
          value: metric,
          child: Text(_getMetricDisplayName(metric)),
        );
      }).toList(),
      underline: Container(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF3b82f6),
        unselectedLabelColor: const Color(0xFF6b7280),
        indicatorColor: const Color(0xFF3b82f6),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'סקירה'),
          Tab(icon: Icon(Icons.bar_chart), text: 'גרפים'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricsGrid(),
          const SizedBox(height: 24),
          _buildInsightsCard(),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTimeSeriesChart(),
          const SizedBox(height: 24),
          _buildDistributionChart(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final metrics = _getMainMetrics();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _buildMetricCard(
          title: metric['title'],
          value: metric['value'],
          subtitle: metric['subtitle'],
          icon: metric['icon'],
          color: metric['color'],
          trend: metric['trend'],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10b981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trend,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10b981),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSeriesChart() {
    if (_timeSeriesData.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('אין נתונים להצגה')),
      );
    }

    return Container(
      height: 300,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'מגמה לאורך זמן',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: _chartAnimation,
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 &&
                                  index < _timeSeriesData.length) {
                                return Text(
                                  _timeSeriesData[index]['label'],
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _timeSeriesData
                              .asMap()
                              .entries
                              .map(
                                (entry) => FlSpot(
                                  entry.key.toDouble(),
                                  (entry.value['value'] as double) *
                                      _chartAnimation.value,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          color: const Color(0xFF3b82f6),
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF3b82f6).withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart() {
    if (_distributionData.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('אין נתונים להצגה')),
      );
    }

    return Container(
      height: 300,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'התפלגות',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AnimatedBuilder(
                      animation: _chartAnimation,
                      builder: (context, child) {
                        return PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, response) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      response == null ||
                                      response.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = response
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _distributionData.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final data = entry.value;
                              final isTouched = index == _touchedIndex;
                              final radius = isTouched ? 60.0 : 50.0;

                              return PieChartSectionData(
                                color: data['color'],
                                value:
                                    (data['value'] as int).toDouble() *
                                    _chartAnimation.value,
                                title: '${data['value']}%',
                                radius: radius,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _distributionData.map((data) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: data['color'],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['name'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6b7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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

  Widget _buildInsightsCard() {
    final insights = _generateInsights();
    return Container(
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
            const Text(
              'תובנות מרכזיות',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 16),
            ...insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3b82f6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _exportAnalytics,
      backgroundColor: const Color(0xFF3b82f6),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.download),
      label: const Text('ייצא דוח'),
    );
  }

  // Helper methods
  void _updateDateRange(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'week':
        _startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        _startDate = now.subtract(const Duration(days: 30));
        break;
      case 'quarter':
        _startDate = now.subtract(const Duration(days: 90));
        break;
    }
    _endDate = now;
  }

  List<String> _getMetricOptions() {
    switch (widget.reportType) {
      case ReportType.attendance:
        return ['attendance', 'rate'];
      case ReportType.workingHours:
        return ['hours', 'entries'];
      case ReportType.userActivity:
        return ['users', 'activity'];
      default:
        return ['general'];
    }
  }

  String _getMetricDisplayName(String metric) {
    switch (metric) {
      case 'hours':
        return 'שעות';
      case 'entries':
        return 'רישומים';
      case 'attendance':
        return 'נוכחות';
      case 'rate':
        return 'אחוזים';
      case 'users':
        return 'משתמשים';
      case 'activity':
        return 'פעילות';
      default:
        return 'כללי';
    }
  }

  String _getReportTypeDisplayName(ReportType type) {
    switch (type) {
      case ReportType.attendance:
        return 'נוכחות';
      case ReportType.workingHours:
        return 'שעות עבודה';
      case ReportType.userActivity:
        return 'פעילות משתמשים';
      case ReportType.financial:
        return 'כספי';
      default:
        return 'כללי';
    }
  }

  List<Map<String, dynamic>> _getMainMetrics() {
    switch (widget.reportType) {
      case ReportType.attendance:
        return [
          {
            'title': 'סה"כ נוכחות',
            'value': '${_analyticsData['presentCount'] ?? 0}',
            'subtitle': 'נוכחים',
            'icon': Icons.people,
            'color': const Color(0xFF10b981),
            'trend': '+12%',
          },
          {
            'title': 'אחוז נוכחות',
            'value':
                '${(_analyticsData['attendanceRate'] ?? 0.0).toStringAsFixed(1)}%',
            'subtitle': 'ממוצע',
            'icon': Icons.trending_up,
            'color': const Color(0xFF3b82f6),
            'trend': '+5%',
          },
          {
            'title': 'איחורים',
            'value': '${_analyticsData['lateCount'] ?? 0}',
            'subtitle': 'מאחרים',
            'icon': Icons.schedule,
            'color': const Color(0xFFf59e0b),
            'trend': '-3%',
          },
          {
            'title': 'נעדרים',
            'value': '${_analyticsData['absentCount'] ?? 0}',
            'subtitle': 'נעדרו',
            'icon': Icons.person_off,
            'color': const Color(0xFFef4444),
            'trend': '-8%',
          },
        ];

      case ReportType.workingHours:
        return [
          {
            'title': 'סה"כ שעות',
            'value':
                '${(_analyticsData['totalHours'] ?? 0.0).toStringAsFixed(1)}',
            'subtitle': 'שעות',
            'icon': Icons.access_time,
            'color': const Color(0xFF10b981),
            'trend': '+15%',
          },
          {
            'title': 'רישומים',
            'value': '${_analyticsData['totalEntries'] ?? 0}',
            'subtitle': 'רישומים',
            'icon': Icons.list_alt,
            'color': const Color(0xFF3b82f6),
            'trend': '+8%',
          },
          {
            'title': 'אחוז אישור',
            'value':
                '${(_analyticsData['approvalRate'] ?? 0.0).toStringAsFixed(1)}%',
            'subtitle': 'אושרו',
            'icon': Icons.check_circle,
            'color': const Color(0xFFf59e0b),
            'trend': '+3%',
          },
          {
            'title': 'ממוצע יומי',
            'value':
                '${(_analyticsData['averageHoursPerDay'] ?? 0.0).toStringAsFixed(1)}',
            'subtitle': 'שעות/יום',
            'icon': Icons.today,
            'color': const Color(0xFF8b5cf6),
            'trend': '+7%',
          },
        ];

      case ReportType.userActivity:
        return [
          {
            'title': 'משתמשים פעילים',
            'value': '${_analyticsData['activeUsers'] ?? 0}',
            'subtitle': 'פעילים',
            'icon': Icons.people,
            'color': const Color(0xFF10b981),
            'trend': '+10%',
          },
          {
            'title': 'סה"כ משתמשים',
            'value': '${_analyticsData['totalUsers'] ?? 0}',
            'subtitle': 'רשומים',
            'icon': Icons.group,
            'color': const Color(0xFF3b82f6),
            'trend': '+5%',
          },
          {
            'title': 'אחוז פעילות',
            'value':
                '${(_analyticsData['activityRate'] ?? 0.0).toStringAsFixed(1)}%',
            'subtitle': 'פעילות',
            'icon': Icons.trending_up,
            'color': const Color(0xFFf59e0b),
            'trend': '+8%',
          },
          {
            'title': 'ממוצע פעילות',
            'value':
                '${(_analyticsData['averageActivityPerUser'] ?? 0.0).toStringAsFixed(1)}',
            'subtitle': 'לכל משתמש',
            'icon': Icons.analytics,
            'color': const Color(0xFF8b5cf6),
            'trend': '+12%',
          },
        ];

      default:
        return [];
    }
  }

  List<String> _generateInsights() {
    switch (widget.reportType) {
      case ReportType.attendance:
        final attendanceRate = _analyticsData['attendanceRate'] ?? 0.0;
        final lateCount = _analyticsData['lateCount'] ?? 0;
        return [
          'אחוז הנוכחות הכללי עומד על ${attendanceRate.toStringAsFixed(1)}%',
          if (attendanceRate > 85)
            'רמת נוכחות מצוינת! האמנים מגיעים באופן קבוע',
          if (attendanceRate < 70)
            'רמת נוכחות נמוכה - מומלץ לבדוק סיבות להיעדרויות',
          if (lateCount > 10) 'מספר איחורים גבוה - כדאי לשקול תזכורות נוספות',
          'הנתונים מבוססים על ${_analyticsData['totalRecords'] ?? 0} רישומי נוכחות',
        ];

      case ReportType.workingHours:
        final totalHours = _analyticsData['totalHours'] ?? 0.0;
        final approvalRate = _analyticsData['approvalRate'] ?? 0.0;
        return [
          'נרשמו סה"כ ${totalHours.toStringAsFixed(1)} שעות עבודה בתקופה',
          if (approvalRate > 90) 'אחוז אישור גבוה - תהליך יעיל של רישום שעות',
          if (approvalRate < 80) 'אחוז אישור נמוך - מומלץ לבדוק תהליכי אישור',
          'ממוצע ${(_analyticsData['averageHoursPerEntry'] ?? 0.0).toStringAsFixed(1)} שעות לכל רישום',
          'פעילות יומית ממוצעת: ${(_analyticsData['averageHoursPerDay'] ?? 0.0).toStringAsFixed(1)} שעות',
        ];

      case ReportType.userActivity:
        final activityRate = _analyticsData['activityRate'] ?? 0.0;
        final activeUsers = _analyticsData['activeUsers'] ?? 0;
        return [
          '${activeUsers} משתמשים פעילים מתוך ${_analyticsData['totalUsers'] ?? 0}',
          if (activityRate > 70) 'רמת מעורבות גבוהה בקהילת האמנים',
          if (activityRate < 50) 'רמת מעורבות נמוכה - מומלץ לעודד השתתפות',
          'ממוצע פעילות למשתמש: ${(_analyticsData['averageActivityPerUser'] ?? 0.0).toStringAsFixed(1)}',
          'הנתונים כוללים את כל סוגי הפעילות במערכת',
        ];

      default:
        return ['אין תובנות זמינות עבור סוג דוח זה'];
    }
  }

  void _exportAnalytics() async {
    try {
      await _reportService.generatePDFReport(
        title: 'דוח ניתוח ${_getReportTypeDisplayName(widget.reportType)}',
        content:
            'דוח מפורט של נתוני ${_getReportTypeDisplayName(widget.reportType)}',
        reportType: widget.reportType,
        startDate: _startDate,
        endDate: _endDate,
        createdByName: widget.user.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הדוח יוצא בהצלחה'),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בייצוא הדוח: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    }
  }
}
