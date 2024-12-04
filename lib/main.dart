import 'package:app_school/screens/teacher/teacher_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:provider/provider.dart' as provider;
import 'package:app_school/models/quiz.dart';
import 'package:app_school/screens/admin/admin_dashboard.dart';
import 'package:app_school/screens/auth/create_new_password_screen.dart';
import 'package:app_school/screens/auth/forgot_password_screen.dart';
import 'package:app_school/screens/auth/login_screen.dart';
import 'package:app_school/screens/courses/add_course_screen.dart';
import 'package:app_school/screens/courses/courses_screen.dart';
import 'package:app_school/screens/onboarding/onboarding_screen.dart';
import 'package:app_school/screens/profile/profile_screen.dart';
import 'package:app_school/screens/ranks/ranks_screen.dart';
import 'package:app_school/screens/splash/splash_screen.dart';
import 'package:app_school/screens/student/edit_profile_screen.dart';
import 'package:app_school/screens/student/quiz/student_quiz_screen.dart';
import 'package:app_school/screens/student/student_course_detail_screen.dart';
import 'package:app_school/screens/student/student_courses_screen.dart';
import 'package:app_school/screens/student/student_dashboard.dart';
import 'package:app_school/screens/student/student_profile_screen.dart';
import 'package:app_school/screens/student/student_ranks_screen.dart';
import 'package:app_school/screens/student/student_xcode_screen.dart';
import 'package:app_school/screens/xcode/xcode_screen.dart';
import 'package:app_school/config/supabase_config.dart';
import 'package:app_school/providers/auth_provider.dart';
import 'package:app_school/constants/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Configuration de l'orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuration de la barre d'état
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'TPsc',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primaryBlue,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            color: Colors.transparent,
            iconTheme: IconThemeData(color: AppColors.textDark),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: AppColors.textDark),
            bodyMedium: TextStyle(color: AppColors.textDark),
          ),
        ),
        initialRoute: '/splash',
        routes: {
          // Routes d'authentification et initiales
          '/splash': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/create-password': (context) => const CreateNewPasswordScreen(),

          // Routes Admin
          '/admin-dashboard': (context) => const AdminDashboard(),
          '/admin/courses': (context) => const CoursesScreen(),
          '/admin/courses/add': (context) => const AddCourseScreen(),
          /* '/admin/courses/add/quiz': (context) => QuizCreationDialog(
                onQuizCreated: (Quiz quiz) {
                  Navigator.pop(context, quiz);
                },
              ), */
          '/admin/xcode': (context) => const XCodeScreen(),
          '/admin/ranks': (context) => const RanksScreen(),
          '/admin/profile': (context) => const ProfileScreen(),

          // Routes Étudiants
          '/student-dashboard': (context) => const StudentDashboard(),
          '/student/courses': (context) => const StudentCoursesScreen(),
          '/student/xcode': (context) => const StudentXCodeScreen(),
          '/student/ranks': (context) => const StudentRanksScreen(),
          '/student/profile': (context) => const StudentProfileScreen(),
          '/student/edit-profile': (context) =>
              const EditStudentProfileScreen(),
          /* '/student/course-detail': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return StudentCourseDetailScreen(
              courseId: args['courseId'],
              courseTitle: args['courseTitle'],
            );
          }, */
          '/student/quiz': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return StudentQuizScreen(
              quizId: args['quizId'],
              moduleId: args['moduleId'],
              moduleTitle: args['moduleTitle'],
              courseTitle: args['courseTitle'],
            );
          },
          /* '/student/tp': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return StudentTPScreen(
              tpId: args['tpId'],
              moduleTitle: args['moduleTitle'],
              courseTitle: args['courseTitle'],
            );
          }, */

          '/teacher-dashboard': (context) => const TeacherDashboard(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const SplashScreen(),
          );
        },
      ),
    );
  }
}
