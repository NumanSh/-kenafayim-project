import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/data/repositories/user_repository.dart';
import 'package:knafayim_app/presentation/screens/booking/edit_room_screen.dart';
import 'package:knafayim_app/presentation/screens/booking/room_booking_screen.dart';
import '../../../data/models/room.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../config/service_locator.dart';
import 'create_room_screen.dart';

class StaffRoomManagementScreen extends ConsumerStatefulWidget {
  final User user;

  const StaffRoomManagementScreen({Key? key, required this.user})
    : super(key: key);

  @override
  ConsumerState<StaffRoomManagementScreen> createState() =>
      _StaffRoomManagementScreenState();
}

class _StaffRoomManagementScreenState
    extends ConsumerState<StaffRoomManagementScreen> {
  final RoomRepository _roomRepository = serviceLocator<RoomRepository>();
  final BookingRepository _bookingRepository =
      serviceLocator<BookingRepository>();

  List<Room> _rooms = [];
  Map<String, Map<String, dynamic>> _roomStats = {};
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);

    try {
      final rooms = await _roomRepository.getAllRooms();

      // Load stats for each room
      final Map<String, Map<String, dynamic>> stats = {};
      for (final room in rooms) {
        stats[room.id] = await _roomRepository.getRoomStats(room.id);
      }

      if (mounted) {
        setState(() {
          _rooms = rooms;
          _roomStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה בטעינת חדרים: $e')));
      }
    }
  }

  List<Room> get _filteredRooms {
    switch (_selectedFilter) {
      case 'available':
        return _rooms
            .where((room) => room.status == RoomStatus.available)
            .toList();
      case 'maintenance':
        return _rooms
            .where((room) => room.status == RoomStatus.maintenance)
            .toList();
      case 'occupied':
        return _rooms
            .where((room) => room.status == RoomStatus.occupied)
            .toList();
      default:
        return _rooms;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                _buildStatsOverview(),
                _buildFilterChips(),
                Expanded(child: _buildRoomsList()),
              ],
            ),
      floatingActionButton: _buildCreateRoomFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      title: const Text(
        'ניהול סטודיואים',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1f2937),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _loadRooms,
          icon: const Icon(Icons.refresh, color: Color(0xFF3b82f6)),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF3b82f6)),
          onSelected: (value) {
            switch (value) {
              case 'bulk_enable':
                _showBulkOperations();
                break;
              case 'export':
                _exportRoomData();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'bulk_enable',
              child: Row(
                children: [
                  Icon(Icons.checklist, color: Color(0xFF3b82f6)),
                  SizedBox(width: 8),
                  Text('פעולות מרובות'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, color: Color(0xFF3b82f6)),
                  SizedBox(width: 8),
                  Text('ייצא נתונים'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
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
            'טוען סטודיואים...',
            style: TextStyle(fontSize: 16, color: Color(0xFF6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    final totalRooms = _rooms.length;
    final availableRooms = _rooms
        .where((r) => r.status == RoomStatus.available)
        .length;
    final maintenanceRooms = _rooms
        .where((r) => r.status == RoomStatus.maintenance)
        .length;
    final totalBookings = _roomStats.values.fold(
      0,
      (sum, stats) => sum + (stats['totalBookings'] as int? ?? 0),
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3b82f6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'סקירת סטודיואים',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'סה"כ חדרים',
                  '$totalRooms',
                  Icons.meeting_room,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'זמינים',
                  '$availableRooms',
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'תחזוקה',
                  '$maintenanceRooms',
                  Icons.build,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'הזמנות החודש',
                  '$totalBookings',
                  Icons.event,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'הכל', 'icon': Icons.apps},
      {'key': 'available', 'label': 'זמינים', 'icon': Icons.check_circle},
      {'key': 'maintenance', 'label': 'תחזוקה', 'icon': Icons.build},
      {'key': 'occupied', 'label': 'תפוסים', 'icon': Icons.event_busy},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];

          return Container(
            margin: const EdgeInsets.only(left: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF6b7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['key'] as String;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF3b82f6),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF3b82f6)
                    : const Color(0xFFe5e7eb),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomsList() {
    final filteredRooms = _filteredRooms;

    if (filteredRooms.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredRooms.length,
      itemBuilder: (context, index) {
        final room = filteredRooms[index];
        final stats = _roomStats[room.id] ?? {};
        return _buildRoomCard(room, stats);
      },
    );
  }

  Widget _buildRoomCard(Room room, Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // Room header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  room.getRoomColor(),
                  room.getRoomColor().withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getRoomIcon(room.type),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        room.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(room.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(room.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(room.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(room.status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Room details and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        Icons.people,
                        'קיבולת',
                        '${room.capacity} אנשים',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.event,
                        'הזמנות החודש',
                        '${stats['totalBookings'] ?? 0}',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.schedule,
                        'שעות שימוש',
                        '${stats['totalHours'] ?? 0}ש\'',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Replace the action buttons Row in _buildRoomCard method:
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => _editRoom(room),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: room.getRoomColor(),
                          side: BorderSide(color: room.getRoomColor()),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'עריכה',
                              style: TextStyle(fontSize: 12),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _bookRoom(room),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3b82f6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_available, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'הזמנה',
                              style: TextStyle(fontSize: 12),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _toggleRoomStatus(room),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: room.status == RoomStatus.available
                              ? const Color(0xFFef4444)
                              : const Color(0xFF10b981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              room.status == RoomStatus.available
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              room.status == RoomStatus.available
                                  ? 'השבת'
                                  : 'הפעל',
                              style: TextStyle(fontSize: 12),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showRoomOptions(room),
                      icon: const Icon(Icons.more_vert, size: 18),
                      color: const Color(0xFF6b7280),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _bookRoom(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomBookingScreen(user: widget.user, room: room),
      ),
    ).then((booked) {
      if (booked == true) {
        _loadRooms(); // Refresh room stats after booking
      }
    });
    _showMentorSelectionDialog;
  }

  // Add this new method to show mentor selection:
  void _showMentorSelectionDialog(Room room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: room.getRoomColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getRoomIcon(room.type),
                        color: room.getRoomColor(),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'בחר מנחה עבור',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6b7280),
                            ),
                          ),
                          Text(
                            room.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Mentors list
              Expanded(
                child: FutureBuilder<List<User>>(
                  future: serviceLocator<UserRepository>().getUsersByRole(
                    UserRole.mentor,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'לא נמצאו מנחים',
                          style: TextStyle(color: Color(0xFF6b7280)),
                        ),
                      );
                    }

                    final mentors = snapshot.data!;

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: mentors.length,
                      itemBuilder: (context, index) {
                        final mentor = mentors[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf8fafc),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: room.getRoomColor().withOpacity(
                                0.1,
                              ),
                              child: Text(
                                mentor.name.isNotEmpty
                                    ? mentor.name[0].toUpperCase()
                                    : 'M',
                                style: TextStyle(
                                  color: room.getRoomColor(),
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
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: room.getRoomColor(),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'בחר',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoomBookingScreen(
                                    user: mentor, // Pass selected mentor
                                    room: room,
                                  ),
                                ),
                              ).then((booked) {
                                if (booked == true) {
                                  _loadRooms();
                                }
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6b7280)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6b7280)),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room,
            size: 64,
            color: const Color(0xFF6b7280).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'אין סטודיואים',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6b7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'התחל ביצירת הסטודיו הראשון שלך',
            style: TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewRoom,
            icon: const Icon(Icons.add),
            label: const Text('צור סטודיו חדש'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3b82f6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateRoomFAB() {
    return FloatingActionButton.extended(
      onPressed: _createNewRoom,
      backgroundColor: const Color(0xFF3b82f6),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('סטודיו חדש'),
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

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return const Color(0xFF10b981);
      case RoomStatus.occupied:
        return const Color(0xFFf59e0b);
      case RoomStatus.maintenance:
        return const Color(0xFFef4444);
      case RoomStatus.reserved:
        return const Color(0xFF3b82f6);
    }
  }

  String _getStatusText(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return 'זמין';
      case RoomStatus.occupied:
        return 'תפוס';
      case RoomStatus.maintenance:
        return 'תחזוקה';
      case RoomStatus.reserved:
        return 'שמור';
    }
  }

  void _createNewRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRoomScreen(user: widget.user),
      ),
    ).then((created) {
      if (created == true) {
        _loadRooms();
      }
    });
  }

  void _editRoom(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRoomScreen(user: widget.user, room: room),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadRooms();
      }
    });
  }

  Future<void> _toggleRoomStatus(Room room) async {
    final newStatus = room.status == RoomStatus.available
        ? RoomStatus.maintenance
        : RoomStatus.available;

    final success = await _roomRepository.updateRoomStatus(room.id, newStatus);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == RoomStatus.available
                ? 'הסטודיו הופעל בהצלחה'
                : 'הסטודיו הושבת בהצלחה',
          ),
          backgroundColor: const Color(0xFF10b981),
        ),
      );
      _loadRooms();
    }
  }

  void _showRoomOptions(Room room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFe5e7eb),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                room.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.analytics, color: Color(0xFF3b82f6)),
                title: const Text('סטטיסטיקות'),
                onTap: () {
                  Navigator.pop(context);
                  _showRoomAnalytics(room);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Color(0xFF10b981)),
                title: const Text('שכפל סטודיו'),
                onTap: () {
                  Navigator.pop(context);
                  _duplicateRoom(room);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFef4444)),
                title: const Text('מחק סטודיו'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteRoom(room);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBulkOperations() {
    // TODO: Implement bulk operations
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('פעולות מרובות יהיו זמינות בקרוב')),
    );
  }

  void _exportRoomData() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ייצוא נתונים יהיה זמין בקרוב')),
    );
  }

  void _showRoomAnalytics(Room room) {
    // TODO: Implement room analytics
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('סטטיסטיקות יהיו זמינות בקרוב')),
    );
  }

  void _duplicateRoom(Room room) {
    // TODO: Implement room duplication
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('שכפול סטודיו יהיה זמין בקרוב')),
    );
  }

  void _deleteRoom(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('מחיקת סטודיו'),
        content: Text('האם אתה בטוח שברצונך למחוק את ${room.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement room deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('מחיקת סטודיו תהיה זמינה בקרוב')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
            ),
            child: const Text('מחק', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
