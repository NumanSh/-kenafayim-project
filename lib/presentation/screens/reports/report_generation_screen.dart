// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:knafayim_app/services/report_generation_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';
import '../../../services/auth_service.dart';

class ReportGenerationScreen extends StatefulWidget {
  const ReportGenerationScreen({super.key});

  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  final AuthService _authService = serviceLocator<AuthService>();
  final ReportGenerationService _reportService = ReportGenerationService();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  String? _selectedArtistId;
  String? _selectedInstructorId;
  bool _includeMedicalFlags = false;
  String _exportFormat = 'pdf';
  String _exportMethod = 'download';

  bool _isLoading = false;
  List<User> _artists = [];
  List<User> _instructors = [];
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await _authService.getCurrentUser();

      if (_currentUser == null || _currentUser!.role != UserRole.staff) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('רק צוות מורשה לגשת למסך זה'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      // Load artists (clients)
      final artists = await _userRepository.getUsersByRole(UserRole.client);

      // Load instructors (mentors)
      final instructors = await _userRepository.getUsersByRole(UserRole.mentor);

      setState(() {
        _artists = artists;
        _instructors = instructors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בטעינת משתמשים: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> uploadReportToStorage(File reportFile, String userId) async {
    try {
      final fileName = reportFile.path.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance.ref().child(
        'reports/$userId/${timestamp}_$fileName',
      );

      final uploadTask = storageRef.putFile(reportFile);
      final snapshot = await uploadTask.whenComplete(() {});

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload report: ${e.toString()}');
    }
  }

  Future<void> sendReportByEmail(
    String email,
    File reportFile,
    String subject,
  ) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': subject,
          'body': 'מצורף דוח ${reportFile.path.split('/').last}',
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      throw Exception('Failed to send email: ${e.toString()}');
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _generateReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text;

      final reportFile = await _reportService.generateAttendanceReport(
        title: title,
        startDate: _startDate,
        endDate: _endDate,
        artistId: _selectedArtistId,
        instructorId: _selectedInstructorId,
        includeMedicalFlags: _includeMedicalFlags,
        format: _exportFormat,
      );

      // Handle export method
      switch (_exportMethod) {
        case 'download':
          // File is already saved locally, show success message with path
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('הדוח נוצר בהצלחה: ${reportFile.path}'),
              backgroundColor: Colors.green,
            ),
          );
          break;

        case 'email':
          if (_currentUser != null) {
            await sendReportByEmail(
              _currentUser!.email,
              reportFile,
              'דוח: $title',
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('הדוח נשלח בהצלחה לאימייל שלך'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;

        case 'storage':
          if (_currentUser != null) {
            final downloadUrl = await uploadReportToStorage(
              reportFile,
              _currentUser!.id,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('הדוח הועלה בהצלחה לאחסון: $downloadUrl'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 10),
              ),
            );
          }
          break;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה ביצירת הדוח: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('יצירת דוח')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'כותרת הדוח',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'נא להזין כותרת';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Range
                    const Text(
                      'טווח תאריכים:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'מתאריך',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_startDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'עד תאריך',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_endDate),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Artist Selection
                    const Text(
                      'סינון לפי:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'אמן (אופציונלי)',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedArtistId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('כל האמנים'),
                        ),
                        ..._artists.map((artist) {
                          return DropdownMenuItem<String>(
                            value: artist.id,
                            child: Text(artist.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedArtistId = value;
                          // Clear instructor if artist is selected
                          if (value != null) {
                            _selectedInstructorId = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Instructor Selection
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'מנחה (אופציונלי)',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedInstructorId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('כל המנחים'),
                        ),
                        ..._instructors.map((instructor) {
                          return DropdownMenuItem<String>(
                            value: instructor.id,
                            child: Text(instructor.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedInstructorId = value;
                          // Clear artist if instructor is selected
                          if (value != null) {
                            _selectedArtistId = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Medical Flags Option
                    CheckboxListTile(
                      title: const Text('כלול מידע רפואי (אם מורשה)'),
                      value: _includeMedicalFlags,
                      onChanged: (value) {
                        setState(() {
                          _includeMedicalFlags = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),

                    // Export Format
                    const Text(
                      'פורמט ייצוא:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('PDF'),
                            value: 'pdf',
                            groupValue: _exportFormat,
                            onChanged: (value) {
                              setState(() {
                                _exportFormat = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Excel'),
                            value: 'excel',
                            groupValue: _exportFormat,
                            onChanged: (value) {
                              setState(() {
                                _exportFormat = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Export Method
                    const Text(
                      'שיטת ייצוא:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('הורדה למכשיר'),
                      value: 'download',
                      groupValue: _exportMethod,
                      onChanged: (value) {
                        setState(() {
                          _exportMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('שליחה באימייל'),
                      value: 'email',
                      groupValue: _exportMethod,
                      onChanged: (value) {
                        setState(() {
                          _exportMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('שמירה באחסון Firebase'),
                      value: 'storage',
                      groupValue: _exportMethod,
                      onChanged: (value) {
                        setState(() {
                          _exportMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _generateReport,
                        child: const Text(
                          'צור דוח',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
