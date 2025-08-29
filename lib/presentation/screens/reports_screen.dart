import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:knafayim_app/config/service_locator.dart';
import 'package:knafayim_app/data/models/report.dart';
import 'package:knafayim_app/data/models/user.dart';
import 'package:knafayim_app/data/repositories/report_repository.dart';
import 'package:knafayim_app/data/repositories/user_repository.dart';
import 'package:knafayim_app/presentation/screens/analytics/artist_community_analytics_screen.dart';
import 'package:knafayim_app/presentation/screens/analytics/artist_search_screen.dart';
import 'package:knafayim_app/presentation/screens/reports/analytics_dashboard_screen.dart';
import 'package:knafayim_app/presentation/screens/reports/create_report_screen.dart';
import 'package:knafayim_app/presentation/screens/reports/report_generation_screen.dart';
import 'package:knafayim_app/presentation/screens/reports/scheduled_reports_screen.dart';
import 'package:knafayim_app/presentation/widgets/reports/advanced_filter_panel.dart';
import 'package:knafayim_app/presentation/widgets/reports/reports_overview.dart';
import 'package:knafayim_app/services/excel_export_service.dart';
import 'package:knafayim_app/services/report_generation_service.dart';
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final User user;

  const ReportsScreen({super.key, required this.user});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with TickerProviderStateMixin {
  final ReportRepository _reportRepository = serviceLocator<ReportRepository>();

  late TabController _tabController;
  List<Report> _reports = [];
  Map<String, dynamic> _quickStats = {};
  bool _isLoading = true;
  ReportType _selectedFilter = ReportType.all;

  FilterCriteria _currentFilters = const FilterCriteria();
  List<User> _availableInstructors = [];
  List<User> _availableArtists = [];

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    ); // ✅ CHANGED: from 2 to 3
    _loadData();
    _loadUsersForFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final reports = await _reportRepository
          .getReports(type: _selectedFilter)
          .timeout(const Duration(seconds: 10));

      final filteredReports = _applyFiltersToReports(reports);

      final analytics = await _loadQuickAnalytics().timeout(
        const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _reports = filteredReports;
          _quickStats = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reports data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _reports = [];
          _quickStats = {
            'totalHours': 0.0,
            'totalLessons': 0,
            'activeUsers': 0,
            'approvalRate': 0.0,
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת נתונים: $e'),
            backgroundColor: const Color(0xFFef4444),
            action: SnackBarAction(
              label: 'נסה שוב',
              textColor: Colors.white,
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  List<Report> _applyFiltersToReports(List<Report> reports) {
    var filtered = reports;

    if (_currentFilters.dateRange != null) {
      filtered = filtered.where((report) {
        return report.createdAt.isAfter(_currentFilters.dateRange!.start) &&
            report.createdAt.isBefore(_currentFilters.dateRange!.end);
      }).toList();
    }

    if (_currentFilters.searchQuery?.isNotEmpty ?? false) {
      final query = _currentFilters.searchQuery!.toLowerCase();
      filtered = filtered.where((report) {
        return report.title.toLowerCase().contains(query) ||
            report.content.toLowerCase().contains(query) ||
            report.createdByName.toLowerCase().contains(query);
      }).toList();
    }

    if (_currentFilters.reportTypes.isNotEmpty) {
      filtered = filtered.where((report) {
        return _currentFilters.reportTypes.contains(report.type);
      }).toList();
    }

    return filtered;
  }

  Future<Map<String, dynamic>> _loadQuickAnalytics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // ✅ UPDATED: Use new consolidated analytics method
      final workingHours = await _reportRepository
          .generateAnalytics(
            type: ReportType.workingHours,
            startDate: startOfMonth,
            endDate: now,
          )
          .timeout(const Duration(seconds: 5));

      final userActivity = await _reportRepository
          .generateAnalytics(
            type: ReportType.userActivity,
            startDate: startOfMonth,
            endDate: now,
          )
          .timeout(const Duration(seconds: 5));

      final attendanceData = await _reportRepository
          .generateAnalytics(
            type: ReportType.attendance,
            startDate: startOfMonth,
            endDate: now,
          )
          .timeout(const Duration(seconds: 5));

      return {
        'totalHours': (workingHours['totalHours'] as num?)?.toDouble() ?? 0.0,
        'totalLessons': (attendanceData['totalRecords'] as num?)?.toInt() ?? 0,
        'activeUsers': (userActivity['activeUsers'] as num?)?.toInt() ?? 0,
        'approvalRate':
            (workingHours['approvalRate'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      print('Error loading quick analytics: $e');
      return {
        'totalHours': 0.0,
        'totalLessons': 0,
        'activeUsers': 0,
        'approvalRate': 0.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsDashboard(), // ✅ NEW: Combined analytics + overview
                _buildReportsAndExports(), // ✅ NEW: Combined reports + exports
                const ReportsOverview(), // ✅ ADDED: Reports Overview to the TabBarView
              ],
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
      title: const Text(
        'דוחות וניתוחים - כנפיים',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1f2937),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh, color: Color(0xFF3b82f6)),
          tooltip: 'רענן נתונים',
        ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduledReportsScreen(user: widget.user),
            ),
          ),
          icon: const Icon(Icons.schedule, color: Color(0xFF3b82f6)),
          tooltip: 'דוחות מתוזמנים',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF3b82f6)),
          onSelected: (value) {
            switch (value) {
              case 'export_all':
                _exportAllReports();
                break;
              case 'generate_custom':
                _navigateToReportGeneration();
                break;
              case 'settings':
                _showReportSettings();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'generate_custom',
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF10b981)),
                  SizedBox(width: 8),
                  Text('יצירת דוח מותאם'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export_all',
              child: Row(
                children: [
                  Icon(Icons.download, color: Color(0xFF3b82f6)),
                  SizedBox(width: 8),
                  Text('ייצא הכל'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: Color(0xFF6b7280)),
                  SizedBox(width: 8),
                  Text('הגדרות'),
                ],
              ),
            ),
          ],
        ),
      ],
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
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.analytics, size: 20),
            text: 'ניתוחים וסקירה',
          ), // ✅ MERGED: Overview + Analytics
          Tab(
            icon: Icon(Icons.file_download, size: 20),
            text: 'דוחות וייצוא',
          ), // ✅ MERGED: Reports + Export
          Tab(
            icon: Icon(Icons.dashboard, size: 20),
            text: 'סקירת דוחות',
          ), // ✅ ADDED: Reports Overview Tab
        ],
      ),
    );
  }

  // ✅ NEW: Combined analytics and overview
  Widget _buildAnalyticsDashboard() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3b82f6)),
            ),
            SizedBox(height: 16),
            Text(
              'טוען נתוני דוחות...',
              style: TextStyle(fontSize: 16, color: Color(0xFF6b7280)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats from overview
          _buildQuickStatsGrid(),
          const SizedBox(height: 24),

          // Analytics cards
          const Text(
            'ניתוחים מתקדמים',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            title: 'ניתוח נוכחות אמנים',
            subtitle: 'מעקב אחר השתתפות ומעורבות האמנים',
            icon: Icons.people,
            color: const Color(0xFF10b981),
            onTap: () => _navigateToAnalytics(ReportType.attendance),
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            title: 'ניתוח שעות מנחים',
            subtitle: 'מעקב אחר פרודוקטיביות והעסקת המנחים',
            icon: Icons.access_time,
            color: const Color(0xFF3b82f6),
            onTap: () => _navigateToAnalytics(ReportType.workingHours),
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            title: 'חיפוש אמן ספציפי',
            subtitle: 'צפה בנתוני נוכחות ופעילות של אמן מסוים',
            icon: Icons.person_search,
            color: const Color(0xFF06b6d4),
            onTap: _navigateToArtistSearch,
          ),
          const SizedBox(height: 24),

          // Recent activity (simplified)
          _buildRecentActivity(),
          const SizedBox(height: 24),

          // Quick actions (updated)
          _buildQuickActions(),
        ],
      ),
    );
  }

  // ✅ NEW: Combined reports and exports
  Widget _buildReportsAndExports() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Export section
                const Text(
                  'ייצוא נתונים',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
                const SizedBox(height: 16),
                _buildExportCard(
                  title: 'ייצוא נתוני נוכחות',
                  subtitle: 'דוח מפורט של נוכחות אמנים בשיעורים',
                  icon: Icons.people,
                  color: const Color(0xFF10b981),
                  onTap: () => _exportReport('attendance'),
                ),
                const SizedBox(height: 16),
                _buildExportCard(
                  title: 'ייצוא שעות מנחים',
                  subtitle: 'Excel עם פירוט שעות לכל מנחה',
                  icon: Icons.access_time,
                  color: const Color(0xFF3b82f6),
                  onTap: () => _exportReport('working_hours'),
                ),
                const SizedBox(height: 16),
                _buildExportCard(
                  title: 'דוח כולל לתרומות',
                  subtitle: 'דוח מקיף לגורמי מימון ותרומות',
                  icon: Icons.description,
                  color: const Color(0xFFf59e0b),
                  onTap: () => _exportReport('full_report'),
                ),
                const SizedBox(height: 32),

                // Reports list section
                const Text(
                  'דוחות קיימים',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _reports.isEmpty
                    ? _buildEmptyState()
                    : _buildReportsList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        int crossAxisCount = 2;
        double childAspectRatio = 1.5;
        double crossAxisSpacing = 8;
        double mainAxisSpacing = 8;

        if (screenWidth > 600) {
          crossAxisCount = 4;
          childAspectRatio = 1.3;
          crossAxisSpacing = 12;
          mainAxisSpacing = 12;
        } else if (screenWidth > 400) {
          crossAxisCount = 2;
          childAspectRatio = 1.6;
          crossAxisSpacing = 10;
          mainAxisSpacing = 10;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              title: 'שעות עבודה החודש',
              value:
                  '${(_quickStats['totalHours'] as double).toStringAsFixed(1)}',
              subtitle: 'שעות',
              icon: Icons.access_time,
              color: const Color(0xFF10b981),
              trend: '+12%',
            ),
            _buildStatCard(
              title: 'שיעורים החודש',
              value: '${_quickStats['totalLessons']}',
              subtitle: 'שיעורים',
              icon: Icons.school,
              color: const Color(0xFF3b82f6),
              trend: '+8%',
            ),
            _buildStatCard(
              title: 'אמנים פעילים',
              value: '${_quickStats['activeUsers']}',
              subtitle: 'אמנים',
              icon: Icons.people,
              color: const Color(0xFF8b5cf6),
              trend: '+5%',
            ),
            _buildStatCard(
              title: 'אחוז אישורים',
              value:
                  '${(_quickStats['approvalRate'] as double).toStringAsFixed(1)}%',
              subtitle: 'אושרו',
              icon: Icons.check_circle,
              color: const Color(0xFFf59e0b),
              trend: '+3%',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
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
            const SizedBox(height: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6b7280)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9ca3af)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 120,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF9ca3af),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (!widget.user.isStaff) return null;

    return FloatingActionButton.extended(
      onPressed: _createNewReport,
      backgroundColor: const Color(0xFF3b82f6),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('דוח חדש'),
    );
  }

  // ✅ CONSOLIDATED: One export method for all types
  void _exportReport(String reportType) async {
    try {
      _showLoadingDialog('מייצא ${_getReportTypeDisplayName(reportType)}...');

      final excelService = serviceLocator<ExcelExportService>();
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final result = await excelService.saveReportExcelToDevice(
        reportType: reportType,
        startDate: startOfMonth,
        endDate: now,
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: const Color(0xFF10b981),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בייצוא: $e'),
          backgroundColor: const Color(0xFFef4444),
        ),
      );
    }
  }

  String _getReportTypeDisplayName(String reportType) {
    switch (reportType) {
      case 'attendance':
        return 'נתוני נוכחות';
      case 'working_hours':
        return 'נתוני שעות עבודה';
      case 'full_report':
        return 'דוח מקיף';
      default:
        return 'דוח';
    }
  }

  // Navigation and action methods
  void _navigateToAnalytics(ReportType type) {
    if (type == ReportType.attendance) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ArtistCommunityAnalyticsScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AnalyticsDashboardScreen(user: widget.user, reportType: type),
        ),
      );
    }
  }

  void _navigateToArtistSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ArtistSearchScreen()),
    );
  }

  void _navigateToReportGeneration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportGenerationScreen()),
    );
  }

  void _createNewReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReportScreen(user: widget.user),
      ),
    ).then((created) {
      if (created == true) {
        _loadData();
      }
    });
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'פעילות אחרונה',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reports.take(3).length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final report = _reports[index];
              return _buildActivityItem(report);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Report report) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getReportColor(report.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getReportIcon(report.type),
            color: _getReportColor(report.type),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ UPDATED: Quick actions with new tab navigation
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'פעולות מהירות',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'חיפוש אמן',
                  Icons.person_search,
                  const Color(0xFF06b6d4),
                  _navigateToArtistSearch,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'ייצא נתונים',
                  Icons.download,
                  const Color(0xFF3b82f6),
                  () => _tabController.animateTo(
                    1,
                  ), // ✅ UPDATED: Go to tab 1 instead of 3
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...ReportType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      // ✅ FIX: Use the correct method for ReportType enum
                      label: Text(
                        _getReportTypeDisplayNameFromEnum(type),
                      ), // Changed this line
                      selected: _selectedFilter == type,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = type);
                          _loadData();
                        }
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF3b82f6).withOpacity(0.1),
                      checkmarkColor: const Color(0xFF3b82f6),
                      side: BorderSide(
                        color: _selectedFilter == type
                            ? const Color(0xFF3b82f6)
                            : const Color(0xFFe5e7eb),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(width: 16),
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
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune,
                              size: 18,
                              color: _currentFilters.hasActiveFilters
                                  ? const Color(0xFF10b981)
                                  : const Color(0xFF6b7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'מסננים מתקדמים',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _currentFilters.hasActiveFilters
                                    ? const Color(0xFF10b981)
                                    : const Color(0xFF6b7280),
                              ),
                            ),
                            if (_currentFilters.hasActiveFilters) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10b981),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_currentFilters.activeFilterCount}',
                                  style: const TextStyle(
                                    fontSize: 12,
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
          if (_currentFilters.hasActiveFilters) ...[
            const SizedBox(height: 12),
            _buildActiveFiltersSummary(),
          ],
        ],
      ),
    );
  }

  // ✅ NEW: Method to handle ReportType enum
  String _getReportTypeDisplayNameFromEnum(ReportType type) {
    switch (type) {
      case ReportType.all:
        return 'הכל';
      case ReportType.attendance:
        return 'נוכחות';
      case ReportType.workingHours:
        return 'שעות עבודה';
      case ReportType.userActivity:
        return 'פעילות משתמשים';
      case ReportType.financial:
        return 'כספי';
      case ReportType.meeting:
        return 'פגישות';
      case ReportType.progress:
        return 'התקדמות';
      case ReportType.event:
        return 'אירועים';
      case ReportType.other:
        return 'אחר';
    }
  }

  // ✅ KEEP: Existing method for String parameters

  // ✅ KEEP: Existing method for String parameters

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
            _loadData();
          },
        ),
      ),
    );
  }

  Widget _buildActiveFiltersSummary() {
    final summaryItems = <String>[];

    if (_currentFilters.dateRange != null) {
      summaryItems.add(
        'תאריכים: ${DateFormat('dd/MM').format(_currentFilters.dateRange!.start)} - ${DateFormat('dd/MM').format(_currentFilters.dateRange!.end)}',
      );
    }

    if (_currentFilters.selectedInstructors.isNotEmpty) {
      summaryItems.add('מנחים: ${_currentFilters.selectedInstructors.length}');
    }

    if (_currentFilters.selectedArtists.isNotEmpty) {
      summaryItems.add('אמנים: ${_currentFilters.selectedArtists.length}');
    }

    if (_currentFilters.searchQuery?.isNotEmpty ?? false) {
      summaryItems.add('חיפוש: "${_currentFilters.searchQuery}"');
    }

    if (_currentFilters.includeRecurringOnly) {
      summaryItems.add('שיעורים חוזרים בלבד');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10b981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF10b981).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt, size: 16, color: Color(0xFF10b981)),
              const SizedBox(width: 6),
              const Text(
                'מסננים פעילים:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10b981),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() => _currentFilters = const FilterCriteria());
                  _loadData();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'נקה הכל',
                  style: TextStyle(fontSize: 12, color: Color(0xFF10b981)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: summaryItems.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10b981).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF059669),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment,
            size: 64,
            color: const Color(0xFF6b7280).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'אין דוחות',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6b7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'צור דוח חדש או השתמש בכלי הניתוח',
            style: TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      shrinkWrap: true, // ✅ FIX: Forces ListView to take only required space
      physics:
          const NeverScrollableScrollPhysics(), // ✅ FIX: Disables ListView scrolling
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getReportColor(report.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getReportIcon(report.type),
                color: _getReportColor(report.type),
                size: 20,
              ),
            ),
            title: Text(
              report.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1f2937),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'נוצר ע"י: ${report.createdByName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6b7280),
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9ca3af),
                  ),
                ),
              ],
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9ca3af),
            ),
            onTap: () => _viewReportDetails(report),
          ),
        );
      },
    );
  }

  Widget _buildExportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      Text(
                        subtitle,
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
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ייצא',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.attendance:
        return Icons.people;
      case ReportType.workingHours:
        return Icons.access_time;
      case ReportType.userActivity:
        return Icons.analytics;
      case ReportType.financial:
        return Icons.attach_money;
      case ReportType.meeting:
        return Icons.groups;
      case ReportType.progress:
        return Icons.trending_up;
      case ReportType.event:
        return Icons.event;
      case ReportType.other:
        return Icons.description;
      default:
        return Icons.assessment;
    }
  }

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.attendance:
        return const Color(0xFF10b981);
      case ReportType.workingHours:
        return const Color(0xFF3b82f6);
      case ReportType.userActivity:
        return const Color(0xFFf59e0b);
      case ReportType.financial:
        return const Color(0xFFef4444);
      case ReportType.meeting:
        return const Color(0xFF3b82f6);
      case ReportType.progress:
        return const Color(0xFF10b981);
      case ReportType.event:
        return const Color(0xFFf59e0b);
      case ReportType.other:
        return const Color(0xFF8b5cf6);
      default:
        return const Color(0xFF6b7280);
    }
  }

  // Action methods
  void _viewReportDetails(Report report) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('פרטי דוח יהיו זמינים בקרוב')));
  }

  void _exportAllReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ייצוא כל הדוחות יהיה זמין בקרוב')),
    );
  }

  void _showReportSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('הגדרות דוחות יהיו זמינות בקרוב')),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
