import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';
import '../../../services/auth_service.dart';

class ArtistProfileScreen extends StatefulWidget {
  final String artistId;
  final bool isStaffView;

  const ArtistProfileScreen({
    Key? key,
    required this.artistId,
    this.isStaffView = false,
  }) : super(key: key);

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  final AuthService _authService = serviceLocator<AuthService>();

  User? _artist;
  User? _currentUser;
  bool _isLoading = true;
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load current user to check permissions
      _currentUser = await _authService.getCurrentUser();
      _isStaff = _currentUser?.role == UserRole.staff;

      // Load artist profile
      _artist = await _userRepository.getUserById(widget.artistId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בטעינת פרופיל: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_artist?.name ?? 'פרופיל אמן'),
        actions: [
          if (_isStaff && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _navigateToEditProfile();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _artist == null
              ? const Center(child: Text('לא נמצא פרופיל'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Public Information Section
                      _buildSectionHeader('מידע ציבורי'),
                      _buildProfileImage(),
                      _buildInfoTile('שם', _artist!.name),
                      if (_artist!.bio != null && _artist!.bio!.isNotEmpty)
                        _buildInfoTile('ביוגרפיה', _artist!.bio!),

                      const SizedBox(height: 24),

                      // Private Information Section - Only visible to staff
                      if (_isStaff || widget.isStaffView)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('מידע פרטי (מוצג רק לצוות)'),
                            _buildInfoTile('אימייל', _artist!.email),
                            _buildInfoTile('טלפון', _artist!.phoneNumber),
                            if (_artist!.emergencyContact != null &&
                                _artist!.emergencyContact!.isNotEmpty)
                              _buildInfoTile(
                                  'איש קשר לחירום', _artist!.emergencyContact!),
                            const SizedBox(height: 24),
                          ],
                        ),

                      // Medical Information Section - Only visible to staff
                      if (_isStaff || widget.isStaffView)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('מידע רפואי (מוצג רק לצוות)'),
                            if (_artist!.healthFund != null &&
                                _artist!.healthFund!.isNotEmpty)
                              _buildInfoTile(
                                  'קופת חולים', _artist!.healthFund!),
                            if (_artist!.therapistContact != null &&
                                _artist!.therapistContact!.isNotEmpty)
                              _buildInfoTile(
                                  'פרטי מטפל', _artist!.therapistContact!),
                            if (_artist!.medicalInfo != null &&
                                _artist!.medicalInfo!.isNotEmpty)
                              _buildInfoTile(
                                  'מידע רפואי נוסף', _artist!.medicalInfo!),
                            if ((_artist!.healthFund == null ||
                                    _artist!.healthFund!.isEmpty) &&
                                (_artist!.therapistContact == null ||
                                    _artist!.therapistContact!.isEmpty) &&
                                (_artist!.medicalInfo == null ||
                                    _artist!.medicalInfo!.isEmpty))
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('אין מידע רפואי זמין'),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: CircleAvatar(
          radius: 60,
          backgroundImage: _artist!.profileImageUrl != null &&
                  _artist!.profileImageUrl!.isNotEmpty
              ? NetworkImage(_artist!.profileImageUrl!)
              : null,
          child: _artist!.profileImageUrl == null ||
                  _artist!.profileImageUrl!.isEmpty
              ? const Icon(Icons.person, size: 60)
              : null,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile() {
    if (_artist != null) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => ArtistProfileEditScreen(artist: _artist!),
        ),
      )
          .then((_) {
        // Refresh data when returning from edit screen
        _loadData();
      });
    }
  }
}

class ArtistProfileEditScreen extends StatefulWidget {
  final User artist;

  const ArtistProfileEditScreen({
    super.key,
    required this.artist,
  });

  @override
  State<ArtistProfileEditScreen> createState() =>
      _ArtistProfileEditScreenState();
}

class _ArtistProfileEditScreenState extends State<ArtistProfileEditScreen> {
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _healthFundController;
  late TextEditingController _therapistContactController;
  late TextEditingController _medicalInfoController;

  bool _isLoading = false;
  File? _selectedImage;
  String? _currentProfileImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.artist.name);
    _bioController = TextEditingController(text: widget.artist.bio ?? '');
    _emailController = TextEditingController(text: widget.artist.email);
    _phoneController = TextEditingController(text: widget.artist.phoneNumber);
    _emergencyContactController =
        TextEditingController(text: widget.artist.emergencyContact ?? '');
    _healthFundController =
        TextEditingController(text: widget.artist.healthFund ?? '');
    _therapistContactController =
        TextEditingController(text: widget.artist.therapistContact ?? '');
    _medicalInfoController =
        TextEditingController(text: widget.artist.medicalInfo ?? '');
    
    _currentProfileImageUrl = widget.artist.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _healthFundController.dispose();
    _therapistContactController.dispose();
    _medicalInfoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בבחירת תמונה: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) {
      return _currentProfileImageUrl;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Create a reference to the location where we'll store the file
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${widget.artist.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the file
      final uploadTask = storageRef.putFile(_selectedImage!);
      
      // Wait for the upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _isUploadingImage = false;
      });
      
      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בהעלאת תמונה: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload profile image if selected
      String? profileImageUrl = await _uploadProfileImage();
      
      // Create updated user object
      final updatedArtist = User(
        id: widget.artist.id,
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        role: widget.artist.role,
        createdAt: widget.artist.createdAt,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        emergencyContact: _emergencyContactController.text.isEmpty
            ? null
            : _emergencyContactController.text,
        healthFund: _healthFundController.text.isEmpty
            ? null
            : _healthFundController.text,
        therapistContact: _therapistContactController.text.isEmpty
            ? null
            : _therapistContactController.text,
        medicalInfo: _medicalInfoController.text.isEmpty
            ? null
            : _medicalInfoController.text,
        profileImageUrl: profileImageUrl,
      );

      // Update user in repository
      await _userRepository.updateUser(updatedArtist);

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('הפרופיל עודכן בהצלחה'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בעדכון פרופיל: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('עריכת פרופיל - ${widget.artist.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image Section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                      : (_currentProfileImageUrl != null &&
                                              _currentProfileImageUrl!.isNotEmpty
                                          ? NetworkImage(_currentProfileImageUrl!)
                                          : null) as ImageProvider?,
                                  child: (_selectedImage == null &&
                                          (_currentProfileImageUrl == null ||
                                              _currentProfileImageUrl!.isEmpty))
                                      ? const Icon(Icons.person, size: 60)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                if (_isUploadingImage)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'לחץ לשינוי תמונת פרופיל',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Public Information Section
                    _buildSectionHeader('מידע ציבורי'),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'שם',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'נא להזין שם';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'ביוגרפיה',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    // Private Information Section
                    _buildSectionHeader('מידע פרטי (מוצג רק לצוות)'),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'אימייל',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'נא להזין אימייל';
                        }
                        if (!value.contains('@')) {
                          return 'נא להזין אימייל תקין';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'טלפון',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'נא להזין מספר טלפון';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyContactController,
                      decoration: const InputDecoration(
                        labelText: 'איש קשר לחירום',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Medical Information Section
                    _buildSectionHeader('מידע רפואי (מוצג רק לצוות)'),
                    TextFormField(
                      controller: _healthFundController,
                      decoration: const InputDecoration(
                        labelText: 'קופת חולים',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _therapistContactController,
                      decoration: const InputDecoration(
                        labelText: 'פרטי מטפל',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _medicalInfoController,
                      decoration: const InputDecoration(
                        labelText: 'מידע רפואי נוסף',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading || _isUploadingImage ? null : _saveProfile,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'שמור שינויים',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
