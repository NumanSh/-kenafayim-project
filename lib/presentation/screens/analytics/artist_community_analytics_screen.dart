import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:knafayim_app/services/excel_export_service.dart';
import '../../../data/repositories/artist_community_analytics_repository.dart';
import '../../../config/service_locator.dart';

class ArtistCommunityAnalyticsScreen extends ConsumerStatefulWidget {
  const ArtistCommunityAnalyticsScreen({super.key});

  @override
  ConsumerState<ArtistCommunityAnalyticsScreen> createState() =>
      _ArtistCommunityAnalyticsScreenState();
}

class _ArtistCommunityAnalyticsScreenState
    extends ConsumerState<ArtistCommunityAnalyticsScreen>
    with TickerProviderStateMixin {
  final ArtistCommunityAnalyticsRepository _analyticsRepository =
      serviceLocator<ArtistCommunityAnalyticsRepository>();

  late TabController _tabController;
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;

  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = true;
  String _selectedPeriod = 'month';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOutCubic,
    );
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _analyticsRepository.getCommunityAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _analyticsData = data;
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
              children: [
                _buildOverviewTab(),
                _buildChartsTab(),
                _buildArtistsTab(),
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
        'ניתוח נוכחות אמנים - קהילת כנפיים',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1f2937),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _exportCommunityReport,
          icon: const Icon(Icons.download, color: Color(0xFF3b82f6)),
          tooltip: 'ייצא דוח קהילה',
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
                  const SizedBox(width: 8),
                  _buildPeriodChip('שנה', 'year'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: _showDateRangePicker,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFe5e7eb)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.date_range,
                    size: 16,
                    color: Color(0xFF6b7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String period) {
    final isSelected = _selectedPeriod == period;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
          _updateDateRangeForPeriod(period);
        });
        _loadAnalyticsData();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3b82f6) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3b82f6)
                : const Color(0xFFe5e7eb),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6b7280),
          ),
        ),
      ),
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
          Tab(icon: Icon(Icons.dashboard, size: 20), text: 'סקירה'),
          Tab(icon: Icon(Icons.bar_chart, size: 20), text: 'תרשימים'),
          Tab(icon: Icon(Icons.people, size: 20), text: 'אמנים'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
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
              'טוען נתוני קהילת האמנים...',
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
          _buildAggregateStatsGrid(),
          const SizedBox(height: 24),
          _buildQuickInsights(),
          const SizedBox(height: 24),
          _buildMostPopularStudio(),
        ],
      ),
    );
  }

  Widget _buildAggregateStatsGrid() {
    final stats = _analyticsData['aggregateStats'] ?? {};

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive parameters
        final screenWidth = constraints.maxWidth;
        int crossAxisCount = 2;
        double childAspectRatio =
            1.0; // ✅ Reduced from 1.1 to 1.0 (taller cards)
        double crossAxisSpacing = 12;
        double mainAxisSpacing = 12;

        if (screenWidth > 600) {
          // Tablet/Desktop
          crossAxisCount = 4;
          childAspectRatio = 0.9; // ✅ Reduced from 1.0 to 0.9
          crossAxisSpacing = 16;
          mainAxisSpacing = 16;
        } else if (screenWidth > 400) {
          // Large phone
          crossAxisCount = 2;
          childAspectRatio = 1.1; // ✅ Reduced from 1.2 to 1.1
          crossAxisSpacing = 14;
          mainAxisSpacing = 14;
        } else {
          // Small phone
          crossAxisCount = 2;
          childAspectRatio = 1.2; // ✅ Reduced from 1.3 to 1.2
          crossAxisSpacing = 12;
          mainAxisSpacing = 12;
        }

        return SizedBox(
          height: 340, // ✅ Increased from 320 to 340 (20px more height)
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
            children: [
              _buildStatCard(
                'אמנים רשומים',
                '${stats['totalRegistered'] ?? 0}',
                'סה"כ בקהילה',
                Icons.people,
                const Color(0xFF3b82f6),
                '+5%',
              ),
              _buildStatCard(
                'אמנים פעילים',
                '${stats['activeThisMonth'] ?? 0}',
                'השתתפו החודש',
                Icons.people_alt,
                const Color(0xFF10b981),
                '+12%',
              ),
              _buildStatCard(
                'אחוז נוכחות',
                '${(stats['averageAttendanceRate'] ?? 0.0).toStringAsFixed(1)}%',
                'ממוצע קהילתי',
                Icons.trending_up,
                const Color(0xFFf59e0b),
                '+8%',
              ),
              _buildStatCard(
                'שיעורים נערכו',
                '${stats['totalLessonsHeld'] ?? 0}',
                'בתקופה זו',
                Icons.school,
                const Color(0xFF8b5cf6),
                '+15%',
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Enhanced stat card with better spacing
  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    String trend,
  ) {
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
        padding: const EdgeInsets.all(
          16,
        ), // ✅ Slightly reduced padding for better fit
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // ✅ Better space distribution
          children: [
            // Top section with icon and trend
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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

            // Bottom section with data
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
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
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6b7280),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9ca3af),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights() {
    final studioData = _analyticsData['studioParticipation'] as List? ?? [];
    final mostPopular = studioData.isNotEmpty ? studioData.first : null;

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
            'תובנות מהירות',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            'הסטודיו הפופולרי ביותר',
            mostPopular != null
                ? '${mostPopular['name']} (${mostPopular['value']}% מהפעילות)'
                : 'אין נתונים זמינים',
            Icons.star,
            const Color(0xFFf59e0b),
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'מגמת נוכחות',
            'עלייה של 8% מהחודש הקודם',
            Icons.trending_up,
            const Color(0xFF10b981),
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'יום הפעילות הגבוהה',
            'יום שלישי - ממוצע 15 אמנים ליום',
            Icons.calendar_today,
            const Color(0xFF3b82f6),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMostPopularStudio() {
    final studioData = _analyticsData['studioParticipation'] as List? ?? [];

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
            'פופולריות הסטודיואים',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          if (studioData.isEmpty)
            const Text('אין נתונים זמינים')
          else
            ...studioData
                .take(3)
                .map(
                  (studio) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(studio['color']),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            studio['name'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                        ),
                        Text(
                          '${studio['value']}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6b7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAttendanceTrendsChart(),
          const SizedBox(height: 24),
          _buildStudioDistributionChart(),
          const SizedBox(height: 24),
          _buildWeeklyPatternsChart(),
        ],
      ),
    );
  }

  Widget _buildAttendanceTrendsChart() {
    final trendsData = _analyticsData['attendanceTrends'] as List? ?? [];

    return Container(
      height: 300,
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
            'מגמות נוכחות לאורך זמן',
            style: TextStyle(
              fontSize: 16,
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
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: trendsData.length > 10
                              ? (trendsData.length / 5).round().toDouble()
                              : 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() < trendsData.length) {
                              return Text(
                                trendsData[value.toInt()]['label'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF6b7280),
                                  fontSize: 10,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 40,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                color: Color(0xFF6b7280),
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (trendsData.length - 1).toDouble(),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: trendsData.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            (entry.value['attendanceRate'] as double) *
                                _chartAnimation.value,
                          );
                        }).toList(),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10b981), Color(0xFF059669)],
                        ),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10b981).withOpacity(0.3),
                              const Color(0xFF10b981).withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
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
    );
  }

  Widget _buildStudioDistributionChart() {
    final studioData = _analyticsData['studioParticipation'] as List? ?? [];

    return Container(
      height: 300,
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
            'התפלגות פעילות לפי סטודיואים',
            style: TextStyle(
              fontSize: 16,
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
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse
                                        .touchedSection!
                                        .touchedSectionIndex;
                                  });
                                },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: studioData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            final isTouched = index == _touchedIndex;
                            final fontSize = isTouched ? 16.0 : 12.0;
                            final radius = isTouched ? 80.0 : 70.0;

                            return PieChartSectionData(
                              color: Color(data['color']),
                              value:
                                  (data['value'] as num).toDouble() *
                                  _chartAnimation.value,
                              title: '${data['value']}%',
                              radius: radius,
                              titleStyle: TextStyle(
                                fontSize: fontSize,
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
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: studioData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(data['color']),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['name'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: index == _touchedIndex
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: const Color(0xFF1f2937),
                                ),
                              ),
                            ),
                            Text(
                              '${data['value']}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: index == _touchedIndex
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: const Color(0xFF6b7280),
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
    );
  }

  Widget _buildWeeklyPatternsChart() {
    final weeklyData = _analyticsData['weeklyPatterns'] as List? ?? [];

    return Container(
      height: 250,
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
            'דפוסי נוכחות שבועיים',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: weeklyData.isNotEmpty
                        ? weeklyData
                                  .map((e) => e['averageAttendance'] as double)
                                  .reduce((a, b) => a > b ? a : b) *
                              1.2
                        : 20,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() < weeklyData.length) {
                              return Text(
                                weeklyData[value.toInt()]['dayOfWeek'],
                                style: const TextStyle(
                                  color: Color(0xFF6b7280),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Color(0xFF6b7280),
                                fontSize: 10,
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: weeklyData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY:
                                (data['averageAttendance'] as double) *
                                _chartAnimation.value,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTopPerformingArtists(),
          const SizedBox(height: 24),
          _buildArtistsNeedingAttention(),
        ],
      ),
    );
  }

  Widget _buildTopPerformingArtists() {
    final topArtists = _analyticsData['topPerformingArtists'] as List? ?? [];

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFf59e0b).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Color(0xFFf59e0b),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'אמנים מצטיינים',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topArtists.isEmpty)
            const Text('אין נתונים זמינים')
          else
            ...topArtists
                .take(5)
                .map(
                  (artist) => _buildArtistItem(
                    artist['artistName'],
                    '${(artist['attendanceRate'] as double).toStringAsFixed(1)}% נוכחות',
                    '${artist['attendedLessons']}/${artist['totalLessons']} שיעורים',
                    const Color(0xFFf59e0b),
                    Icons.star,
                  ),
                )
                .toList(),
        ],
      ),
    );
  }

  Widget _buildArtistsNeedingAttention() {
    final needAttentionArtists =
        _analyticsData['artistsNeedingAttention'] as List? ?? [];

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFef4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning,
                  color: Color(0xFFef4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'אמנים הזקוקים לתשומת לב',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (needAttentionArtists.isEmpty)
            const Text('כל האמנים פעילים! 🎉')
          else
            ...needAttentionArtists
                .take(5)
                .map(
                  (artist) => _buildArtistItem(
                    artist['artistName'],
                    artist['reason'],
                    '${(artist['attendanceRate'] as double).toStringAsFixed(1)}% נוכחות',
                    const Color(0xFFef4444),
                    Icons.warning,
                  ),
                )
                .toList(),
        ],
      ),
    );
  }

  Widget _buildArtistItem(
    String name,
    String status,
    String details,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 2),
              Text(
                details,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _exportCommunityReport,
      backgroundColor: const Color(0xFF10b981),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.download),
      label: const Text('ייצא דוח קהילה'),
    );
  }

  // Helper methods
  void _updateDateRangeForPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'week':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'quarter':
        _startDate = now.subtract(const Duration(days: 90));
        _endDate = now;
        break;
      case 'year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
    }
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF10b981)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'custom';
      });
      _loadAnalyticsData();
    }
  }

  void _exportCommunityReport() async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('מייצא דוח קהילת האמנים...'),
            ],
          ),
          backgroundColor: Color(0xFF10b981),
          duration: Duration(seconds: 3),
        ),
      );

      final excelService = serviceLocator<ExcelExportService>();

      final result = await excelService.saveCommunityAnalyticsExcelToDevice(
        startDate: _startDate,
        endDate: _endDate,
        analyticsData: _analyticsData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: const Color(0xFF10b981),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'פתח תיקייה',
              textColor: Colors.white,
              onPressed: () {
                // Could open file manager here
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בייצוא דוח קהילה: $e'),
            backgroundColor: const Color(0xFFef4444),
            action: SnackBarAction(
              label: 'נסה שוב',
              textColor: Colors.white,
              onPressed: _exportCommunityReport,
            ),
          ),
        );
      }
    }
  }
}
