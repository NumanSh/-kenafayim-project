// lib/presentation/widgets/reports/reports_overview.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/user.dart';
import '../../../config/service_locator.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/user_repository.dart';

class ReportsOverview extends ConsumerWidget {
  const ReportsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RealTimeFeed(ref: ref),
        const SizedBox(height: 20),
        _TodaysSchedule(ref: ref),
      ],
    );
  }
}

class _RealTimeFeed extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _RealTimeFeed({required this.ref});

  @override
  ConsumerState<_RealTimeFeed> createState() => _RealTimeFeedState();
}

class _RealTimeFeedState extends ConsumerState<_RealTimeFeed> {
  final _lessonRepo = serviceLocator<LessonRepository>();
  final _bookingRepo = serviceLocator<BookingRepository>();
  final _userRepo = serviceLocator<UserRepository>();

  Stream<List<String>> _feedStream() async* {
    final now = DateTime.now();
    // 1️⃣ lesson started
    yield* _lessonRepo
        .getAllLessons(
          startDate: now.subtract(const Duration(hours: 2)),
          endDate: now,
        )
        .asStream()
        .map(
          (lessons) => lessons
              .map(
                (l) =>
                    '📅 "${l.title}" החל עכשיו – ${l.registeredArtistIds.length} אמנים נכחו',
              )
              .toList(),
        );
    // 2️⃣ working hours completed
    // 3️⃣ studio booking
    // 4️⃣ new users
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: _feedStream(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const SizedBox.shrink();
        }
        final items = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('פעילות בזמן-אמת', style: TextStyle(fontSize: 18)),
            ...items.map(
              (txt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  txt,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TodaysSchedule extends ConsumerWidget {
  final WidgetRef ref;
  const _TodaysSchedule({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonRepo = serviceLocator<LessonRepository>();
    final today = DateTime.now();
    return FutureBuilder(
      future: lessonRepo.getAllLessons(
        startDate: DateTime(today.year, today.month, today.day),
        endDate: DateTime(today.year, today.month, today.day, 23, 59),
      ),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final lessons = snap.data as List<Lesson>;
        lessons.sort((a, b) => a.date.compareTo(b.date));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('לו״ז היום', style: TextStyle(fontSize: 18)),
            ...lessons.map(
              (l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '🕒 ${TimeOfDay.fromDateTime(l.date).format(ctx)} - '
                  '${l.title} (${l.registeredArtistIds.length} אמנים)',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
