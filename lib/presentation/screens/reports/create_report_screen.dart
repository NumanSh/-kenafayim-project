import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/report.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../services/report_generation_service.dart';
import '../../../config/service_locator.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  final User user;

  const CreateReportScreen({super.key, required this.user});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen>
    with TickerProviderStateMixin {
  final ReportRepository _reportRepository = serviceLocator<ReportRepository>();
  final ReportGenerationService _reportService =
      serviceLocator<ReportGenerationService>();

  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Report configuration
  ReportType _selectedType = ReportType.attendance;
  ReportPeriod _selectedPeriod = ReportPeriod.monthly;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedFormat = 'pdf';
  bool _includeCharts = true;
  bool _includeMedicalInfo = false;
  List<String> _selectedUserIds = [];
  List<String> _selectedStudioIds = [];

  // UI state
  bool _isLoading = false;
  bool _isGenerating = false;
  Map<String, dynamic> _previewData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPreviewData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviewData() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> data;
      switch (_selectedType) {
        case ReportType.attendance:
          data = await _reportRepository.generateWorkingHoursAnalytics(
            startDate: _startDate,
            endDate: _endDate,
          );
          break;

        case ReportType.userActivity:
          data = await _reportRepository.generateUserActivityAnalytics(
            startDate: _startDate,
            endDate: _endDate,
          );
          break;
        default:
          data = {};
      }

      if (mounted) {
        setState(() {
          _previewData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTemplateTab(),
                _buildConfigurationTab(),
                _buildFiltersTab(),
                _buildPreviewTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      title: const Text(
        'יצירת דוח חדש',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1f2937),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _saveAsDraft,
          icon: const Icon(Icons.save_outlined, color: Color(0xFF6b7280)),
          tooltip: 'שמור כטיוטה',
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
          Tab(icon: Icon(Icons.dashboard, size: 20), text: 'תבניות'),
          Tab(icon: Icon(Icons.settings, size: 20), text: 'הגדרות'),
          Tab(icon: Icon(Icons.filter_list, size: 20), text: 'מסננים'),
          Tab(icon: Icon(Icons.preview, size: 20), text: 'תצוגה מקדימה'),
        ],
      ),
    );
  }

  Widget _buildTemplateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'בחר תבנית דוח',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'תבניות מוכנות לסוגי דוחות נפוצים במרכז כנפיים',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildTemplateCard(
                title: 'דוח נוכחות אמנים',
                subtitle: 'מעקב השתתפות בשיעורים',
                icon: Icons.people,
                color: const Color(0xFF10b981),
                type: ReportType.attendance,
              ),

              _buildTemplateCard(
                title: 'שעות מנחים',
                subtitle: 'מעקב פרודוקטיביות',
                icon: Icons.access_time,
                color: const Color(0xFF8b5cf6),
                type: ReportType.workingHours,
              ),
              _buildTemplateCard(
                title: 'פעילות כללית',
                subtitle: 'סקירה מקיפה',
                icon: Icons.analytics,
                color: const Color(0xFFf59e0b),
                type: ReportType.userActivity,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required ReportType type,
  }) {
    final isSelected = _selectedType == type;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFe5e7eb),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedType = type;
              _titleController.text = title;
            });
            _loadPreviewData();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : const Color(0xFF1f2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6b7280),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'נבחר',
                      style: TextStyle(
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
    );
  }

  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('פרטי הדוח'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _titleController,
              label: 'כותרת הדוח',
              hint: 'הזן כותרת מתארת לדוח',
              icon: Icons.title,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'נא להזין כותרת לדוח';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'תיאור (אופציונלי)',
              hint: 'הוסף תיאור קצר למטרת הדוח',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('תקופת הדוח'),
            const SizedBox(height: 16),
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            _buildDateRangeSelector(),
            const SizedBox(height: 24),
            _buildSectionTitle('פורמט ואפשרויות'),
            const SizedBox(height: 16),
            _buildFormatSelector(),
            const SizedBox(height: 16),
            _buildOptionsSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1f2937),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
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
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF3b82f6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'תקופה מוגדרת מראש',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPeriodChip('שבוע אחרון', ReportPeriod.weekly),
              _buildPeriodChip('חודש אחרון', ReportPeriod.monthly),
              _buildPeriodChip('רבעון אחרון', ReportPeriod.quarterly),
              _buildPeriodChip('שנה אחרונה', ReportPeriod.yearly),
              _buildPeriodChip('תקופה מותאמת', ReportPeriod.custom),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, ReportPeriod period) {
    final isSelected = _selectedPeriod == period;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
          _updateDateRangeForPeriod(period);
        });
        _loadPreviewData();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3b82f6) : const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3b82f6)
                : const Color(0xFFe5e7eb),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6b7280),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // ✅ CORRECT - Fixed the typo
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'טווח תאריכים',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateSelector('מתאריך', _startDate, (date) {
                  setState(() => _startDate = date);
                  _loadPreviewData();
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateSelector('עד תאריך', _endDate, (date) {
                  setState(() => _endDate = date);
                  _loadPreviewData();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
            );
            if (selectedDate != null) {
              onChanged(selectedDate);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFe5e7eb)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF6b7280),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'פורמט הדוח',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFormatOption(
                  'PDF',
                  'מסמך מעוצב לצפייה והדפסה',
                  Icons.picture_as_pdf,
                  'pdf',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormatOption(
                  'Excel',
                  'גיליון אלקטרוני לניתוח נתונים',
                  Icons.table_chart,
                  'excel',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(
    String title,
    String subtitle,
    IconData icon,
    String format,
  ) {
    final isSelected = _selectedFormat == format;

    return InkWell(
      onTap: () => setState(() => _selectedFormat = format),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3b82f6).withOpacity(0.1)
              : const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3b82f6)
                : const Color(0xFFe5e7eb),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF3b82f6)
                  : const Color(0xFF6b7280),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF3b82f6)
                    : const Color(0xFF1f2937),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6b7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'אפשרויות נוספות',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('כלול תרשימים'),
            subtitle: const Text('הוסף גרפים ותרשימים לדוח'),
            value: _includeCharts,
            onChanged: (value) => setState(() => _includeCharts = value),
            activeColor: const Color(0xFF3b82f6),
          ),
          if (widget.user.isStaff) ...[
            SwitchListTile(
              title: const Text('כלול מידע רפואי'),
              subtitle: const Text('הוסף מידע רפואי רלוונטי (צוות בלבד)'),
              value: _includeMedicalInfo,
              onChanged: (value) => setState(() => _includeMedicalInfo = value),
              activeColor: const Color(0xFF3b82f6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'מסננים מתקדמים',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'סנן את הנתונים לפי קריטריונים ספציפיים',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
          ),
          const SizedBox(height: 24),
          _buildUserFilter(),
          const SizedBox(height: 16),
          _buildStudioFilter(),
        ],
      ),
    );
  }

  Widget _buildUserFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Color(0xFF3b82f6), size: 20),
              const SizedBox(width: 8),
              const Text(
                'סינון לפי משתמשים',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'בחר משתמשים ספציפיים לכלול בדוח (השאר ריק לכלול הכל)',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
          ),
          const SizedBox(height: 16),
          // User selection would go here - simplified for now
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFe5e7eb)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF6b7280), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'בחירת משתמשים ספציפיים תהיה זמינה בקרוב',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.meeting_room,
                color: Color(0xFF8b5cf6),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'סינון לפי סטודיואים',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'בחר סטודיואים ספציפיים לכלול בדוח',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  'פלסטיקה',
                  'תיאטרון',
                  'כתיבה',
                  'מוזיקה',
                  'אנימציה',
                  'וידאו',
                ].map((studio) {
                  final isSelected = _selectedStudioIds.contains(studio);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedStudioIds.remove(studio);
                        } else {
                          _selectedStudioIds.add(studio);
                        }
                      });
                      _loadPreviewData();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8b5cf6)
                            : const Color(0xFFf8fafc),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF8b5cf6)
                              : const Color(0xFFe5e7eb),
                        ),
                      ),
                      child: Text(
                        studio,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6b7280),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
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
              'טוען תצוגה מקדימה...',
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
          _buildPreviewHeader(),
          const SizedBox(height: 24),
          _buildPreviewSummary(),
          const SizedBox(height: 24),
          _buildPreviewChart(),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3b82f6).withOpacity(0.3),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.preview, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'תצוגה מקדימה',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _titleController.text.isNotEmpty
                ? _titleController.text
                : 'דוח ${_getReportTypeDisplayName(_selectedType)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'תקופה: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'סיכום נתונים',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryMetrics(),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics() {
    switch (_selectedType) {
      case ReportType.attendance:
      case ReportType.workingHours:
        return _buildWorkingHoursSummary();

      case ReportType.userActivity:
        return _buildUserActivitySummary();
      default:
        return const Text('נתוני תצוגה מקדימה יהיו זמינים בקרוב');
    }
  }

  Widget _buildWorkingHoursSummary() {
    final totalHours = _previewData['totalHours']?.toDouble() ?? 0;
    final totalEntries = _previewData['totalEntries']?.toInt() ?? 0;
    final approvalRate = _previewData['approvalRate']?.toDouble() ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'סה"כ שעות',
                '${totalHours.toStringAsFixed(1)}',
                Icons.access_time,
                const Color(0xFF10b981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'רשומות',
                '$totalEntries',
                Icons.list,
                const Color(0xFF3b82f6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'אחוז אישור',
                '${approvalRate.toStringAsFixed(1)}%',
                Icons.check_circle,
                const Color(0xFFf59e0b),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'ממוצע',
                '${totalEntries > 0 ? (totalHours / totalEntries).toStringAsFixed(1) : "0"}',
                Icons.trending_up,
                const Color(0xFF8b5cf6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserActivitySummary() {
    final totalUsers = _previewData['totalUsers']?.toInt() ?? 0;
    final activeUsers = _previewData['activeUsers']?.toInt() ?? 0;
    final averageActivity =
        _previewData['averageActivityPerUser']?.toDouble() ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'משתמשים',
                '$totalUsers',
                Icons.people,
                const Color(0xFF8b5cf6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'פעילים',
                '$activeUsers',
                Icons.people_alt,
                const Color(0xFF10b981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'אחוז פעילות',
                '${totalUsers > 0 ? ((activeUsers / totalUsers) * 100).toStringAsFixed(1) : "0"}%',
                Icons.trending_up,
                const Color(0xFF3b82f6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'ממוצע',
                '${averageActivity.toStringAsFixed(1)}',
                Icons.analytics,
                const Color(0xFFf59e0b),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'תרשים לדוגמה',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFe5e7eb)),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 48, color: Color(0xFF6b7280)),
                  SizedBox(height: 8),
                  Text(
                    'תרשים יוצג כאן בדוח הסופי',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6b7280),
                side: const BorderSide(color: Color(0xFFe5e7eb)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ביטול',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3b82f6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'יצירת דוח ${_selectedFormat.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  // Helper methods
  void _updateDateRangeForPeriod(ReportPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.weekly:
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case ReportPeriod.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case ReportPeriod.quarterly:
        _startDate = now.subtract(const Duration(days: 90));
        _endDate = now;
        break;
      case ReportPeriod.yearly:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
      case ReportPeriod.custom:
        // Keep current dates for custom selection
        break;
      default:
        break;
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
      default:
        return 'כללי';
    }
  }

  Future<void> _generateReport() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(1); // Go to configuration tab
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Generate the report using the service
      final reportFile = await _reportService.generateAttendanceReport(
        title: _titleController.text,
        startDate: _startDate,
        endDate: _endDate,
        includeMedicalFlags: _includeMedicalInfo,
        format: _selectedFormat,
      );

      // Create report record
      final report = Report(
        id: '',
        title: _titleController.text,
        content: _descriptionController.text,
        createdById: widget.user.id,
        createdByName: widget.user.name,
        createdAt: DateTime.now(),
        type: _selectedType,
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
        data: _previewData,
        filters: {
          'format': _selectedFormat,
          'includeCharts': _includeCharts,
          'includeMedicalInfo': _includeMedicalInfo,
          'selectedUserIds': _selectedUserIds,
          'selectedStudioIds': _selectedStudioIds,
        },
      );

      await _reportRepository.createReport(report);

      if (mounted) {
        setState(() => _isGenerating = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('הדוח נוצר בהצלחה! (${reportFile.path.split('/').last})'),
              ],
            ),
            backgroundColor: const Color(0xFF10b981),
            action: SnackBarAction(
              label: 'פתח',
              textColor: Colors.white,
              onPressed: () {
                // Open the generated file
              },
            ),
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה ביצירת הדוח: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    }
  }

  void _saveAsDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('שמירה כטיוטה תהיה זמינה בקרוב'),
        backgroundColor: Color(0xFF6b7280),
      ),
    );
  }
}
