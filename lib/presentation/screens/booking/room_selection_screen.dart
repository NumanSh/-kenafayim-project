import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/room.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../config/service_locator.dart';
import 'room_booking_screen.dart';

class RoomSelectionScreen extends ConsumerStatefulWidget {
  final User user;

  const RoomSelectionScreen({super.key, required this.user});

  @override
  ConsumerState<RoomSelectionScreen> createState() =>
      _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends ConsumerState<RoomSelectionScreen> {
  final RoomRepository _roomRepository = serviceLocator<RoomRepository>();
  List<Room> _rooms = [];
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
      if (mounted) {
        setState(() {
          _rooms = rooms;
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
    if (_selectedFilter == 'all') return _rooms;
    if (_selectedFilter == 'available') {
      return _rooms.where((room) => room.isAvailable).toList();
    }

    // Filter by room type
    final roomType = RoomType.values.firstWhere(
      (type) => type.toString().split('.').last == _selectedFilter,
      orElse: () => RoomType.plasticArts,
    );
    return _rooms.where((room) => room.type == roomType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: const Text(
          'בחירת סטודיו',
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
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(child: _buildRoomGrid()),
              ],
            ),
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

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'הכל', 'icon': Icons.apps},
      {'key': 'available', 'label': 'זמין', 'icon': Icons.check_circle},
      {'key': 'plasticArts', 'label': 'אמנות פלסטית', 'icon': Icons.palette},
      {'key': 'theater', 'label': 'תאטרון', 'icon': Icons.theater_comedy},
      {'key': 'music', 'label': 'מוזיקה', 'icon': Icons.music_note},
      {'key': 'writing', 'label': 'כתיבה', 'icon': Icons.edit},
      {'key': 'animation', 'label': 'אנימציה', 'icon': Icons.animation},
      {'key': 'videoCinema', 'label': 'וידאו', 'icon': Icons.videocam},
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

  Widget _buildRoomGrid() {
    final filteredRooms = _filteredRooms;
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth > 1200) {
      crossAxisCount = 4;
      childAspectRatio = 0.65; // ✅ FIXED: Increased height
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
      childAspectRatio = 0.7; // ✅ FIXED: Increased height
    } else if (screenWidth > 600) {
      crossAxisCount = 2;
      childAspectRatio = 0.75; // ✅ FIXED: Increased height
    } else {
      crossAxisCount = 2;
      childAspectRatio = 0.75; // ✅ FIXED: Increased height
    }

    if (filteredRooms.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: screenWidth > 600 ? 20 : 16,
        mainAxisSpacing: screenWidth > 600 ? 20 : 16,
      ),
      itemCount: filteredRooms.length,
      itemBuilder: (context, index) {
        final room = filteredRooms[index];
        return _buildRoomCard(room);
      },
    );
  }

  Widget _buildRoomCard(Room room) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToBooking(room),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room header with color and icon
              Container(
                height: 70, // ✅ FIXED: Reduced header height
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
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      top: -20,
                      left: -20,
                      child: Container(
                        width: 80, // ✅ FIXED: Reduced size
                        height: 80, // ✅ FIXED: Reduced size
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Room icon and status
                    Padding(
                      padding: const EdgeInsets.all(
                        12,
                      ), // ✅ FIXED: Reduced padding
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(
                              6,
                            ), // ✅ FIXED: Reduced padding
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getRoomIcon(room.type),
                              color: Colors.white,
                              size: 20, // ✅ FIXED: Reduced size
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, // ✅ FIXED: Reduced padding
                              vertical: 3, // ✅ FIXED: Reduced padding
                            ),
                            decoration: BoxDecoration(
                              color: room.isAvailable
                                  ? const Color(0xFF10b981).withOpacity(0.2)
                                  : const Color(0xFFef4444).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: room.isAvailable
                                    ? const Color(0xFF10b981)
                                    : const Color(0xFFef4444),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              room.isAvailable ? 'זמין' : 'תפוס',
                              style: TextStyle(
                                fontSize: 9, // ✅ FIXED: Reduced font size
                                fontWeight: FontWeight.w600,
                                color: room.isAvailable
                                    ? const Color(0xFF10b981)
                                    : const Color(0xFFef4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Room details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12), // ✅ FIXED: Reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:
                        MainAxisSize.min, // ✅ FIXED: Added to prevent overflow
                    children: [
                      Text(
                        room.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                        maxLines: 1, // ✅ FIXED: Reduced to 1 line
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3), // ✅ FIXED: Reduced spacing
                      Text(
                        room.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6b7280),
                        ),
                        maxLines: 1, // ✅ FIXED: Added max lines
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6), // ✅ FIXED: Reduced spacing
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: room.getRoomColor(),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            // ✅ FIXED: Added Expanded
                            child: Text(
                              'עד ${room.capacity} אנשים',
                              style: TextStyle(
                                fontSize: 12,
                                color: room.getRoomColor(),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6), // ✅ FIXED: Reduced spacing
                      Expanded(
                        child: Text(
                          room.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6b7280),
                            height: 1.2, // ✅ FIXED: Reduced line height
                          ),
                          maxLines: 2, // ✅ FIXED: Reduced to 2 lines
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6), // ✅ FIXED: Reduced spacing
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                        ), // ✅ FIXED: Reduced padding
                        decoration: BoxDecoration(
                          color: room.getRoomColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'הזמן עכשיו',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: room.getRoomColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            'אין סטודיואים זמינים',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6b7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'נסה לשנות את הפילטר או לחזור מאוחר יותר',
            style: TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
            textAlign: TextAlign.center,
          ),
        ],
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

  void _navigateToBooking(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomBookingScreen(user: widget.user, room: room),
      ),
    );
  }
}
