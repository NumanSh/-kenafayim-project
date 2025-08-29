import 'package:flutter/material.dart';

class NavigationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final Color badgeColor;
  final Color textColor;

  const NavigationBadge({
    Key? key,
    required this.child,
    required this.count,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
