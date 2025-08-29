import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:knafayim_app/services/image_service.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';

class EnhancedProfileEditScreen extends StatefulWidget {
  final User user;
  final User currentUser;
  final Function(User) onSave;
  final VoidCallback onCancel;

  const EnhancedProfileEditScreen({
    super.key,
    required this.user,
    required this.currentUser,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<EnhancedProfileEditScreen> createState() =>
      _EnhancedProfileEditScreenState();
}

class _EnhancedProfileEditScreenState extends State<EnhancedProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserRepository _userRepository = serviceLocator<UserRepository>();

  String? _profileImageUrl;
  bool _isUploadingImage = false;

  // Controllers for all fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _idNumberController;
  late TextEditingController _bioController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;

  // Emergency contact controllers
  late TextEditingController _emergencyContactController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _emergencyRelationController;

  // Medical info controllers
  late TextEditingController _healthFundController;
  late TextEditingController _medicalFileController;
  late TextEditingController _medicalInfoController;
  late TextEditingController _nationalInsuranceController;

  // Professional info controllers
  late TextEditingController _specializationController;
  late TextEditingController _therapistContactController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _profileImageUrl = widget.user.profileImageUrl;

    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _idNumberController = TextEditingController(
      text: widget.user.idNumber ?? '',
    );
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _cityController = TextEditingController(text: widget.user.city ?? '');
    _postalCodeController = TextEditingController(
      text: widget.user.postalCode ?? '',
    );

    _emergencyContactController = TextEditingController(
      text: widget.user.emergencyContact ?? '',
    );
    _emergencyPhoneController = TextEditingController(
      text: widget.user.emergencyContactPhone ?? '',
    );
    _emergencyRelationController = TextEditingController(
      text: widget.user.emergencyContactRelation ?? '',
    );

    _healthFundController = TextEditingController(
      text: widget.user.healthFund ?? '',
    );
    _medicalFileController = TextEditingController(
      text: widget.user.medicalFileNumber ?? '',
    );
    _medicalInfoController = TextEditingController(
      text: widget.user.medicalInfo ?? '',
    );
    _nationalInsuranceController = TextEditingController(
      text: widget.user.nationalInsurance ?? '',
    );

    _specializationController = TextEditingController(
      text: widget.user.specialization ?? '',
    );
    _therapistContactController = TextEditingController(
      text: widget.user.therapistContact ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
    _specializationController.dispose();
    _therapistContactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: const Text('עריכת פרופיל'),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        actions: [
          TextButton(onPressed: widget.onCancel, child: const Text('ביטול')),
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
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
              _buildBasicInfoSection(),
              const SizedBox(height: 16),
              _buildContactInfoSection(),
              const SizedBox(height: 16),
              if (widget.currentUser.isStaff && widget.user.isArtist)
                _buildMedicalInfoSection(),
              if (widget.user.isMentor || widget.user.isStaff) ...[
                const SizedBox(height: 16),
                _buildProfessionalInfoSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'מידע בסיסי',
      icon: Icons.person_outline,
      children: [
        // ✅ ADD PROFILE IMAGE PICKER
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'תמונת פרופיל',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1f2937),
                ),
              ),
              const SizedBox(height: 8),

              // Profile Image Preview and Picker
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFf1f5f9),
                  border: Border.all(color: const Color(0xFFe2e8f0), width: 2),
                ),
                child: Stack(
                  children: [
                    // Profile Image or Placeholder
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: _profileImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_profileImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profileImageUrl == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: const Color(0xFF8b5cf6).withOpacity(0.6),
                            )
                          : null,
                    ),

                    // Edit Button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickProfileImage,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8b5cf6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        _buildTextField(
          controller: _nameController,
          label: 'שם מלא',
          icon: Icons.person,
          validator: (value) => value?.isEmpty == true ? 'שדה חובה' : null,
        ),
        _buildTextField(
          controller: _emailController,
          label: 'אימייל',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
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
          validator: (value) => value?.isEmpty == true ? 'שדה חובה' : null,
        ),
        _buildTextField(
          controller: _idNumberController,
          label: 'מספר זהות',
          icon: Icons.badge,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _buildTextField(
          controller: _bioController,
          label: 'ביוגרפיה',
          icon: Icons.info_outline,
          maxLines: 3,
        ),
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

  Future<void> _pickProfileImage() async {
    setState(() => _isUploadingImage = true);

    try {
      // ✅ FIX: Change from uploadProfilePicture to pickAndSaveProfileImage
      final String? imageUrl = await ImageService.pickAndSaveProfileImage(
        userId: widget.user.id,
        source: ImageSource.gallery,
      );

      if (imageUrl != null) {
        setState(() {
          _profileImageUrl = imageUrl;
        });

        // Save immediately to user profile
        await _updateProfileImage(imageUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה בהעלאת תמונה: $e')));
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _updateProfileImage(String imageUrl) async {
    try {
      final userRepository = serviceLocator<UserRepository>();
      final updatedUser = widget.user.copyWith(profileImageUrl: imageUrl);
      await userRepository.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('תמונת הפרופיל עודכנה בהצלחה')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשמירת תמונת הפרופיל: $e')),
        );
      }
    }
  }

  Widget _buildContactInfoSection() {
    return _buildSection(
      title: 'פרטי קשר לחירום',
      icon: Icons.emergency,
      children: [
        _buildTextField(
          controller: _emergencyContactController,
          label: 'שם איש קשר',
          icon: Icons.contact_emergency,
        ),
        _buildTextField(
          controller: _emergencyPhoneController,
          label: 'טלפון חירום',
          icon: Icons.phone_in_talk,
          keyboardType: TextInputType.phone,
        ),
        _buildTextField(
          controller: _emergencyRelationController,
          label: 'קרבה משפחתית',
          icon: Icons.family_restroom,
        ),
      ],
    );
  }

  Widget _buildMedicalInfoSection() {
    return _buildSection(
      title: 'מידע רפואי (צוות בלבד)',
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3b82f6)),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImageUrl: _profileImageUrl, // ✅ ADD THIS LINE

        idNumber: _idNumberController.text.trim().isEmpty
            ? null
            : _idNumberController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty
            ? null
            : _postalCodeController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        emergencyContactRelation:
            _emergencyRelationController.text.trim().isEmpty
            ? null
            : _emergencyRelationController.text.trim(),
        healthFund: _healthFundController.text.trim().isEmpty
            ? null
            : _healthFundController.text.trim(),
        medicalFileNumber: _medicalFileController.text.trim().isEmpty
            ? null
            : _medicalFileController.text.trim(),
        medicalInfo: _medicalInfoController.text.trim().isEmpty
            ? null
            : _medicalInfoController.text.trim(),
        nationalInsurance: _nationalInsuranceController.text.trim().isEmpty
            ? null
            : _nationalInsuranceController.text.trim(),
        specialization: _specializationController.text.trim().isEmpty
            ? null
            : _specializationController.text.trim(),
        therapistContact: _therapistContactController.text.trim().isEmpty
            ? null
            : _therapistContactController.text.trim(),
      );

      await _userRepository.updateUser(updatedUser);
      widget.onSave(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ הפרופיל עודכן בהצלחה!'),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ שגיאה בעדכון הפרופיל: $e'),
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
