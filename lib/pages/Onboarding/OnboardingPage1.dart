import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import 'onboarding_theme.dart';
import 'package:price_book/keys.dart';

class OnboardingPage1 extends StatefulWidget {
  final PageController controller;

  const OnboardingPage1({super.key, required this.controller});

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1> {
  String _selectedLang = 'kz';

  void _changeLang(String code) {
    setState(() => _selectedLang = code);

    if (code == 'kz') {
      context.setLocale(const Locale('kz'));
    } else if (code == 'ru') {
      context.setLocale(const Locale('ru'));
    } else {
      context.setLocale(const Locale('en'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ВЕРХНЯЯ КАРТИНКА — занимает адаптивную высоту
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
                  // АДАПТИВНАЯ ВЫСОТА: минимум 40% экрана, но не больше 55%
                  constraints: BoxConstraints(
                    minHeight: screenHeight * 0.40,
                    maxHeight: screenHeight * 0.55,
                  ),
                  padding: EdgeInsets.fromLTRB(
                    28,
                    32,
                    28,
                    32 + 24, // +24 снизу под точки-индикатор
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Теглайн
                      Text(
                        onboardingTagline.tr(),
                        style: OnboardingTheme.tag,
                      )
                          .animate()
                          .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                          .moveY(begin: 10, end: 0, duration: 300.ms),

                      const SizedBox(height: 8),

                      // Заголовок
                      Text(
                        onboardingTitle1.tr(),
                        style: OnboardingTheme.title,
                      )
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 350.ms)
                          .moveY(begin: 12, end: 0, duration: 300.ms),

                      const SizedBox(height: 14),

                      // Описание
                      Text(
                        onboardingDescription1.tr(),
                        style: OnboardingTheme.body,
                      )
                          .animate()
                          .fadeIn(delay: 140.ms, duration: 350.ms)
                          .moveY(begin: 14, end: 0, duration: 300.ms),

                      const SizedBox(height: 18),

                      // Подпись "Выберите язык"
                      Text(
                        onboardingChooseLanguage.tr(),
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            color: Color(0xFF444444),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 300.ms)
                          .moveY(begin: 10, end: 0, duration: 250.ms),

                      const SizedBox(height: 10),

                      // Чипы языков
                      Row(
                        children: [
                          _LanguageChip(
                            label: 'Қазақша',
                            selected: _selectedLang == 'kz',
                            onTap: () => _changeLang('kz'),
                          ),
                          const SizedBox(width: 8),
                          _LanguageChip(
                            label: 'Русский',
                            selected: _selectedLang == 'ru',
                            onTap: () => _changeLang('ru'),
                          ),
                          const SizedBox(width: 8),
                          _LanguageChip(
                            label: 'English',
                            selected: _selectedLang == 'en',
                            onTap: () => _changeLang('en'),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 260.ms, duration: 300.ms)
                          .moveY(begin: 8, end: 0, duration: 250.ms)
                          .scaleXY(begin: 0.96, end: 1.0, duration: 220.ms),

                      const Spacer(),

                      // КНОПКА "Продолжить"
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: OnboardingTheme.primaryButton,
                          onPressed: () {
                            widget.controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(
                            onboardingContinue.tr(),
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(
                              delay: 320.ms,
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

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? OnboardingTheme.primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? OnboardingTheme.primaryColor
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected
                  ? OnboardingTheme.primaryColor
                  : const Color(0xFF555555),
            ),
          ),
        ),
      ),
    );
  }
}
