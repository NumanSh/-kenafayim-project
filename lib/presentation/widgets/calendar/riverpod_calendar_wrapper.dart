import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import 'enhanced_calendar_view.dart';

class RiverpodCalendarWrapper extends ConsumerWidget {
  final User user;

  const RiverpodCalendarWrapper({Key? key, required this.user})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: constraints.maxHeight,
              child: UniversalCalendarView(user: user),
            );
          },
        ),
      ),
    );
  }
}
