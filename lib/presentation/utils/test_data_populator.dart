import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:knafayim_app/data/models/attendance_record.dart';
import 'package:knafayim_app/data/models/lesson.dart';
import 'package:knafayim_app/data/models/report.dart';
import 'package:knafayim_app/data/models/room.dart';
import 'package:knafayim_app/data/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class TestDataPopulator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> populateAllTestData() async {
    if (!kDebugMode) {
      print('❌ Test data can only be populated in debug mode');
      return;
    }

    try {
      print('🚀 Starting test data population...');

      await _populateUsers();
      await _populateRooms();
      await _populateLessons();
      await _populateReports();

      print('✅ Test data population completed successfully!');
    } catch (e) {
      print('❌ Error populating test data: $e');
    }
  }

  static Future<void> _populateUsers() async {
    print('👥 Creating users...');

    // Staff members
    final staff = [
      User(
        id: 'staff_001',
        name: 'אלי כהן',
        email: 'eli@knafayim.org',
        role: UserRole.staff,
        phoneNumber: '050-1234567',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
      User(
        id: 'staff_002',
        name: 'רחל לוי',
        email: 'rachel@knafayim.org',
        role: UserRole.staff,
        phoneNumber: '052-9876543',
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
      ),
    ];

    // Mentors/Instructors
    final mentors = [
      User(
        id: 'mentor_001',
        name: 'יוסי כהן',
        email: 'yossi@knafayim.org',
        role: UserRole.mentor,
        phoneNumber: '054-1111111',
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
      ),
      User(
        id: 'mentor_002',
        name: 'שרה לוי',
        email: 'sara@knafayim.org',
        role: UserRole.mentor,
        phoneNumber: '053-2222222',
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
      ),
      User(
        id: 'mentor_003',
        name: 'דוד אברהם',
        email: 'david@knafayim.org',
        role: UserRole.mentor,
        phoneNumber: '052-3333333',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      User(
        id: 'mentor_004',
        name: 'מירי רוזן',
        email: 'miri.r@knafayim.org',
        role: UserRole.mentor,
        phoneNumber: '050-4444444',
        createdAt: DateTime.now().subtract(const Duration(days: 80)),
      ),
    ];

    // Artists/Clients
    final artists = [
      User(
        id: 'artist_001',
        name: 'מירי לוי',
        email: 'miri.levi@example.com',
        role: UserRole.client,
        phoneNumber: '050-5555555',
        createdAt: DateTime.now().subtract(const Duration(days: 70)),
      ),
      User(
        id: 'artist_002',
        name: 'דוד אברהמוב',
        email: 'david.a@example.com',
        role: UserRole.client,
        phoneNumber: '052-6666666',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      User(
        id: 'artist_003',
        name: 'נועה כהן',
        email: 'noa.cohen@example.com',
        role: UserRole.client,
        phoneNumber: '053-7777777',
        createdAt: DateTime.now().subtract(const Duration(days: 50)),
      ),
      User(
        id: 'artist_004',
        name: 'אור שמיר',
        email: 'or.shamir@example.com',
        role: UserRole.client,
        phoneNumber: '054-8888888',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      User(
        id: 'artist_005',
        name: 'תמר גולן',
        email: 'tamar.golan@example.com',
        role: UserRole.client,
        phoneNumber: '050-9999999',
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
      ),
      User(
        id: 'artist_006',
        name: 'יונתן לוי',
        email: 'yonatan.levi@example.com',
        role: UserRole.client,
        phoneNumber: '052-1010101',
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
      ),
      User(
        id: 'artist_007',
        name: 'שירה אבני',
        email: 'shira.avni@example.com',
        role: UserRole.client,
        phoneNumber: '053-1212121',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      User(
        id: 'artist_008',
        name: 'רון כץ',
        email: 'ron.katz@example.com',
        role: UserRole.client,
        phoneNumber: '054-1313131',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
    ];

    // Save all users
    final allUsers = [...staff, ...mentors, ...artists];

    for (final user in allUsers) {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      print('   ✅ Created user: ${user.name} (${user.role.name})');
    }

    print('👥 Created ${allUsers.length} users');
  }

  // Add this method to TestDataPopulator class
  static Future<void> createAuthAccounts() async {
    print('🔐 Creating Firebase Auth accounts...');

    final firebaseAuth = auth.FirebaseAuth.instance;

    // Test accounts with simple passwords
    final testAccounts = [
      {
        'email': 'yossi@knafayim.org',
        'password': '123456',
        'name': 'יוסי כהן',
        'role': 'mentor',
      },
      {
        'email': 'sara@knafayim.org',
        'password': '123456',
        'name': 'שרה לוי',
        'role': 'mentor',
      },
      {
        'email': 'eli@knafayim.org',
        'password': '123456',
        'name': 'אלי כהן',
        'role': 'staff',
      },
      {
        'email': 'miri.levi@example.com',
        'password': '123456',
        'name': 'מירי לוי',
        'role': 'client',
      },
    ];

    for (final account in testAccounts) {
      try {
        // Create Firebase Auth account
        final userCredential = await firebaseAuth
            .createUserWithEmailAndPassword(
              email: account['email']!,
              password: account['password']!,
            );

        // Update display name
        await userCredential.user?.updateDisplayName(account['name']);

        print(
          '   ✅ Created auth account: ${account['name']} (${account['email']})',
        );
        print('   🔑 Password: ${account['password']}');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('   ⚠️  Account already exists: ${account['email']}');
        } else {
          print('   ❌ Error creating account ${account['email']}: $e');
        }
      }
    }
  }

  static Future<void> _populateRooms() async {
    print('🏢 Creating rooms...');

    final rooms = [
      Room(
        id: 'room_001',
        displayName: 'סטודיו אמנות פלסטית',
        location: 'בניין א, קומה 1',
        capacity: 15,
        type: RoomType.plasticArts,
        description: 'סטודיו מואר לאמנות פלסטית עם כל הציוד הנדרש',
        name: 'סטודיו פלסטיקה מרכזי',
        features: ['תאורה טבעית', 'כיורים', 'מדפים לאחסון', 'לוחות ציור'],
        availableResources: ['צבעים', 'מכחולים', 'נייר ציור', 'חימר'],
      ),
      Room(
        id: 'room_002',
        displayName: 'סטודיו מוזיקה',
        location: 'בניין ב, קומה 2',
        capacity: 10,
        type: RoomType.music,
        description: 'סטודיו מוזיקה מצויד בכלי נגינה ומערכת הגברה',
        name: 'סטודיו מוזיקה א',
        features: ['בידוד אקוסטי', 'מערכת הגברה', 'פסנתר', 'מיקרופונים'],
        availableResources: ['גיטרות', 'תופים', 'קלידים', 'מערכת הקלטה'],
      ),
      Room(
        id: 'room_003',
        displayName: 'אולם תיאטרון',
        location: 'בניין א, קומה 3',
        capacity: 20,
        type: RoomType.theater,
        description: 'אולם תיאטרון עם במה ותאורה מקצועית',
        name: 'אולם התיאטרון הראשי',
        features: ['במה מרכזית', 'תאורה מקצועית', 'מערכת קול', 'יציע צופים'],
        availableResources: [
          'תלבושות',
          'אביזרי במה',
          'מיקרופוני דש',
          'תפאורות',
        ],
      ),
      Room(
        id: 'room_004',
        displayName: 'חדר כתיבה יצירתית',
        location: 'בניין ב, קומה 1',
        capacity: 12,
        type: RoomType.writing,
        description: 'חדר שקט ונעים לכתיבה יצירתית',
        name: 'סטודיו הכתיבה',
        features: ['שקט מוחלט', 'תאורה רכה', 'כורסאות נוחות', 'שולחנות כתיבה'],
        availableResources: ['מחשבים', 'מדפסות', 'ספרי השראה', 'מחברות'],
      ),
      Room(
        id: 'room_005',
        displayName: 'סטודיו אנימציה',
        location: 'בניין ג, קומה 2',
        capacity: 8,
        type: RoomType.animation,
        description: 'סטודיו מחשבים לאנימציה ועיצוב דיגיטלי',
        name: 'מעבדת האנימציה',
        features: [
          'מחשבים חזקים',
          'טאבלטים גרפיים',
          'מסכים גדולים',
          'תוכנות מקצועיות',
        ],
        availableResources: [
          'Adobe Creative Suite',
          'Blender',
          'טאבלטים',
          'מצלמות',
        ],
      ),
      Room(
        id: 'room_006',
        displayName: 'סטודיו וידאו',
        location: 'בניין ג, קומה 1',
        capacity: 6,
        type: RoomType.videoCinema,
        description: 'סטודיו צילום ועריכת וידאו מקצועי',
        name: 'סטודיו הווידאו המקצועי',
        features: ['רקע ירוק', 'תאורה מקצועית', 'מצלמות 4K', 'חדר עריכה'],
        availableResources: [
          'מצלמות מקצועיות',
          'חצובות',
          'מיקרופונים',
          'תוכנות עריכה',
        ],
      ),
    ];

    for (final room in rooms) {
      await _firestore.collection('rooms').doc(room.id).set(room.toMap());
      print('   ✅ Created room: ${room.displayName}');
    }

    print('🏢 Created ${rooms.length} rooms');
  }

  static Future<void> _populateLessons() async {
    print('📚 Creating lessons...');

    final now = DateTime.now();
    final lessons = <Lesson>[];

    // Create regular lessons for the past month
    for (int i = 30; i >= 0; i--) {
      final lessonDate = now.subtract(Duration(days: i));

      // Skip weekends for most lessons
      if (lessonDate.weekday == 6 || lessonDate.weekday == 7) continue;

      // Morning lessons (9:00-12:00)
      if (i % 3 == 0) {
        lessons.add(
          _createLesson(
            id: 'lesson_${lessons.length + 1}',
            title: 'ציור בצבעי מים',
            date: DateTime(
              lessonDate.year,
              lessonDate.month,
              lessonDate.day,
              9,
              0,
            ),
            duration: 90,
            instructorId: 'mentor_001',
            instructorName: 'יוסי כהן',
            artistIds: ['artist_001', 'artist_002', 'artist_003'],
            status: i > 0 ? 'completed' : 'scheduled',
          ),
        );
      }

      // Afternoon lessons (14:00-17:00)
      if (i % 4 == 0) {
        lessons.add(
          _createLesson(
            id: 'lesson_${lessons.length + 1}',
            title: 'תיאטרון אלתור',
            date: DateTime(
              lessonDate.year,
              lessonDate.month,
              lessonDate.day,
              14,
              0,
            ),
            duration: 120,
            instructorId: 'mentor_002',
            instructorName: 'שרה לוי',
            artistIds: ['artist_004', 'artist_005', 'artist_006'],
            status: i > 0 ? 'completed' : 'scheduled',
          ),
        );
      }

      // Evening lessons (18:00-21:00)
      if (i % 5 == 0) {
        lessons.add(
          _createLesson(
            id: 'lesson_${lessons.length + 1}',
            title: 'מוזיקה וקצב',
            date: DateTime(
              lessonDate.year,
              lessonDate.month,
              lessonDate.day,
              18,
              0,
            ),
            duration: 60,
            instructorId: 'mentor_003',
            instructorName: 'דוד אברהם',
            artistIds: ['artist_007', 'artist_008', 'artist_001'],
            status: i > 0 ? 'completed' : 'scheduled',
          ),
        );
      }
    }

    // Create recurring lesson series
    final recurringLessons = _createRecurringLessonSeries();
    lessons.addAll(recurringLessons);

    // Save all lessons
    for (final lesson in lessons) {
      await _firestore.collection('lessons').doc(lesson.id).set(lesson.toMap());
      print(
        '   ✅ Created lesson: ${lesson.title} - ${DateFormat('dd/MM/yyyy').format(lesson.date)}',
      );
    }

    print('📚 Created ${lessons.length} lessons');
  }

  static Lesson _createLesson({
    required String id,
    required String title,
    required DateTime date,
    required int duration,
    required String instructorId,
    required String instructorName,
    required List<String> artistIds,
    required String status,
    bool isRecurring = false,
    String? recurrenceId,
    int? instanceNumber,
  }) {
    // Generate attendance records for completed lessons
    final attendanceRecords = <AttendanceRecord>[];

    if (status == 'completed') {
      for (final artistId in artistIds) {
        // Simulate realistic attendance patterns
        String attendanceStatus;
        final random = DateTime.now().millisecond % 100;

        if (random < 80) {
          attendanceStatus = 'present';
        } else if (random < 90) {
          attendanceStatus = 'late';
        } else if (random < 95) {
          attendanceStatus = 'excused';
        } else {
          attendanceStatus = 'absent';
        }

        attendanceRecords.add(
          AttendanceRecord(
            id: '${id}_${artistId}',
            artistId: artistId,
            lessonId: id,
            date: date,
            status: attendanceStatus,
            notes: attendanceStatus == 'late' ? 'איחור של 10 דקות' : null,
            checkedInAt:
                attendanceStatus == 'present' || attendanceStatus == 'late'
                ? date.add(
                    Duration(minutes: attendanceStatus == 'late' ? 10 : 0),
                  )
                : null,
            checkedOutAt:
                attendanceStatus == 'present' || attendanceStatus == 'late'
                ? date.add(Duration(minutes: duration))
                : null,
            markedBy: instructorId,
          ),
        );
      }
    }

    return Lesson(
      id: id,
      title: title,
      date: date,
      durationMinutes: duration,
      instructorName: instructorName,
      assignedInstructorId: instructorId,
      registeredArtistIds: artistIds,
      attendanceRecords: attendanceRecords,
      maxCapacity: 15,
      status: status,
      isRecurring: isRecurring,
      recurrenceId: recurrenceId,
      instanceNumber: instanceNumber,
    );
  }

  static List<Lesson> _createRecurringLessonSeries() {
    final lessons = <Lesson>[];
    final now = DateTime.now();

    // Weekly watercolor series (8 weeks)
    final seriesStartDate = now.subtract(
      const Duration(days: 56),
    ); // 8 weeks ago
    for (int i = 0; i < 8; i++) {
      final lessonDate = seriesStartDate.add(Duration(days: i * 7));

      lessons.add(
        _createLesson(
          id: 'series_watercolor_${i + 1}',
          title: 'סדרת ציור בצבעי מים - שיעור ${i + 1}',
          date: DateTime(
            lessonDate.year,
            lessonDate.month,
            lessonDate.day,
            10,
            0,
          ),
          duration: 90,
          instructorId: 'mentor_001',
          instructorName: 'יוסי כהן',
          artistIds: ['artist_001', 'artist_002', 'artist_003', 'artist_004'],
          status: lessonDate.isBefore(now) ? 'completed' : 'scheduled',
          isRecurring: true,
          recurrenceId: 'series_watercolor',
          instanceNumber: i + 1,
        ),
      );
    }

    // Bi-weekly theater series (6 sessions)
    final theaterStartDate = now.subtract(
      const Duration(days: 70),
    ); // 10 weeks ago
    for (int i = 0; i < 6; i++) {
      final lessonDate = theaterStartDate.add(
        Duration(days: i * 14),
      ); // Every 2 weeks

      lessons.add(
        _createLesson(
          id: 'series_theater_${i + 1}',
          title: 'סדרת תיאטרון - מפגש ${i + 1}',
          date: DateTime(
            lessonDate.year,
            lessonDate.month,
            lessonDate.day,
            16,
            0,
          ),
          duration: 120,
          instructorId: 'mentor_002',
          instructorName: 'שרה לוי',
          artistIds: ['artist_005', 'artist_006', 'artist_007', 'artist_008'],
          status: lessonDate.isBefore(now) ? 'completed' : 'scheduled',
          isRecurring: true,
          recurrenceId: 'series_theater',
          instanceNumber: i + 1,
        ),
      );
    }

    return lessons;
  }

  static Future<void> _populateReports() async {
    print('📊 Creating reports...');

    final now = DateTime.now();
    final reports = [
      Report(
        id: 'report_001',
        title:
            'דוח נוכחות חודשי - ${DateFormat('MMMM yyyy', 'he').format(now)}',
        content:
            'דוח נוכחות מפורט לחודש ${DateFormat('MMMM', 'he').format(now)}',
        type: ReportType.attendance,
        createdById: 'staff_001',
        createdByName: 'אלי כהן',
        createdAt: now.subtract(const Duration(days: 2)),
        startDate: DateTime(now.year, now.month, 1),
        endDate: now,
        relatedUserIds: [
          'artist_001',
          'artist_002',
          'artist_003',
          'artist_004',
        ],
        data: {
          'totalLessons': 25,
          'totalAttendance': 85.5,
          'averageParticipants': 3.2,
        },
      ),
      Report(
        id: 'report_002',
        title: 'דוח שעות עבודה מנחים - שבוע ${DateFormat('w').format(now)}',
        content: 'סיכום שעות עבודה של כל המנחים השבוע',
        type: ReportType.workingHours,
        createdById: 'staff_002',
        createdByName: 'רחל לוי',
        createdAt: now.subtract(const Duration(days: 1)),
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
        relatedUserIds: [
          'mentor_001',
          'mentor_002',
          'mentor_003',
          'mentor_004',
        ],
        data: {
          'totalHours': 32.5,
          'averageHoursPerMentor': 8.1,
          'topMentor': 'mentor_001',
        },
      ),
      Report(
        id: 'report_003',
        title: 'דוח פעילות משתמשים - ${DateFormat('dd/MM/yyyy').format(now)}',
        content: 'ניתוח פעילות כללית של המשתמשים במערכת',
        type: ReportType.userActivity,
        createdById: 'staff_001',
        createdByName: 'אלי כהן',
        createdAt: now,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
        relatedUserIds: [
          'artist_001',
          'artist_002',
          'artist_003',
          'artist_004',
          'artist_005',
        ],
        data: {
          'activeUsers': 8,
          'totalSessions': 156,
          'averageSessionDuration': 85.5,
        },
      ),
    ];

    for (final report in reports) {
      await _firestore.collection('reports').doc(report.id).set(report.toMap());
      print('   ✅ Created report: ${report.title}');
    }

    print('📊 Created ${reports.length} reports');
  }

  static Future<void> populateWorkingHoursData() async {
    print('⏰ Creating working hours data...');

    final now = DateTime.now();
    final workingHours = <Map<String, dynamic>>[];

    // Generate working hours for mentors over the past month
    final mentorIds = ['mentor_001', 'mentor_002', 'mentor_003', 'mentor_004'];

    for (int day = 30; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));

      // Skip weekends
      if (date.weekday == 6 || date.weekday == 7) continue;

      for (final mentorId in mentorIds) {
        // Random working hours between 4-8 hours per day
        final hours = 4.0 + (DateTime.now().millisecond % 4);

        workingHours.add({
          'id': 'wh_${mentorId}_${DateFormat('yyyyMMdd').format(date)}',
          'mentorId': mentorId,
          'date': Timestamp.fromDate(date),
          'hours': hours,
          'description': 'שעות הוראה ושעות הכנה',
          'approved': day > 3, // Last 3 days not approved yet
          'createdAt': Timestamp.fromDate(date),
        });
      }
    }

    // Save working hours data
    for (final wh in workingHours) {
      await _firestore.collection('workingHours').doc(wh['id']).set(wh);
    }

    print('⏰ Created ${workingHours.length} working hours records');
  }
}
