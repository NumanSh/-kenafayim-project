import 'package:flutter/material.dart';

class RTLTextDirectionWrapper extends StatelessWidget {
  final Widget child;

  const RTLTextDirectionWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: child);
  }
}
