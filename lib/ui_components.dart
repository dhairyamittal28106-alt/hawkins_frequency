import 'dart:math';
import 'package:flutter/material.dart';


class CRTScreenEffect extends StatelessWidget {
  final Widget child;
  const CRTScreenEffect({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        
        IgnorePointer(
          child: CustomPaint(
            painter: _ScanlinePainter(),
            size: Size.infinite,
          ),
        ),
        
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
    
    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(old) => false;
}


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
    
    final color = isDestructive ? const Color(0xFFFF0033) : const Color(0xFF00FFC5);
    
    return Container(
      
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