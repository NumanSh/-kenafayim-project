import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../data/models/calendar_event.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../data/repositories/unified_calendar_repository.dart';
import '../../../config/service_locator.dart';
import '../../screens/calendar/event_details_screen.dart';
import '../../screens/calendar/create_event_screen.dart';
import '../../utils/calendar_permissions.dart';

class UniversalCalendarView extends StatefulWidget {
  final User user;

  const UniversalCalendarView({Key? key, required this.user}) : super(key: key);

  @override
  State<UniversalCalendarView> createState() => _UniversalCalendarViewState();
}

class _UniversalCalendarViewState extends State<UniversalCalendarView> {
  final CalendarRepository _calendarRepository =
      serviceLocator<CalendarRepository>();
  final ScrollController _scrollController = ScrollController();

  late CalendarPermissions _permissions;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};
  List<CalendarEvent> _selectedDayEvents = [];
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isCalendarExpanded = true;
  double _calendarHeight = 400.0;
  bool _showAllEvents = true;

  // ✅ NEW: Stream subscription for real-time updates
  StreamSubscription<List<dynamic>>? _eventsSubscription;
  Timer? _refreshTimer;

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _permissions = CalendarPermissions(widget.user);
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _setupScrollListener();
    _subscribeToEvents(); // ✅ NEW: Subscribe to real-time events
    _setupPeriodicRefresh(); // ✅ NEW: Periodic refresh as backup
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel(); // ✅ NEW: Cancel subscription
    _refreshTimer?.cancel(); // ✅ NEW: Cancel timer
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ NEW: Real-time event subscription
  void _subscribeToEvents() {
    _safeSetState(() => _isLoading = true);

    try {
      final unifiedRepository = serviceLocator<UnifiedCalendarRepository>();

      // Subscribe to real-time events stream
      _eventsSubscription = unifiedRepository.eventsStream.listen(
        (unifiedItems) {
          if (mounted) {
            _processUnifiedItems(unifiedItems);
          }
        },
        onError: (error) {
          print('❌ CALENDAR: Stream error: $error');
          if (mounted) {
            _safeSetState(() => _isLoading = false);
            _showErrorSnackBar('שגיאה בטעינת אירועים: $error');
          }
        },
      );

      // Initial load to trigger the stream
      _loadInitialEvents();
    } catch (e) {
      print('❌ CALENDAR: Error setting up stream: $e');
      // Fallback to manual loading
      _loadEvents();
    }
  }

  // ✅ NEW: Load initial events to trigger stream
  Future<void> _loadInitialEvents() async {
    try {
      final unifiedRepository = serviceLocator<UnifiedCalendarRepository>();

      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      // This will trigger the stream with fresh data
      await unifiedRepository.getUnifiedCalendarItems(
        userId: widget.user.id,
        userRole: widget.user.role,
        startDate: startDate,
        endDate: endDate,
        forceRefresh: true, // ✅ Force refresh to get latest data
      );
    } catch (e) {
      print('❌ CALENDAR: Error loading initial events: $e');
      if (mounted) {
        _safeSetState(() => _isLoading = false);
        // Fallback to manual loading
        _loadEvents();
      }
    }
  }

  // ✅ NEW: Process unified items from stream
  void _processUnifiedItems(List<dynamic> unifiedItems) {
    final Map<DateTime, List<CalendarEvent>> newEvents = {};

    for (final item in unifiedItems) {
      try {
        final date = DateTime(
          item.startTime.year,
          item.startTime.month,
          item.startTime.day,
        );

        // Convert unified item to calendar event
        final calendarEvent = CalendarEvent(
          id: item.id,
          title: item.title,
          description: item.description ?? '',
          startTime: item.startTime,
          endTime: item.endTime,
          createdById: item.originalLesson?.assignedInstructorId ?? '',
          createdByName: item.originalLesson?.instructorName ?? 'מערכת',
          participantIds: item.participantIds ?? [],
          type: item.isLesson ? EventType.workshop : EventType.meeting,
          priority: EventPriority.medium,
          locationOrLink: item.location ?? 'אולפן כנפיים',
          createdAt: DateTime.now(),
          additionalInfo: item.isLesson
              ? {
                  'isLesson': true,
                  'lessonId': item.originalLesson?.id,
                  'maxCapacity': item.originalLesson?.maxCapacity,
                  'attendanceCount':
                      item.originalLesson?.attendanceRecords.length ?? 0,
                }
              : {},
        );

        newEvents.putIfAbsent(date, () => []).add(calendarEvent);
      } catch (e) {
        print('❌ CALENDAR: Error processing item: $e');
        continue;
      }
    }

    // Sort events within each date
    newEvents.forEach((date, eventList) {
      eventList.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    _safeSetState(() {
      _events = newEvents;
      _selectedDayEvents = _getEventsForDay(_selectedDay);
      _isLoading = false;
    });

    print(
      '✅ CALENDAR: Updated with ${unifiedItems.length} unified items via stream',
    );
  }

  // ✅ NEW: Setup periodic refresh as backup
  void _setupPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _refreshEvents();
      }
    });
  }

  // ✅ NEW: Refresh events (called by timer and manually)
  Future<void> _refreshEvents() async {
    try {
      final unifiedRepository = serviceLocator<UnifiedCalendarRepository>();

      // Clear cache and force refresh
      unifiedRepository.clearUserCache(widget.user.id);

      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      await unifiedRepository.getUnifiedCalendarItems(
        userId: widget.user.id,
        userRole: widget.user.role,
        startDate: startDate,
        endDate: endDate,
        forceRefresh: true,
      );
    } catch (e) {
      print('❌ CALENDAR: Error refreshing events: $e');
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final scrollOffset = _scrollController.offset;

      if (scrollOffset > 50 && _isCalendarExpanded) {
        _safeSetState(() {
          _isCalendarExpanded = false;
          _calendarHeight = 120.0;
        });
      } else if (scrollOffset < 20 && !_isCalendarExpanded) {
        _safeSetState(() {
          _isCalendarExpanded = true;
          _calendarHeight = 400.0;
        });
      }
    });
  }

  // ✅ MODIFIED: Enhanced load events with fallback
  Future<void> _loadEvents() async {
    _safeSetState(() => _isLoading = true);

    try {
      // Try unified repository first
      final unifiedRepository = serviceLocator<UnifiedCalendarRepository>();

      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      final unifiedItems = await unifiedRepository.getUnifiedCalendarItems(
        userId: widget.user.id,
        userRole: widget.user.role,
        startDate: startDate,
        endDate: endDate,
        forceRefresh: true,
      );

      if (mounted) {
        _processUnifiedItems(unifiedItems);
      }
    } catch (e) {
      print(
        '❌ CALENDAR: Unified repository failed, falling back to manual loading: $e',
      );

      // Fallback to original loading method
      try {
        final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
        final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

        // Load calendar events
        final events = await _calendarRepository.getEventsByDateRange(
          startDate,
          endDate,
          userId: widget.user.id,
        );

        // Load lessons as events
        final lessonEvents = await _loadLessonsAsEvents(startDate, endDate);

        // Merge and filter events based on user permissions
        final allEvents = _mergeAndFilterEvents(events, lessonEvents);

        if (mounted) {
          _safeSetState(() {
            _events = allEvents;
            _selectedDayEvents = _getEventsForDay(_selectedDay);
            _isLoading = false;
          });
        }
      } catch (fallbackError) {
        if (mounted) {
          _safeSetState(() => _isLoading = false);
          _showErrorSnackBar('שגיאה בטעינת אירועים: $fallbackError');
        }
      }
    }
  }

  Map<DateTime, List<CalendarEvent>> _mergeAndFilterEvents(
    Map<DateTime, List<CalendarEvent>> events,
    Map<DateTime, List<CalendarEvent>> lessonEvents,
  ) {
    final Map<DateTime, List<CalendarEvent>> allEvents = {};

    // Add calendar events
    events.forEach((date, eventList) {
      final filteredEvents = eventList
          .where((event) => _permissions.visibleEventTypes.contains(event.type))
          .toList();
      if (filteredEvents.isNotEmpty) {
        allEvents[date] = List.from(filteredEvents);
      }
    });

    // Add lesson events
    lessonEvents.forEach((date, lessonList) {
      allEvents.putIfAbsent(date, () => []).addAll(lessonList);
    });

    // Sort events within each date
    allEvents.forEach((date, eventList) {
      eventList.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    return allEvents;
  }

  Future<Map<DateTime, List<CalendarEvent>>> _loadLessonsAsEvents(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final lessonRepository = serviceLocator<LessonRepository>();

      // Load lessons based on user role
      List<dynamic> lessons;
      if (widget.user.isMentor) {
        lessons = await lessonRepository.getLessonsForMentor(
          widget.user.id,
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        lessons = await lessonRepository.getAllLessons(
          startDate: startDate,
          endDate: endDate,
        );
      }

      final Map<DateTime, List<CalendarEvent>> lessonEvents = {};

      for (final lesson in lessons) {
        final lessonDate = DateTime(
          lesson.date.year,
          lesson.date.month,
          lesson.date.day,
        );

        final calendarEvent = CalendarEvent(
          id: 'lesson_${lesson.id}',
          title: lesson.title,
          description: _buildLessonDescription(lesson),
          startTime: lesson.date,
          endTime: lesson.date.add(Duration(minutes: lesson.durationMinutes)),
          createdById: lesson.assignedInstructorId ?? '',
          createdByName: lesson.instructorName ?? 'מערכת',
          participantIds: lesson.registeredArtistIds,
          type: EventType.workshop,
          priority: EventPriority.medium,
          locationOrLink: 'אולפן כנפיים',
          createdAt: DateTime.now(),
          additionalInfo: {
            'isLesson': true,
            'lessonId': lesson.id,
            'maxCapacity': lesson.maxCapacity,
            'attendanceCount': lesson.attendanceRecords.length,
          },
        );

        lessonEvents.putIfAbsent(lessonDate, () => []).add(calendarEvent);
      }

      return lessonEvents;
    } catch (e) {
      print('Error loading lessons: $e');
      return {};
    }
  }

  String _buildLessonDescription(dynamic lesson) {
    final buffer = StringBuffer();
    buffer.write('שיעור ${lesson.title}');

    if (lesson.instructorName != null) {
      buffer.write('\nמנחה: ${lesson.instructorName}');
    }

    if (widget.user.isStaff || widget.user.isMentor) {
      buffer.write('\nמשתתפים: ${lesson.registeredArtistIds.length}');
      if (lesson.maxCapacity != null) {
        buffer.write('/${lesson.maxCapacity}');
      }
    }

    return buffer.toString();
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  List<CalendarEvent> _getAllEventsSorted() {
    final List<CalendarEvent> allEvents = [];
    _events.forEach((date, eventList) {
      allEvents.addAll(eventList);
    });
    allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return allEvents;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? _buildLoadingState() : _buildCalendarContent();
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _permissions.appBarTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const Spacer(),
          ..._buildAppBarActions(),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    final actions = <Widget>[
      // View toggle (everyone)
      IconButton(
        onPressed: () => _safeSetState(() => _showAllEvents = !_showAllEvents),
        icon: Icon(
          _showAllEvents ? Icons.today : Icons.view_list,
          color: const Color(0xFF3b82f6),
        ),
        tooltip: _showAllEvents ? 'הצג יום נבחר' : 'הצג כל האירועים',
      ),

      // ✅ ENHANCED: Refresh with force refresh
      IconButton(
        onPressed: () async {
          await _refreshEvents(); // ✅ Use enhanced refresh
        },
        icon: const Icon(Icons.refresh, color: Color(0xFF3b82f6)),
        tooltip: 'רענן יומן',
      ),
    ];

    // Add create button only for staff
    if (_permissions.canCreateEvents) {
      actions.add(
        IconButton(
          onPressed: _showCreateEventScreen,
          icon: const Icon(Icons.add, color: Color(0xFF3b82f6)),
          tooltip: 'צור אירוע חדש',
        ),
      );
    }

    return actions;
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF3b82f6)),
          ),
          SizedBox(height: 16),
          Text(
            'טוען יומן...',
            style: TextStyle(fontSize: 16, color: Color(0xFF6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final headerHeight = 70.0;
        final availableHeight = screenHeight - headerHeight;

        double calendarHeight;
        if (_isCalendarExpanded) {
          switch (_calendarFormat) {
            case CalendarFormat.week:
              calendarHeight = 140.0;
              break;
            case CalendarFormat.twoWeeks:
              calendarHeight = 180.0;
              break;
            case CalendarFormat.month:
            default:
              calendarHeight = 280.0;
              break;
          }
        } else {
          calendarHeight = 80.0;
        }

        calendarHeight = calendarHeight.clamp(80.0, availableHeight * 0.4);

        return Column(
          children: [
            SizedBox(height: headerHeight, child: _buildCalendarHeader()),
            Flexible(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: calendarHeight,
                      child: _buildCalendarCard(),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildEventsHeader()),
                  _buildEventsList(),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isCalendarExpanded
            ? _buildExpandedCalendar()
            : _buildCollapsedCalendar(),
      ),
    );
  }

  Widget _buildExpandedCalendar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safeHeight = constraints.maxHeight * 0.9;
        final safeWidth = constraints.maxWidth * 0.95;

        double fixedHeight;
        double rowHeight;

        switch (_calendarFormat) {
          case CalendarFormat.week:
            fixedHeight = 140.0;
            rowHeight = 35.0;
            break;
          case CalendarFormat.twoWeeks:
            fixedHeight = 180.0;
            rowHeight = 30.0;
            break;
          case CalendarFormat.month:
          default:
            fixedHeight = 280.0;
            rowHeight = 25.0;
            break;
        }

        final maxAllowedHeight = safeHeight - 40;
        if (fixedHeight > maxAllowedHeight) {
          fixedHeight = maxAllowedHeight;
          rowHeight = (fixedHeight - 80) / 6;
          rowHeight = rowHeight.clamp(20.0, 35.0);
        }

        return Container(
          height: fixedHeight,
          width: safeWidth,
          padding: const EdgeInsets.all(8),
          child: TableCalendar<CalendarEvent>(
            locale: 'he_IL',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: const Color(0xFF3b82f6),
                borderRadius: BorderRadius.circular(4),
              ),
              formatButtonTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Color(0xFF374151),
                size: 18,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Color(0xFF374151),
                size: 18,
              ),
              titleTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1f2937),
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
            daysOfWeekHeight: 25.0,
            rowHeight: rowHeight,
            shouldFillViewport: false,
            availableCalendarFormats: const {
              CalendarFormat.month: 'חודש',
              CalendarFormat.twoWeeks: 'שבועיים',
              CalendarFormat.week: 'שבוע',
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (mounted) {
                _safeSetState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedDayEvents = _getEventsForDay(selectedDay);
                  _showAllEvents = false;
                });

                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    150,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            },
            onFormatChanged: (format) {
              if (mounted) {
                _safeSetState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              if (mounted) {
                _safeSetState(() {
                  _focusedDay = focusedDay;
                });
                // ✅ ENHANCED: Use refresh instead of load
                _refreshEvents();
              }
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(0.5),
              cellPadding: const EdgeInsets.all(0),
              markersMaxCount: 1,
              markerDecoration: const BoxDecoration(
                color: Color(0xFF3b82f6),
                shape: BoxShape.circle,
              ),
              markerMargin: const EdgeInsets.all(0),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF3b82f6),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF3b82f6).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(
                color: Color(0xFF1f2937),
                fontSize: 11,
              ),
              weekendTextStyle: const TextStyle(
                color: Color(0xFF6b7280),
                fontSize: 11,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              todayTextStyle: const TextStyle(
                color: Color(0xFF1f2937),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Color(0xFF374151),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              weekendStyle: TextStyle(
                color: Color(0xFF6b7280),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Color(0xFF3b82f6), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'he_IL').format(_focusedDay),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
              Text(
                'יום נבחר: ${DateFormat('dd/MM').format(_selectedDay)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'גלול למעלה לפתיחה',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF6b7280).withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_up,
            color: const Color(0xFF6b7280).withOpacity(0.7),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsHeader() {
    final eventsToShow = _showAllEvents
        ? _getAllEventsSorted()
        : _selectedDayEvents;
    final headerText = _showAllEvents
        ? 'כל האירועים והשיעורים'
        : 'אירועים ב-${DateFormat('dd/MM/yyyy').format(_selectedDay)}';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              headerText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1f2937),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3b82f6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${eventsToShow.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3b82f6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    final eventsToShow = _showAllEvents
        ? _getAllEventsSorted()
        : _selectedDayEvents;

    if (eventsToShow.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final event = eventsToShow[index];
        final showDateHeader =
            _showAllEvents &&
            (index == 0 ||
                !_isSameDay(
                  eventsToShow[index - 1].startTime,
                  event.startTime,
                ));

        return Column(
          children: [
            if (showDateHeader) _buildDateHeader(event.startTime),
            _buildEventCard(event),
          ],
        );
      }, childCount: eventsToShow.length),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: const Color(0xFF6b7280).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _permissions.emptyStateMessage,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6b7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final isToday = _isSameDay(date, DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF3b82f6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: isToday ? Colors.white : const Color(0xFF3b82f6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            DateFormat('EEEE, dd MMMM', 'he_IL').format(date),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isToday ? Colors.white : const Color(0xFF1f2937),
            ),
          ),
          if (isToday) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'היום',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    final isLesson = event.additionalInfo['isLesson'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showEventDetails(event),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Time column
                SizedBox(
                  width: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!event.isAllDay) ...[
                        Text(
                          DateFormat('HH:mm').format(event.startTime),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: event.getEventColor(),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: event.getEventColor().withOpacity(0.3),
                          margin: const EdgeInsets.symmetric(vertical: 2),
                        ),
                        Text(
                          DateFormat('HH:mm').format(event.endTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: event.getEventColor().withOpacity(0.7),
                          ),
                        ),
                      ] else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: event.getEventColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'כל היום',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: event.getEventColor(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Event content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: event.getEventColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: event.getEventColor().withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1f2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: event.getEventColor(),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isLesson ? 'שיעור' : event.getTypeDisplayName(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (isLesson && (_permissions.canViewAllEvents)) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 12,
                                color: event.getEventColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.createdByName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: event.getEventColor(),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.people,
                                size: 12,
                                color: event.getEventColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${event.participantIds.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: event.getEventColor(),
                                ),
                              ),
                            ],
                          ),
                        ] else if (event.locationOrLink != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: event.getEventColor(),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.locationOrLink!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: event.getEventColor(),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showEventDetails(CalendarEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EventDetailsScreen(event: event, user: widget.user),
      ),
    );
  }

  void _showCreateEventScreen() {
    if (!_permissions.canCreateEvents) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateEventScreen(user: widget.user, initialDate: _selectedDay),
      ),
    ).then((created) {
      if (created == true) {
        // ✅ ENHANCED: Use refresh instead of load
        _refreshEvents();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFef4444),
      ),
    );
  }
}
