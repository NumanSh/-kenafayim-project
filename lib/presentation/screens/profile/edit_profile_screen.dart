import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';
import '../../../config/themes.dart';
import 'package:flutter/foundation.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  final UserRepository _userRepository = serviceLocator<UserRepository>();

  File? _profileImage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _bioController = TextEditingController(
      text: widget.user.additionalInfo?['bio'] as String? ?? '',
    );

    if (kDebugMode) {
      print(
        'EditProfileScreen initialized for user: ${widget.user.id}, ${widget.user.name}, ${widget.user.role}',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בבחירת תמונה: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return widget.user.profileImageUrl;

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final profileImageRef = storageRef.child('profile_images/$userId.jpg');

      // Upload the file
      await profileImageRef.putFile(_profileImage!);

      // Get download URL
      final downloadUrl = await profileImageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile image: $e');
      }
      return widget.user.profileImageUrl;
    }
  }

  Future<void> _updateUserProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Upload profile image if selected
      final imageUrl = await _uploadProfileImage(widget.user.id);

      // Create updated user object
      final updatedUser = User(
        id: widget.user.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: widget.user.role,
        createdAt: widget.user.createdAt,
        profileImageUrl: imageUrl,
        additionalInfo: {
          ...widget.user.additionalInfo ?? {},
          'bio': _bioController.text.trim(),
        },
      );

      if (kDebugMode) {
        print('Updating user profile: ${updatedUser.id}, ${updatedUser.name}');
        print('User data to update: ${updatedUser.toMap()}');
      }

      // Update user in Firestore
      final success = await _userRepository.updateUser(updatedUser);

      if (kDebugMode) {
        print('Update result: $success');
      }

      if (!success) {
        throw Exception('עדכון הפרופיל נכשל');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הפרופיל עודכן בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }

      setState(() {
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בעדכון פרופיל: $_errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getRoleTitle() {
    switch (widget.user.role) {
      case UserRole.client:
        return 'אמן';
      case UserRole.mentor:
        return 'מנחה';
      case UserRole.staff:
        return 'צוות';
      default:
        return 'משתמש';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('עריכת פרופיל ${_getRoleTitle()}'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Image
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (widget.user.profileImageUrl != null &&
                                    widget.user.profileImageUrl!.isNotEmpty
                                ? NetworkImage(widget.user.profileImageUrl!)
                                      as ImageProvider
                                : null),
                      child:
                          (_profileImage == null &&
                              (widget.user.profileImageUrl == null ||
                                  widget.user.profileImageUrl!.isEmpty))
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _pickImage,
                    child: const Text('שנה תמונת פרופיל'),
                  ),
                ),
                const SizedBox(height: 16),

                // Role Display (non-editable)
                TextFormField(
                  initialValue: _getRoleTitle(),
                  decoration: const InputDecoration(
                    labelText: 'תפקיד',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 16),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'שם מלא',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textDirection: TextDirection.rtl,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'נא להזין שם מלא';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'אימייל',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'נא להזין כתובת אימייל';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'נא להזין כתובת אימייל תקינה';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'מספר טלפון',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'נא להזין מספר טלפון';
                    }
                    if (value.length < 9 || value.length > 10) {
                      return 'מספר טלפון חייב להכיל 9-10 ספרות';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Bio Field
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'פרטים נוספים / ביוגרפיה',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 4,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateUserProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'שמור שינויים',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
