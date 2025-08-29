import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: width ?? 120,
          height: height ?? 60,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if logo fails to load
            return Container(
              width: width ?? 120,
              height: height ?? 60,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            );
          },
        ),
      ),
    );
  }
}
