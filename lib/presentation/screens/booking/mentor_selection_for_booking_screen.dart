import 'package:flutter/material.dart';
import '../../../data/models/room.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';
import 'room_booking_screen.dart';

class MentorSelectionForBookingScreen extends StatefulWidget {
  final User staffUser;
  final Room room;

  const MentorSelectionForBookingScreen({
    Key? key,
    required this.staffUser,
    required this.room,
  }) : super(key: key);

  @override
  State<MentorSelectionForBookingScreen> createState() =>
      _MentorSelectionForBookingScreenState();
}

class _MentorSelectionForBookingScreenState
    extends State<MentorSelectionForBookingScreen> {
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  List<User> _mentors = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMentors();
  }

  Future<void> _loadMentors() async {
    setState(() => _isLoading = true);

    try {
      final mentors = await _userRepository.getUsersByRole(UserRole.mentor);
      if (mounted) {
        setState(() {
          _mentors = mentors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה בטעינת מנחים: $e')));
      }
    }
  }

  List<User> get _filteredMentors {
    if (_searchQuery.isEmpty) return _mentors;
    return _mentors
        .where(
          (mentor) =>
              mentor.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: Text(
          'בחר מנחה עבור ${widget.room.displayName}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                _buildRoomInfo(),
                Expanded(child: _buildMentorsList()),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'חפש מנחה...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6b7280)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          hintStyle: const TextStyle(color: Color(0xFF9ca3af)),
        ),
      ),
    );
  }

  Widget _buildRoomInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.room.getRoomColor(),
            widget.room.getRoomColor().withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
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
              _getRoomIcon(widget.room.type),
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
                  widget.room.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'בחר מנחה להזמנת הסטודיו',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorsList() {
    final filteredMentors = _filteredMentors;

    if (filteredMentors.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Color(0xFF6b7280)),
            SizedBox(height: 16),
            Text(
              'לא נמצאו מנחים',
              style: TextStyle(fontSize: 16, color: Color(0xFF6b7280)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMentors.length,
      itemBuilder: (context, index) {
        final mentor = filteredMentors[index];
        return _buildMentorCard(mentor);
      },
    );
  }

  Widget _buildMentorCard(User mentor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectMentor(mentor),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: widget.room.getRoomColor().withOpacity(0.1),
                  child: Text(
                    mentor.name.isNotEmpty ? mentor.name[0].toUpperCase() : 'M',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.room.getRoomColor(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      Text(
                        mentor.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.room.getRoomColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'בחר',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.room.getRoomColor(),
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

  void _selectMentor(User mentor) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RoomBookingScreen(
          user: mentor, // Pass the selected mentor, not staff
          room: widget.room,
        ),
      ),
    );
  }
}
