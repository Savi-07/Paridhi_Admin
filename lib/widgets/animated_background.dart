import 'package:flutter/material.dart';
import 'dart:async';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  
  const AnimatedGradientBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground> {
  List<Color> colorList = [
    const Color(0xFF1A1C1E),
    const Color(0xFF2C3E50),
    const Color(0xFF1A1C1E),
    const Color(0xFF2C3E50).withOpacity(0.8),
  ];
  
  int index = 0;
  Color bottomColor = const Color(0xFF1A1C1E);
  Color topColor = const Color(0xFF2C3E50);
  Alignment begin = Alignment.bottomLeft;
  Alignment end = Alignment.topRight;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          bottomColor = colorList[index % colorList.length];
          topColor = colorList[(index + 1) % colorList.length];
          index = index + 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 2),
      onEnd: () {
        if (mounted) {
          setState(() {
            begin = begin == Alignment.bottomLeft 
                ? Alignment.bottomRight 
                : Alignment.bottomLeft;
            end = end == Alignment.topRight 
                ? Alignment.topLeft 
                : Alignment.topRight;
          });
        }
      },
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [bottomColor, topColor],
        ),
      ),
      child: widget.child,
    );
  }
} 