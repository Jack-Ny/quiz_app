import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider =
        provider.Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      final userType = authProvider.user?.userType;
      if (userType != null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AuthService().getInitialRoute(userType),
        );
      }
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double circleSize =
        screenSize.width * 0.6 > 300 ? 300 : screenSize.width * 0.6;

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment
              .center, // Ensure center alignment on larger screens
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white,
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: circleSize * 0.1,
                    right: circleSize * 0.15,
                    child: _buildDecorationDot(8),
                  ),
                  Positioned(
                    top: circleSize * 0.1,
                    right: circleSize * 0.2,
                    child: _buildDecorationDot(12),
                  ),
                  Container(
                    width: circleSize * 0.25,
                    height: circleSize * 0.25,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: AppColors.primaryBlue,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'TPsc',
              style: AppTextStyles.appName,
            ),
            const Text(
              'DEVIENS UN GENIE',
              style: AppTextStyles.slogan,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorationDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
