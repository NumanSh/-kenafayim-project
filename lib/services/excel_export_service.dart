import 'dart:io';
import 'dart:math' as math;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../data/models/lesson.dart';
import '../data/models/user.dart';
import '../data/models/attendance_record.dart';
import '../data/repositories/lesson_repository.dart';
import '../data/repositories/user_repository.dart';
import '../config/service_locator.dart';

class ExcelExportService {
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
  final UserRepository _userRepository = serviceLocator<UserRepository>();

  // ✅ CONSOLIDATED: One method for all Excel exports
  Future<String> saveReportExcelToDevice({
    required String reportType, // 'attendance', 'working_hours', 'full_report'
    DateTime? startDate,
    DateTime? endDate,
    List<String>? specificStudentIds,
    List<String>? specificInstructorIds,
  }) async {
    try {
      // Request permissions only if needed
      await _requestStoragePermissions();

      // Generate Excel based on report type
      final excel = await _generateExcelByType(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
        specificStudentIds: specificStudentIds,
        specificInstructorIds: specificInstructorIds,
      );

      // Get file bytes
      final bytes = excel.save();
      if (bytes == null) throw Exception('Failed to generate Excel bytes');

      // Create filename with report type
      final fileName =
          '${reportType}_report_${DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now())}.xlsx';

      // Save to device
      final filePath = await _saveToDevice(fileName, bytes);

      return 'הקובץ נשמר ב: $filePath';
    } catch (e) {
      throw Exception('Failed to save Excel file: $e');
    }
  }

  // ✅ CONSOLIDATED: One Excel generation method
  Future<Excel> _generateExcelByType({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? specificStudentIds,
    List<String>? specificInstructorIds,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    // Get common data
    final lessons = await _lessonRepository.getAllLessons(
      startDate: startDate,
      endDate: endDate,
    );

    final allUsers = await _userRepository.getAllUsers();
    final students = allUsers.where((u) => u.role == UserRole.client).toList();
    final instructors = allUsers
        .where((u) => u.role == UserRole.mentor)
        .toList();

    // Filter data based on parameters
    final targetStudents = specificStudentIds != null
        ? students.where((s) => specificStudentIds.contains(s.id)).toList()
        : students;

    final targetInstructors = specificInstructorIds != null
        ? instructors
              .where((i) => specificInstructorIds.contains(i.id))
              .toList()
        : instructors;

    final targetLessons = specificInstructorIds != null
        ? lessons
              .where(
                (l) => specificInstructorIds.contains(l.assignedInstructorId),
              )
              .toList()
        : lessons;

    // Generate sheets based on report type
    switch (reportType) {
      case 'attendance':
        await _createSheet(
          excel,
          'attendance_summary',
          targetStudents,
          targetLessons,
          targetInstructors,
        );
        await _createSheet(
          excel,
          'attendance_detailed',
          targetStudents,
          targetLessons,
          targetInstructors,
        );
        await _createSheet(
          excel,
          'student_stats',
          targetStudents,
          targetLessons,
          targetInstructors,
        );
        break;

      case 'working_hours':
        await _createSheet(
          excel,
          'working_hours_summary',
          targetInstructors,
          targetLessons,
          targetStudents,
        );
        await _createSheet(
          excel,
          'working_hours_detailed',
          targetInstructors,
          targetLessons,
          targetStudents,
        );
        await _createSheet(
          excel,
          'instructor_stats',
          targetInstructors,
          targetLessons,
          targetStudents,
        );
        break;

      case 'full_report':
        await _createSheet(
          excel,
          'attendance_summary',
          targetStudents,
          targetLessons,
          targetInstructors,
        );
        await _createSheet(
          excel,
          'working_hours_summary',
          targetInstructors,
          targetLessons,
          targetStudents,
        );
        await _createSheet(
          excel,
          'lesson_stats',
          targetLessons,
          targetInstructors,
          targetStudents,
        );
        break;
    }

    return excel;
  }

  // ✅ CONSOLIDATED: One sheet creation method
  Future<void> _createSheet(
    Excel excel,
    String sheetType,
    List<dynamic> primaryData,
    List<dynamic> secondaryData,
    List<dynamic> tertiaryData,
  ) async {
    switch (sheetType) {
      case 'attendance_summary':
        await _createAttendanceSummarySheet(
          excel,
          primaryData as List<User>,
          secondaryData as List<Lesson>,
        );
        break;
      case 'attendance_detailed':
        await _createDetailedAttendanceSheet(
          excel,
          primaryData as List<User>,
          secondaryData as List<Lesson>,
          tertiaryData as List<User>,
        );
        break;
      case 'student_stats':
        await _createStudentStatisticsSheet(
          excel,
          primaryData as List<User>,
          secondaryData as List<Lesson>,
        );
        break;
      case 'working_hours_summary':
        await _createWorkingHoursSummarySheet(
          excel,
          primaryData as List<User>,
          secondaryData as List<Lesson>,
        );
        break;
      case 'working_hours_detailed':
        await _createDetailedWorkingHoursSheet(
          excel,
          primaryData as List<User>,
          secondaryData as List<Lesson>,
        );
        break;
      case 'instructor_stats':
        await _createInstructorStatisticsSheet(
          excel,
          primaryData as List<User>,
          secondaryData as List<Lesson>,
        );
        break;
      case 'lesson_stats':
        await _createLessonStatisticsSheet(
          excel,
          primaryData as List<Lesson>,
          secondaryData as List<User>,
        );
        break;
    }
  }

  // ✅ CONSOLIDATED: One file saving method
  Future<String> _saveToDevice(String fileName, List<int> bytes) async {
    String filePath;

    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        filePath = '${directory.path}/$fileName';
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        filePath = '${appDir.path}/$fileName';
      }
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      filePath = '${directory.path}/$fileName';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      filePath = '${directory.path}/$fileName';
    }

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  // ✅ SIMPLIFIED: Permission handling
  Future<void> _requestStoragePermissions() async {
    if (Platform.isAndroid) {
      final plugin = DeviceInfoPlugin();
      final android = await plugin.androidInfo;

      if (android.version.sdkInt >= 33) {
        return; // No permission needed for Android 13+
      }

      if (android.version.sdkInt >= 30) {
        await Permission.manageExternalStorage.request();
      } else {
        await Permission.storage.request();
      }
    }
  }

  // Keep only essential sheet creation methods (simplified versions)
  Future<void> _createAttendanceSummarySheet(
    Excel excel,
    List<User> students,
    List<Lesson> lessons,
  ) async {
    final sheet = excel['סיכום נוכחות'];
    final headers = [
      'שם הסטודנט',
      'מספר זהות',
      'סה"כ שיעורים',
      'נוכח',
      'נעדר',
      'איחור',
      'אחוז נוכחות',
    ];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
      );
    }

    // Add data
    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      final stats = _calculateStudentStats(student, lessons);
      final rowData = [
        student.name,
        student.id,
        stats['totalLessons'].toString(),
        stats['present'].toString(),
        stats['absent'].toString(),
        stats['late'].toString(),
        '${stats['attendanceRate'].toStringAsFixed(1)}%',
      ];

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1),
        );
        cell.value = TextCellValue(rowData[col]);
      }
    }
  }

  Future<void> _createDetailedAttendanceSheet(
    Excel excel,
    List<User> students,
    List<Lesson> lessons,
    List<User> instructors,
  ) async {
    final sheet = excel['פירוט נוכחות'];
    lessons.sort((a, b) => a.date.compareTo(b.date));

    final headers = [
      'תאריך',
      'שם השיעור',
      'מנחה',
      'שם הסטודנט',
      'סטטוס נוכחות',
      'הערות',
    ];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
      );
    }

    int currentRow = 1;
    for (final lesson in lessons) {
      final instructor = instructors
          .where((i) => i.id == lesson.assignedInstructorId)
          .firstOrNull;

      for (final record in lesson.attendanceRecords) {
        final student = students
            .where((s) => s.id == record.artistId)
            .firstOrNull;
        if (student != null) {
          final rowData = [
            DateFormat('dd/MM/yyyy').format(lesson.date),
            lesson.title,
            instructor?.name ?? lesson.instructorName ?? 'לא ידוע',
            student.name,
            _getAttendanceStatusInHebrew(record.status),
            record.notes ?? '',
          ];

          for (int col = 0; col < rowData.length; col++) {
            final cell = sheet.cell(
              CellIndex.indexByColumnRow(
                columnIndex: col,
                rowIndex: currentRow,
              ),
            );
            cell.value = TextCellValue(rowData[col]);
          }
          currentRow++;
        }
      }
    }
  }

  Future<void> _createWorkingHoursSummarySheet(
    Excel excel,
    List<User> instructors,
    List<Lesson> lessons,
  ) async {
    final sheet = excel['סיכום שעות מנחים'];
    final headers = [
      'שם המנחה',
      'מספר זהות',
      'סה"כ שיעורים',
      'סה"כ שעות',
      'ממוצע שעות לשיעור',
      'סטטוס פעילות',
    ];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
      );
    }

    // Add data
    for (int i = 0; i < instructors.length; i++) {
      final instructor = instructors[i];
      final stats = _calculateInstructorStats(instructor, lessons);
      final rowData = [
        instructor.name,
        instructor.id,
        stats['totalLessons'].toString(),
        '${stats['totalHours'].toStringAsFixed(1)}',
        '${stats['averageHours'].toStringAsFixed(1)}',
        stats['status'],
      ];

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1),
        );
        cell.value = TextCellValue(rowData[col]);
      }
    }
  }

  Future<void> _createDetailedWorkingHoursSheet(
    Excel excel,
    List<User> instructors,
    List<Lesson> lessons,
  ) async {
    final sheet = excel['פירוט שעות עבודה'];
    lessons.sort((a, b) => a.date.compareTo(b.date));

    final headers = [
      'תאריך',
      'שם השיעור',
      'שם המנחה',
      'משך השיעור (שעות)',
      'סוג שיעור',
      'מספר משתתפים',
    ];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
      );
    }

    int currentRow = 1;
    for (final lesson in lessons) {
      final instructor = instructors
          .where((i) => i.id == lesson.assignedInstructorId)
          .firstOrNull;
      if (instructor != null) {
        final rowData = [
          DateFormat('dd/MM/yyyy').format(lesson.date),
          lesson.title,
          instructor.name,
          (lesson.durationMinutes / 60.0).toStringAsFixed(2),
          lesson.isRecurring ? 'שיעור חוזר' : 'שיעור יחיד',
          lesson.registeredArtistIds.length.toString(),
        ];

        for (int col = 0; col < rowData.length; col++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: currentRow),
          );
          cell.value = TextCellValue(rowData[col]);
        }
        currentRow++;
      }
    }
  }

  // Simplified placeholder methods for other sheet types
  Future<void> _createStudentStatisticsSheet(
    Excel excel,
    List<User> students,
    List<Lesson> lessons,
  ) async {
    final sheet = excel['סטטיסטיקות סטודנטים'];
    // Simplified implementation
  }

  Future<void> _createInstructorStatisticsSheet(
    Excel excel,
    List<User> instructors,
    List<Lesson> lessons,
  ) async {
    final sheet = excel['סטטיסטיקות מנחים'];
    // Simplified implementation
  }

  Future<void> _createLessonStatisticsSheet(
    Excel excel,
    List<Lesson> lessons,
    List<User> instructors,
  ) async {
    final sheet = excel['סטטיסטיקות שיעורים'];
    // Simplified implementation
  }

  // ✅ CONSOLIDATED: Simplified calculation methods
  Map<String, dynamic> _calculateStudentStats(
    User student,
    List<Lesson> lessons,
  ) {
    int totalLessons = 0, present = 0, absent = 0, late = 0;

    for (final lesson in lessons) {
      final record = lesson.attendanceRecords
          .where((r) => r.artistId == student.id)
          .firstOrNull;
      if (record != null) {
        totalLessons++;
        switch (record.status) {
          case 'present':
            present++;
            break;
          case 'absent':
            absent++;
            break;
          case 'late':
            late++;
            break;
        }
      }
    }

    return {
      'totalLessons': totalLessons,
      'present': present,
      'absent': absent,
      'late': late,
      'attendanceRate': totalLessons > 0
          ? ((present + late) / totalLessons) * 100
          : 0.0,
    };
  }

  Map<String, dynamic> _calculateInstructorStats(
    User instructor,
    List<Lesson> lessons,
  ) {
    final instructorLessons = lessons
        .where((l) => l.assignedInstructorId == instructor.id)
        .toList();
    final totalHours = instructorLessons.fold(
      0.0,
      (sum, lesson) => sum + (lesson.durationMinutes / 60.0),
    );

    return {
      'totalLessons': instructorLessons.length,
      'totalHours': totalHours,
      'averageHours': instructorLessons.isNotEmpty
          ? totalHours / instructorLessons.length
          : 0.0,
      'status': totalHours >= 40
          ? 'פעיל'
          : totalHours >= 20
          ? 'בינוני'
          : 'לא פעיל',
    };
  }

  String _getAttendanceStatusInHebrew(String status) {
    switch (status) {
      case 'present':
        return 'נוכח';
      case 'absent':
        return 'נעדר';
      case 'late':
        return 'איחור';
      case 'excused':
        return 'מוצדק';
      default:
        return status;
    }
  }

  // ✅ LEGACY: Keep for backward compatibility
  @Deprecated('Use saveReportExcelToDevice instead')
  Future<String> saveAttendanceExcelToDevice({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? specificStudentIds,
    List<String>? specificInstructorIds,
  }) async {
    return saveReportExcelToDevice(
      reportType: 'attendance',
      startDate: startDate,
      endDate: endDate,
      specificStudentIds: specificStudentIds,
      specificInstructorIds: specificInstructorIds,
    );
  }

  @Deprecated('Use saveReportExcelToDevice instead')
  Future<String> saveWorkingHoursExcelToDevice({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? specificInstructorIds,
  }) async {
    return saveReportExcelToDevice(
      reportType: 'working_hours',
      startDate: startDate,
      endDate: endDate,
      specificInstructorIds: specificInstructorIds,
    );
  }

  // ✅ NEW: Export community analytics data as Excel
  Future<String> saveCommunityAnalyticsExcelToDevice({
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? analyticsData,
  }) async {
    try {
      // Generate Excel file
      final excel = await _generateCommunityAnalyticsExcel(
        startDate: startDate,
        endDate: endDate,
        analyticsData: analyticsData,
      );

      // Get file bytes
      final bytes = excel.save();
      if (bytes == null) throw Exception('Failed to generate Excel bytes');

      // Create filename
      final fileName =
          'community_analytics_${DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now())}.xlsx';

      // Save to device
      final filePath = await _saveToDevice(fileName, bytes);

      return 'דוח קהילת האמנים נשמר ב: $filePath';
    } catch (e) {
      throw Exception('Failed to save community analytics Excel file: $e');
    }
  }

  // Generate Excel file with community analytics data
  Future<Excel> _generateCommunityAnalyticsExcel({
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? analyticsData,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    // Get all lessons and users in date range
    final lessons = await _lessonRepository.getAllLessons(
      startDate: startDate,
      endDate: endDate,
    );

    final allUsers = await _userRepository.getAllUsers();
    final artists = allUsers.where((u) => u.role == UserRole.client).toList();
    final instructors = allUsers
        .where((u) => u.role == UserRole.mentor)
        .toList();

    // Create multiple sheets for comprehensive analytics
    await _createCommunityOverviewSheet(excel, analyticsData, lessons, artists);
    await _createIndividualArtistSheet(excel, artists, lessons);
    await _createStudioParticipationSheet(excel, analyticsData, lessons);
    await _createWeeklyPatternsSheet(excel, analyticsData, lessons);
    await _createTopPerformersSheet(excel, analyticsData, artists, lessons);

    return excel;
  }

  // Create community overview sheet
  Future<void> _createCommunityOverviewSheet(
    Excel excel,
    Map<String, dynamic>? analyticsData,
    List<Lesson> lessons,
    List<User> artists,
  ) async {
    final sheet = excel['סיכום קהילת האמנים'];

    // Headers
    final headers = ['מדד', 'ערך', 'תיאור', 'תקופה'];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Get analytics data
    final aggregateStats = analyticsData?['aggregateStats'] ?? {};

    // Add overview data
    final overviewData = [
      [
        'אמנים רשומים',
        '${aggregateStats['totalRegistered'] ?? artists.length}',
        'סה"כ אמנים רשומים במערכת',
        'כללי',
      ],
      [
        'אמנים פעילים',
        '${aggregateStats['activeThisMonth'] ?? 0}',
        'אמנים שהשתתפו בתקופה הנבחרת',
        'תקופה נבחרת',
      ],
      [
        'אחוז נוכחות ממוצע',
        '${(aggregateStats['averageAttendanceRate'] ?? 0.0).toStringAsFixed(1)}%',
        'ממוצע נוכחות של כל האמנים',
        'תקופה נבחרת',
      ],
      [
        'שיעורים נערכו',
        '${aggregateStats['totalLessonsHeld'] ?? lessons.length}',
        'סה"כ שיעורים שנערכו',
        'תקופה נבחרת',
      ],
      [
        'ממוצע משתתפים לשיעור',
        '${_calculateAverageParticipants(lessons).toStringAsFixed(1)}',
        'ממוצע אמנים לשיעור',
        'תקופה נבחרת',
      ],
    ];

    for (int i = 0; i < overviewData.length; i++) {
      final rowData = overviewData[i];
      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1),
        );
        cell.value = TextCellValue(rowData[col]);

        // Color code based on metric type
        if (col == 1) {
          // Value column
          if (i == 2) {
            // Attendance rate
            final rate = double.tryParse(rowData[col].replaceAll('%', '')) ?? 0;
            if (rate >= 90) {
              cell.cellStyle = CellStyle(
                backgroundColorHex: ExcelColor.green100,
              );
            } else if (rate >= 75) {
              cell.cellStyle = CellStyle(
                backgroundColorHex: ExcelColor.yellow100,
              );
            } else {
              cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.red100);
            }
          }
        }
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }
  }

  // Create individual artist attendance sheet
  Future<void> _createIndividualArtistSheet(
    Excel excel,
    List<User> artists,
    List<Lesson> lessons,
  ) async {
    final sheet = excel['נוכחות אמנים פרטנית'];

    // Headers
    final headers = [
      'שם האמן',
      'מספר זהות',
      'סה"כ שיעורים זמינים',
      'השתתף בשיעורים',
      'נוכח',
      'איחור',
      'נעדר',
      'מוצדק',
      'אחוז נוכחות',
      'אחוז איחורים',
      'שיעור אחרון',
      'סטטוס פעילות',
    ];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add artist data
    for (int artistIndex = 0; artistIndex < artists.length; artistIndex++) {
      final artist = artists[artistIndex];
      final row = artistIndex + 1;

      // Calculate detailed stats for each artist
      final stats = _calculateDetailedArtistStats(artist, lessons);

      final rowData = [
        artist.name,
        artist.id,
        stats['availableLessons'].toString(),
        stats['attendedLessons'].toString(),
        stats['present'].toString(),
        stats['late'].toString(),
        stats['absent'].toString(),
        stats['excused'].toString(),
        '${stats['attendanceRate'].toStringAsFixed(1)}%',
        '${stats['lateRate'].toStringAsFixed(1)}%',
        stats['lastLessonDate'] ?? 'אין נתונים',
        stats['activityStatus'],
      ];

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = TextCellValue(rowData[col]);

        // Color code attendance rate
        if (col == 8) {
          // Attendance rate column
          final rate = stats['attendanceRate'] as double;
          if (rate >= 90) {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.green100);
          } else if (rate >= 75) {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.yellow100,
            );
          } else if (rate >= 50) {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.orange100,
            );
          } else {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.red100);
          }
        }

        // Color code activity status
        if (col == 11) {
          // Activity status column
          final status = stats['activityStatus'] as String;
          if (status == 'פעיל מאוד') {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.green100);
          } else if (status == 'פעיל') {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.blue100);
          } else if (status == 'בינוני') {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.yellow100,
            );
          } else {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.red100);
          }
        }
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }
  }

  // Create studio participation sheet
  Future<void> _createStudioParticipationSheet(
    Excel excel,
    Map<String, dynamic>? analyticsData,
    List<Lesson> lessons,
  ) async {
    final sheet = excel['התפלגות סטודיואים'];

    // Headers
    final headers = [
      'סטודיו',
      'מספר שיעורים',
      'אחוז מכלל השיעורים',
      'סה"כ משתתפים',
      'ממוצע משתתפים לשיעור',
      'אחוז נוכחות ממוצע',
    ];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Get studio data from analytics or calculate from lessons
    final studioData = analyticsData?['studioParticipation'] as List? ?? [];
    final studioStats = _calculateStudioStats(lessons);

    // Combine analytics data with calculated stats
    final combinedData = <Map<String, dynamic>>[];

    if (studioData.isNotEmpty) {
      for (final studio in studioData) {
        final studioName = studio['name'] as String;
        final calculatedStats = studioStats[studioName] ?? {};

        combinedData.add({
          'name': studioName,
          'percentage': studio['value'] ?? 0,
          'lessonCount': calculatedStats['lessonCount'] ?? 0,
          'totalParticipants': calculatedStats['totalParticipants'] ?? 0,
          'averageParticipants': calculatedStats['averageParticipants'] ?? 0.0,
          'averageAttendance': calculatedStats['averageAttendance'] ?? 0.0,
        });
      }
    } else {
      // Use calculated stats if no analytics data
      studioStats.forEach((studioName, stats) {
        combinedData.add({
          'name': studioName,
          'percentage': (stats['lessonCount'] / lessons.length * 100),
          'lessonCount': stats['lessonCount'],
          'totalParticipants': stats['totalParticipants'],
          'averageParticipants': stats['averageParticipants'],
          'averageAttendance': stats['averageAttendance'],
        });
      });
    }

    // Add studio data
    for (int i = 0; i < combinedData.length; i++) {
      final studio = combinedData[i];
      final row = i + 1;

      final rowData = [
        studio['name'],
        studio['lessonCount'].toString(),
        '${studio['percentage'].toStringAsFixed(1)}%',
        studio['totalParticipants'].toString(),
        studio['averageParticipants'].toStringAsFixed(1),
        '${studio['averageAttendance'].toStringAsFixed(1)}%',
      ];

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = TextCellValue(rowData[col]);
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 18);
    }
  }

  // Create weekly patterns sheet
  Future<void> _createWeeklyPatternsSheet(
    Excel excel,
    Map<String, dynamic>? analyticsData,
    List<Lesson> lessons,
  ) async {
    final sheet = excel['דפוסים שבועיים'];

    // Headers
    final headers = [
      'יום בשבוע',
      'מספר שיעורים',
      'ממוצע משתתפים',
      'אחוז נוכחות',
      'שעות פעילות פופולריות',
    ];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Calculate weekly patterns
    final weeklyPatterns = _calculateWeeklyPatterns(lessons);
    final daysOfWeek = [
      'ראשון',
      'שני',
      'שלישי',
      'רביעי',
      'חמישי',
      'שישי',
      'שבת',
    ];

    for (int i = 0; i < daysOfWeek.length; i++) {
      final day = daysOfWeek[i];
      final dayData = weeklyPatterns[day] ?? {};
      final row = i + 1;

      final rowData = [
        day,
        (dayData['lessonCount'] ?? 0).toString(),
        (dayData['averageParticipants'] ?? 0.0).toStringAsFixed(1),
        '${(dayData['attendanceRate'] ?? 0.0).toStringAsFixed(1)}%',
        dayData['popularHours'] ?? 'אין נתונים',
      ];

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = TextCellValue(rowData[col]);
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 18);
    }
  }

  // Create top performers sheet
  Future<void> _createTopPerformersSheet(
    Excel excel,
    Map<String, dynamic>? analyticsData,
    List<User> artists,
    List<Lesson> lessons,
  ) async {
    final sheet = excel['אמנים מצטיינים'];

    // Headers
    final headers = [
      'דירוג',
      'שם האמן',
      'אחוז נוכחות',
      'רצף נוכחות נוכחי',
      'רצף נוכחות הכי ארוך',
      'סה"כ שיעורים',
      'הישג מיוחד',
    ];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.yellow400,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Calculate top performers
    final topPerformers = _calculateTopPerformers(artists, lessons);

    for (int i = 0; i < topPerformers.length && i < 20; i++) {
      // Top 20
      final performer = topPerformers[i];
      final row = i + 1;

      final rowData = [
        '${i + 1}',
        performer['name'],
        '${performer['attendanceRate'].toStringAsFixed(1)}%',
        performer['currentStreak'].toString(),
        performer['longestStreak'].toString(),
        performer['totalLessons'].toString(),
        performer['achievement'],
      ];

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = TextCellValue(rowData[col]);

        // Gold, silver, bronze for top 3
        if (col == 0) {
          if (i == 0) {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.yellow400,
            );
          } else if (i == 1) {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.grey);
          } else if (i == 2) {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.orange100,
            );
          }
        }
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 16);
    }
  }

  // Helper calculation methods
  Map<String, dynamic> _calculateDetailedArtistStats(
    User artist,
    List<Lesson> lessons,
  ) {
    int availableLessons = 0;
    int attendedLessons = 0;
    int present = 0;
    int absent = 0;
    int late = 0;
    int excused = 0;
    DateTime? lastLessonDate;

    for (final lesson in lessons) {
      // Check if artist was registered for this lesson
      if (lesson.registeredArtistIds.contains(artist.id)) {
        availableLessons++;

        // Find attendance record
        final record = lesson.attendanceRecords
            .where((r) => r.artistId == artist.id)
            .firstOrNull;

        if (record != null) {
          attendedLessons++;
          lastLessonDate = lesson.date;

          switch (record.status) {
            case 'present':
              present++;
              break;
            case 'absent':
              absent++;
              break;
            case 'late':
              late++;
              break;
            case 'excused':
              excused++;
              break;
          }
        }
      }
    }

    final attendanceRate = availableLessons > 0
        ? ((present + late) / availableLessons) * 100
        : 0.0;
    final lateRate = availableLessons > 0
        ? (late / availableLessons) * 100
        : 0.0;

    String activityStatus;
    if (attendanceRate >= 95) {
      activityStatus = 'פעיל מאוד';
    } else if (attendanceRate >= 85) {
      activityStatus = 'פעיל';
    } else if (attendanceRate >= 60) {
      activityStatus = 'בינוני';
    } else {
      activityStatus = 'זקוק לתשומת לב';
    }

    return {
      'availableLessons': availableLessons,
      'attendedLessons': attendedLessons,
      'present': present,
      'absent': absent,
      'late': late,
      'excused': excused,
      'attendanceRate': attendanceRate,
      'lateRate': lateRate,
      'lastLessonDate': lastLessonDate != null
          ? DateFormat('dd/MM/yyyy').format(lastLessonDate)
          : null,
      'activityStatus': activityStatus,
    };
  }

  double _calculateAverageParticipants(List<Lesson> lessons) {
    if (lessons.isEmpty) return 0.0;

    final totalParticipants = lessons.fold(
      0,
      (sum, lesson) => sum + lesson.registeredArtistIds.length,
    );
    return totalParticipants / lessons.length;
  }

  Map<String, Map<String, dynamic>> _calculateStudioStats(
    List<Lesson> lessons,
  ) {
    final studioStats = <String, Map<String, dynamic>>{};

    for (final lesson in lessons) {
      final studioName = lesson.title; // Assuming title contains studio info

      if (!studioStats.containsKey(studioName)) {
        studioStats[studioName] = {
          'lessonCount': 0,
          'totalParticipants': 0,
          'totalAttendance': 0,
          'totalPossibleAttendance': 0,
        };
      }

      final stats = studioStats[studioName]!;
      stats['lessonCount'] = (stats['lessonCount'] as int) + 1;
      stats['totalParticipants'] =
          (stats['totalParticipants'] as int) +
          lesson.registeredArtistIds.length;

      // Calculate attendance for this lesson
      final presentCount = lesson.attendanceRecords
          .where((r) => r.status == 'present' || r.status == 'late')
          .length;
      stats['totalAttendance'] =
          (stats['totalAttendance'] as int) + presentCount;
      stats['totalPossibleAttendance'] =
          (stats['totalPossibleAttendance'] as int) +
          lesson.attendanceRecords.length;
    }

    // Calculate averages
    studioStats.forEach((studioName, stats) {
      final lessonCount = stats['lessonCount'] as int;
      stats['averageParticipants'] = lessonCount > 0
          ? (stats['totalParticipants'] as int) / lessonCount
          : 0.0;
      stats['averageAttendance'] = (stats['totalPossibleAttendance'] as int) > 0
          ? ((stats['totalAttendance'] as int) /
                    (stats['totalPossibleAttendance'] as int)) *
                100
          : 0.0;
    });

    return studioStats;
  }

  Map<String, Map<String, dynamic>> _calculateWeeklyPatterns(
    List<Lesson> lessons,
  ) {
    final patterns = <String, Map<String, dynamic>>{};
    final daysOfWeek = [
      'ראשון',
      'שני',
      'שלישי',
      'רביעי',
      'חמישי',
      'שישי',
      'שבת',
    ];

    // Initialize patterns
    for (final day in daysOfWeek) {
      patterns[day] = {
        'lessonCount': 0,
        'totalParticipants': 0,
        'totalAttendance': 0,
        'totalPossibleAttendance': 0,
        'hours': <int, int>{},
      };
    }

    for (final lesson in lessons) {
      final dayIndex = lesson.date.weekday % 7; // Convert to 0-6
      final dayName = daysOfWeek[dayIndex];
      final hour = lesson.date.hour;

      final dayStats = patterns[dayName]!;
      dayStats['lessonCount'] = (dayStats['lessonCount'] as int) + 1;
      dayStats['totalParticipants'] =
          (dayStats['totalParticipants'] as int) +
          lesson.registeredArtistIds.length;

      final presentCount = lesson.attendanceRecords
          .where((r) => r.status == 'present' || r.status == 'late')
          .length;
      dayStats['totalAttendance'] =
          (dayStats['totalAttendance'] as int) + presentCount;
      dayStats['totalPossibleAttendance'] =
          (dayStats['totalPossibleAttendance'] as int) +
          lesson.attendanceRecords.length;

      // Track popular hours
      final hours = dayStats['hours'] as Map<int, int>;
      hours[hour] = (hours[hour] ?? 0) + 1;
    }

    // Calculate averages and popular hours
    patterns.forEach((day, stats) {
      final lessonCount = stats['lessonCount'] as int;
      stats['averageParticipants'] = lessonCount > 0
          ? (stats['totalParticipants'] as int) / lessonCount
          : 0.0;
      stats['attendanceRate'] = (stats['totalPossibleAttendance'] as int) > 0
          ? ((stats['totalAttendance'] as int) /
                    (stats['totalPossibleAttendance'] as int)) *
                100
          : 0.0;

      // Find popular hours
      final hours = stats['hours'] as Map<int, int>;
      if (hours.isNotEmpty) {
        final sortedHours = hours.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        stats['popularHours'] = sortedHours
            .take(3)
            .map((e) => '${e.key}:00')
            .join(', ');
      } else {
        stats['popularHours'] = 'אין נתונים';
      }
    });

    return patterns;
  }

  List<Map<String, dynamic>> _calculateTopPerformers(
    List<User> artists,
    List<Lesson> lessons,
  ) {
    final performers = <Map<String, dynamic>>[];

    for (final artist in artists) {
      final stats = _calculateDetailedArtistStats(artist, lessons);

      // Calculate streaks
      final streaks = _calculateAttendanceStreaks(artist, lessons);

      // Determine achievement
      String achievement = '';
      final attendanceRate = stats['attendanceRate'] as double;
      if (attendanceRate == 100) {
        achievement = '🏆 נוכחות מושלמת';
      } else if (attendanceRate >= 95) {
        achievement = '🥇 נוכחות מצוינת';
      } else if (attendanceRate >= 90) {
        achievement = '🥈 נוכחות טובה מאוד';
      } else if (attendanceRate >= 85) {
        achievement = '🥉 נוכחות טובה';
      } else {
        achievement = '📈 בהתקדמות';
      }

      performers.add({
        'name': artist.name,
        'attendanceRate': attendanceRate,
        'currentStreak': streaks['current'],
        'longestStreak': streaks['longest'],
        'totalLessons': stats['availableLessons'],
        'achievement': achievement,
      });
    }

    // Sort by attendance rate
    performers.sort(
      (a, b) => (b['attendanceRate'] as double).compareTo(
        a['attendanceRate'] as double,
      ),
    );

    return performers;
  }

  Map<String, int> _calculateAttendanceStreaks(
    User artist,
    List<Lesson> lessons,
  ) {
    final artistLessons =
        lessons
            .where((lesson) => lesson.registeredArtistIds.contains(artist.id))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    for (final lesson in artistLessons) {
      final record = lesson.attendanceRecords
          .where((r) => r.artistId == artist.id)
          .firstOrNull;

      if (record != null &&
          (record.status == 'present' || record.status == 'late')) {
        tempStreak++;
        longestStreak = math.max(longestStreak, tempStreak);
      } else {
        tempStreak = 0;
      }
    }

    // Calculate current streak (from the end)
    for (int i = artistLessons.length - 1; i >= 0; i--) {
      final lesson = artistLessons[i];
      final record = lesson.attendanceRecords
          .where((r) => r.artistId == artist.id)
          .firstOrNull;

      if (record != null &&
          (record.status == 'present' || record.status == 'late')) {
        currentStreak++;
      } else {
        break;
      }
    }

    return {'current': currentStreak, 'longest': longestStreak};
  }

  // ✅ NEW: Export individual artist data as Excel
  Future<String> saveIndividualArtistExcelToDevice({
    required User artist,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Generate Excel file specifically for this artist
      final excel = await _generateIndividualArtistExcel(
        artist: artist,
        startDate: startDate,
        endDate: endDate,
      );

      // Get file bytes
      final bytes = excel.save();
      if (bytes == null) throw Exception('Failed to generate Excel bytes');

      // Create filename with artist name
      final fileName =
          'artist_report_${artist.name.replaceAll(' ', '_')}_${DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now())}.xlsx';

      // Save to device
      final filePath = await _saveToDevice(fileName, bytes);

      return 'דוח ${artist.name} נשמר ב: $filePath';
    } catch (e) {
      throw Exception('Failed to save artist Excel file: $e');
    }
  }

  // Generate Excel file with individual artist data
  Future<Excel> _generateIndividualArtistExcel({
    required User artist,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    // Get artist's lessons in date range
    final allLessons = await _lessonRepository.getAllLessons(
      startDate: startDate,
      endDate: endDate,
    );

    // Filter lessons where this artist was registered
    final artistLessons = allLessons
        .where((lesson) => lesson.registeredArtistIds.contains(artist.id))
        .toList();

    // Get all users for instructor names
    final allUsers = await _userRepository.getAllUsers();
    final instructors = allUsers
        .where((u) => u.role == UserRole.mentor)
        .toList();

    // Create artist-specific sheets
    await _createArtistOverviewSheet(
      excel,
      artist,
      artistLessons,
      startDate,
      endDate,
    );
    await _createArtistAttendanceDetailSheet(
      excel,
      artist,
      artistLessons,
      instructors,
    );
    await _createArtistStudioAnalysisSheet(excel, artist, artistLessons);
    await _createArtistProgressSheet(excel, artist, artistLessons);

    return excel;
  }

  // Create artist overview sheet
  Future<void> _createArtistOverviewSheet(
    Excel excel,
    User artist,
    List<Lesson> artistLessons,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final sheet = excel['פרופיל ${artist.name}'];

    // Artist info section
    final headers = ['פרט', 'ערך', 'הערות'];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Calculate artist stats
    final stats = _calculateIndividualArtistStats(artist, artistLessons);

    // Artist overview data
    final overviewData = [
      ['שם האמן', artist.name, 'שם מלא'],
      ['אימייל', artist.email, 'כתובת מייל'],
      [
        'תקופת הדוח',
        '${DateFormat('dd/MM/yyyy').format(startDate ?? DateTime.now().subtract(const Duration(days: 30)))} - ${DateFormat('dd/MM/yyyy').format(endDate ?? DateTime.now())}',
        'טווח התאריכים',
      ],
      [
        'סה"כ שיעורים רשומים',
        '${stats['totalRegistered']}',
        'שיעורים שהאמן נרשם אליהם',
      ],
      ['שיעורים בהם השתתף', '${stats['attended']}', 'שיעורים שהאמן באמת הגיע'],
      [
        'אחוז נוכחות',
        '${stats['attendanceRate'].toStringAsFixed(1)}%',
        'אחוז ההשתתפות הכללי',
      ],
      ['נוכח', '${stats['present']}', 'שיעורים שהגיע בזמן'],
      ['איחורים', '${stats['late']}', 'שיעורים שהגיע באיחור'],
      ['היעדרויות', '${stats['absent']}', 'שיעורים שלא הגיע'],
      ['היעדרויות מוצדקות', '${stats['excused']}', 'היעדרויות עם הצדקה'],
      ['רצף נוכחות נוכחי', '${stats['currentStreak']}', 'שיעורים ברצף שהגיע'],
      [
        'רצף הכי ארוך',
        '${stats['longestStreak']}',
        'הרצף הארוך ביותר של נוכחות',
      ],
      [
        'סטודיו מועדף',
        '${stats['favoriteStudio']}',
        'הסטודיו שהכי הרבה משתתף בו',
      ],
      [
        'ממוצע שיעורים בשבוע',
        '${stats['averagePerWeek'].toStringAsFixed(1)}',
        'ממוצע השתתפות שבועית',
      ],
      ['סטטוס פעילות', '${stats['activityStatus']}', 'רמת הפעילות של האמן'],
    ];

    // Add data rows
    for (int i = 0; i < overviewData.length; i++) {
      final rowData = overviewData[i];
      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1),
        );
        cell.value = TextCellValue(rowData[col]);

        // Color code attendance rate
        if (i == 5 && col == 1) {
          // Attendance rate row, value column
          final rate = stats['attendanceRate'] as double;
          if (rate >= 90) {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.green100);
          } else if (rate >= 75) {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.yellow100,
            );
          } else {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.red100);
          }
        }
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 25);
    }
  }

  // Create detailed attendance sheet for the artist
  Future<void> _createArtistAttendanceDetailSheet(
    Excel excel,
    User artist,
    List<Lesson> artistLessons,
    List<User> instructors,
  ) async {
    final sheet = excel['פירוט נוכחות ${artist.name}'];

    // Sort lessons by date
    artistLessons.sort((a, b) => a.date.compareTo(b.date));

    // Headers
    final headers = [
      'תאריך',
      'יום בשבוע',
      'שעה',
      'שם השיעור',
      'מנחה',
      'משך השיעור (דקות)',
      'סטטוס נוכחות',
      'זמן הגעה',
      'זמן יציאה',
      'הערות',
      'סוג שיעור',
      'מספר בסדרה',
    ];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add lesson data
    for (
      int lessonIndex = 0;
      lessonIndex < artistLessons.length;
      lessonIndex++
    ) {
      final lesson = artistLessons[lessonIndex];
      final row = lessonIndex + 1;

      final instructor = instructors
          .where((i) => i.id == lesson.assignedInstructorId)
          .firstOrNull;

      // Find attendance record for this artist
      final attendanceRecord = lesson.attendanceRecords
          .where((record) => record.artistId == artist.id)
          .firstOrNull;

      final rowData = [
        DateFormat('dd/MM/yyyy').format(lesson.date),
        DateFormat('EEEE', 'he').format(lesson.date),
        DateFormat('HH:mm').format(lesson.date),
        lesson.title,
        instructor?.name ?? lesson.instructorName ?? 'לא ידוע',
        lesson.durationMinutes.toString(),
        attendanceRecord != null
            ? _getAttendanceStatusInHebrew(attendanceRecord.status)
            : 'לא נרשם',
        attendanceRecord?.checkedInAt != null
            ? DateFormat('HH:mm').format(attendanceRecord!.checkedInAt!)
            : '',
        attendanceRecord?.checkedOutAt != null
            ? DateFormat('HH:mm').format(attendanceRecord!.checkedOutAt!)
            : '',
        attendanceRecord?.notes ?? '',
        lesson.isRecurring ? 'שיעור חוזר' : 'שיעור יחיד',
        lesson.instanceNumber?.toString() ?? '',
      ];

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = TextCellValue(rowData[col]);

        // Color code attendance status
        if (col == 6 && attendanceRecord != null) {
          // Status column
          switch (attendanceRecord.status) {
            case 'present':
              cell.cellStyle = CellStyle(
                backgroundColorHex: ExcelColor.green100,
              );
              break;
            case 'late':
              cell.cellStyle = CellStyle(
                backgroundColorHex: ExcelColor.yellow100,
              );
              break;
            case 'absent':
              cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.red100);
              break;
            case 'excused':
              cell.cellStyle = CellStyle(
                backgroundColorHex: ExcelColor.blue100,
              );
              break;
          }
        }
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }
  }

  // Create studio analysis sheet for the artist
  Future<void> _createArtistStudioAnalysisSheet(
    Excel excel,
    User artist,
    List<Lesson> artistLessons,
  ) async {
    final sheet = excel['ניתוח סטודיואים ${artist.name}'];

    // Calculate studio participation
    final studioStats = <String, Map<String, dynamic>>{};

    for (final lesson in artistLessons) {
      final studio = _getStudioFromLesson(lesson);

      if (!studioStats.containsKey(studio)) {
        studioStats[studio] = {
          'totalLessons': 0,
          'attended': 0,
          'present': 0,
          'late': 0,
          'absent': 0,
          'excused': 0,
        };
      }

      final stats = studioStats[studio]!;
      stats['totalLessons'] = (stats['totalLessons'] as int) + 1;

      final record = lesson.attendanceRecords
          .where((r) => r.artistId == artist.id)
          .firstOrNull;

      if (record != null) {
        switch (record.status) {
          case 'present':
            stats['attended'] = (stats['attended'] as int) + 1;
            stats['present'] = (stats['present'] as int) + 1;
            break;
          case 'late':
            stats['attended'] = (stats['attended'] as int) + 1;
            stats['late'] = (stats['late'] as int) + 1;
            break;
          case 'absent':
            stats['absent'] = (stats['absent'] as int) + 1;
            break;
          case 'excused':
            stats['excused'] = (stats['excused'] as int) + 1;
            break;
        }
      }
    }

    // Headers
    final headers = [
      'סטודיו',
      'סה"כ שיעורים',
      'השתתף',
      'נוכח',
      'איחור',
      'נעדר',
      'מוצדק',
      'אחוז נוכחות',
      'אחוז מכלל השיעורים',
    ];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add studio data
    final sortedStudios = studioStats.entries.toList()
      ..sort(
        (a, b) => (b.value['totalLessons'] as int).compareTo(
          a.value['totalLessons'] as int,
        ),
      );

    for (int i = 0; i < sortedStudios.length; i++) {
      final entry = sortedStudios[i];
      final studio = entry.key;
      final stats = entry.value;
      final row = i + 1;

      final totalLessons = stats['totalLessons'] as int;
      final attended = stats['attended'] as int;
      final attendanceRate = totalLessons > 0
          ? (attended / totalLessons) * 100
          : 0.0;
      final percentageOfTotal = artistLessons.isNotEmpty
          ? (totalLessons / artistLessons.length) * 100
          : 0.0;

      final rowData = [
        studio,
        totalLessons.toString(),
        attended.toString(),
        (stats['present'] as int).toString(),
        (stats['late'] as int).toString(),
        (stats['absent'] as int).toString(),
        (stats['excused'] as int).toString(),
        '${attendanceRate.toStringAsFixed(1)}%',
        '${percentageOfTotal.toStringAsFixed(1)}%',
      ];

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = TextCellValue(rowData[col]);

        // Color code attendance rate
        if (col == 7) {
          // Attendance rate column
          if (attendanceRate >= 90) {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.green100);
          } else if (attendanceRate >= 75) {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.yellow100,
            );
          } else {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.red100);
          }
        }
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 18);
    }
  }

  // Create progress tracking sheet
  Future<void> _createArtistProgressSheet(
    Excel excel,
    User artist,
    List<Lesson> artistLessons,
  ) async {
    final sheet = excel['התקדמות ${artist.name}'];

    // Sort lessons by date for progress tracking
    artistLessons.sort((a, b) => a.date.compareTo(b.date));

    // Group lessons by month for progress tracking
    final monthlyProgress = <String, Map<String, dynamic>>{};

    for (final lesson in artistLessons) {
      final monthKey = DateFormat('yyyy-MM').format(lesson.date);
      final monthName = DateFormat('MMMM yyyy', 'he').format(lesson.date);

      if (!monthlyProgress.containsKey(monthKey)) {
        monthlyProgress[monthKey] = {
          'monthName': monthName,
          'totalLessons': 0,
          'attended': 0,
          'present': 0,
          'late': 0,
          'absent': 0,
        };
      }

      final progress = monthlyProgress[monthKey]!;
      progress['totalLessons'] = (progress['totalLessons'] as int) + 1;

      final record = lesson.attendanceRecords
          .where((r) => r.artistId == artist.id)
          .firstOrNull;

      if (record != null) {
        switch (record.status) {
          case 'present':
            progress['attended'] = (progress['attended'] as int) + 1;
            progress['present'] = (progress['present'] as int) + 1;
            break;
          case 'late':
            progress['attended'] = (progress['attended'] as int) + 1;
            progress['late'] = (progress['late'] as int) + 1;
            break;
          case 'absent':
            progress['absent'] = (progress['absent'] as int) + 1;
            break;
        }
      }
    }

    // Headers
    final headers = [
      'חודש',
      'סה"כ שיעורים',
      'השתתף',
      'נוכח',
      'איחור',
      'נעדר',
      'אחוז נוכחות',
      'מגמה',
    ];

    // Set headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue50,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add monthly progress data
    final sortedMonths = monthlyProgress.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (int i = 0; i < sortedMonths.length; i++) {
      final entry = sortedMonths[i];
      final progress = entry.value;
      final row = i + 1;

      final totalLessons = progress['totalLessons'] as int;
      final attended = progress['attended'] as int;
      final attendanceRate = totalLessons > 0
          ? (attended / totalLessons) * 100
          : 0.0;

      // Calculate trend
      String trend = '→';
      if (i > 0) {
        final prevProgress = sortedMonths[i - 1].value;
        final prevRate = (prevProgress['totalLessons'] as int) > 0
            ? ((prevProgress['attended'] as int) /
                      (prevProgress['totalLessons'] as int)) *
                  100
            : 0.0;

        if (attendanceRate > prevRate + 5) {
          trend = '↗ שיפור';
        } else if (attendanceRate < prevRate - 5) {
          trend = '↘ ירידה';
        } else {
          trend = '→ יציב';
        }
      }

      final rowData = [
        progress['monthName'],
        totalLessons.toString(),
        attended.toString(),
        (progress['present'] as int).toString(),
        (progress['late'] as int).toString(),
        (progress['absent'] as int).toString(),
        '${attendanceRate.toStringAsFixed(1)}%',
        trend,
      ];

      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = TextCellValue(rowData[col]);

        // Color code attendance rate
        if (col == 6) {
          // Attendance rate column
          if (attendanceRate >= 90) {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.green100);
          } else if (attendanceRate >= 75) {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.yellow100,
            );
          } else {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.red100);
          }
        }
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }
  }

  // Helper method to calculate individual artist stats
  Map<String, dynamic> _calculateIndividualArtistStats(
    User artist,
    List<Lesson> artistLessons,
  ) {
    int totalRegistered = artistLessons.length;
    int attended = 0;
    int present = 0;
    int late = 0;
    int absent = 0;
    int excused = 0;

    // Studio tracking
    final studioCount = <String, int>{};

    // Streak tracking
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    // Sort lessons by date for streak calculation
    final sortedLessons = List<Lesson>.from(artistLessons)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final lesson in sortedLessons) {
      final record = lesson.attendanceRecords
          .where((r) => r.artistId == artist.id)
          .firstOrNull;

      if (record != null) {
        switch (record.status) {
          case 'present':
            present++;
            attended++;
            tempStreak++;
            break;
          case 'late':
            late++;
            attended++;
            tempStreak++;
            break;
          case 'absent':
            absent++;
            tempStreak = 0;
            break;
          case 'excused':
            excused++;
            tempStreak = 0;
            break;
        }

        longestStreak = math.max(longestStreak, tempStreak);

        // Track studio participation
        final studio = _getStudioFromLesson(lesson);
        studioCount[studio] = (studioCount[studio] ?? 0) + 1;
      }
    }

    // Calculate current streak from the end
    for (int i = sortedLessons.length - 1; i >= 0; i--) {
      final lesson = sortedLessons[i];
      final record = lesson.attendanceRecords
          .where((r) => r.artistId == artist.id)
          .firstOrNull;

      if (record != null &&
          (record.status == 'present' || record.status == 'late')) {
        currentStreak++;
      } else {
        break;
      }
    }

    final attendanceRate = totalRegistered > 0
        ? (attended / totalRegistered) * 100
        : 0.0;
    final favoriteStudio = studioCount.isNotEmpty
        ? studioCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'אין נתונים';

    String activityStatus;
    if (attendanceRate >= 95) {
      activityStatus = 'פעיל מאוד';
    } else if (attendanceRate >= 85) {
      activityStatus = 'פעיל';
    } else if (attendanceRate >= 70) {
      activityStatus = 'בינוני';
    } else if (attendanceRate >= 50) {
      activityStatus = 'זקוק לעידוד';
    } else {
      activityStatus = 'זקוק לתשומת לב';
    }

    return {
      'totalRegistered': totalRegistered,
      'attended': attended,
      'present': present,
      'late': late,
      'absent': absent,
      'excused': excused,
      'attendanceRate': attendanceRate,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'favoriteStudio': favoriteStudio,
      'averagePerWeek': totalRegistered / 4, // Assuming 4 weeks in period
      'activityStatus': activityStatus,
    };
  }

  String _getStudioFromLesson(Lesson lesson) {
    final title = lesson.title.toLowerCase();
    if (title.contains('פלסטיק') ||
        title.contains('ציור') ||
        title.contains('פיסול')) {
      return 'פלסטיקה';
    } else if (title.contains('תיאטרון') || title.contains('משחק')) {
      return 'תיאטרון';
    } else if (title.contains('מוזיקה') || title.contains('שירה')) {
      return 'מוזיקה';
    } else if (title.contains('כתיבה') || title.contains('ספרות')) {
      return 'כתיבה';
    } else if (title.contains('אנימציה') || title.contains('הנפשה')) {
      return 'אנימציה';
    } else if (title.contains('וידאו') || title.contains('צילום')) {
      return 'וידאו';
    }
    return 'כללי';
  }
}
