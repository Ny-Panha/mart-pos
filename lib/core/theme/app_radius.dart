import 'package:flutter/material.dart';

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double card = 24.0; // Specified: cards radius 24
  static const double button = 12.0; // Specified: button radius 12
  static const double pill = 999.0;

  static final BorderRadius smBorder = BorderRadius.circular(sm);
  static final BorderRadius mdBorder = BorderRadius.circular(md);
  static final BorderRadius lgBorder = BorderRadius.circular(lg);
  static final BorderRadius cardBorder = BorderRadius.circular(card);
  static final BorderRadius buttonBorder = BorderRadius.circular(button);
  static final BorderRadius pillBorder = BorderRadius.circular(pill);
}
