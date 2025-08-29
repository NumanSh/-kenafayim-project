// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../data/models/user.dart';
// import '../../utils/calendar_permissions.dart';

// class ResponsiveCalendarView extends ConsumerStatefulWidget {
//   final User user;

//   const ResponsiveCalendarView({Key? key, required this.user})
//     : super(key: key);

//   @override
//   ConsumerState<ResponsiveCalendarView> createState() =>
//       _ResponsiveCalendarViewState();
// }

// class _ResponsiveCalendarViewState
//     extends ConsumerState<ResponsiveCalendarView> {
//   late DateTime _focusedDay;
//   late DateTime _selectedDay;
//   CalendarFormat _calendarFormat = CalendarFormat.month;
//   late CalendarPermissions _permissions;

//   @override
//   void initState() {
//     super.initState();
//     _focusedDay = DateTime.now();
//     _selectedDay = DateTime.now();
//     _permissions = CalendarPermissions(widget.user);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isTablet = screenWidth > 600;
//     final padding = screenWidth * 0.04; // 4% responsive padding

//     return Scaffold(
//       backgroundColor: const Color(0xFFf8fafc),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Calendar Header
//             _buildCalendarHeader(context, isTablet),

//             // Responsive Calendar Card
//             Expanded(
//               flex: isTablet ? 7 : 6, // More space on tablets
//               child: _buildResponsiveCalendarCard(
//                 context,
//                 screenHeight,
//                 screenWidth,
//                 padding,
//               ),
//             ),

//             // Events List
//             Expanded(
//               flex: isTablet ? 5 : 4,
//               child: _buildEventsList(context, padding),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: _buildFloatingActionButton(),
//     );
//   }

//   Widget _buildCalendarHeader(BuildContext context, bool isTablet) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: MediaQuery.of(context).size.width * 0.04,
//         vertical: 12,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.9),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             _permissions.appBarTitle,
//             style: TextStyle(
//               fontSize: isTablet ? 24 : 20,
//               fontWeight: FontWeight.w600,
//               color: const Color(0xFF1f2937),
//             ),
//           ),
//           Row(
//             children: [
//               IconButton(
//                 onPressed: () {
//                   // Refresh functionality
//                 },
//                 icon: const Icon(Icons.refresh, color: Color(0xFF3b82f6)),
//               ),
//               IconButton(
//                 onPressed: () {
//                   setState(() {
//                     _focusedDay = DateTime.now();
//                     _selectedDay = DateTime.now();
//                   });
//                 },
//                 icon: const Icon(Icons.today, color: Color(0xFF3b82f6)),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResponsiveCalendarCard(
//     BuildContext context,
//     double screenHeight,
//     double screenWidth,
//     double padding,
//   ) {
//     final isTablet = screenWidth > 600;

//     return Container(
//       margin: EdgeInsets.all(padding),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(isTablet ? 20 : 16),
//         child: TableCalendar<dynamic>(
//           locale: 'he_IL',
//           firstDay: DateTime.utc(2020, 1, 1),
//           lastDay: DateTime.utc(2030, 12, 31),
//           focusedDay: _focusedDay,
//           selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//           calendarFormat: _calendarFormat,

//           // ✅ Responsive sizing fixes
//           rowHeight: isTablet ? 65 : 55, // Responsive row height
//           daysOfWeekHeight: isTablet ? 35 : 30, // ✅ Fixes day headers cutoff

//           headerStyle: HeaderStyle(
//             formatButtonVisible: true,
//             titleCentered: true,
//             formatButtonShowsNext: false,
//             formatButtonDecoration: BoxDecoration(
//               color: const Color(0xFF3b82f6),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             formatButtonTextStyle: const TextStyle(
//               color: Colors.white,
//               fontSize: 12,
//             ),
//             titleTextStyle: TextStyle(
//               fontSize: isTablet ? 18 : 16,
//               fontWeight: FontWeight.w600,
//             ),
//             leftChevronIcon: const Icon(
//               Icons.chevron_left,
//               color: Color(0xFF3b82f6),
//             ),
//             rightChevronIcon: const Icon(
//               Icons.chevron_right,
//               color: Color(0xFF3b82f6),
//             ),
//           ),

//           daysOfWeekStyle: DaysOfWeekStyle(
//             weekdayStyle: TextStyle(
//               color: const Color(0xFF6b7280),
//               fontSize: isTablet ? 14 : 12,
//               fontWeight: FontWeight.w500,
//             ),
//             weekendStyle: TextStyle(
//               color: const Color(0xFFef4444),
//               fontSize: isTablet ? 14 : 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),

//           calendarStyle: CalendarStyle(
//             outsideDaysVisible: false,
//             weekendTextStyle: const TextStyle(color: Color(0xFFef4444)),

//             // ✅ Responsive cell styling
//             cellMargin: EdgeInsets.all(isTablet ? 6 : 4),
//             cellPadding: EdgeInsets.all(isTablet ? 8 : 6),

//             defaultDecoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
//             ),

//             selectedDecoration: BoxDecoration(
//               color: const Color(0xFF3b82f6),
//               borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
//             ),

//             todayDecoration: BoxDecoration(
//               color: const Color(0xFF93c5fd),
//               borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
//             ),

//             markerDecoration: const BoxDecoration(
//               color: Color(0xFF059669),
//               shape: BoxShape.circle,
//             ),

//             markersMaxCount: 3,
//             markersOffset: PositionedOffset(
//               bottom: isTablet ? 6 : 4,
//             ), // ✅ Responsive marker position
//           ),

//           eventLoader: (day) => _getEventsForDay(day),

//           onDaySelected: (selectedDay, focusedDay) {
//             setState(() {
//               _selectedDay = selectedDay;
//               _focusedDay = focusedDay;
//             });
//           },

//           onFormatChanged: (format) {
//             setState(() {
//               _calendarFormat = format;
//             });
//           },

//           onPageChanged: (focusedDay) {
//             _focusedDay = focusedDay;
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildEventsList(BuildContext context, double padding) {
//     final events = _getEventsForDay(_selectedDay);
//     final isTablet = MediaQuery.of(context).size.width > 600;

//     if (events.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.event_note,
//               size: isTablet ? 80 : 64,
//               color: const Color(0xFF6b7280).withOpacity(0.5),
//             ),
//             SizedBox(height: isTablet ? 20 : 16),
//             Text(
//               _permissions.emptyStateMessage,
//               style: TextStyle(
//                 fontSize: isTablet ? 18 : 16,
//                 fontWeight: FontWeight.w500,
//                 color: const Color(0xFF6b7280),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }

//     return Padding(
//       padding: EdgeInsets.all(padding),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'אירועים ליום ${_selectedDay.day}/${_selectedDay.month}',
//             style: TextStyle(
//               fontSize: isTablet ? 20 : 18,
//               fontWeight: FontWeight.w600,
//               color: const Color(0xFF1f2937),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Expanded(
//             child: ListView.builder(
//               itemCount: events.length,
//               itemBuilder: (context, index) =>
//                   _buildEventCard(events[index], isTablet),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEventCard(dynamic event, bool isTablet) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ListTile(
//         contentPadding: EdgeInsets.all(isTablet ? 16 : 12),
//         leading: Container(
//           width: isTablet ? 16 : 12,
//           height: isTablet ? 16 : 12,
//           decoration: const BoxDecoration(
//             color: Color(0xFF3b82f6),
//             shape: BoxShape.circle,
//           ),
//         ),
//         title: Text(
//           'שיעור לדוגמה', // Replace with actual event title
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: isTablet ? 16 : 14,
//             color: const Color(0xFF1f2937),
//           ),
//         ),
//         subtitle: Text(
//           'תיאור קצר של השיעור', // Replace with actual event description
//           style: TextStyle(
//             color: const Color(0xFF6b7280),
//             fontSize: isTablet ? 14 : 12,
//           ),
//         ),
//         trailing: Text(
//           '10:00', // Replace with actual event time
//           style: TextStyle(
//             color: const Color(0xFF3b82f6),
//             fontWeight: FontWeight.w500,
//             fontSize: isTablet ? 14 : 12,
//           ),
//         ),
//       ),
//     );
//   }

//   List<dynamic> _getEventsForDay(DateTime day) {
//     // Mock events - replace with actual data
//     if (day.day == 11) {
//       return ['שיעור ציור', 'שיעור מוזיקה'];
//     }
//     return [];
//   }

//   Widget? _buildFloatingActionButton() {
//     if (!_permissions.canCreateEvents) return null;

//     return FloatingActionButton(
//       onPressed: () {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('יצירת אירוע - בפיתוח')));
//       },
//       backgroundColor: const Color(0xFF3b82f6),
//       child: const Icon(Icons.add, color: Colors.white),
//     );
//   }
// }
