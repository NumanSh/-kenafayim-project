import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/presentation/screens/analytics/artist_profile_analytics.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';

class ArtistSearchScreen extends ConsumerStatefulWidget {
  const ArtistSearchScreen({super.key});

  @override
  ConsumerState<ArtistSearchScreen> createState() => _ArtistSearchScreenState();
}

class _ArtistSearchScreenState extends ConsumerState<ArtistSearchScreen> {
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  final TextEditingController _searchController = TextEditingController();

  List<User> _allArtists = [];
  List<User> _filteredArtists = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);

    try {
      final allUsers = await _userRepository.getAllUsers();
      final artists = allUsers
          .where((user) => user.role == UserRole.client)
          .toList();

      // Sort by name
      artists.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _allArtists = artists;
          _filteredArtists = artists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת אמנים: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    }
  }

  void _filterArtists(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredArtists = _allArtists;
      } else {
        _filteredArtists = _allArtists.where((artist) {
          return artist.name.toLowerCase().contains(query.toLowerCase()) ||
              artist.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: const Text(
          'חיפוש אמן',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildArtistsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'חפש אמן לצפייה בנתוני נוכחות',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFe5e7eb)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterArtists,
              decoration: const InputDecoration(
                hintText: 'הזן שם או אימייל של אמן...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF6b7280)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3b82f6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_filteredArtists.length} אמנים נמצאו',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3b82f6),
                  ),
                ),
              ),
              const Spacer(),
              if (_searchQuery.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterArtists('');
                  },
                  child: const Text(
                    'נקה חיפוש',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
                  ),
                ),
            ],
          ),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3b82f6)),
          ),
          SizedBox(height: 16),
          Text(
            'טוען רשימת אמנים...',
            style: TextStyle(fontSize: 16, color: Color(0xFF6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsList() {
    if (_filteredArtists.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredArtists.length,
      itemBuilder: (context, index) {
        final artist = _filteredArtists[index];
        return _buildArtistCard(artist, index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: const Color(0xFF6b7280).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'אין אמנים רשומים' : 'לא נמצאו אמנים',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6b7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'נסה לרענן את הרשימה'
                : 'נסה לחפש במילות חיפוש אחרות',
            style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(User artist, int index) {
    final colors = [
      const Color(0xFF3b82f6),
      const Color(0xFF10b981),
      const Color(0xFF8b5cf6),
      const Color(0xFFf59e0b),
      const Color(0xFFef4444),
      const Color(0xFF06b6d4),
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToArtistProfile(artist),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Artist avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      artist.name.isNotEmpty
                          ? artist.name[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Artist info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'אמן',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action indicators
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.analytics, color: color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF9ca3af),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToArtistProfile(User artist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArtistProfileAnalytics(artist: artist),
      ),
    );
  }
}
