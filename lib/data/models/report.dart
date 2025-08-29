enum ReportType {
  all,
  meeting,
  progress,
  event,
  other,
  // ANALYTICS TYPES (REMOVED bookingAnalytics and roomUtilization)
  workingHours,
  userActivity,
  financial,
  attendance,
}

enum ReportPeriod { daily, weekly, monthly, quarterly, yearly, custom }

class Report {
  final String id;
  final String title;
  final String content;
  final String createdById;
  final String createdByName;
  final DateTime createdAt;
  final ReportType type;
  final ReportPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> relatedUserIds;
  final Map<String, dynamic> data; // NEW: Store analytics data
  final Map<String, dynamic> filters; // NEW: Store applied filters

  Report({
    required this.id,
    required this.title,
    required this.content,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    required this.type,
    this.period = ReportPeriod.monthly,
    this.startDate,
    this.endDate,
    this.relatedUserIds = const [],
    this.data = const {},
    this.filters = const {},
  });

  // Get report type display name in Hebrew
  String getTypeDisplayName() {
    switch (type) {
      case ReportType.meeting:
        return 'פגישות';
      case ReportType.progress:
        return 'התקדמות';
      case ReportType.event:
        return 'אירועים';
      case ReportType.workingHours:
        return 'שעות עבודה';

      case ReportType.userActivity:
        return 'פעילות משתמשים';
      case ReportType.financial:
        return 'דוח כספי';
      case ReportType.attendance:
        return 'נוכחות';
      case ReportType.other:
        return 'אחר';
      default:
        return 'הכל';
    }
  }

  // Get report period display name in Hebrew
  String getPeriodDisplayName() {
    switch (period) {
      case ReportPeriod.daily:
        return 'יומי';
      case ReportPeriod.weekly:
        return 'שבועי';
      case ReportPeriod.monthly:
        return 'חודשי';
      case ReportPeriod.quarterly:
        return 'רבעוני';
      case ReportPeriod.yearly:
        return 'שנתי';
      case ReportPeriod.custom:
        return 'מותאם אישית';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdById': createdById,
      'createdByName': createdByName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'type': type.toString().split('.').last,
      'period': period.toString().split('.').last,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'relatedUserIds': relatedUserIds,
      'data': data,
      'filters': filters,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdById: map['createdById'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      type: _typeFromString(map['type'] ?? 'other'),
      period: _periodFromString(map['period'] ?? 'monthly'),
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'])
          : null,
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
          : null,
      relatedUserIds: List<String>.from(map['relatedUserIds'] ?? []),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      filters: Map<String, dynamic>.from(map['filters'] ?? {}),
    );
  }

  static ReportType _typeFromString(String typeStr) {
    switch (typeStr) {
      case 'meeting':
        return ReportType.meeting;
      case 'progress':
        return ReportType.progress;
      case 'event':
        return ReportType.event;
      case 'workingHours':
        return ReportType.workingHours;

      case 'userActivity':
        return ReportType.userActivity;
      case 'financial':
        return ReportType.financial;
      case 'attendance':
        return ReportType.attendance;
      case 'other':
        return ReportType.other;
      case 'all':
        return ReportType.all;
      default:
        return ReportType.other;
    }
  }

  static ReportPeriod _periodFromString(String periodStr) {
    switch (periodStr) {
      case 'daily':
        return ReportPeriod.daily;
      case 'weekly':
        return ReportPeriod.weekly;
      case 'monthly':
        return ReportPeriod.monthly;
      case 'quarterly':
        return ReportPeriod.quarterly;
      case 'yearly':
        return ReportPeriod.yearly;
      case 'custom':
        return ReportPeriod.custom;
      default:
        return ReportPeriod.monthly;
    }
  }
}
