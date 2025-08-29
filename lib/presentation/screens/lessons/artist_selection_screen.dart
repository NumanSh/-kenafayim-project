import 'package:flutter/material.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';
import '../profile/artist_profile_screen.dart';

class ArtistSelectionScreen extends StatefulWidget {
  final List<String> currentArtistIds;
  
  const ArtistSelectionScreen({
    Key? key, 
    required this.currentArtistIds,
  }) : super(key: key);

  @override
  _ArtistSelectionScreenState createState() => _ArtistSelectionScreenState();
}

class _ArtistSelectionScreenState extends State<ArtistSelectionScreen> {
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  
  List<User> _allArtists = [];
  List<User> _filteredArtists = [];
  List<String> _selectedArtistIds = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _selectedArtistIds = List.from(widget.currentArtistIds);
    _loadArtists();
  }
  
  Future<void> _loadArtists() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get all users with client role
      final artists = await _userRepository.getUsersByRole(UserRole.client);
      
      if (mounted) {
        setState(() {
          _allArtists = artists;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת רשימת האמנים: $e')),
        );
      }
    }
  }
  
  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredArtists = List.from(_allArtists);
    } else {
      _filteredArtists = _allArtists
          .where((artist) => 
              artist.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              artist.email.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }
  
  void _toggleArtistSelection(String artistId) {
    setState(() {
      if (_selectedArtistIds.contains(artistId)) {
        _selectedArtistIds.remove(artistId);
      } else {
        _selectedArtistIds.add(artistId);
      }
    });
  }

  void _viewArtistProfile(String artistId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArtistProfileScreen(
          artistId: artistId,
          isStaffView: true,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הרשמת אמנים לשיעור'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_selectedArtistIds);
            },
            child: const Text(
              'שמור',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'חיפוש אמנים',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilter();
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredArtists.isEmpty
                    ? const Center(child: Text('לא נמצאו אמנים'))
                    : ListView.builder(
                        itemCount: _filteredArtists.length,
                        itemBuilder: (context, index) {
                          final artist = _filteredArtists[index];
                          final isSelected = _selectedArtistIds.contains(artist.id);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: CheckboxListTile(
                              title: Text(artist.name),
                              subtitle: Text(artist.email),
                              value: isSelected,
                              onChanged: (_) => _toggleArtistSelection(artist.id),
                              secondary: GestureDetector(
                                onTap: () => _viewArtistProfile(artist.id),
                                child: CircleAvatar(
                                  backgroundImage: artist.profileImageUrl != null && 
                                                  artist.profileImageUrl!.isNotEmpty
                                      ? NetworkImage(artist.profileImageUrl!)
                                      : null,
                                  child: artist.profileImageUrl == null || 
                                        artist.profileImageUrl!.isEmpty
                                      ? Text(artist.name.isNotEmpty ? artist.name[0] : '?')
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'נבחרו ${_selectedArtistIds.length} אמנים',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(_selectedArtistIds);
                  },
                  child: const Text('אישור הרשמה'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
