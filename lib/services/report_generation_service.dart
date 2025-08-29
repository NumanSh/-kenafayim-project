import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../data/models/report.dart';
import '../data/models/lesson.dart';
import '../data/models/user.dart';
import '../data/repositories/lesson_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/report_repository.dart';
import '../config/service_locator.dart';

class ReportGenerationService {
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  final ReportRepository _reportRepository = serviceLocator<ReportRepository>();

  /// ✅ NEW: Public method for Analytics Dashboard
  Future<File> generatePDFReport({
    required String title,
    required String content,
    required ReportType reportType,
    required DateTime startDate,
    required DateTime endDate,
    required String createdByName,
  }) async {
    try {
      // Get the data needed for the report
      final lessons = await _lessonRepository.getAllLessons(
        startDate: startDate,
        endDate: endDate,
      );

      final users = await _userRepository.getAllUsers();
      final artists = users.where((u) => u.role == UserRole.client).toList();
      final mentors = users.where((u) => u.role == UserRole.mentor).toList();

      // Get analytics data based on report type
      Map<String, dynamic> analyticsData = {};
      Map<String, dynamic> userActivityData = {};

      switch (reportType) {
        case ReportType.attendance:
          analyticsData = await _reportRepository.generateAttendanceAnalytics(
            startDate: startDate,
            endDate: endDate,
          );
          break;
        case ReportType.workingHours:
          analyticsData = await _reportRepository.generateWorkingHoursAnalytics(
            startDate: startDate,
            endDate: endDate,
          );
          break;
        case ReportType.userActivity:
          userActivityData = await _reportRepository
              .generateUserActivityAnalytics(
                startDate: startDate,
                endDate: endDate,
              );
          break;
        default:
          analyticsData = await _reportRepository.generateWorkingHoursAnalytics(
            startDate: startDate,
            endDate: endDate,
          );
      }

      // Use the existing private method to generate the PDF
      return await _generatePDFReport(
        title: title,
        startDate: startDate,
        endDate: endDate,
        lessons: lessons,
        artists: artists,
        mentors: mentors,
        analyticsData: analyticsData,
        userActivityData: userActivityData,
        includeMedicalFlags: false,
      );
    } catch (e) {
      throw Exception('Failed to generate PDF report: $e');
    }
  }

  /// Generate comprehensive attendance report with analytics
  Future<File> generateAttendanceReport({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    bool includeMedicalFlags = false,
    String format = 'pdf',
    Map<String, dynamic>? additionalData,
    String? instructorId,
    String? artistId,
  }) async {
    try {
      // Gather all necessary data
      final lessons = await _lessonRepository.getAllLessons(
        startDate: startDate,
        endDate: endDate,
      );

      final users = await _userRepository.getAllUsers();
      final artists = users.where((u) => u.role == UserRole.client).toList();
      final mentors = users.where((u) => u.role == UserRole.mentor).toList();

      // Generate analytics data
      final analyticsData = await _reportRepository
          .generateWorkingHoursAnalytics(
            startDate: startDate,
            endDate: endDate,
          );

      final userActivityData = await _reportRepository
          .generateUserActivityAnalytics(
            startDate: startDate,
            endDate: endDate,
          );

      // Generate report based on format
      switch (format.toLowerCase()) {
        case 'pdf':
          return await _generatePDFReport(
            title: title,
            startDate: startDate,
            endDate: endDate,
            lessons: lessons,
            artists: artists,
            mentors: mentors,
            analyticsData: analyticsData,
            userActivityData: userActivityData,
            includeMedicalFlags: includeMedicalFlags,
          );
        case 'excel':
          return await _generateExcelReport(
            title: title,
            startDate: startDate,
            endDate: endDate,
            lessons: lessons,
            artists: artists,
            mentors: mentors,
            analyticsData: analyticsData,
            userActivityData: userActivityData,
          );
        default:
          throw Exception('Unsupported format: $format');
      }
    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }

  /// Generate beautiful PDF report with charts and analytics
  Future<File> _generatePDFReport({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required List<Lesson> lessons,
    required List<User> artists,
    required List<User> mentors,
    required Map<String, dynamic> analyticsData,
    required Map<String, dynamic> userActivityData,
    bool includeMedicalFlags = false,
  }) async {
    final pdf = pw.Document();

    // Load Hebrew font
    final fontData = await rootBundle.load('assets/fonts/Rubik-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    // Cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  gradient: const pw.LinearGradient(
                    colors: [PdfColors.blue700, PdfColors.blue900],
                  ),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'עמותת כנפיים',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'מרכז לאמנות טיפולית',
                      style: pw.TextStyle(fontSize: 16, color: PdfColors.white),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 40),

              // Report title
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),

              pw.SizedBox(height: 20),

              // Date range
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'תקופת הדוח:',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Key metrics summary
              pw.Text(
                'סיכום מרכזי',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 15),

              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildMetricBox(
                      'סה"כ שיעורים',
                      '${lessons.length}',
                      ttf,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: _buildMetricBox(
                      'אמנים פעילים',
                      '${artists.length}',
                      ttf,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: _buildMetricBox('מנחים', '${mentors.length}', ttf),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'דוח נוצר ב-${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'מערכת ניהול כנפיים - גרסה 2.0',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Analytics page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ניתוח נתונים',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 20),

              // Working hours analytics
              _buildAnalyticsSection('ניתוח שעות עבודה', analyticsData, ttf),

              pw.SizedBox(height: 20),

              // User activity analytics
              _buildAnalyticsSection('פעילות משתמשים', userActivityData, ttf),
            ],
          );
        },
      ),
    );

    // Detailed lessons page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'פירוט שיעורים',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 20),

              // Lessons table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      _buildTableCell('תאריך', ttf, isHeader: true),
                      _buildTableCell('שם השיעור', ttf, isHeader: true),
                      _buildTableCell('מנחה', ttf, isHeader: true),
                      _buildTableCell('משתתפים', ttf, isHeader: true),
                      _buildTableCell('סטטוס', ttf, isHeader: true),
                    ],
                  ),
                  // Data rows
                  ...lessons
                      .take(20)
                      .map(
                        (lesson) => pw.TableRow(
                          children: [
                            _buildTableCell(
                              DateFormat('dd/MM').format(lesson.date),
                              ttf,
                            ),
                            _buildTableCell(lesson.title, ttf),
                            _buildTableCell(
                              lesson.instructorName ?? 'לא צוין',
                              ttf,
                            ),
                            _buildTableCell(
                              '${lesson.registeredArtistIds.length}',
                              ttf,
                            ),
                            _buildTableCell(
                              _getStatusInHebrew(lesson.status),
                              ttf,
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ],
              ),

              if (lessons.length > 20) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  'מוצגים 20 שיעורים ראשונים מתוך ${lessons.length}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Generate comprehensive Excel report
  Future<File> _generateExcelReport({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required List<Lesson> lessons,
    required List<User> artists,
    required List<User> mentors,
    required Map<String, dynamic> analyticsData,
    required Map<String, dynamic> userActivityData,
  }) async {
    final excel = Excel.createExcel();

    // Remove default sheet
    excel.delete('Sheet1');

    // Summary sheet
    final summarySheet = excel['סיכום'];
    summarySheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      title,
    );
    summarySheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
      'תקופה: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
    );

    // Key metrics
    summarySheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
      'מדדים מרכזיים',
    );
    summarySheet.cell(CellIndex.indexByString('A5')).value = TextCellValue(
      'סה"כ שיעורים',
    );
    summarySheet.cell(CellIndex.indexByString('B5')).value = IntCellValue(
      lessons.length,
    );
    summarySheet.cell(CellIndex.indexByString('A6')).value = TextCellValue(
      'אמנים פעילים',
    );
    summarySheet.cell(CellIndex.indexByString('B6')).value = IntCellValue(
      artists.length,
    );
    summarySheet.cell(CellIndex.indexByString('A7')).value = TextCellValue(
      'מנחים',
    );
    summarySheet.cell(CellIndex.indexByString('B7')).value = IntCellValue(
      mentors.length,
    );

    // Lessons sheet
    final lessonsSheet = excel['שיעורים'];
    final headers = ['תאריך', 'שעה', 'שם השיעור', 'מנחה', 'משתתפים', 'סטטוס'];

    for (int i = 0; i < headers.length; i++) {
      lessonsSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }

    for (int i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      lessonsSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          .value = TextCellValue(
        DateFormat('dd/MM/yyyy').format(lesson.date),
      );
      lessonsSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
          .value = TextCellValue(
        DateFormat('HH:mm').format(lesson.date),
      );
      lessonsSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
          .value = TextCellValue(
        lesson.title,
      );
      lessonsSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1))
          .value = TextCellValue(
        lesson.instructorName ?? 'לא צוין',
      );
      lessonsSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1))
          .value = IntCellValue(
        lesson.registeredArtistIds.length,
      );
      lessonsSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1))
          .value = TextCellValue(
        _getStatusInHebrew(lesson.status),
      );
    }

    // Analytics sheet
    final analyticsSheet = excel['ניתוחים'];
    analyticsSheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      'ניתוח נתונים',
    );

    // Working hours analytics
    analyticsSheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
      'שעות עבודה',
    );
    analyticsSheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
      'סה"כ שעות',
    );
    analyticsSheet.cell(CellIndex.indexByString('B4')).value = DoubleCellValue(
      (analyticsData['totalHours'] ?? 0).toDouble(),
    );
    analyticsSheet.cell(CellIndex.indexByString('A5')).value = TextCellValue(
      'אחוז אישור',
    );
    analyticsSheet.cell(CellIndex.indexByString('B5')).value = DoubleCellValue(
      (analyticsData['approvalRate'] ?? 0).toDouble(),
    );

    // User activity analytics
    analyticsSheet.cell(CellIndex.indexByString('A7')).value = TextCellValue(
      'פעילות משתמשים',
    );
    analyticsSheet.cell(CellIndex.indexByString('A8')).value = TextCellValue(
      'משתמשים פעילים',
    );
    analyticsSheet.cell(CellIndex.indexByString('B8')).value = IntCellValue(
      (userActivityData['activeUsers'] ?? 0),
    );
    analyticsSheet.cell(CellIndex.indexByString('A9')).value = TextCellValue(
      'אחוז פעילות',
    );
    analyticsSheet.cell(CellIndex.indexByString('B9')).value = DoubleCellValue(
      (userActivityData['activityRate'] ?? 0).toDouble(),
    );

    // Save Excel file
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    final bytes = excel.save();
    await file.writeAsBytes(bytes!);

    return file;
  }

  // Helper methods for PDF generation
  pw.Widget _buildMetricBox(String title, String value, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAnalyticsSection(
    String title,
    Map<String, dynamic> data,
    pw.Font font,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: data.entries.take(3).map((entry) {
              return pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(left: 5),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '${entry.value}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        entry.key,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _getStatusInHebrew(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'מתוכנן';
      case 'completed':
        return 'הושלם';
      case 'cancelled':
        return 'בוטל';
      default:
        return status;
    }
  }
}
