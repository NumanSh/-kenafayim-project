import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/image_service.dart';

class LessonImagePicker extends StatefulWidget {
  final String? initialImagePath;
  final String lessonId;
  final Function(String?) onImageChanged;
  final bool showIcon;

  const LessonImagePicker({
    super.key,
    this.initialImagePath,
    required this.lessonId,
    required this.onImageChanged,
    this.showIcon = true,
  });

  @override
  State<LessonImagePicker> createState() => _LessonImagePickerState();
}

class _LessonImagePickerState extends State<LessonImagePicker> {
  String? _currentImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.initialImagePath;
  }

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);

    try {
      final String? imagePath = await ImageService.pickAndSaveImage(
        lessonId: widget.lessonId,
        source: ImageSource.gallery,
      );

      if (imagePath != null) {
        // Delete old image if exists
        if (_currentImagePath != null) {
          await ImageService.deleteImage(_currentImagePath!);
        }

        setState(() {
          _currentImagePath = imagePath;
        });
        widget.onImageChanged(imagePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בבחירת תמונה: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeImage() async {
    if (_currentImagePath != null) {
      await ImageService.deleteImage(_currentImagePath!);
      setState(() {
        _currentImagePath = null;
      });
      widget.onImageChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image preview or placeholder
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFf1f5f9),
                image: _currentImagePath != null &&
                        File(_currentImagePath!).existsSync()
                    ? DecorationImage(
                        image: FileImage(File(_currentImagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _currentImagePath == null ||
                      !File(_currentImagePath!).existsSync()
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.showIcon) ...[
                          Icon(
                            Icons.image_outlined,
                            size: 24,
                            color: const Color(0xFF8b5cf6).withOpacity(0.6),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          'אין תמונת רקע',
                          style: TextStyle(
                            color: const Color(0xFF6b7280),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        // Overlay for better button visibility
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        // Image icon overlay
                        if (widget.showIcon)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image,
                                size: 20,
                                color: const Color(0xFF8b5cf6),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: Text(_currentImagePath != null
                          ? 'שנה תמונה'
                          : 'הוסף תמונה'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8b5cf6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (_currentImagePath != null) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete),
                      label: const Text('הסר'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFef4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
