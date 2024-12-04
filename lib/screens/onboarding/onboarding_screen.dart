import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const LoginScreen()), // À créer plus tard
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Bouton Passer en haut à droite
            Positioned(
              top: 20,
              right: 20,
              child: TextButton(
                onPressed: () => _navigateToLogin(context),
                child: const Text(
                  'Passer',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Contenu principal
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width *
                      0.08), // Ajuste l'espacement horizontal
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Titre
                  Text(
                    'Quizz & TP en ligne',
                    style: TextStyle(
                      fontSize: screenSize.width *
                          0.08, // Taille de police proportionnelle
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                      height:
                          screenSize.height * 0.03), // Espacement proportionnel
                  // Sous-titre
                  Text(
                    'Améliorez vos compétences en faisant nos différents quizz et TP.',
                    style: TextStyle(
                      fontSize: screenSize.width *
                          0.05, // Taille de police proportionnelle
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Indicateurs de page et bouton suivant en bas
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width *
                        0.08), // Ajuste l'espacement horizontal
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Indicateurs de page
                    Row(
                      children: [
                        _buildPageIndicator(true),
                        const SizedBox(width: 8),
                        _buildPageIndicator(false),
                        const SizedBox(width: 8),
                        _buildPageIndicator(false),
                      ],
                    ),
                    // Bouton suivant
                    FloatingActionButton(
                      onPressed: () => _navigateToLogin(context),
                      backgroundColor: AppColors.primaryBlue,
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
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

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryBlue : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
