import 'package:flutter/material.dart';
import '../../../data/models/user.dart';

class CreateEventScreen extends StatelessWidget {
  final User user;
  final DateTime initialDate;

  const CreateEventScreen({
    Key? key,
    required this.user,
    required this.initialDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: const Text(
          'יצירת אירוע חדש',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Color(0xFF3b82f6)),
            SizedBox(height: 16),
            Text(
              'יצירת אירועים',
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
    );
  }
}
