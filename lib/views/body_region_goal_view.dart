import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BodyRegionGoalView extends StatefulWidget {
  const BodyRegionGoalView({Key? key}) : super(key: key);

  @override
  _BodyRegionGoalViewState createState() => _BodyRegionGoalViewState();
}

class _BodyRegionGoalViewState extends State<BodyRegionGoalView> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Vücut bölgeleri seçimleri için Map
  Map<String, bool> bodyRegionSelections = {
    'Karın': false,
    'Göğüs': false,
    'Bacak': false,
    'Omuz': false,
    'Sırt': false,
    'Tüm vücut': false,
  };

  // Hedef seçimi için değişken
  String selectedGoal = 'Kilo vermek';

  // Hedef seçenekleri
  final List<String> goals = [
    'Kilo vermek',
    'Kas yapmak',
    'Esneklik kazanmak',
    'Sıkılaşmak',
    'Genel sağlık',
  ];

  @override
  void initState() {
    super.initState();
    _prefillFromFirestore();
  }

  Future<void> _prefillFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};

      final savedRegions = List<String>.from((data['bodyRegions'] ?? []) as List);
      final savedGoal = (data['goal'] ?? '') as String;

      setState(() {
        for (final key in bodyRegionSelections.keys.toList()) {
          bodyRegionSelections[key] = savedRegions.contains(key);
        }
        if (savedGoal.isNotEmpty && goals.contains(savedGoal)) {
          selectedGoal = savedGoal;
        }
      });
    } catch (e) {
      // sessiz geç; prefill opsiyonel
    }
  }

  Future<void> _saveSelections() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          List<String> selectedRegions = bodyRegionSelections.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'bodyRegions': selectedRegions,
            'goal': selectedGoal,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bölge ve hedef bilgileri kaydedildi')),
          );
          
          Navigator.pushReplacementNamed(context, '/exercise-recommendations');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt hatası: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('fitness_bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Başlık
                    const Text(
                      'Bölge ve Hedef Seçimi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Vücut bölgeleri başlığı
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Çalışmak İstediğiniz Bölgeler',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Vücut bölgeleri seçimleri
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: bodyRegionSelections.entries.map((entry) {
                          return CheckboxListTile(
                            title: Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            value: entry.value,
                            activeColor: Colors.lightBlue,
                            checkColor: Colors.white,
                            onChanged: (bool? value) {
                              setState(() {
                                bodyRegionSelections[entry.key] = value ?? false;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Hedef başlığı
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Hedefiniz',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Hedef seçimi
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: goals.map((goal) {
                          return RadioListTile<String>(
                            title: Text(
                              goal,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            value: goal,
                            groupValue: selectedGoal,
                            activeColor: Colors.lightBlue,
                            onChanged: (String? value) {
                              setState(() {
                                selectedGoal = value!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Kaydet butonu
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveSelections,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.lightBlue.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: const Size(double.infinity, 55),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
                              ),
                            )
                          : const Text(
                              'Kaydet ve Devam Et',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 