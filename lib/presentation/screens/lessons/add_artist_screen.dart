import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../services/custom_auth_service.dart';
import '../../../config/service_locator.dart';
import '../../../config/themes.dart';

class AddArtistScreen extends StatefulWidget {
  const AddArtistScreen({Key? key}) : super(key: key);

  @override
  State<AddArtistScreen> createState() => _AddArtistScreenState();
}

class _AddArtistScreenState extends State<AddArtistScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic info controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _bioController = TextEditingController();

  // Address controllers
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Emergency contact controllers
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  // Medical info controllers
  final _healthFundController = TextEditingController();
  final _medicalFileController = TextEditingController();
  final _medicalInfoController = TextEditingController();
  final _nationalInsuranceController = TextEditingController();
  final _therapistContactController = TextEditingController();

  // Professional info controllers
  final _specializationController = TextEditingController();

  final CustomAuthService _authService = serviceLocator<CustomAuthService>();
  final UserRepository _userRepository = serviceLocator<UserRepository>();

  UserRole _selectedRole = UserRole.client;
  File? _profileImage;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _idNumberController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _healthFundController.dispose();
    _medicalFileController.dispose();
    _medicalInfoController.dispose();
    _nationalInsuranceController.dispose();
    _therapistContactController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Widget _buildRequiredFieldsLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFef4444).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFef4444).withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFFef4444), size: 20),
          SizedBox(width: 8),
          Text(
            'שדות המסומנים ב-',
            style: TextStyle(color: Color(0xFF6b7280), fontSize: 14),
          ),
          Text(
            ' * ',
            style: TextStyle(
              color: Color(0xFFef4444),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'הם שדות חובה',
            style: TextStyle(color: Color(0xFF6b7280), fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: Text('הוספת ${_getRoleTitle()} חדש'),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: _isLoading ? null : _createUserAccount,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('שמירה'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRequiredFieldsLegend(), // ✅ ADD: Legend

              _buildProfileImageSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 16),
              _buildContactInfoSection(),
              const SizedBox(height: 16),
              if (_selectedRole == UserRole.client)
                _buildEmergencyContactSection(),
              if (_selectedRole == UserRole.client) const SizedBox(height: 16),
              if (_selectedRole == UserRole.client) _buildMedicalInfoSection(),
              if (_selectedRole == UserRole.client) const SizedBox(height: 16),
              if (_selectedRole == UserRole.mentor ||
                  _selectedRole == UserRole.staff)
                _buildProfessionalInfoSection(),
              const SizedBox(height: 24),
              _buildPasswordSection(),
              const SizedBox(height: 24),
              if (_errorMessage != null) _buildErrorMessage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF3b82f6).withOpacity(0.1),
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : null,
              child: _profileImage == null
                  ? const Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Color(0xFF3b82f6),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('בחר תמונת פרופיל'),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'מידע בסיסי',
      icon: Icons.person_outline,
      children: [
        // Role Selection - Required
        DropdownButtonFormField<UserRole>(
          decoration: InputDecoration(
            labelText: 'תפקיד *', // ✅ ADD: Red asterisk
            labelStyle: const TextStyle(color: Color(0xFF6b7280)),
            prefixIcon: const Icon(Icons.work),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFef4444).withOpacity(0.3),
              ),
            ),
          ),
          value: _selectedRole,
          items: const [
            DropdownMenuItem(value: UserRole.client, child: Text('אמן')),
            DropdownMenuItem(value: UserRole.mentor, child: Text('מנחה')),
            DropdownMenuItem(value: UserRole.staff, child: Text('צוות')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedRole = value;
              });
            }
          },
          validator: (value) => value == null ? 'נא לבחור תפקיד' : null,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _nameController,
          label: 'שם מלא',
          icon: Icons.person,
          isRequired: true, // ✅ ADD: Required
          validator: (value) => value?.isEmpty == true ? 'שדה חובה' : null,
        ),
        _buildTextField(
          controller: _emailController,
          label: 'אימייל',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          isRequired: true, // ✅ ADD: Required
          validator: (value) {
            if (value?.isEmpty == true) return 'שדה חובה';
            if (!value!.contains('@')) return 'אימייל לא תקין';
            return null;
          },
        ),
        _buildTextField(
          controller: _phoneController,
          label: 'טלפון',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          isRequired: true, // ✅ ADD: Required
          validator: (value) => value?.isEmpty == true ? 'שדה חובה' : null,
        ),
        _buildTextField(
          controller: _idNumberController,
          label: 'מספר זהות',
          icon: Icons.badge,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          isRequired: false, // Optional
        ),
        _buildTextField(
          controller: _bioController,
          label: 'ביוגרפיה',
          icon: Icons.info_outline,
          maxLines: 3,
          isRequired: false, // Optional
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return _buildSection(
      title: 'פרטי כתובת',
      icon: Icons.home,
      children: [
        _buildTextField(
          controller: _addressController,
          label: 'כתובת',
          icon: Icons.home,
        ),
        _buildTextField(
          controller: _cityController,
          label: 'עיר',
          icon: Icons.location_city,
        ),
        _buildTextField(
          controller: _postalCodeController,
          label: 'מיקוד',
          icon: Icons.markunread_mailbox,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildEmergencyContactSection() {
    return _buildSection(
      title: 'פרטי קשר לחירום',
      icon: Icons.emergency,
      children: [
        _buildTextField(
          controller: _emergencyContactController,
          label: 'שם איש קשר',
          icon: Icons.contact_emergency,
          isRequired: true, // ✅ ADD: Required for artists
          validator: _selectedRole == UserRole.client
              ? (value) => value?.isEmpty == true ? 'שדה חובה עבור אמנים' : null
              : null,
        ),
        _buildTextField(
          controller: _emergencyPhoneController,
          label: 'טלפון חירום',
          icon: Icons.phone_in_talk,
          keyboardType: TextInputType.phone,
          isRequired: true, // ✅ ADD: Required for artists
          validator: _selectedRole == UserRole.client
              ? (value) => value?.isEmpty == true ? 'שדה חובה עבור אמנים' : null
              : null,
        ),
        _buildTextField(
          controller: _emergencyRelationController,
          label: 'קרבה משפחתית',
          icon: Icons.family_restroom,
          isRequired: false, // Optional
        ),
      ],
    );
  }

  Widget _buildMedicalInfoSection() {
    return _buildSection(
      title: 'מידע רפואי',
      icon: Icons.medical_services,
      isStaffOnly: true,
      children: [
        _buildTextField(
          controller: _healthFundController,
          label: 'קופת חולים',
          icon: Icons.local_hospital,
        ),
        _buildTextField(
          controller: _medicalFileController,
          label: 'מספר תיק רפואי',
          icon: Icons.folder_special,
        ),
        _buildTextField(
          controller: _nationalInsuranceController,
          label: 'ביטוח לאומי',
          icon: Icons.credit_card,
        ),
        _buildTextField(
          controller: _therapistContactController,
          label: 'פרטי מטפל',
          icon: Icons.psychology,
        ),
        _buildTextField(
          controller: _medicalInfoController,
          label: 'מידע רפואי נוסף',
          icon: Icons.note_add,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoSection() {
    return _buildSection(
      title: 'מידע מקצועי',
      icon: Icons.work_outline,
      children: [
        _buildTextField(
          controller: _specializationController,
          label: 'התמחות',
          icon: Icons.star,
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return _buildSection(
      title: 'פרטי התחברות',
      icon: Icons.lock_outline,
      children: [
        _buildTextField(
          controller: _passwordController,
          label: 'סיסמה',
          icon: Icons.lock,
          obscureText: _obscurePassword,
          isRequired: true, // ✅ ADD: Required
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) {
            if (value?.isEmpty == true) return 'שדה חובה';
            if (value!.length < 6) return 'הסיסמה חייבת להכיל לפחות 6 תווים';
            return null;
          },
        ),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'אימות סיסמה',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          isRequired: true, // ✅ ADD: Required
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
          validator: (value) {
            if (value?.isEmpty == true) return 'שדה חובה';
            if (value != _passwordController.text)
              return 'הסיסמאות אינן תואמות';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isStaffOnly = false,
  }) {
    return Container(
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isStaffOnly
                        ? const Color(0xFFef4444).withOpacity(0.1)
                        : const Color(0xFF3b82f6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isStaffOnly
                        ? const Color(0xFFef4444)
                        : const Color(0xFF3b82f6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                ),
                if (isStaffOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFef4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'צוות בלבד',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFef4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool obscureText = false,
    Widget? suffixIcon,
    bool isRequired = false, // ✅ ADD: Required field indicator
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        obscureText: obscureText,
        decoration: InputDecoration(
          // ✅ ADD: Red asterisk for required fields
          labelText: isRequired ? '$label *' : label,
          labelStyle: TextStyle(
            color: isRequired
                ? const Color(0xFF6b7280)
                : const Color(0xFF6b7280),
          ),
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isRequired
                  ? const Color(0xFFef4444).withOpacity(0.3)
                  : const Color(0xFFe5e7eb),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3b82f6)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFef4444)),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFef4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFef4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFef4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFef4444)),
            ),
          ),
        ],
      ),
    );
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
          backgroundColor: const Color(0xFFef4444),
        ),
      );
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final profileImageRef = storageRef.child('profile_images/$userId.jpg');

      await profileImageRef.putFile(_profileImage!);
      final downloadUrl = await profileImageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  Future<void> _createUserAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user with all the comprehensive data
      final user = await _authService.createUserByStaff(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        additionalInfo: {
          'bio': _bioController.text.trim(),
          'idNumber': _idNumberController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'postalCode': _postalCodeController.text.trim(),
          'emergencyContact': _emergencyContactController.text.trim(),
          'emergencyContactPhone': _emergencyPhoneController.text.trim(),
          'emergencyContactRelation': _emergencyRelationController.text.trim(),
          'healthFund': _healthFundController.text.trim(),
          'medicalFileNumber': _medicalFileController.text.trim(),
          'medicalInfo': _medicalInfoController.text.trim(),
          'nationalInsurance': _nationalInsuranceController.text.trim(),
          'therapistContact': _therapistContactController.text.trim(),
          'specialization': _specializationController.text.trim(),
        },
      );

      if (user == null) {
        throw Exception('יצירת המשתמש נכשלה');
      }

      // Upload profile image if selected
      if (_profileImage != null) {
        final imageUrl = await _uploadProfileImage(user.id);
        if (imageUrl != null) {
          final updatedUser = user.copyWith(profileImageUrl: imageUrl);
          await _userRepository.updateUser(updatedUser);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getRoleTitle()} נוצר בהצלחה'),
            backgroundColor: const Color(0xFF10b981),
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getRoleTitle() {
    switch (_selectedRole) {
      case UserRole.client:
        return 'אמן';
      case UserRole.mentor:
        return 'מנחה';
      case UserRole.staff:
        return 'צוות';
    }
  }
}
