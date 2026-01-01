import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'views/login_view.dart';
import 'views/register_view.dart';
import 'views/profile_view.dart';
import 'views/welcome_view.dart';
import 'views/equipment_selection_view.dart';
import 'views/body_region_goal_view.dart';
import 'views/exercise_recommendation_view.dart';
import 'views/onboarding_plan_view.dart';
import 'views/weekly_plan_view.dart';
import 'views/progress_view.dart';
import 'views/workout_detail_view.dart';
import 'views/achievements_view.dart';
import 'views/notification_settings_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'views/startup_view.dart';
import 'models/workout_session.dart';
import 'views/admin/admin_login_view.dart';
import 'views/admin/admin_dashboard_view.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Firestore offline persistence ayarla
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // Bildirim servisini başlat
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(MyFitnessApp());
}

class MyFitnessApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartupView(),
        '/welcome': (context) => const WelcomeView(),
        '/login': (context) => const LoginView(),
        '/register': (context) => const RegisterView(),
        '/profile': (context) => const ProfileView(),
        '/equipment': (context) => const EquipmentSelectionView(),
        '/body-region-goal': (context) => const BodyRegionGoalView(),
        '/onboarding-plan': (context) => const OnboardingPlanView(),
        '/exercise-recommendations': (context) => const ExerciseRecommendationView(),
        '/weekly-plan': (context) => const WeeklyPlanView(),
        '/progress': (context) => const ProgressView(),
        '/achievements': (context) => const AchievementsView(),
        '/notification-settings': (context) => const NotificationSettingsView(),
        '/workout-detail': (context) {
          final workout = ModalRoute.of(context)!.settings.arguments as WorkoutSession;
          return WorkoutDetailView(workout: workout);
        },
        // Admin routes
        '/admin/login': (context) => const AdminLoginView(),
        '/admin/dashboard': (context) => const AdminDashboardView(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return const ProfileView();
        } else {
          return const LoginView();
        }
      },
    );
  }
}

// Screen 4: Equipment Selection
class EquipmentSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Equipment')),
      body: Center(child: const Text('Checkboxes for dumbbells, mat, etc.')),
    );
  }
}

// Screen 5: Goal Selection
class GoalSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Workout Focus')),
      body: Center(child: const Text('Select areas like abs, legs, chest...')),
    );
  }
}

// Screen 6: Workout Suggestion Screen
class WorkoutSuggestionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Workouts')),
      body: Center(child: const Text('List of exercises based on user profile')), 
    );
  }
}
