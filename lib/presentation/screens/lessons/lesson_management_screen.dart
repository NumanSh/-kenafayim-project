import 'package:flutter/material.dart';
import '../../../data/models/lesson.dart';

class LessonManagementScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonManagementScreen({Key? key, required this.lesson})
    : super(key: key);

  @override
  State<LessonManagementScreen> createState() => _LessonManagementScreenState();
}

class _LessonManagementScreenState extends State<LessonManagementScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      animationDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFf8fafc,
      ), // ✅ Light background like screenshot
      body: Column(
        children: [
          // ✅ ENHANCED BLUE HEADER (exactly like screenshot)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4285F4), Color(0xFF1976D2)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  25,
                ), // ✅ Better padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button and close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // ✅ ENHANCED Lesson title and icon
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.lesson.title,
                                style: const TextStyle(
                                  fontSize:
                                      28, // ✅ Slightly smaller for better fit
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // ✅ Additional lesson info
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${widget.lesson.durationMinutes} דקות • ${widget.lesson.registeredArtistIds.length} משתתפים',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ✅ ENHANCED Date and time with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDateTime(widget.lesson.date),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ ENHANCED TAB BAR
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController!,
              labelColor: const Color(0xFF4285F4),
              unselectedLabelColor: const Color(0xFF9E9E9E),
              indicatorColor: const Color(0xFF4285F4),
              indicatorWeight: 3,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'פרטים'),
                Tab(text: 'משתתפים'),
                Tab(text: 'פעולות'),
              ],
            ),
          ),

          // ✅ TAB CONTENT with better spacing
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: [
                _buildDetailsTab(),
                _buildParticipantsTab(),
                _buildActionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24), // ✅ Better padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Section header
          const Text(
            'פרטי השיעור',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 20),

          _buildDetailCard('שם השיעור', widget.lesson.title, Icons.title),
          const SizedBox(height: 16),
          _buildDetailCard(
            'תאריך ושעה',
            _formatDetailedDateTime(widget.lesson.date),
            Icons.schedule,
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            'משך השיעור',
            '${widget.lesson.durationMinutes} דקות',
            Icons.timer,
          ),
          const SizedBox(height: 16),
          if (widget.lesson.instructorName != null)
            _buildDetailCard(
              'מנחה',
              widget.lesson.instructorName!,
              Icons.person,
            ),
          const SizedBox(height: 16),
          _buildDetailCard(
            'סטטוס שיעור',
            _getStatusText(widget.lesson.status),
            Icons.info,
          ),
          const SizedBox(height: 16),
          if (widget.lesson.maxCapacity != null)
            _buildDetailCard(
              'קיבולת מקסימלית',
              '${widget.lesson.maxCapacity} משתתפים',
              Icons.groups,
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Enhanced header with stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'רשימת משתתפים',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.lesson.registeredArtistIds.length} משתתפים רשומים',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6b7280),
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ Add participant button
              ElevatedButton.icon(
                onPressed: () => _manageParticipants(),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('הוסף'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10b981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (widget.lesson.registeredArtistIds.isEmpty)
            // ✅ Enhanced empty state
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFe5e7eb)),
              ),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'אין משתתפים רשומים',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'לחץ על "הוסף" כדי להוסיף משתתפים לשיעור',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.lesson.registeredArtistIds.length,
              itemBuilder: (context, index) {
                final artistId = widget.lesson.registeredArtistIds[index];
                return _buildEnhancedParticipantCard(artistId, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Section header
          const Text(
            'פעולות זמינות',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'בחר פעולה לביצוע על השיעור',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
          ),
          const SizedBox(height: 24),

          // ✅ ENHANCED ACTION CARDS
          _buildEnhancedActionCard(
            'עריכת שיעור',
            'ערוך את פרטי השיעור, תאריך, שעה ומנחה',
            Icons.edit_outlined,
            const Color(0xFF4285F4),
            () => _editLesson(),
          ),
          const SizedBox(height: 16),
          _buildEnhancedActionCard(
            'ניהול משתתפים',
            'הוסף או הסר משתתפים מהשיעור',
            Icons.people_outline,
            const Color(0xFF10b981),
            () => _manageParticipants(),
          ),
          const SizedBox(height: 16),
          _buildEnhancedActionCard(
            'נוכחות',
            'סמן נוכחות ונהל רשימת הנוכחים',
            Icons.how_to_reg_outlined,
            const Color(0xFF8b5cf6),
            () => _manageAttendance(),
          ),
          const SizedBox(height: 16),
          _buildEnhancedActionCard(
            'שכפול שיעור',
            'צור שיעור חדש על בסיס השיעור הנוכחי',
            Icons.content_copy_outlined,
            const Color(0xFFf59e0b),
            () => _duplicateLesson(),
          ),
          const SizedBox(height: 24),
          // ✅ Danger zone
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFfef2f2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFfecaca)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'אזור מסוכן',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFdc2626),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'פעולות אלו אינן ניתנות לביטול',
                  style: TextStyle(fontSize: 14, color: Color(0xFF7f1d1d)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteLesson(),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('מחק שיעור'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFdc2626),
                      side: const BorderSide(color: Color(0xFFdc2626)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ENHANCED DETAIL CARD
  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe5e7eb)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF4285F4), size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6b7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF1f2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ENHANCED ACTION CARD
  Widget _buildEnhancedActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
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
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_forward_ios, color: color, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ENHANCED PARTICIPANT CARD
  Widget _buildEnhancedParticipantCard(String artistId, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe5e7eb)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF4285F4), const Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'משתתף ${artistId.length > 10 ? artistId.substring(0, 10) + '...' : artistId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $artistId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _viewParticipantDetails(artistId),
            icon: const Icon(Icons.more_vert, color: Color(0xFF6b7280)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFf8fafc),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} • ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatDetailedDateTime(DateTime dateTime) {
    final weekdays = ['ראשון', 'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת'];
    final months = [
      'ינואר',
      'פברואר',
      'מרץ',
      'אפריל',
      'מאי',
      'יוני',
      'יולי',
      'אוגוסט',
      'ספטמבר',
      'אוקטובר',
      'נובמבר',
      'דצמבר',
    ];

    return '${weekdays[dateTime.weekday - 1]}, ${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} בשעה ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'scheduled':
        return 'מתוכנן';
      case 'ongoing':
        return 'מתרחש כעת';
      case 'completed':
        return 'הושלם';
      case 'cancelled':
        return 'בוטל';
      default:
        return status;
    }
  }

  void _editLesson() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('עריכת שיעור - בפיתוח')));
  }

  void _manageParticipants() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ניהול משתתפים - בפיתוח')));
  }

  void _manageAttendance() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ניהול נוכחות - בפיתוח')));
  }

  void _duplicateLesson() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('שכפול שיעור - בפיתוח')));
  }

  void _viewParticipantDetails(String artistId) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('פרטי משתתף: $artistId')));
  }

  void _deleteLesson() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            const Text('מחיקת שיעור'),
          ],
        ),
        content: const Text(
          'האם אתה בטוח שברצונך למחוק את השיעור? פעולה זו אינה ניתנת לביטול.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('השיעור נמחק בהצלחה'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }
}
