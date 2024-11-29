class SendGridConfig {
  // Clé API SendGrid (à remplacer par votre clé)
  static const String apiKey = 'YOUR_SENDGRID_API_KEY';

  // Email de l'expéditeur vérifié
  static const String senderEmail = 'zboubacar@pschool.pro';
  static const String senderName = 'SchoolApp';

  // Templates d'emails (si vous utilisez des templates SendGrid)
  static const String welcomeTemplateId = 'YOUR_WELCOME_TEMPLATE_ID';

  // URLs de l'application
  static const String appUrl = 'https://votre-app-url.supabase.co';
  static const String loginUrl = '$appUrl/login';

  // Configurations par défaut des emails
  static Map<String, dynamic> getDefaultEmailConfig() {
    return {
      'from': {
        'email': senderEmail,
        'name': senderName,
      },
      'templateData': {
        'appName': senderName,
        'year': DateTime.now().year.toString(),
        'loginUrl': loginUrl,
      },
    };
  }

  // Validation de l'email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
