import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';
import '../profile/enhanced_profile_edit_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final User user;
  final User? currentUser; // To check if staff can edit

  const UserProfileScreen({super.key, required this.user, this.currentUser});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  late User _currentUser;
  final UserRepository _userRepository = serviceLocator<UserRepository>();

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.currentUser?.isStaff == true;

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: Text('פרופיל - ${_currentUser.name}'),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        actions: [
          if (canEdit)
            IconButton(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit, color: Color(0xFF3b82f6)),
              tooltip: 'עריכת פרופיל',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            _buildContactInfoCard(),
            const SizedBox(height: 16),
            if (_currentUser.isArtist) _buildEmergencyContactCard(),
            if (_currentUser.isArtist) const SizedBox(height: 16),
            if (widget.currentUser?.isStaff == true && _currentUser.isArtist)
              _buildMedicalInfoCard(),
            if (widget.currentUser?.isStaff == true && _currentUser.isArtist)
              const SizedBox(height: 16),
            if (_currentUser.isMentor || _currentUser.isStaff)
              _buildProfessionalInfoCard(),
          ],
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: _editProfile,
              backgroundColor: const Color(0xFF3b82f6),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'עריכת פרופיל',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getRoleColor(_currentUser.role),
            _getRoleColor(_currentUser.role).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getRoleColor(_currentUser.role).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage:
                _currentUser.profileImageUrl != null &&
                    _currentUser.profileImageUrl!.isNotEmpty
                ? NetworkImage(_currentUser.profileImageUrl!)
                : null,
            child:
                (_currentUser.profileImageUrl == null ||
                    _currentUser.profileImageUrl!.isEmpty)
                ? Text(
                    _currentUser.name.isNotEmpty
                        ? _currentUser.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getRoleDisplayName(_currentUser.role),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_currentUser.bio != null && _currentUser.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _currentUser.bio!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return _buildInfoCard(
      title: 'מידע בסיסי',
      icon: Icons.person_outline,
      children: [
        // ✅ FIX: Add null checks for all user fields
        if (_currentUser.idNumber?.isNotEmpty == true)
          _buildDetailRow('מספר זהות', _currentUser.idNumber!),
        _buildDetailRow('אימייל', _currentUser.email ?? 'לא זמין'),
        _buildDetailRow('טלפון', _currentUser.phoneNumber ?? 'לא זמין'),
        _buildDetailRow(
          'תאריך הצטרפות',
          _currentUser.createdAt != null
              ? '${_currentUser.createdAt.day}/${_currentUser.createdAt.month}/${_currentUser.createdAt.year}'
              : 'לא ידוע',
        ),
        if (_currentUser.address?.isNotEmpty == true)
          _buildDetailRow('כתובת', _currentUser.address!),
        if (_currentUser.city?.isNotEmpty == true)
          _buildDetailRow('עיר', _currentUser.city!),
        if (_currentUser.postalCode?.isNotEmpty == true)
          _buildDetailRow('מיקוד', _currentUser.postalCode!),
      ],
    );
  }

  Widget _buildContactInfoCard() {
    return _buildInfoCard(
      title: 'פרטי קשר',
      icon: Icons.contact_phone,
      children: [
        _buildDetailRow('אימייל', _currentUser.email),
        _buildDetailRow('טלפון', _currentUser.phoneNumber),
        if (_currentUser.address != null && _currentUser.address!.isNotEmpty)
          _buildDetailRow(
            'כתובת מלאה',
            '${_currentUser.address!}${_currentUser.city != null ? ', ${_currentUser.city!}' : ''}${_currentUser.postalCode != null ? ' ${_currentUser.postalCode!}' : ''}',
          ),
      ],
    );
  }

  Widget _buildEmergencyContactCard() {
    if (_currentUser.emergencyContact == null &&
        _currentUser.emergencyContactPhone == null &&
        _currentUser.emergencyContactRelation == null) {
      return _buildInfoCard(
        title: 'פרטי קשר לחירום',
        icon: Icons.emergency,
        children: [
          const Text(
            'לא הוגדרו פרטי קשר לחירום',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6b7280),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return _buildInfoCard(
      title: 'פרטי קשר לחירום',
      icon: Icons.emergency,
      children: [
        if (_currentUser.emergencyContact != null &&
            _currentUser.emergencyContact!.isNotEmpty)
          _buildDetailRow('שם איש קשר', _currentUser.emergencyContact!),
        if (_currentUser.emergencyContactPhone != null &&
            _currentUser.emergencyContactPhone!.isNotEmpty)
          _buildDetailRow('טלפון חירום', _currentUser.emergencyContactPhone!),
        if (_currentUser.emergencyContactRelation != null &&
            _currentUser.emergencyContactRelation!.isNotEmpty)
          _buildDetailRow(
            'קרבה משפחתית',
            _currentUser.emergencyContactRelation!,
          ),
      ],
    );
  }

  Widget _buildMedicalInfoCard() {
    final hasAnyMedicalInfo =
        _currentUser.healthFund != null ||
        _currentUser.nationalInsurance != null ||
        _currentUser.medicalFileNumber != null ||
        _currentUser.medicalInfo != null ||
        _currentUser.therapistContact != null;

    if (!hasAnyMedicalInfo) {
      return _buildInfoCard(
        title: 'מידע רפואי',
        icon: Icons.medical_services,
        isStaffOnly: true,
        children: [
          const Text(
            'לא הוגדר מידע רפואי',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6b7280),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return _buildInfoCard(
      title: 'מידע רפואי (צוות בלבד)',
      icon: Icons.medical_services,
      isStaffOnly: true,
      children: [
        if (_currentUser.healthFund != null &&
            _currentUser.healthFund!.isNotEmpty)
          _buildDetailRow('קופת חולים', _currentUser.healthFund!),
        if (_currentUser.nationalInsurance != null &&
            _currentUser.nationalInsurance!.isNotEmpty)
          _buildDetailRow('ביטוח לאומי', _currentUser.nationalInsurance!),
        if (_currentUser.medicalFileNumber != null &&
            _currentUser.medicalFileNumber!.isNotEmpty)
          _buildDetailRow('מספר תיק רפואי', _currentUser.medicalFileNumber!),
        if (_currentUser.therapistContact != null &&
            _currentUser.therapistContact!.isNotEmpty)
          _buildDetailRow('פרטי מטפל', _currentUser.therapistContact!),
        if (_currentUser.medicalInfo != null &&
            _currentUser.medicalInfo!.isNotEmpty)
          _buildDetailRow('מידע רפואי נוסף', _currentUser.medicalInfo!),
        if (_currentUser.lastMedicalUpdate != null)
          _buildDetailRow(
            'עדכון רפואי אחרון',
            '${_currentUser.lastMedicalUpdate!.day}/${_currentUser.lastMedicalUpdate!.month}/${_currentUser.lastMedicalUpdate!.year}',
          ),
      ],
    );
  }

  Widget _buildProfessionalInfoCard() {
    return _buildInfoCard(
      title: 'מידע מקצועי',
      icon: Icons.work_outline,
      children: [
        if (_currentUser.specialization != null &&
            _currentUser.specialization!.isNotEmpty)
          _buildDetailRow('התמחות', _currentUser.specialization!),
        if (_currentUser.disciplines != null &&
            _currentUser.disciplines!.isNotEmpty)
          _buildDetailRow('תחומי הוראה', _currentUser.disciplines!.join(', ')),
        if (_currentUser.startDate != null)
          _buildDetailRow(
            'תאריך התחלה',
            '${_currentUser.startDate!.day}/${_currentUser.startDate!.month}/${_currentUser.startDate!.year}',
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
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
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1f2937),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    if (widget.currentUser?.isStaff != true) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedProfileEditScreen(
          user: _currentUser,
          currentUser: widget.currentUser!,
          onSave: (updatedUser) {
            setState(() {
              _currentUser = updatedUser;
            });
            Navigator.pop(context);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.client:
        return const Color(0xFF10b981);
      case UserRole.mentor:
        return const Color(0xFF3b82f6);
      case UserRole.staff:
        return const Color(0xFFf59e0b);
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.client:
        return 'אמן';
      case UserRole.mentor:
        return 'מנחה';
      case UserRole.staff:
        return 'צוות';
    }
  }
}
