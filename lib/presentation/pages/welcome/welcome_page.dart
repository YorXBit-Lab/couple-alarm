import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_note/presentation/themes/app_colors.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool moveLogoUp = false;
  bool showText = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => moveLogoUp = true);

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => showText = true);
      });
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 800),
              alignment: moveLogoUp ? Alignment(0, -0.5) : Alignment.center,
              curve: Curves.easeInOut,
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 150,
                height: 150,
              ),
            ),

            AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: showText ? 1.0 : 0.0,
              curve: Curves.easeIn,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "Love Note",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: AppColors.darkTextPrimary,
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
