import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:knafayim_app/presentation/screens/profile/enhanced_profile_edit_screen.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserRepository _userRepository = serviceLocator<UserRepository>();

  late User _currentUser;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Use the user passed from the drawer directly
    _currentUser = widget.user;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: const Text(
          'פרופיל אישי',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
        actions: [
          // Only show edit button if user is NOT an artist (client)
          if (_currentUser.role != UserRole.client)
            IconButton(
              onPressed: () => _toggleEditMode(),
              icon: Icon(
                _isEditing ? Icons.save : Icons.edit,
                color: const Color(0xFF3b82f6),
              ),
            ),
          // Show info icon for artists to explain why they can't edit
          if (_currentUser.role == UserRole.client)
            IconButton(
              onPressed: () => _showReadOnlyInfo(),
              icon: const Icon(Icons.info_outline, color: Color(0xFF6b7280)),
            ),
        ],
      ),
      body: _isEditing ? _buildEditMode() : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // Show read-only notice for artists
          if (_currentUser.role == UserRole.client) _buildReadOnlyNotice(),

          if (_currentUser.role == UserRole.client) const SizedBox(height: 16),

          _buildBasicInfoCard(),
          const SizedBox(height: 16),

          // Contact info - show to staff or if viewing own profile
          if (_currentUser.isStaff || _currentUser.id == widget.user.id)
            _buildContactInfoCard(),
          if (_currentUser.isStaff || _currentUser.id == widget.user.id)
            const SizedBox(height: 16),

          // Medical info - only staff can see for artists
          if (_currentUser.isStaff && widget.user.isArtist)
            _buildMedicalInfoCard(),
          if (_currentUser.isStaff && widget.user.isArtist)
            const SizedBox(height: 16),

          // Professional info - for mentors and staff
          if (widget.user.isMentor || widget.user.isStaff)
            _buildProfessionalInfoCard(),
        ],
      ),
    );
  }

  Widget _buildReadOnlyNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFfef3c7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility, color: const Color(0xFFf59e0b), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'פרופיל לקריאה בלבד',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400e),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'לעדכון פרטים אישיים, פנה לצוות הארגון',
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400e)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return EnhancedProfileEditScreen(
      user: widget.user,
      currentUser: _currentUser,
      onSave: (updatedUser) {
        setState(() {
          _currentUser = updatedUser;
          _isEditing = false;
        });
      },
      onCancel: () {
        setState(() => _isEditing = false);
      },
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _currentUser.role == UserRole.client
                ? const Color(0xFF8b5cf6) // Purple for artists
                : const Color(0xFF3b82f6), // Blue for staff/mentors
            (_currentUser.role == UserRole.client
                    ? const Color(0xFF8b5cf6)
                    : const Color(0xFF3b82f6))
                .withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (_currentUser.role == UserRole.client
                        ? const Color(0xFF8b5cf6)
                        : const Color(0xFF3b82f6))
                    .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage:
                    widget.user.profileImageUrl != null &&
                        widget.user.profileImageUrl!.isNotEmpty
                    ? NetworkImage(widget.user.profileImageUrl!)
                    : null,
                child:
                    widget.user.profileImageUrl == null ||
                        widget.user.profileImageUrl!.isEmpty
                    ? Text(
                        widget.user.name.isNotEmpty
                            ? widget.user.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              // Add read-only indicator for artists
              if (_currentUser.role == UserRole.client)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.visibility,
                      color: Color(0xFF8b5cf6),
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentUser.role == UserRole.client)
                  const Icon(Icons.visibility, size: 14, color: Colors.white),
                if (_currentUser.role == UserRole.client)
                  const SizedBox(width: 4),
                Text(
                  _getRoleText(widget.user.role),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return _buildInfoCard(
      title: 'מידע בסיסי',
      icon: Icons.person_outline,
      children: [
        // ✅ ADD: ID Number
        if (widget.user.idNumber != null && widget.user.idNumber!.isNotEmpty)
          _buildInfoRow('מספר זהות', widget.user.idNumber!),

        // ✅ ADD: Biography
        if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
          _buildInfoRow('ביוגרפיה', widget.user.bio!),

        _buildInfoRow('אימייל', widget.user.email),
        _buildInfoRow('טלפון', widget.user.phoneNumber),

        // ✅ ADD: Address fields
        if (widget.user.address != null && widget.user.address!.isNotEmpty)
          _buildInfoRow('כתובת', widget.user.address!),
        if (widget.user.city != null && widget.user.city!.isNotEmpty)
          _buildInfoRow('עיר', widget.user.city!),
        if (widget.user.postalCode != null &&
            widget.user.postalCode!.isNotEmpty)
          _buildInfoRow('מיקוד', widget.user.postalCode!),
      ],
    );
  }

  Widget _buildContactInfoCard() {
    return _buildInfoCard(
      title: 'פרטי קשר לחירום',
      icon: Icons.emergency,
      children: [
        if (widget.user.emergencyContact != null &&
            widget.user.emergencyContact!.isNotEmpty)
          _buildInfoRow('איש קשר', widget.user.emergencyContact!),
        if (widget.user.emergencyContactPhone != null &&
            widget.user.emergencyContactPhone!.isNotEmpty)
          _buildInfoRow('טלפון חירום', widget.user.emergencyContactPhone!),
        if (widget.user.emergencyContactRelation != null &&
            widget.user.emergencyContactRelation!.isNotEmpty)
          _buildInfoRow('קרבה משפחתית', widget.user.emergencyContactRelation!),
      ],
    );
  }

  Widget _buildMedicalInfoCard() {
    return _buildInfoCard(
      title: 'מידע רפואי (צוות בלבד)',
      icon: Icons.medical_services,
      isStaffOnly: true,
      children: [
        if (widget.user.healthFund != null &&
            widget.user.healthFund!.isNotEmpty)
          _buildInfoRow('קופת חולים', widget.user.healthFund!),
        if (widget.user.therapistContact != null &&
            widget.user.therapistContact!.isNotEmpty)
          _buildInfoRow('פרטי מטפל', widget.user.therapistContact!),
        if (widget.user.nationalInsurance != null &&
            widget.user.nationalInsurance!.isNotEmpty)
          _buildInfoRow('ביטוח לאומי', widget.user.nationalInsurance!),
        if (widget.user.medicalFileNumber != null &&
            widget.user.medicalFileNumber!.isNotEmpty)
          _buildInfoRow('מספר תיק רפואי', widget.user.medicalFileNumber!),
        if (widget.user.medicalInfo != null &&
            widget.user.medicalInfo!.isNotEmpty)
          _buildInfoRow('מידע רפואי נוסף', widget.user.medicalInfo!),
      ],
    );
  }

  Widget _buildProfessionalInfoCard() {
    return _buildInfoCard(
      title: 'מידע מקצועי',
      icon: Icons.work_outline,
      children: [
        if (widget.user.specialization != null &&
            widget.user.specialization!.isNotEmpty)
          _buildInfoRow('התמחות', widget.user.specialization!),
        if (widget.user.disciplines != null &&
            widget.user.disciplines!.isNotEmpty)
          _buildInfoRow('תחומי הוראה', widget.user.disciplines!.join(', ')),
        if (widget.user.startDate != null)
          _buildInfoRow('תאריך התחלה', _formatDate(widget.user.startDate!)),
      ],
    );
  }

  Widget _buildInfoCard({
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
              ],
            ),
            if (children.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...children,
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'אין מידע זמין',
                  style: TextStyle(
                    color: Color(0xFF6b7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6b7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1f2937)),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleEditMode() {
    // Prevent artists from entering edit mode
    if (_currentUser.role == UserRole.client) {
      _showReadOnlyInfo();
      return;
    }

    setState(() => _isEditing = !_isEditing);
  }

  void _showReadOnlyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF3b82f6)),
            SizedBox(width: 8),
            Text('פרופיל לקריאה בלבד'),
          ],
        ),
        content: const Text(
          'אמנים יכולים לצפות בפרופיל שלהם אך לא לערוך אותו.\n\n'
          'לעדכון פרטים אישיים, אנא פנה לצוות הארגון.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'הבנתי',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.client:
        return 'אמן';
      case UserRole.mentor:
        return 'מנחה';
      case UserRole.staff:
        return 'צוות';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
