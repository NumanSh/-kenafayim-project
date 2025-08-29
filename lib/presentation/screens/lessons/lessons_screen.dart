// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // For date formatting
// import '../../../data/models/lesson.dart';
// import '../../../data/models/user.dart';
// import '../../../data/repositories/lesson_repository.dart';
// import '../../../services/auth_service.dart';
// import '../../../config/service_locator.dart';
// import './add_lesson_screen.dart';
// import './lesson_management_screen.dart';
// import './lesson_details_screen_for_client.dart';
// import './lesson_details_screen_for_instructor.dart';

// class LessonsScreen extends StatefulWidget {
//   const LessonsScreen({super.key});

//   @override
//   // ignore: library_private_types_in_public_api
//   _LessonsScreenState createState() => _LessonsScreenState();
// }

// class _LessonsScreenState extends State<LessonsScreen>
//     with TickerProviderStateMixin {
//   final AuthService _authService = serviceLocator<AuthService>();
//   final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
//   User? _currentUser;
//   UserRole? _currentUserRole;
//   bool _isLoading = true;

//   List<Lesson> _lessons =
//       []; // For Staff and Mentor, or Client's registered lessons
//   List<Lesson> _availableLessonsForClient =
//       []; // For Client's available lessons tab

//   TabController? _clientTabController;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserDataAndLessons();
//   }

//   Future<void> _loadUserDataAndLessons() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoading = true;
//     });
//     _currentUser = await _authService.getCurrentUser(); // MODIFIED HERE
//     _currentUserRole = _currentUser?.role;

//     if (_currentUserRole == null) {
//       // MODIFIED BLOCK START
//       if (kDebugMode) {
//         print(
//           "LessonsScreen: _currentUserRole is null during _loadUserDataAndLessons.",
//         );
//       }
//       if (_currentUser == null) {
//         if (kDebugMode) {
//           print("LessonsScreen: _authService.getCurrentUser() returned null.");
//         }
//       } else {
//         if (kDebugMode) {
//           print(
//             "LessonsScreen: _currentUser is not null, but _currentUser.role is null. User ID: ${_currentUser!.id}, User Role from object: ${_currentUser!.role}",
//           );
//         }
//       }
//       // MODIFIED BLOCK END
//       setState(() {
//         _isLoading = false;
//       });
//       return;
//     }

//     try {
//       if (_currentUserRole == UserRole.staff) {
//         _lessons = await _lessonRepository.getAllLessonsForStaff();
//         if (kDebugMode) {
//           print("LessonsScreen: Loaded ${_lessons.length} lessons for staff");
//         }
//       } else if (_currentUserRole == UserRole.mentor) {
//         _lessons = await _lessonRepository.getLessonsForMentor(
//           _currentUser!.id,
//         );
//       } else if (_currentUserRole == UserRole.client) {
//         _lessons = await _lessonRepository.getLessonsForArtist(
//           _currentUser!.id,
//           startDate: DateTime.now().subtract(
//             const Duration(days: 365),
//           ), // Example: 1 year ago
//           endDate: DateTime.now().add(
//             const Duration(days: 365),
//           ), // Example: 1 year ahead
//         );
//         _availableLessonsForClient = await _lessonRepository
//             .getAvailableLessonsForArtist(_currentUser!.id);
//         _clientTabController = TabController(length: 2, vsync: this);
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("Error loading lessons: $e");
//       }
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("שגיאה בטעינת השיעורים: $e")));
//       }
//     }

//     if (mounted) {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _clientTabController?.dispose();
//     super.dispose();
//   }

//   Future<void> _refreshLessons() async {
//     await _loadUserDataAndLessons();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('לוח שיעורים'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _isLoading ? null : _refreshLessons,
//             tooltip: "רענן",
//           ),
//         ],
//         bottom:
//             _currentUserRole == UserRole.client && _clientTabController != null
//             ? TabBar(
//                 controller: _clientTabController,
//                 tabs: const [
//                   Tab(text: 'שיעורים זמינים'),
//                   Tab(text: 'השיעורים שלי'),
//                 ],
//               )
//             : null,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _buildLessonsViewForRole(),
//       floatingActionButton: _currentUserRole == UserRole.staff
//           ? FloatingActionButton(
//               onPressed: () async {
//                 final result = await Navigator.of(context).push(
//                   MaterialPageRoute(
//                     builder: (context) => AddLessonScreen(user: _currentUser!),
//                   ),
//                 );
//                 if (result == true) {
//                   _refreshLessons();
//                 }
//               },
//               tooltip: 'הוסף שיעור חדש',
//               child: const Icon(Icons.add),
//             )
//           : null,
//     );
//   }

//   Widget _buildLessonsViewForRole() {
//     if (_currentUserRole == null) {
//       return const Center(
//         child: Text("לא ניתן לטעון שיעורים. תפקיד משתמש לא ידוע."),
//       );
//     }
//     switch (_currentUserRole!) {
//       case UserRole.staff:
//         return _buildStaffLessonsView(_lessons);
//       case UserRole.mentor:
//         return _buildMentorLessonsView(_lessons);
//       case UserRole.client:
//         if (_clientTabController == null) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         return TabBarView(
//           controller: _clientTabController,
//           children: [
//             _buildClientAvailableLessonsView(_availableLessonsForClient),
//             _buildClientRegisteredLessonsView(_lessons),
//           ],
//         );
//     }
//   }

//   Widget _buildLessonList(
//     List<Lesson> lessons,
//     UserRole role, {
//     bool isAvailableForClient = false,
//   }) {
//     if (lessons.isEmpty) {
//       String message = "אין שיעורים להצגה.";
//       if (role == UserRole.mentor) message = "אין לך שיעורים משויכים כרגע.";
//       if (role == UserRole.client && !isAvailableForClient) {
//         message = "אינך רשום/ה לשיעורים כרגע.";
//       }
//       if (role == UserRole.client && isAvailableForClient) {
//         message = "אין שיעורים זמינים כרגע.";
//       }
//       return Center(child: Text(message));
//     }

//     return ListView.builder(
//       itemCount: lessons.length,
//       itemBuilder: (context, index) {
//         final lesson = lessons[index];
//         String subtitleText = "";
//         Widget? trailingWidget = const Icon(Icons.arrow_forward_ios);
//         VoidCallback? onTapAction;

//         if (role == UserRole.staff) {
//           int presentCount = lesson.attendanceRecords
//               .where((ar) => ar.status == "present")
//               .length;
//           String attendanceSummary = "";
//           if (lesson.status == "scheduled" || lesson.status == "completed") {
//             if (lesson.date.isBefore(DateTime.now()) ||
//                 lesson.status == "completed") {
//               attendanceSummary =
//                   "נוכחות: $presentCount/${lesson.registeredArtistIds.length}";
//             } else {
//               attendanceSummary =
//                   "רשומים: ${lesson.registeredArtistIds.length}${lesson.maxCapacity != null ? '/${lesson.maxCapacity}' : ''}";
//             }
//           } else if (lesson.status == "cancelled") {
//             attendanceSummary = "בוטל";
//           }

//           subtitleText =
//               "תאריך: ${DateFormat('dd/MM/yy HH:mm', 'he_IL').format(lesson.date)}\n"
//               "מנחה: ${lesson.instructorName ?? 'טרם שויך'}\n"
//               "$attendanceSummary";
//           onTapAction = () async {
//             final result = await Navigator.of(context).push(
//               MaterialPageRoute(
//                 builder: (context) => LessonManagementScreen(lesson: lesson),
//               ),
//             );
//             if (result == true) _refreshLessons();
//           };
//         } else if (role == UserRole.mentor) {
//           subtitleText =
//               "תאריך: ${DateFormat('dd/MM/yy HH:mm', 'he_IL').format(lesson.date)}\n"
//               "רשומים: ${lesson.registeredArtistIds.length}";
//           if (lesson.status == "cancelled") subtitleText += "\nבוטל";
//           onTapAction = () async {
//             if (lesson.status == "cancelled") {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("לא ניתן לגשת לשיעור מבוטל.")),
//               );
//               return;
//             }
//             final result = await Navigator.of(context).push(
//               MaterialPageRoute(
//                 builder: (context) =>
//                     LessonDetailsScreenForInstructor(lesson: lesson),
//               ),
//             );
//             if (result == true) _refreshLessons();
//           };
//         } else if (role == UserRole.client) {
//           subtitleText =
//               "תאריך: ${DateFormat('dd/MM/yy HH:mm', 'he_IL').format(lesson.date)}\n"
//               "מנחה: ${lesson.instructorName ?? 'טרם שויך'}";
//           if (isAvailableForClient) {
//             subtitleText +=
//                 "\nמקומות פנויים: ${lesson.maxCapacity != null ? lesson.maxCapacity! - lesson.registeredArtistIds.length : 'לא מוגבל'}";
//           }
//           if (lesson.status == "cancelled") subtitleText += "\nבוטל";
//           onTapAction = () async {
//             if (lesson.status == "cancelled") {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("לא ניתן לגשת לשיעור מבוטל.")),
//               );
//               return;
//             }
//             final result = await Navigator.of(context).push(
//               MaterialPageRoute(
//                 builder: (context) =>
//                     LessonDetailsScreenForClient(lesson: lesson),
//               ),
//             );
//             if (result == true) _refreshLessons();
//           };
//         }

//         return Card(
//           margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           child: ListTile(
//             title: Text(
//               lesson.title,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             subtitle: Text(subtitleText),
//             isThreeLine:
//                 role == UserRole.staff ||
//                 (role == UserRole.client &&
//                     isAvailableForClient), // Adjust based on content
//             trailing: trailingWidget,
//             onTap: onTapAction,
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildStaffLessonsView(List<Lesson> lessonsToDisplay) {
//     // TODO: Add filtering UI for staff (upcoming, past, cancelled, by instructor)
//     return _buildLessonList(lessonsToDisplay, UserRole.staff);
//   }

//   Widget _buildMentorLessonsView(List<Lesson> lessonsToDisplay) {
//     // TODO: Add filtering UI for mentor (upcoming, past)
//     return _buildLessonList(lessonsToDisplay, UserRole.mentor);
//   }

//   Widget _buildClientAvailableLessonsView(List<Lesson> lessonsToDisplay) {
//     return _buildLessonList(
//       lessonsToDisplay,
//       UserRole.client,
//       isAvailableForClient: true,
//     );
//   }

//   Widget _buildClientRegisteredLessonsView(List<Lesson> lessonsToDisplay) {
//     return _buildLessonList(
//       lessonsToDisplay,
//       UserRole.client,
//       isAvailableForClient: false,
//     );
//   }
// }
