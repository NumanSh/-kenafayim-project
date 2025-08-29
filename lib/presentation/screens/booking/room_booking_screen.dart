import 'package:flutter/material.dart';
import 'package:knafayim_app/data/repositories/user_repository.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../data/models/room.dart';
import '../../../data/models/user.dart';
import '../../../data/models/booking.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../config/service_locator.dart';

class RoomBookingScreen extends StatefulWidget {
  final User user;
  final Room room;

  const RoomBookingScreen({Key? key, required this.user, required this.room})
    : super(key: key);

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  final BookingRepository _bookingRepository =
      serviceLocator<BookingRepository>();
  final RoomRepository _roomRepository = serviceLocator<RoomRepository>();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(
    hour: TimeOfDay.now().hour + 1,
  );
  BookingType _bookingType = BookingType.lesson;
  List<String> _selectedResources = [];
  bool _isLoading = false;

  Map<DateTime, List<Booking>> _roomBookings = {};
  List<Booking> _selectedDayBookings = [];

  User? _selectedMentor;
  List<User> _mentors = [];
  bool _isLoadingMentors = false;
  bool _showMentorError = false; // ADD THISD THIS

  @override
  void initState() {
    super.initState();
    _loadRoomBookings();
    _loadMentors(); // ADD THIS LINE
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMentors() async {
    setState(() => _isLoadingMentors = true);

    try {
      final userRepository = serviceLocator<UserRepository>();
      final mentors = await userRepository.getUsersByRole(UserRole.mentor);

      if (mounted) {
        setState(() {
          _mentors = mentors;
          _isLoadingMentors = false;
          // If current user is a mentor, pre-select them
          if (widget.user.isMentor) {
            _selectedMentor = widget.user;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMentors = false);
      }
    }
  }

  Future<void> _loadRoomBookings() async {
    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now().add(const Duration(days: 60));

      final bookings = await _bookingRepository.getBookingsForRoom(
        widget.room.id,
        startDate: startDate,
        endDate: endDate,
      );

      final Map<DateTime, List<Booking>> bookingsByDate = {};
      for (final booking in bookings) {
        final date = DateTime(
          booking.startTime.year,
          booking.startTime.month,
          booking.startTime.day,
        );
        bookingsByDate.putIfAbsent(date, () => []).add(booking);
      }

      if (mounted) {
        setState(() {
          _roomBookings = bookingsByDate;
          _selectedDayBookings = _getBookingsForDay(_selectedDate);
        });
      }
    } catch (e) {
      print('Error loading room bookings: $e');
    }
  }

  List<Booking> _getBookingsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _roomBookings[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildRoomHeader(),
              _buildCalendarSection(),
              _buildBookingForm(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBookingButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      title: Text(
        'הזמנת ${widget.room.displayName}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1f2937),
        ),
      ),
    );
  }

  Widget _buildRoomHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.room.getRoomColor(),
            widget.room.getRoomColor().withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.room.getRoomColor().withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getRoomIcon(widget.room.type),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.room.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.room.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.room.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRoomFeature(
                  Icons.people,
                  'עד ${widget.room.capacity} אנשים',
                ),
                const SizedBox(width: 16),
                _buildRoomFeature(
                  Icons.check_circle,
                  widget.room.isAvailable ? 'זמין' : 'תפוס',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: widget.room.getRoomColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'בחר תאריך',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ],
            ),
          ),
          TableCalendar<Booking>(
            locale: 'he_IL',
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            eventLoader: _getBookingsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
                _selectedDayBookings = _getBookingsForDay(selectedDay);
              });
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(
                color: widget.room.getRoomColor(),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: widget.room.getRoomColor().withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: const Color(0xFFef4444),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          if (_selectedDayBookings.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'הזמנות קיימות ב-${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._selectedDayBookings.map(
                    (booking) => _buildBookingItem(booking),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingItem(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: booking.getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: booking.getStatusColor().withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: booking.getStatusColor(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              booking.title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: booking.getStatusColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              booking.getStatusDisplayName(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_calendar,
                  color: widget.room.getRoomColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'פרטי ההזמנה',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ADD MENTOR SELECTION FIELD HERE
            if (widget.user.isStaff) ...[
              const Text(
                'בחר מנחה',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),

              // FIXED DROPDOWN IMPLEMENTATION
              InkWell(
                onTap: _isLoadingMentors
                    ? null
                    : () => _showMentorSelectionBottomSheet(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFe5e7eb)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: widget.room.getRoomColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLoadingMentors
                            ? const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('טוען מנחים...'),
                                ],
                              )
                            : _selectedMentor != null
                            ? Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: widget.room
                                        .getRoomColor()
                                        .withOpacity(0.1),
                                    child: Text(
                                      _selectedMentor!.name.isNotEmpty
                                          ? _selectedMentor!.name[0]
                                                .toUpperCase()
                                          : 'M',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: widget.room.getRoomColor(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedMentor!.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1f2937),
                                          ),
                                        ),
                                        Text(
                                          _selectedMentor!.email,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6b7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'בחר מנחה להזמנה',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9ca3af),
                                ),
                              ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF6b7280),
                      ),
                    ],
                  ),
                ),
              ),

              // Validation error display
              if (_selectedMentor == null && _showMentorError) ...[
                const SizedBox(height: 4),
                const Text(
                  'אנא בחר מנחה להזמנה',
                  style: TextStyle(fontSize: 12, color: Color(0xFFef4444)),
                ),
              ],

              const SizedBox(height: 16),
            ],

            // Title field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'כותרת ההזמנה',
                hintText: 'לדוגמה: שיעור ציור קבוצתי',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.title,
                  color: widget.room.getRoomColor(),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'אנא הכנס כותרת להזמנה';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Resources selection
            if (widget.room.availableResources.isNotEmpty) ...[
              Text(
                'ציוד נדרש (אופציונלי)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.room.getRoomColor(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.room.availableResources.map((resource) {
                  final isSelected = _selectedResources.contains(resource);
                  return FilterChip(
                    label: Text(resource),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedResources.add(resource);
                        } else {
                          _selectedResources.remove(resource);
                        }
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: widget.room.getRoomColor().withOpacity(0.2),
                    checkmarkColor: widget.room.getRoomColor(),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? widget.room.getRoomColor()
                          : const Color(0xFF6b7280),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMentorSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFe5e7eb),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.person_search,
                    color: widget.room.getRoomColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'בחר מנחה להזמנה',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ביטול'),
                  ),
                ],
              ),
            ),

            // Mentors list
            Expanded(
              child: _mentors.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 48,
                            color: Color(0xFF6b7280),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'לא נמצאו מנחים',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _mentors.length,
                      itemBuilder: (context, index) {
                        final mentor = _mentors[index];
                        final isSelected = _selectedMentor?.id == mentor.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.room.getRoomColor().withOpacity(0.1)
                                : const Color(0xFFf8fafc),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: widget.room.getRoomColor())
                                : null,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: widget.room
                                  .getRoomColor()
                                  .withOpacity(0.1),
                              child: Text(
                                mentor.name.isNotEmpty
                                    ? mentor.name[0].toUpperCase()
                                    : 'M',
                                style: TextStyle(
                                  color: widget.room.getRoomColor(),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              mentor.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(mentor.email),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: widget.room.getRoomColor(),
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedMentor = mentor;
                                _showMentorError = false;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selectedTime = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (selectedTime != null) {
              onChanged(selectedTime);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFe5e7eb)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  color: widget.room.getRoomColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.room.getRoomColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'שלח בקשת הזמנה',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  IconData _getRoomIcon(RoomType type) {
    switch (type) {
      case RoomType.plasticArts:
        return Icons.palette;
      case RoomType.theater:
        return Icons.theater_comedy;
      case RoomType.music:
        return Icons.music_note;
      case RoomType.writing:
        return Icons.edit;
      case RoomType.animation:
        return Icons.animation;
      case RoomType.videoCinema:
        return Icons.videocam;
    }
  }

  String _getBookingTypeText(BookingType type) {
    switch (type) {
      case BookingType.lesson:
        return 'שיעור';
      case BookingType.meeting:
        return 'פגישה';
      case BookingType.event:
        return 'אירוע';
      case BookingType.maintenance:
        return 'תחזוקה';
      case BookingType.personal:
        return 'אישי';
    }
  }

  Future<void> _submitBooking() async {
    setState(() => _showMentorError = false);

    if (!_formKey.currentState!.validate()) return;

    // For staff, ensure mentor is selected
    final bookingUser = widget.user.isStaff ? _selectedMentor : widget.user;

    if (widget.user.isStaff && bookingUser == null) {
      setState(() => _showMentorError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר מנחה להזמנה'),
          backgroundColor: Color(0xFFef4444),
        ),
      );
      return;
    }

    // Validate time
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('שעת הסיום חייבת להיות אחרי שעת ההתחלה'),
          backgroundColor: Color(0xFFef4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check room availability
      final isAvailable = await _roomRepository.isRoomAvailable(
        widget.room.id,
        startDateTime,
        endDateTime,
      );

      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('החדר תפוס בזמן הנבחר. אנא בחר זמן אחר'),
              backgroundColor: Color(0xFFef4444),
            ),
          );
        }
        return;
      }

      // Create booking with selected mentor (for staff) or current user (for mentors)
      final booking = Booking(
        id: '',
        roomId: widget.room.id,
        userId:
            bookingUser!.id, // Use selected mentor's ID or current user's ID
        userName: bookingUser
            .name, // Use selected mentor's name or current user's name
        type: _bookingType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        requestedResources: _selectedResources,
        createdAt: DateTime.now(),
      );

      final bookingId = await _bookingRepository.createBooking(booking);

      if (bookingId != null && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.user.isStaff
                      ? 'הזמנה נוצרה בהצלחה עבור ${bookingUser.name}!'
                      : 'בקשת ההזמנה נשלחה בהצלחה!',
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשליחת הבקשה: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
