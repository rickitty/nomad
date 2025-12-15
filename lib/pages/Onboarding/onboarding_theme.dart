import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingTheme {
  static const Color primaryColor = Color.fromARGB(255, 87, 174, 255);

  static final TextStyle tag = GoogleFonts.notoSans(
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.grey,
      letterSpacing: 1.2,
    ),
  );

  static final TextStyle title = GoogleFonts.notoSans(
    textStyle: const TextStyle(
      color: Color(0xFF333333),
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.25,
    ),
  );

  static final TextStyle body = GoogleFonts.notoSans(
    textStyle: const TextStyle(
      color: Color(0xFF666666),
      fontSize: 13.5,
      height: 1.45,
    ),
  );

  static final TextStyle smallInfo = GoogleFonts.notoSans(
    textStyle: const TextStyle(
      color: Color(0xFF888888),
      fontSize: 12,
    ),
  );

  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
    ),
    elevation: 0,
  );
}
