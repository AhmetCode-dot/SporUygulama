import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StartupView extends StatefulWidget {
  const StartupView({Key? key}) : super(key: key);

  @override
  State<StartupView> createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView> {
  @override
  void initState() {
    super.initState();
    // Navigasyonu ilk frame'den sonra başlat (context güvenli)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _decideNavigation();
    });
  }

  Future<void> _decideNavigation() async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user == null) {
        Navigator.pushReplacementNamed(context, '/welcome');
        return;
      }

      // 1) Profil var mı? (user_profiles/<uid>)
      final profileDoc = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (!profileDoc.exists) {
        Navigator.pushReplacementNamed(context, '/profile');
        return;
      }

      // 2) Ekipman/Ortam var mı? (users/<uid>)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      final data = userDoc.data() ?? {};
      final hasEquipment = (data['equipment'] is List) && (data['equipment'] as List).isNotEmpty;
      final hasEnvironment = (data['environment'] is String) && (data['environment'] as String).isNotEmpty;
      if (!(hasEquipment && hasEnvironment)) {
        Navigator.pushReplacementNamed(context, '/equipment');
        return;
      }

      // 3) Hedef/Bölgeler var mı?
      final hasGoal = (data['goal'] is String) && (data['goal'] as String).isNotEmpty;
      final hasRegions = (data['bodyRegions'] is List) && (data['bodyRegions'] as List).isNotEmpty;
      if (!(hasGoal && hasRegions)) {
        Navigator.pushReplacementNamed(context, '/body-region-goal');
        return;
      }

      // 4) Her şey tamam → egzersizlere git
      Navigator.pushReplacementNamed(context, '/exercise-recommendations');
    } catch (_) {
      // Hata durumunda güvenli rota: welcome
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}


