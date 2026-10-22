import 'package:flutter/material.dart';

/// Ambient glowing mesh gradient background inspired by Tavola.
/// Creates a calm, luminous dark backdrop with subtle colored glow blobs.
class MeshBackground extends StatelessWidget {
  final Widget child;
  final bool enableGlow;

  const MeshBackground({
    super.key,
    required this.child,
    this.enableGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base Ambient Gradient Layer
        Positioned.fill(
          child: RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF0E1830), // Tavola deep navy surface
                          Color(0xFF0A1222), // Tavola background
                          Color(0xFF070D19),
                        ]
                      : const [
                          Color(0xFFF1F5F9),
                          Color(0xFFE8EEF5),
                          Color(0xFFE2E8F0),
                        ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Glowing Ambient Blobs (Frosted Light Spheres)
        if (enableGlow) ...[
          // Top Left Ambient Glow (Cyan/Indigo)
          Positioned(
            top: -120,
            left: -100,
            width: 480,
            height: 480,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF4668B2).withValues(alpha: 0.18),
                              const Color(0xFF38569C).withValues(alpha: 0.08),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFF6D28D9).withValues(alpha: 0.08),
                              const Color(0xFF0891B2).withValues(alpha: 0.03),
                              Colors.transparent,
                            ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Right Ambient Glow (Warm Violet/Coral)
          Positioned(
            bottom: -140,
            right: -100,
            width: 520,
            height: 520,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF6D28D9).withValues(alpha: 0.15),
                              const Color(0xFFEEB2A3).withValues(alpha: 0.05),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFF38BDF8).withValues(alpha: 0.07),
                              const Color(0xFF6366F1).withValues(alpha: 0.03),
                              Colors.transparent,
                            ],
                      stops: const [0.0, 0.60, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        // Foreground Content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
