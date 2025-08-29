import 'package:flutter/material.dart';

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // Start from top-left
    path.lineTo(0, 0);
    path.lineTo(0, size.height - 50);

    // Create wave effect
    var firstControlPoint = Offset(size.width * 0.2, size.height);
    var firstEndPoint = Offset(size.width * 0.5, size.height - 30);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 0.8, size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 20);

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    // Complete the path
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
