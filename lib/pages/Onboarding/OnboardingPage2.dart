import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';

import 'onboarding_theme.dart';
import 'package:price_book/keys.dart';

class OnboardingPage2 extends StatefulWidget {
  final PageController controller;

  const OnboardingPage2({super.key, required this.controller});

  @override
  State<OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<OnboardingPage2> {
  bool? _cameraGranted;

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _cameraGranted = status.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ВЕРХНЯЯ КАРТИНКА
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
              child: SizedBox(
                width: double.infinity,
                height: screenHeight * 0.55,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/StartPage.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            // НИЖНИЙ БЛОК
            Align(
              alignment: Alignment.bottomCenter,
              child: Animate(
                effects: [
                  FadeEffect(duration: 350.ms, curve: Curves.easeOut),
                  MoveEffect(
                    begin: const Offset(0, 80),
                    end: Offset.zero,
                    curve: Curves.easeOutCubic,
                    duration: 400.ms,
                  ),
                ],
                child: Container(
                  width: double.infinity,
                  // Только минимальная высота — дальше блок растёт по контенту
                  constraints: BoxConstraints(
                    minHeight: screenHeight * 0.40,
                  ),
                  padding: EdgeInsets.fromLTRB(
                    28,
                    32,
                    28,
                    32 + 24, // запас под индикаторы
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt_rounded,
                        color: OnboardingTheme.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(height: 10),

                      Text(
                        onboardingCameraTitle.tr(),
                        style: OnboardingTheme.title,
                      ),
                      const SizedBox(height: 14),

                      Text(
                        onboardingCameraDescription.tr(),
                        style: OnboardingTheme.body,
                      ),

                      if (_cameraGranted != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _cameraGranted == true
                              ? onboardingCameraGranted.tr()
                              : onboardingCameraDenied.tr(),
                          style: OnboardingTheme.smallInfo.copyWith(
                            color: _cameraGranted == true
                                ? Colors.green
                                : Colors.redAccent,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Кнопка "Разрешить доступ к камере"
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: OnboardingTheme.primaryButton,
                          onPressed: () async {
                            await _requestCameraPermission();
                            widget.controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(
                            onboardingCameraButton.tr(),
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
                            .fadeIn(
                              duration: 500.ms,
                              curve: Curves.easeOut,
                            )
                            .moveY(
                              begin: 30,
                              end: 0,
                              curve: Curves.easeOut,
                            )
                            .scaleXY(
                              begin: 0.9,
                              end: 1.0,
                              duration: 400.ms,
                            ),
                      ),

                      const SizedBox(height: 8),

                      // Кнопка "Пропустить"
                      TextButton(
                        onPressed: () {
                          widget.controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          onboardingSkip.tr(),
                          style: OnboardingTheme.smallInfo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
