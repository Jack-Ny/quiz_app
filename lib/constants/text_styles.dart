import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  // Styles pour le Splash Screen
  static const TextStyle appName = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.purple,
  );

  static const TextStyle slogan = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Styles pour l'Onboarding
  static const TextStyle onboardingTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle onboardingDescription = TextStyle(
    fontSize: 16,
    color: AppColors.textGrey,
    height: 1.5,
  );

  // Styles pour le Login
  static const TextStyle loginTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1E1E1E),
  );

  static const TextStyle loginSubtitle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  // Styles généraux
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textGrey,
  );
}
