import 'dart:math';
import 'package:flutter/material.dart';

// 📺 CRT SCANLINE OVERLAY (The Retro TV Effect)
class CRTScreenEffect extends StatelessWidget {
  final Widget child;
  const CRTScreenEffect({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Scanlines
        IgnorePointer(
          child: CustomPaint(
            painter: _ScanlinePainter(),
            size: Size.infinite,
          ),
        ),
        // Vignette (Dark Corners) - Added to make it look deeper
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 1;
    // Draw lines every 4 pixels
    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(old) => false;
}

// 🔴 NEON GLOW BUTTON (Updated for Full Width)
class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isDestructive;

  const NeonButton({
    super.key, 
    required this.text, 
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    // Red for dangerous actions, Cyan/Teal for normal ones
    final color = isDestructive ? const Color(0xFFFF0033) : const Color(0xFF00FFC5);
    
    return Container(
      // Glowing shadow
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, spreadRadius: 1),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          backgroundColor: Colors.black.withOpacity(0.7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          // THIS IS THE KEY CHANGE: Makes button fill the width
          minimumSize: const Size(double.infinity, 50), 
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 16, 
            letterSpacing: 2, 
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: color, blurRadius: 10)]
          ),
        ),
      ),
    );
  }
}