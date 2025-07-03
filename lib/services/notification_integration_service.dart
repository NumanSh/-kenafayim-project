// import 'package:flutter/foundation.dart';
// import 'package:knafayim_app/data/models/enhanced_notification.dart';
// import 'package:knafayim_app/config/service_locator.dart';
// import '../data/models/lesson.dart';
// import '../data/models/user.dart';
// import '../data/models/attendance_record.dart';
// import '../data/repositories/lesson_repository.dart';
// import '../data/repositories/user_repository.dart';
// import '../data/repositories/attendance_repository.dart';
// import 'enhanced_notification_service.dart';

// class NotificationIntegrationService {
//   static final NotificationIntegrationService _instance =
//       NotificationIntegrationService._internal();
//   factory NotificationIntegrationService() => _instance;
//   NotificationIntegrationService._internal();

//   // Use service locator to get dependencies
//   EnhancedNotificationService get _notificationService =>
//       serviceLocator<EnhancedNotificationService>();
//   LessonRepository get _lessonRepository => serviceLocator<LessonRepository>();
//   UserRepository get _userRepository => serviceLocator<UserRepository>();
//   AttendanceRepository get _attendanceRepository =>
//       serviceLocator<AttendanceRepository>();

//   // Initialize the integration service
//   Future<void> initialize() async {
//     await _notificationService.initialize();
//     await _setupLessonListeners();
//     await _setupAttendanceListeners();
//     if (kDebugMode) {
//       print('Notification Integration Service initialized');
//     }
//   }

//   // Setup listeners for lesson changes
//   Future<void> _setupLessonListeners() async {
//     // Listen to lesson creation/updates to schedule notifications
//     // This would integrate with your existing lesson management
//   }

//   // Setup listeners for attendance changes
//   Future<void> _setupAttendanceListeners() async {
//     // Listen to attendance updates to send notifications
//     // This would integrate with your existing attendance system
//   }

//   // Lesson-related notification triggers
//   Future<void> onLessonCreated(Lesson lesson) async {
//     try {
//       // Schedule lesson reminders for all registered artists
//       await _notificationService.scheduleLessonReminders(
//         lesson,
//         lesson.registeredArtistIds,
//       );

//       // ✅ FIXED: Use assignedInstructorId instead of instructorId
//       // Notify instructor about new lesson assignment
//       if (lesson.assignedInstructorId != null &&
//           lesson.assignedInstructorId!.isNotEmpty) {
//         await _notificationService.sendRealTimeUpdate(
//           userIds: [lesson.assignedInstructorId!],
//           title: 'שיעור חדש הוקצה',
//           content:
//               'הוקצה לך שיעור חדש: ${lesson.title} ב-${_formatDateTime(lesson.date)}',
//           priority: NotificationPriority.normal,
//           data: {'lessonId': lesson.id, 'type': 'lesson_assignment'},
//         );
//       }

//       // Notify staff about new lesson
//       final staffUsers = await _getStaffUsers();
//       if (staffUsers.isNotEmpty) {
//         await _notificationService.sendRealTimeUpdate(
//           userIds: staffUsers.map((u) => u.id).toList(),
//           title: 'שיעור חדש נוצר',
//           content: 'שיעור חדש נוצר: ${lesson.title}',
//           priority: NotificationPriority.low,
//           data: {'lessonId': lesson.id, 'type': 'new_lesson'},
//         );
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error in onLessonCreated: $e');
//       }
//     }
//   }

//   Future<void> onLessonUpdated(Lesson oldLesson, Lesson newLesson) async {
//     try {
//       // Check if lesson time changed
//       if (oldLesson.date != newLesson.date) {
//         // Cancel old reminders and schedule new ones
//         await _cancelLessonReminders(oldLesson);
//         await _notificationService.scheduleLessonReminders(
//           newLesson,
//           newLesson.registeredArtistIds,
//         );

//         // ✅ FIXED: Use assignedInstructorId instead of instructorId
//         // Notify participants about time change
//         final participantIds = [...newLesson.registeredArtistIds];
//         if (newLesson.assignedInstructorId != null &&
//             newLesson.assignedInstructorId!.isNotEmpty) {
//           participantIds.add(newLesson.assignedInstructorId!);
//         }

//         await _notificationService.sendRealTimeUpdate(
//           userIds: participantIds,
//           title: 'שינוי זמן שיעור',
//           content:
//               'זמן השיעור ${newLesson.title} שונה ל-${_formatDateTime(newLesson.date)}',
//           priority: NotificationPriority.high,
//           data: {'lessonId': newLesson.id, 'type': 'lesson_time_change'},
//         );
//       }

//       // Check if participants changed
//       final addedParticipants = newLesson.registeredArtistIds
//           .where((id) => !oldLesson.registeredArtistIds.contains(id))
//           .toList();

//       final removedParticipants = oldLesson.registeredArtistIds
//           .where((id) => !newLesson.registeredArtistIds.contains(id))
//           .toList();

//       // Schedule reminders for new participants
//       if (addedParticipants.isNotEmpty) {
//         await _notificationService.scheduleLessonReminders(
//           newLesson,
//           addedParticipants,
//         );

//         // Welcome notification for new participants
//         for (final artistId in addedParticipants) {
//           await _notificationService.sendRealTimeUpdate(
//             userIds: [artistId],
//             title: 'נרשמת לשיעור חדש! 🎨',
//             content:
//                 'נרשמת לשיעור ${newLesson.title} ב-${_formatDateTime(newLesson.date)}',
//             priority: NotificationPriority.normal,
//             data: {'lessonId': newLesson.id, 'type': 'lesson_registration'},
//           );
//         }
//       }

//       // Cancel reminders for removed participants
//       for (final artistId in removedParticipants) {
//         await _cancelUserLessonReminders(newLesson.id, artistId);
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error in onLessonUpdated: $e');
//       }
//     }
//   }

//   Future<void> onLessonCancelled(Lesson lesson) async {
//     try {
//       // Cancel all reminders
//       await _cancelLessonReminders(lesson);

//       // ✅ FIXED: Use assignedInstructorId instead of instructorId
//       // Notify all participants about cancellation
//       final allParticipants = [...lesson.registeredArtistIds];
//       if (lesson.assignedInstructorId != null &&
//           lesson.assignedInstructorId!.isNotEmpty) {
//         allParticipants.add(lesson.assignedInstructorId!);
//       }

//       await _notificationService.sendRealTimeUpdate(
//         userIds: allParticipants,
//         title: 'שיעור בוטל ❌',
//         content:
//             'השיעור ${lesson.title} ב-${_formatDateTime(lesson.date)} בוטל',
//         priority: NotificationPriority.high,
//         data: {'lessonId': lesson.id, 'type': 'lesson_cancelled'},
//       );
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error in onLessonCancelled: $e');
//       }
//     }
//   }

//   // Attendance-related notification triggers
//   Future<void> onLessonStarted(Lesson lesson) async {
//     try {
//       // Send attendance requests to all registered artists
//       for (final artistId in lesson.registeredArtistIds) {
//         await _notificationService.sendAttendanceRequest(lesson, artistId);
//       }

//       // Set up auto-reminder for missing attendance (30 minutes after lesson start)
//       Future.delayed(const Duration(minutes: 30), () async {
//         await _checkAndSendMissingAttendanceAlerts(lesson);
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error in onLessonStarted: $e');
//       }
//     }
//   }

//   Future<void> onAttendanceMarked(AttendanceRecord attendance) async {
//     try {
//       final lesson = await _lessonRepository.getLessonById(attendance.lessonId);
//       if (lesson == null) return;

//       // ✅ FIXED: Use assignedInstructorId and proper attendance properties
//       // Notify instructor about attendance confirmation
//       if (lesson.assignedInstructorId != null &&
//           lesson.assignedInstructorId!.isNotEmpty) {
//         final artist = await _userRepository.getUserById(attendance.artistId);
//         if (artist != null) {
//           // ✅ FIXED: Use proper attendance status check
//           final statusText = attendance.status == 'present' ? 'נוכח' : 'נעדר';
//           await _notificationService.sendRealTimeUpdate(
//             userIds: [lesson.assignedInstructorId!],
//             title: 'עדכון נוכחות',
//             content: '${artist.name} סומן כ$statusText בשיעור ${lesson.title}',
//             priority: NotificationPriority.low,
//             data: {
//               'lessonId': lesson.id,
//               'artistId': attendance.artistId,
//               'status': attendance.status.toString(),
//               'type': 'attendance_update',
//             },
//           );
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error in onAttendanceMarked: $e');
//       }
//     }
//   }

//   Future<void> _checkAndSendMissingAttendanceAlerts(Lesson lesson) async {
//     try {
//       // ✅ FIXED: Use the lesson's attendance records directly
//       // Get attendance records from the lesson object
//       final attendanceRecords = lesson.attendanceRecords;
//       final markedUserIds = attendanceRecords.map((a) => a.artistId).toSet();

//       // Find users who haven't marked attendance
//       final missingAttendanceUserIds = lesson.registeredArtistIds
//           .where((userId) => !markedUserIds.contains(userId))
//           .toList();

//       // ✅ FIXED: Use assignedInstructorId instead of instructorId
//       // Send alerts to instructor about missing attendance
//       if (missingAttendanceUserIds.isNotEmpty &&
//           lesson.assignedInstructorId != null &&
//           lesson.assignedInstructorId!.isNotEmpty) {
//         for (final artistId in missingAttendanceUserIds) {
//           await _notificationService.sendAttendanceMissingAlert(
//             lesson,
//             artistId,
//             lesson.assignedInstructorId!,
//           );
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error in _checkAndSendMissingAttendanceAlerts: $e');
//       }
//     }
//   }

//   // Recurring series notifications
//   Future<void> onSeriesCompleted(String userId, String seriesName) async {
//     try {
//       await _notificationService.sendSeriesCompleteNotification(
//         userId,
//         seriesName,
//       );
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error in onSeriesCompleted: $e');
//       }
//     }
//   }

//   Future<void> onSeriesUpdated(
//     List<String> participantIds,
//     String seriesName,
//     String updateMessage,
//   ) async {
//     try {
//       await _notificationService.sendSeriesUpdateNotification(
//         userIds: participantIds,
//         seriesName: seriesName,
//         updateMessage: updateMessage,
//       );
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error in onSeriesUpdated: $e');
//       }
//     }
//   }

//   // User registration notifications
//   Future<void> onUserRegistered(User newUser) async {
//     try {
//       final staffUsers = await _getStaffUsers();
//       if (staffUsers.isNotEmpty) {
//         await _notificationService.sendRealTimeUpdate(
//           userIds: staffUsers.map((u) => u.id).toList(),
//           title: 'משתמש חדש נרשם',
//           content:
//               'משתמש חדש נרשם: ${newUser.name} (${newUser.role.toString().split('.').last})',
//           priority: NotificationPriority.normal,
//           data: {'userId': newUser.id, 'type': 'new_user_registration'},
//         );
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error in onUserRegistered: $e');
//       }
//     }
//   }

//   // Emergency notifications
//   Future<void> sendEmergencyAlert(
//     String message, {
//     List<UserRole>? targetRoles,
//   }) async {
//     try {
//       List<String> targetUserIds;

//       if (targetRoles != null) {
//         final users = await _getUsersByRoles(targetRoles);
//         targetUserIds = users.map((u) => u.id).toList();
//       } else {
//         final allUsers = await _getAllUsers();
//         targetUserIds = allUsers.map((u) => u.id).toList();
//       }

//       await _notificationService.sendEmergencyNotification(
//         userIds: targetUserIds,
//         message: message,
//       );
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error in sendEmergencyAlert: $e');
//       }
//     }
//   }

//   // Helper methods
//   Future<void> _cancelLessonReminders(Lesson lesson) async {
//     // Implementation to cancel scheduled notifications
//     // This would interact with your notification repository
//     try {
//       // Cancel notifications for this lesson
//       // This is a placeholder - you'd implement the actual cancellation logic
//       if (kDebugMode) {
//         print('Cancelling reminders for lesson: ${lesson.id}');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error cancelling lesson reminders: $e');
//       }
//     }
//   }

//   Future<void> _cancelUserLessonReminders(
//     String lessonId,
//     String userId,
//   ) async {
//     // Implementation to cancel specific user's lesson reminders
//     try {
//       // Cancel specific user's notifications for this lesson
//       // This is a placeholder - you'd implement the actual cancellation logic
//       if (kDebugMode) {
//         print('Cancelling reminders for user $userId, lesson: $lessonId');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error cancelling user lesson reminders: $e');
//       }
//     }
//   }

//   Future<List<User>> _getStaffUsers() async {
//     try {
//       return await _userRepository.getUsersByRole(UserRole.staff);
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error getting staff users: $e');
//       }
//       return [];
//     }
//   }

//   Future<List<User>> _getUsersByRoles(List<UserRole> roles) async {
//     try {
//       final users = <User>[];
//       for (final role in roles) {
//         final roleUsers = await _userRepository.getUsersByRole(role);
//         users.addAll(roleUsers);
//       }
//       return users;
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error getting users by roles: $e');
//       }
//       return [];
//     }
//   }

//   Future<List<User>> _getAllUsers() async {
//     try {
//       return await _userRepository.getAllUsers();
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error getting all users: $e');
//       }
//       return [];
//     }
//   }

//   String _formatDateTime(DateTime dateTime) {
//     return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
//   }
// }
