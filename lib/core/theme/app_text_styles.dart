import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle get title2XL => GoogleFonts.notoSansKhmer(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.3,
      );

  static TextStyle get titleXL => GoogleFonts.notoSansKhmer(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.3,
      );

  static TextStyle get titleLG => GoogleFonts.notoSansKhmer(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get body => GoogleFonts.notoSansKhmer(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.45,
      );

  static TextStyle get bodyBold => GoogleFonts.notoSansKhmer(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.45,
      );

  static TextStyle get caption => GoogleFonts.notoSansKhmer(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: 1.4,
      );

  static TextStyle get eyebrow => GoogleFonts.notoSansKhmer(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      );

  static TextStyle get button => GoogleFonts.notoSansKhmer(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      );
}
