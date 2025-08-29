import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/room.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../config/service_locator.dart';

class CreateRoomScreen extends StatefulWidget {
  final User user;

  const CreateRoomScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final RoomRepository _roomRepository = serviceLocator<RoomRepository>();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();

  // Form data
  RoomType _selectedType = RoomType.plasticArts;
  RoomStatus _selectedStatus = RoomStatus.available;
  List<String> _features = [];
  List<String> _resources = [];
  File? _roomImage;
  bool _isLoading = false;

  // Predefined options
  final List<String> _availableFeatures = [
    'תאורה מקצועית',
    'מערכת קול',
    'מיזוג אוויר',
    'אוורור',
    'כיור לניקוי',
    'מראות',
    'במה',
    'בידוד קולי',
    'מקרן',
    'מסך',
    'שולחנות גדולים',
    'כסאות נוחים',
  ];

  final Map<RoomType, List<String>> _typeResources = {
    RoomType.plasticArts: [
      'צבעים',
      'מכחולים',
      'בדים',
      'עפרונות',
      'פחם',
      'חימר',
    ],
    RoomType.theater: [
      'תלבושות',
      'אביזרי במה',
      'מיקרופונים',
      'כסאות',
      'תאורת במה',
    ],
    RoomType.music: ['גיטרות', 'תופים', 'מיקרופונים', 'אוזניות', 'פסנתר'],
    RoomType.writing: ['מחשבים', 'מדפסת', 'נייר', 'עטים', 'מכונות כתיבה'],
    RoomType.animation: ['טאבלטים', 'עטים דיגיטליים', 'אוזניות', 'מקלדות'],
    RoomType.videoCinema: [
      'מצלמות',
      'חצובות',
      'מיקרופונים',
      'כרטיסי זיכרון',
      'תאורה',
    ],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildTypeAndStatusSection(),
              const SizedBox(height: 24),
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildFeaturesSection(),
              const SizedBox(height: 24),
              _buildResourcesSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildCreateButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      title: const Text(
        'יצירת סטודיו חדש',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1f2937),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'מידע בסיסי',
      icon: Icons.info_outline,
      child: Column(
        children: [
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'שם הסטודיו',
              hintText: 'לדוגמה: סטודיו אמנות פלסטית',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'אנא הכנס שם לסטודיו';
              }
              return null;
            },
            onChanged: (value) {
              // Auto-generate internal name
              _nameController.text = value
                  .toLowerCase()
                  .replaceAll(' ', '_')
                  .replaceAll(RegExp(r'[^\w\u0590-\u05FF]'), '');
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'מיקום',
              hintText: 'לדוגמה: קומה 1, חדר 101',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'אנא הכנס מיקום';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'קיבולת מקסימלית',
              hintText: 'מספר אנשים',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.people),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'אנא הכנס קיבולת';
              }
              final capacity = int.tryParse(value);
              if (capacity == null || capacity <= 0) {
                return 'אנא הכנס מספר חוקי';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'תיאור',
              hintText: 'תאר את הסטודיו ויעודו...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'אנא הכנס תיאור';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeAndStatusSection() {
    return _buildSection(
      title: 'סוג וסטטוס',
      icon: Icons.category,
      child: Column(
        children: [
          DropdownButtonFormField<RoomType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'סוג סטודיו',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.palette),
            ),
            items: RoomType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      _getRoomIcon(type),
                      size: 20,
                      color: _getRoomColor(type),
                    ),
                    const SizedBox(width: 8),
                    Text(_getRoomTypeDisplayName(type)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
                _resources = []; // Reset resources when type changes
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<RoomStatus>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'סטטוס ראשוני',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.info),
            ),
            items: RoomStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_getStatusText(status)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return _buildSection(
      title: 'תמונת סטודיו',
      icon: Icons.image,
      child: Column(
        children: [
          if (_roomImage != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_roomImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_roomImage != null ? 'שנה תמונה' : 'הוסף תמונה'),
                ),
              ),
              if (_roomImage != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => setState(() => _roomImage = null),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return _buildSection(
      title: 'מאפיינים',
      icon: Icons.star,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'בחר מאפיינים של הסטודיו:',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableFeatures.map((feature) {
              final isSelected = _features.contains(feature);
              return FilterChip(
                label: Text(feature),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _features.add(feature);
                    } else {
                      _features.remove(feature);
                    }
                  });
                },
                backgroundColor: Colors.grey[100],
                selectedColor: _getRoomColor(_selectedType).withOpacity(0.2),
                checkmarkColor: _getRoomColor(_selectedType),
                labelStyle: TextStyle(
                  color: isSelected
                      ? _getRoomColor(_selectedType)
                      : const Color(0xFF6b7280),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesSection() {
    final availableResources = _typeResources[_selectedType] ?? [];

    return _buildSection(
      title: 'ציוד וחומרים',
      icon: Icons.inventory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'בחר ציוד זמין ב${_getRoomTypeDisplayName(_selectedType)}:',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
          ),
          const SizedBox(height: 8),
          if (availableResources.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableResources.map((resource) {
                final isSelected = _resources.contains(resource);
                return FilterChip(
                  label: Text(resource),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _resources.add(resource);
                      } else {
                        _resources.remove(resource);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: _getRoomColor(_selectedType).withOpacity(0.2),
                  checkmarkColor: _getRoomColor(_selectedType),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? _getRoomColor(_selectedType)
                        : const Color(0xFF6b7280),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            )
          else
            const Text(
              'אין ציוד מוגדר מראש לסוג סטודיו זה',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9ca3af),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createRoom,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getRoomColor(_selectedType),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'צור סטודיו',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
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
                    color: _getRoomColor(_selectedType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: _getRoomColor(_selectedType),
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
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _roomImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Upload image to Firebase Storage if exists
      String? imageUrl;
      if (_roomImage != null) {
        // Implement image upload
        // imageUrl = await _uploadImage(_roomImage!);
      }

      // Create room object
      final room = Room(
        id: _nameController.text.isNotEmpty
            ? _nameController.text
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.isNotEmpty
            ? _nameController.text
            : _displayNameController.text.toLowerCase().replaceAll(' ', '_'),
        displayName: _displayNameController.text.trim(),
        type: _selectedType,
        capacity: int.parse(_capacityController.text),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        features: _features,
        availableResources: _resources,
        status: _selectedStatus,
        imageUrl: imageUrl,
      );

      // Save room
      final success = await _roomRepository.saveRoom(room);

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('הסטודיו נוצר בהצלחה!'),
              ],
            ),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה ביצירת הסטודיו: $e'),
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

  IconData _getRoomIcon(RoomType type) {
    switch (type) {
      case RoomType.plasticArts:
        return Icons.palette;
      case RoomType.theater:
        return Icons.theater_comedy;
      case RoomType.music:
        return Icons.music_note;
      case RoomType.writing:
        return Icons.edit;
      case RoomType.animation:
        return Icons.animation;
      case RoomType.videoCinema:
        return Icons.videocam;
    }
  }

  Color _getRoomColor(RoomType type) {
    switch (type) {
      case RoomType.plasticArts:
        return const Color(0xFFef4444);
      case RoomType.theater:
        return const Color(0xFF8b5cf6);
      case RoomType.music:
        return const Color(0xFF10b981);
      case RoomType.writing:
        return const Color(0xFF3b82f6);
      case RoomType.animation:
        return const Color(0xFFf59e0b);
      case RoomType.videoCinema:
        return const Color(0xFF06b6d4);
    }
  }

  String _getRoomTypeDisplayName(RoomType type) {
    switch (type) {
      case RoomType.plasticArts:
        return 'אמנות פלסטית';
      case RoomType.theater:
        return 'תאטרון';
      case RoomType.music:
        return 'מוזיקה';
      case RoomType.writing:
        return 'כתיבה יוצרת';
      case RoomType.animation:
        return 'אנימציה';
      case RoomType.videoCinema:
        return 'וידאו קולנוע';
    }
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return const Color(0xFF10b981);
      case RoomStatus.occupied:
        return const Color(0xFFf59e0b);
      case RoomStatus.maintenance:
        return const Color(0xFFef4444);
      case RoomStatus.reserved:
        return const Color(0xFF3b82f6);
    }
  }

  String _getStatusText(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return 'זמין';
      case RoomStatus.occupied:
        return 'תפוס';
      case RoomStatus.maintenance:
        return 'תחזוקה';
      case RoomStatus.reserved:
        return 'שמור';
    }
  }
}
