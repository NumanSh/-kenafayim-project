import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lesson_series.dart';
import '../../../data/models/user.dart';
import '../../widgets/common/rtl_wrapper.dart';

class EditLessonSeriesScreen extends ConsumerStatefulWidget {
  final User user;
  final LessonSeries series;

  const EditLessonSeriesScreen({
    Key? key,
    required this.user,
    required this.series,
  }) : super(key: key);

  @override
  ConsumerState<EditLessonSeriesScreen> createState() =>
      _EditLessonSeriesScreenState();
}

class _EditLessonSeriesScreenState
    extends ConsumerState<EditLessonSeriesScreen> {
  @override
  Widget build(BuildContext context) {
    return RTLTextDirectionWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFf8fafc),
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.95),
          elevation: 0,
          title: Text(
            'עריכת ${widget.series.title}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_forward, color: Color(0xFF374151)),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Color(0xFF3b82f6)),
              SizedBox(height: 16),
              Text(
                'עריכת סדרות שיעורים',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'תכונה זו תהיה זמינה בקרוב',
                style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
