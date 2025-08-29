// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../../data/models/calendar_event.dart';
// import '../../../data/models/user.dart';
// import '../../../data/repositories/calendar_repository.dart';
// import '../../../data/repositories/user_repository.dart';
// import '../../../config/service_locator.dart';
// import '../../../services/auth_service.dart';
// import '../../widgets/common/app_logo.dart';

// class EventCreationScreen extends StatefulWidget {
//   final DateTime selectedDate;
//   final CalendarEvent? eventToEdit;

//   const EventCreationScreen({
//     super.key,
//     required this.selectedDate,
//     this.eventToEdit,
//   });

//   @override
//   State<EventCreationScreen> createState() => _EventCreationScreenState();
// }

// class _EventCreationScreenState extends State<EventCreationScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _locationController = TextEditingController();

//   final CalendarRepository _calendarRepository =
//       serviceLocator<CalendarRepository>();
//   final UserRepository _userRepository = serviceLocator<UserRepository>();
//   final AuthService _authService = serviceLocator<AuthService>();

//   User? _currentUser;
//   List<User> _availableUsers = [];
//   List<String> _selectedParticipants = [];

//   DateTime _startDate = DateTime.now();
//   TimeOfDay _startTime = TimeOfDay.now();
//   DateTime _endDate = DateTime.now();
//   TimeOfDay _endTime = TimeOfDay.now();
//   EventType _selectedEventType = EventType.meeting;

//   bool _isLoading = false;
//   bool _isRecurring = false;
//   RecurrenceType _recurrenceType = RecurrenceType.daily;
//   int _recurrenceInterval = 1;
//   DateTime? _recurrenceEndDate;

//   @override
//   void initState() {
//     super.initState();
//     _initializeScreen();
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _locationController.dispose();
//     super.dispose();
//   }

//   Future<void> _initializeScreen() async {
//     _currentUser = await _authService.getCurrentUser();

//     if (widget.eventToEdit != null) {
//       _loadEventData();
//     } else {
//       _setDefaultDateTime();
//     }

//     await _loadAvailableUsers();
//   }

//   void _setDefaultDateTime() {
//     _startDate = widget.selectedDate;
//     _endDate = widget.selectedDate;

//     // Set default times
//     final now = DateTime.now();
//     if (widget.selectedDate.day == now.day &&
//         widget.selectedDate.month == now.month &&
//         widget.selectedDate.year == now.year) {
//       // If today, start from next hour
//       final nextHour = now.hour + 1;
//       _startTime = TimeOfDay(hour: nextHour > 23 ? 23 : nextHour, minute: 0);
//       _endTime = TimeOfDay(
//         hour: nextHour + 1 > 23 ? 23 : nextHour + 1,
//         minute: 0,
//       );
//     } else {
//       // Default to 9 AM - 10 AM
//       _startTime = const TimeOfDay(hour: 9, minute: 0);
//       _endTime = const TimeOfDay(hour: 10, minute: 0);
//     }
//   }

//   void _loadEventData() {
//     final event = widget.eventToEdit!;
//     _titleController.text = event.title;
//     _descriptionController.text = event.description;
//     _locationController.text = event.locationOrLink ?? '';

//     _startDate = event.startTime;
//     _startTime = TimeOfDay.fromDateTime(event.startTime);
//     _endDate = event.endTime;
//     _endTime = TimeOfDay.fromDateTime(event.endTime);
//     _selectedEventType = event.type;
//     _selectedParticipants = List.from(event.participantIds);
//   }

//   Future<void> _loadAvailableUsers() async {
//     try {
//       final users = await _userRepository.getAllUsers();
//       setState(() {
//         _availableUsers = users;
//         if (_currentUser != null &&
//             !_selectedParticipants.contains(_currentUser!.id)) {
//           _selectedParticipants.add(_currentUser!.id);
//         }
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('שגיאה בטעינת משתמשים: $e')));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFf8fafc),
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildHeader(),
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildEventTypeSelector(),
//                         const SizedBox(height: 24),
//                         _buildBasicInfoSection(),
//                         const SizedBox(height: 24),
//                         _buildDateTimeSection(),
//                         const SizedBox(height: 24),
//                         _buildParticipantsSection(),
//                         const SizedBox(height: 24),
//                         _buildRecurrenceSection(),
//                         const SizedBox(height: 32),
//                         _buildActionButtons(),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: () => Navigator.of(context).pop(),
//             icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF374151)),
//           ),
//           const Expanded(
//             child: Text(
//               'אירוע חדש',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1f2937),
//               ),
//             ),
//           ),
//           const AppLogo(width: 32, height: 24, margin: EdgeInsets.zero),
//         ],
//       ),
//     );
//   }

//   Widget _buildEventTypeSelector() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.all(20),
//             child: Text(
//               'סוג האירוע',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1f2937),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Wrap(
//               spacing: 12,
//               runSpacing: 12,
//               children: EventType.values.map((type) {
//                 final isSelected = _selectedEventType == type;
//                 return InkWell(
//                   onTap: () => setState(() => _selectedEventType = type),
//                   borderRadius: BorderRadius.circular(12),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 12,
//                     ),
//                     decoration: BoxDecoration(
//                       color: isSelected
//                           ? _getEventTypeColor(type).withOpacity(0.1)
//                           : const Color(0xFFf1f5f9),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: isSelected
//                             ? _getEventTypeColor(type)
//                             : const Color(0xFFe2e8f0),
//                         width: 2,
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _getEventTypeIcon(type),
//                           color: isSelected
//                               ? _getEventTypeColor(type)
//                               : const Color(0xFF6b7280),
//                           size: 20,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           _getEventTypeText(type),
//                           style: TextStyle(
//                             color: isSelected
//                                 ? _getEventTypeColor(type)
//                                 : const Color(0xFF6b7280),
//                             fontWeight: isSelected
//                                 ? FontWeight.w600
//                                 : FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildBasicInfoSection() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'פרטי האירוע',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1f2937),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextFormField(
//               controller: _titleController,
//               decoration: InputDecoration(
//                 labelText: 'כותרת האירוע *',
//                 hintText: 'הזן כותרת לאירוע',
//                 prefixIcon: Icon(
//                   Icons.title,
//                   color: _getEventTypeColor(_selectedEventType),
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(
//                     color: _getEventTypeColor(_selectedEventType),
//                     width: 2,
//                   ),
//                 ),
//               ),
//               validator: (value) {
//                 if (value == null || value.trim().isEmpty) {
//                   return 'נא להזין כותרת לאירוע';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             TextFormField(
//               controller: _descriptionController,
//               maxLines: 3,
//               decoration: InputDecoration(
//                 labelText: 'תיאור האירוע',
//                 hintText: 'הזן תיאור מפורט לאירוע',
//                 prefixIcon: Icon(
//                   Icons.description,
//                   color: _getEventTypeColor(_selectedEventType),
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(
//                     color: _getEventTypeColor(_selectedEventType),
//                     width: 2,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextFormField(
//               controller: _locationController,
//               decoration: InputDecoration(
//                 labelText: 'מיקום או קישור',
//                 hintText: 'כתובת פיזית או קישור לפגישה',
//                 prefixIcon: Icon(
//                   Icons.location_on,
//                   color: _getEventTypeColor(_selectedEventType),
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(
//                     color: _getEventTypeColor(_selectedEventType),
//                     width: 2,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateTimeSection() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'תאריך ושעה',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1f2937),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildDateTimePicker(
//                     'תאריך התחלה',
//                     DateFormat('dd/MM/yyyy').format(_startDate),
//                     Icons.calendar_today,
//                     () => _selectDate(context, true),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildDateTimePicker(
//                     'שעת התחלה',
//                     _startTime.format(context),
//                     Icons.access_time,
//                     () => _selectTime(context, true),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildDateTimePicker(
//                     'תאריך סיום',
//                     DateFormat('dd/MM/yyyy').format(_endDate),
//                     Icons.calendar_today,
//                     () => _selectDate(context, false),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildDateTimePicker(
//                     'שעת סיום',
//                     _endTime.format(context),
//                     Icons.access_time,
//                     () => _selectTime(context, false),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateTimePicker(
//     String label,
//     String value,
//     IconData icon,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           border: Border.all(color: const Color(0xFFe2e8f0)),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Color(0xFF6b7280),
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(
//                   icon,
//                   color: _getEventTypeColor(_selectedEventType),
//                   size: 20,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1f2937),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildParticipantsSection() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Text(
//                   'משתתפים',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1f2937),
//                   ),
//                 ),
//                 const Spacer(),
//                 Text(
//                   '${_selectedParticipants.length} נבחרו',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: _getEventTypeColor(_selectedEventType),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             if (_availableUsers.isNotEmpty)
//               ...(_availableUsers.take(5).map((user) {
//                 final isSelected = _selectedParticipants.contains(user.id);
//                 return Container(
//                   margin: const EdgeInsets.only(bottom: 8),
//                   child: CheckboxListTile(
//                     value: isSelected,
//                     onChanged: (value) {
//                       setState(() {
//                         if (value == true) {
//                           _selectedParticipants.add(user.id);
//                         } else {
//                           _selectedParticipants.remove(user.id);
//                         }
//                       });
//                     },
//                     title: Text(user.name),
//                     subtitle: Text(_getRoleText(user.role)),
//                     secondary: CircleAvatar(
//                       backgroundColor: _getEventTypeColor(
//                         _selectedEventType,
//                       ).withOpacity(0.1),
//                       child: Text(
//                         user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
//                         style: TextStyle(
//                           color: _getEventTypeColor(_selectedEventType),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     activeColor: _getEventTypeColor(_selectedEventType),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 );
//               }).toList()),
//             if (_availableUsers.length > 5)
//               TextButton(
//                 onPressed: () => _showAllParticipants(),
//                 child: Text('הצג את כל המשתתפים (${_availableUsers.length})'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecurrenceSection() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Text(
//                   'אירוע חוזר',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1f2937),
//                   ),
//                 ),
//                 const Spacer(),
//                 Switch(
//                   value: _isRecurring,
//                   onChanged: (value) => setState(() => _isRecurring = value),
//                   activeColor: _getEventTypeColor(_selectedEventType),
//                 ),
//               ],
//             ),
//             if (_isRecurring) ...[
//               const SizedBox(height: 16),
//               DropdownButtonFormField<RecurrenceType>(
//                 value: _recurrenceType,
//                 decoration: InputDecoration(
//                   labelText: 'תדירות החזרה',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 items: RecurrenceType.values.map((type) {
//                   return DropdownMenuItem(
//                     value: type,
//                     child: Text(_getRecurrenceText(type)),
//                   );
//                 }).toList(),
//                 onChanged: (value) => setState(() => _recurrenceType = value!),
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 initialValue: _recurrenceInterval.toString(),
//                 decoration: InputDecoration(
//                   labelText:
//                       'כל כמה ${_getRecurrenceText(_recurrenceType).toLowerCase()}',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 keyboardType: TextInputType.number,
//                 onChanged: (value) =>
//                     _recurrenceInterval = int.tryParse(value) ?? 1,
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           height: 56,
//           child: ElevatedButton(
//             onPressed: _isLoading ? null : _saveEvent,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _getEventTypeColor(_selectedEventType),
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               elevation: 0,
//             ),
//             child: _isLoading
//                 ? const SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                 : Text(
//                     widget.eventToEdit != null ? 'עדכן אירוע' : 'צור אירוע',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           width: double.infinity,
//           height: 56,
//           child: OutlinedButton(
//             onPressed: () => Navigator.of(context).pop(),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: const Color(0xFF6b7280),
//               side: const BorderSide(color: Color(0xFFe2e8f0)),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//             ),
//             child: const Text(
//               'ביטול',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _selectDate(BuildContext context, bool isStartDate) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: isStartDate ? _startDate : _endDate,
//       firstDate: DateTime.now().subtract(const Duration(days: 1)),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: Theme.of(context).colorScheme.copyWith(
//               primary: _getEventTypeColor(_selectedEventType),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         if (isStartDate) {
//           _startDate = picked;
//           if (_endDate.isBefore(_startDate)) {
//             _endDate = _startDate;
//           }
//         } else {
//           _endDate = picked;
//         }
//       });
//     }
//   }

//   Future<void> _selectTime(BuildContext context, bool isStartTime) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: isStartTime ? _startTime : _endTime,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: Theme.of(context).colorScheme.copyWith(
//               primary: _getEventTypeColor(_selectedEventType),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         if (isStartTime) {
//           _startTime = picked;
//           // Auto-adjust end time to be 1 hour later
//           final startDateTime = DateTime(
//             _startDate.year,
//             _startDate.month,
//             _startDate.day,
//             picked.hour,
//             picked.minute,
//           );
//           final endDateTime = startDateTime.add(const Duration(hours: 1));
//           _endTime = TimeOfDay.fromDateTime(endDateTime);
//         } else {
//           _endTime = picked;
//         }
//       });
//     }
//   }

//   void _showAllParticipants() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.7,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           children: [
//             Container(
//               margin: const EdgeInsets.symmetric(vertical: 12),
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFe5e7eb),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const Padding(
//               padding: EdgeInsets.all(20),
//               child: Text(
//                 'בחר משתתפים',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1f2937),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _availableUsers.length,
//                 itemBuilder: (context, index) {
//                   final user = _availableUsers[index];
//                   final isSelected = _selectedParticipants.contains(user.id);
//                   return CheckboxListTile(
//                     value: isSelected,
//                     onChanged: (value) {
//                       setState(() {
//                         if (value == true) {
//                           _selectedParticipants.add(user.id);
//                         } else {
//                           _selectedParticipants.remove(user.id);
//                         }
//                       });
//                       Navigator.pop(context);
//                     },
//                     title: Text(user.name),
//                     subtitle: Text(_getRoleText(user.role)),
//                     secondary: CircleAvatar(
//                       backgroundColor: _getEventTypeColor(
//                         _selectedEventType,
//                       ).withOpacity(0.1),
//                       child: Text(
//                         user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
//                         style: TextStyle(
//                           color: _getEventTypeColor(_selectedEventType),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     activeColor: _getEventTypeColor(_selectedEventType),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _saveEvent() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (_selectedParticipants.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('נא לבחור לפחות משתתף אחד')));
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final startDateTime = DateTime(
//         _startDate.year,
//         _startDate.month,
//         _startDate.day,
//         _startTime.hour,
//         _startTime.minute,
//       );

//       final endDateTime = DateTime(
//         _endDate.year,
//         _endDate.month,
//         _endDate.day,
//         _endTime.hour,
//         _endTime.minute,
//       );

//       if (endDateTime.isBefore(startDateTime)) {
//         throw Exception('זמן הסיום חייב להיות אחרי זמן ההתחלה');
//       }

//       final event = CalendarEvent(
//         id: widget.eventToEdit?.id ?? '',
//         title: _titleController.text.trim(),
//         description: _descriptionController.text.trim(),
//         startTime: startDateTime,
//         endTime: endDateTime,
//         createdById: _currentUser!.id,
//         createdByName: _currentUser!.name, // ADD THIS LINE
//         participantIds: _selectedParticipants,
//         type: _selectedEventType,
//         locationOrLink: _locationController.text.trim().isEmpty
//             ? null
//             : _locationController.text.trim(),
//         createdAt:
//             widget.eventToEdit?.createdAt ?? DateTime.now(), // ADD THIS LINE
//       );

//       if (widget.eventToEdit != null) {
//         await _calendarRepository.updateEvent(event);
//         if (mounted) {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text('האירוע עודכן בהצלחה')));
//         }
//       } else {
//         await _calendarRepository.createEvent(event);
//         if (mounted) {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text('האירוע נוצר בהצלחה')));
//         }
//       }

//       if (mounted) {
//         Navigator.of(context).pop(true);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('שגיאה בשמירת האירוע: $e')));
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   Color _getEventTypeColor(EventType type) {
//     switch (type) {
//       case EventType.holiday:
//         return const Color(0xFFef4444); // Red
//       case EventType.meeting:
//         return const Color(0xFF3b82f6); // Blue
//       case EventType.workshop:
//         return const Color(0xFF8b5cf6); // Purple
//       case EventType.special_event:
//         return const Color(0xFF10b981); // Green
//       case EventType.announcement:
//         return const Color(0xFFf59e0b); // Orange
//       case EventType.therapy:
//         return const Color(0xFF06b6d4); // Cyan
//       case EventType.other:
//         return const Color(0xFF6b7280); // Gray
//     }
//   }

//   IconData _getEventTypeIcon(EventType type) {
//     switch (type) {
//       case EventType.holiday:
//         return Icons.celebration;
//       case EventType.meeting:
//         return Icons.people;
//       case EventType.workshop:
//         return Icons.school;
//       case EventType.special_event:
//         return Icons.event;
//       case EventType.announcement:
//         return Icons.campaign;
//       case EventType.therapy:
//         return Icons.healing;
//       case EventType.other:
//         return Icons.event_note;
//     }
//   }

//   String _getEventTypeText(EventType type) {
//     switch (type) {
//       case EventType.holiday:
//         return 'חג/חופש';
//       case EventType.meeting:
//         return 'פגישה';
//       case EventType.workshop:
//         return 'סדנה';
//       case EventType.special_event:
//         return 'אירוע מיוחד';
//       case EventType.announcement:
//         return 'הודעה';
//       case EventType.therapy:
//         return 'טיפול';
//       case EventType.other:
//         return 'אחר';
//     }
//   }

//   String _getRoleText(UserRole role) {
//     switch (role) {
//       case UserRole.client:
//         return 'אמן';
//       case UserRole.mentor:
//         return 'מנחה';
//       case UserRole.staff:
//         return 'צוות';
//     }
//   }

//   String _getRecurrenceText(RecurrenceType type) {
//     switch (type) {
//       case RecurrenceType.daily:
//         return 'יומי';
//       case RecurrenceType.weekly:
//         return 'שבועי';
//       case RecurrenceType.monthly:
//         return 'חודשי';
//     }
//   }
// }

// // Add these enums if they don't exist
// enum RecurrenceType { daily, weekly, monthly }
