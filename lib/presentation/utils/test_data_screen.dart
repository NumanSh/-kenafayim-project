import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/presentation/utils/test_data_populator.dart';

class TestDataScreen extends ConsumerStatefulWidget {
  const TestDataScreen({super.key});

  @override
  ConsumerState<TestDataScreen> createState() => _TestDataScreenState();
}

class _TestDataScreenState extends ConsumerState<TestDataScreen> {
  bool _isPopulating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('נתוני בדיקה'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ אזהרה',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'פעולה זו תוסיף נתוני בדיקה למסד הנתונים. השתמש בזה רק בסביבת פיתוח!',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'נתונים שיווצרו:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildDataTypeCard(
              '👥 משתמשים',
              '10 משתמשים (2 צוות, 4 מנחים, 8 אמנים)',
            ),
            _buildDataTypeCard('🏢 חדרים', '6 סטודיואים שונים'),
            _buildDataTypeCard('📚 שיעורים', '~50 שיעורים (כולל סדרות חוזרות)'),
            _buildDataTypeCard('📊 דוחות', '3 דוחות לדוגמה'),
            _buildDataTypeCard('⏰ שעות עבודה', 'נתוני שעות עבודה למנחים'),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isPopulating ? null : _populateTestData,
              icon: _isPopulating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload),
              label: Text(_isPopulating ? 'יוצר נתונים...' : 'צור נתוני בדיקה'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10b981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 5),
            OutlinedButton.icon(
              onPressed: _isPopulating ? null : _populateWorkingHours,
              icon: const Icon(Icons.access_time),
              label: const Text('צור רק נתוני שעות עבודה'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
            const SizedBox(height: 5),
            ElevatedButton.icon(
              onPressed: _isPopulating ? null : _createAuthAccounts,
              icon: const Icon(Icons.lock),
              label: const Text('צור חשבונות התחברות'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8b5cf6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAuthAccounts() async {
    setState(() => _isPopulating = true);

    try {
      await TestDataPopulator.createAuthAccounts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ חשבונות התחברות נוצרו בהצלחה!'),
            backgroundColor: Color(0xFF8b5cf6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ שגיאה ביצירת חשבונות: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPopulating = false);
      }
    }
  }

  Widget _buildDataTypeCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _populateTestData() async {
    setState(() => _isPopulating = true);

    try {
      await TestDataPopulator.populateAllTestData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ נתוני בדיקה נוצרו בהצלחה!'),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ שגיאה ביצירת נתונים: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPopulating = false);
      }
    }
  }

  Future<void> _populateWorkingHours() async {
    setState(() => _isPopulating = true);

    try {
      await TestDataPopulator.populateWorkingHoursData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ נתוני שעות עבודה נוצרו בהצלחה!'),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ שגיאה ביצירת נתוני שעות עבודה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPopulating = false);
      }
    }
  }
}
