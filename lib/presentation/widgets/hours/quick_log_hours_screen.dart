import 'package:flutter/material.dart';
import '../../../data/models/user.dart';
import 'log_hours_screen.dart';

class QuickLogHoursScreen extends StatelessWidget {
  final User user;

  const QuickLogHoursScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFe5e7eb),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'לוג שעות מהיר',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ),

              // Options
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildQuickOption(
                        context,
                        'רישום מלא',
                        'רשום שעות עבודה עם כל הפרטים',
                        Icons.edit_note,
                        const Color(0xFF8b5cf6),
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LogHoursScreen(user: user),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildQuickOption(
                        context,
                        'שיעור שהסתיים עכשיו',
                        'רישום מהיר לשיעור שזה עתה הסתיים',
                        Icons.timer_off,
                        const Color(0xFF10b981),
                        () {
                          Navigator.pop(context);
                          _showQuickLogDialog(context);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildQuickOption(
                        context,
                        'צפה בשעות שלי',
                        'ראה את כל שעות העבודה שלך',
                        Icons.visibility,
                        const Color(0xFF3b82f6),
                        () {
                          Navigator.pop(context);
                          // Navigate to hours dashboard
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFe5e7eb)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6b7280)),
          ],
        ),
      ),
    );
  }

  void _showQuickLogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('רישום מהיר'),
        content: const Text('תכונה זו תהיה זמינה בקרוב'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('הבנתי'),
          ),
        ],
      ),
    );
  }
}
