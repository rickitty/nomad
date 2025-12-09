import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:price_book/auth_wrapper.dart';
import 'package:price_book/pages/login_screen.dart'; 

import 'onboarding_theme.dart';
import 'package:price_book/keys.dart';
// import 'package:price_book/auth_wrapper.dart'; 

class OnboardingPage3 extends StatefulWidget {
  final PageController controller;

  const OnboardingPage3({super.key, required this.controller, required Future<void> Function() onFinish});

  @override
  State<OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<OnboardingPage3> {
  bool? _locationGranted;

  Future<void> _requestLocationPermission() async {
    if (kIsWeb) {
      setState(() {
        _locationGranted = null; 
      });
      return;
    }

    final status = await Permission.locationWhenInUse.request();
    setState(() => _locationGranted = status.isGranted);
  }

  void _goToAuthWrapper(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Animate(
              effects: [
                FadeEffect(duration: 450.ms, curve: Curves.easeOut),
                MoveEffect(
                  begin: const Offset(0, 40),
                  end: Offset.zero,
                  duration: 450.ms,
                  curve: Curves.easeOut,
                ),
              ],
              child: Container(
                width: double.infinity,
                height: screenHeight * 0.55,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/StartPage.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: screenHeight * 0.45,
                width: screenWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: OnboardingTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      onboardingLocationTitle.tr(),
                      style: OnboardingTheme.title,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      onboardingLocationDescription.tr(),
                      style: OnboardingTheme.body,
                    ),

                    if (_locationGranted != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _locationGranted == true
                            ? onboardingLocationGranted.tr()
                            : onboardingLocationDenied.tr(),
                        style: OnboardingTheme.smallInfo.copyWith(
                          color: _locationGranted == true
                              ? Colors.green
                              : Colors.redAccent,
                        ),
                      ),
                    ],

                    const Spacer(),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: OnboardingTheme.primaryButton,
                        onPressed: () async {
                          await _requestLocationPermission();
                          _goToAuthWrapper(context);
                        },
                        child: Text(
                          onboardingLocationButton.tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                          .moveY(begin: 30, end: 0, curve: Curves.easeOut)
                          .scaleXY(begin: 0.9, end: 1.0, duration: 400.ms),
                    ),

                    TextButton(
                      onPressed: () => _goToAuthWrapper(context),
                      child: Text(
                        onboardingContinueWithoutLocation.tr(),
                        style: OnboardingTheme.smallInfo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
