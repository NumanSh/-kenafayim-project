import 'package:flutter/material.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';
import '../../../config/themes.dart';
import 'package:flutter/foundation.dart';

class ChangeRoleScreen extends StatefulWidget {
  final User user;

  const ChangeRoleScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ChangeRoleScreen> createState() => _ChangeRoleScreenState();
}

class _ChangeRoleScreenState extends State<ChangeRoleScreen> {
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  late UserRole _selectedRole;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    
    if (kDebugMode) {
      print('ChangeRoleScreen initialized for user: ${widget.user.id}, ${widget.user.name}, current role: ${widget.user.role}');
    }
  }

  Future<void> _updateUserRole() async {
    // If role hasn't changed, just go back
    if (_selectedRole == widget.user.role) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) {
        print('Changing user role: ${widget.user.id}, ${widget.user.name}, from ${widget.user.role} to $_selectedRole');
      }
      
      // Create updated user object with new role
      final updatedUser = User(
        id: widget.user.id,
        name: widget.user.name,
        email: widget.user.email,
        phoneNumber: widget.user.phoneNumber,
        role: _selectedRole,
        createdAt: widget.user.createdAt,
        profileImageUrl: widget.user.profileImageUrl,
        additionalInfo: widget.user.additionalInfo,
      );

      if (kDebugMode) {
        print('User data to update: ${updatedUser.toMap()}');
      }

      // Update user in Firestore
      final success = await _userRepository.updateUser(updatedUser);

      if (kDebugMode) {
        print('Update result: $success');
      }

      if (!success) {
        throw Exception('עדכון תפקיד המשתמש נכשל');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('תפקיד המשתמש עודכן בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user role: $e');
      }
      
      setState(() {
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בעדכון תפקיד המשתמש: $_errorMessage'),
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

  String _getRoleTitle(UserRole role) {
    switch (role) {
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
        title: Text('שינוי תפקיד: ${widget.user.name}'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User info card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryColor,
                      backgroundImage: widget.user.profileImageUrl != null &&
                              widget.user.profileImageUrl!.isNotEmpty
                          ? NetworkImage(widget.user.profileImageUrl!)
                          : null,
                      child: (widget.user.profileImageUrl == null ||
                              widget.user.profileImageUrl!.isEmpty)
                          ? Text(
                              widget.user.name.isNotEmpty
                                  ? widget.user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 24),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.user.email,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'תפקיד נוכחי: ${_getRoleTitle(widget.user.role)}',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Role selection
            const Text(
              'בחר תפקיד חדש:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Role radio buttons
            RadioListTile<UserRole>(
              title: const Text('אמן'),
              value: UserRole.client,
              groupValue: _selectedRole,
              onChanged: (UserRole? value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
              activeColor: AppTheme.primaryColor,
            ),
            RadioListTile<UserRole>(
              title: const Text('מנחה'),
              value: UserRole.mentor,
              groupValue: _selectedRole,
              onChanged: (UserRole? value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
              activeColor: AppTheme.primaryColor,
            ),
            RadioListTile<UserRole>(
              title: const Text('צוות'),
              value: UserRole.staff,
              groupValue: _selectedRole,
              onChanged: (UserRole? value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
              activeColor: AppTheme.primaryColor,
            ),

            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _updateUserRole,
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
    );
  }
}

