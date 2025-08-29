// import 'package:flutter/material.dart';
// import '../../../data/models/lesson.dart';
// import '../../../data/models/user.dart';
// import '../../../data/repositories/lesson_repository.dart';
// import '../../../data/repositories/user_repository.dart';
// import '../../../config/service_locator.dart';
// import 'lesson_management_screen.dart';
// import 'add_lesson_screen.dart';

// class LessonsListScreen extends StatefulWidget {
//   const LessonsListScreen({Key? key}) : super(key: key);

//   @override
//   _LessonsListScreenState createState() => _LessonsListScreenState();
// }

// class _LessonsListScreenState extends State<LessonsListScreen> {
//   final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
//   final UserRepository _userRepository = serviceLocator<UserRepository>();
//   List<Lesson> _allLessons = [];
//   bool _isLoading = true;

//   // Cache for artist names to avoid repeated fetches
//   final Map<String, String> _artistNamesCache = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadLessons();
//   }

//   Future<void> _loadLessons() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       final lessons = await _lessonRepository.getAllLessonsForStaff();
//       if (mounted) {
//         setState(() {
//           _allLessons = lessons;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('שגיאה בטעינת שיעורים: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _confirmDeleteLesson(Lesson lesson) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('מחיקת שיעור'),
//         content: Text(
//             'האם אתה בטוח שברצונך למחוק את השיעור "${lesson.title}"? פעולה זו אינה ניתנת לביטול.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('ביטול'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('מחק'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       _deleteLesson(lesson.id);
//     }
//   }

//   Future<void> _deleteLesson(String lessonId) async {
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       final success = await _lessonRepository.deleteLesson(lessonId);
//       if (mounted) {
//         if (success) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('השיעור נמחק בהצלחה')),
//           );
//           _loadLessons(); // Refresh the list
//         } else {
//           setState(() {
//             _isLoading = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('שגיאה במחיקת השיעור'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('שגיאה במחיקת השיעור: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _navigateToLessonManagement(Lesson lesson) async {
//     final result = await Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => LessonManagementScreen(lesson: lesson),
//       ),
//     );

//     if (result == true) {
//       _loadLessons();
//     }
//   }

//   Future<void> _navigateToAddLesson() async {
//     final result = await Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => const AddLessonScreen(),
//       ),
//     );

//     if (result == true) {
//       _loadLessons();
//     }
//   }

//   // Function to get registered artists names as a comma-separated string
//   Future<String> _getRegisteredArtistsNames(List<String> artistIds) async {
//     if (artistIds.isEmpty) {
//       return '';
//     }

//     List<String> names = [];

//     for (String artistId in artistIds) {
//       // Check if name is already in cache
//       if (_artistNamesCache.containsKey(artistId)) {
//         names.add(_artistNamesCache[artistId]!);
//       } else {
//         try {
//           // Fetch artist name from repository
//           User? artist = await _userRepository.getUserById(artistId);
//           _artistNamesCache[artistId] = artist!.name; // Cache the name
//           names.add(artist.name);
//         } catch (e) {
//           print('Error fetching artist $artistId: $e');
//           _artistNamesCache[artistId] = 'אמן לא ידוע'; // Cache error state
//           names.add('אמן לא ידוע');
//         }
//       }
//     }

//     return names.join(', ');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('ניהול שיעורים'),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadLessons,
//         child: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : _allLessons.isEmpty
//                 ? const Center(child: Text('אין שיעורים להצגה'))
//                 : ListView.builder(
//                     padding: const EdgeInsets.all(16.0),
//                     itemCount: _allLessons.length,
//                     itemBuilder: (context, index) {
//                       final lesson = _allLessons[index];
//                       return Card(
//                         margin: const EdgeInsets.only(bottom: 16.0),
//                         elevation: 2,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Column(
//                           children: [
//                             ListTile(
//                               contentPadding: const EdgeInsets.all(16.0),
//                               leading: Container(
//                                 width: 48,
//                                 height: 48,
//                                 decoration: BoxDecoration(
//                                   color: Theme.of(context)
//                                       .primaryColor
//                                       .withOpacity(0.2),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Center(
//                                   child: Icon(
//                                     Icons.school,
//                                     color: Theme.of(context).primaryColor,
//                                   ),
//                                 ),
//                               ),
//                               title: Text(
//                                 lesson.title,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                               subtitle: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const SizedBox(height: 8),
//                                   Text(
//                                       'מנחה: ${lesson.instructorName ?? 'לא שויך'}'),
//                                   Text(
//                                       'תאריך: ${lesson.date.day}/${lesson.date.month}/${lesson.date.year}'),
//                                   Text(
//                                       'שעה: ${lesson.date.hour}:${lesson.date.minute.toString().padLeft(2, '0')}'),
//                                   Text('סטטוס: ${lesson.status}'),
//                                   Text(
//                                       'נרשמו: ${lesson.registeredArtistIds.length}${lesson.maxCapacity != null ? '/${lesson.maxCapacity}' : ''}'),
//                                   const SizedBox(height: 8),
//                                   Row(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       const Text(
//                                         'אמנים רשומים: ',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold),
//                                       ),
//                                       Expanded(
//                                         child: FutureBuilder<String>(
//                                           future: _getRegisteredArtistsNames(
//                                               lesson.registeredArtistIds),
//                                           builder: (context, snapshot) {
//                                             if (snapshot.connectionState ==
//                                                 ConnectionState.waiting) {
//                                               return const Text(
//                                                   'טוען שמות אמנים...');
//                                             } else if (snapshot.hasError) {
//                                               return Text(
//                                                   'שגיאה בטעינת שמות: ${snapshot.error}');
//                                             } else if (!snapshot.hasData ||
//                                                 snapshot.data!.isEmpty) {
//                                               return const Text(
//                                                   'אין אמנים רשומים');
//                                             } else {
//                                               return Text(snapshot.data!);
//                                             }
//                                           },
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                               trailing: const Icon(Icons.edit_note, size: 24),
//                               onTap: () => _navigateToLessonManagement(lesson),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.only(
//                                   right: 16.0, left: 16.0, bottom: 16.0),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.end,
//                                 children: [
//                                   TextButton.icon(
//                                     icon: const Icon(Icons.delete,
//                                         color: Colors.red),
//                                     label: const Text('מחק שיעור',
//                                         style: TextStyle(color: Colors.red)),
//                                     onPressed: () =>
//                                         _confirmDeleteLesson(lesson),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _navigateToAddLesson,
//         tooltip: 'הוסף שיעור',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
