import 'package:flutter/material.dart';

/// A wrapper widget that elevates and smoothly translates upwards on mouse hover.
/// Inspired by Tavola's interactive card hover micro-animations.
class HoverCard extends StatefulWidget {
  final Widget child;
  final double liftOffset;
  final Duration duration;

  const HoverCard({
    super.key,
    required this.child,
    this.liftOffset = 4.0,
    this.duration = const Duration(milliseconds: 220),
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0,
          _isHovered ? -widget.liftOffset : 0,
          0,
        ),
        child: widget.child,
      ),
    );
  }
}
