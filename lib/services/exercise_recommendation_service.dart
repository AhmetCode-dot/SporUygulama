import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

class ExerciseRecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'exercises';

  // Kullanıcının tercihlerine göre egzersiz önerilerini getir
  Future<List<Exercise>> getRecommendedExercises({
    required List<String> bodyRegions,
    required String goal,
    required List<String> equipment,
    required String environment,
  }) async {
    try {
      // Firestore'dan egzersizleri getir
      final QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      
      List<Exercise> allExercises = snapshot.docs
          .map((doc) => Exercise.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Eğer Firestore'da egzersiz yoksa, varsayılan egzersizleri kullan
      if (allExercises.isEmpty) {
        allExercises = _getDefaultExercises();
      }

      // Filtreleme ve skorlama
      List<Exercise> filteredExercises = allExercises.where((exercise) {
        return _isExerciseSuitable(exercise, bodyRegions, goal, equipment, environment);
      }).toList();

      // Skorlama sistemi ile sıralama
      filteredExercises.sort((a, b) {
        int scoreA = _calculateExerciseScore(a, bodyRegions, goal, equipment, environment);
        int scoreB = _calculateExerciseScore(b, bodyRegions, goal, equipment, environment);
        return scoreB.compareTo(scoreA); // Yüksek skor önce
      });

      return filteredExercises.take(10).toList(); // En iyi 10 egzersiz
    } catch (e) {
      // Hata durumunda varsayılan egzersizleri döndür
      return _getDefaultExercises().where((exercise) {
        return _isExerciseSuitable(exercise, bodyRegions, goal, equipment, environment);
      }).take(10).toList();
    }
  }

  // Egzersizin uygun olup olmadığını kontrol et
  bool _isExerciseSuitable(Exercise exercise, List<String> bodyRegions, String goal, 
      List<String> equipment, String environment) {
    
    // Vücut bölgesi uyumu
    bool bodyRegionMatch = exercise.bodyRegions.any((region) => bodyRegions.contains(region));
    
    // Hedef uyumu
    bool goalMatch = exercise.goals.contains(goal);
    
    // Ekipman uyumu (kullanıcının sahip olduğu ekipmanlar)
    bool equipmentMatch = exercise.equipment.every((eq) => equipment.contains(eq) || eq == 'Vücut Ağırlığı ile Çalışıyorum');
    
    // Ortam uyumu
    bool environmentMatch = exercise.environments.contains(environment);

    return bodyRegionMatch && goalMatch && equipmentMatch && environmentMatch;
  }

  // Egzersiz skorunu hesapla (ne kadar uygun olduğunu)
  int _calculateExerciseScore(Exercise exercise, List<String> bodyRegions, String goal, 
      List<String> equipment, String environment) {
    
    int score = 0;
    
    // Vücut bölgesi skoru
    int bodyRegionMatches = exercise.bodyRegions.where((region) => bodyRegions.contains(region)).length;
    score += bodyRegionMatches * 10;
    
    // Hedef skoru
    if (exercise.goals.contains(goal)) {
      score += 20;
    }
    
    // Ekipman skoru
    int equipmentMatches = exercise.equipment.where((eq) => equipment.contains(eq) || eq == 'Vücut Ağırlığı ile Çalışıyorum').length;
    score += equipmentMatches * 5;
    
    // Ortam skoru
    if (exercise.environments.contains(environment)) {
      score += 15;
    }
    
    // Zorluk skoru (orta zorluk tercih edilir)
    if (exercise.difficulty == 3) {
      score += 5;
    } else if (exercise.difficulty == 2 || exercise.difficulty == 4) {
      score += 3;
    }
    
    return score;
  }

  // Varsayılan egzersiz verileri
  List<Exercise> _getDefaultExercises() {
    return [
      // Karın egzersizleri
      Exercise(
        id: 'plank',
        name: 'Plank',
        description: 'Tüm vücut için mükemmel bir egzersiz',
        bodyRegions: ['Karın', 'Tüm vücut'],
        goals: ['Kas yapmak', 'Sıkılaşmak', 'Genel sağlık'],
        equipment: ['Vücut Ağırlığı ile Çalışıyorum'],
        environments: ['Evde çalışıyorum', 'Spor salonunda çalışıyorum', 'Hem evde hem salonda'],
        duration: 5,
        difficulty: 2,
        instructions: '1. Yüzüstü pozisyonda başla\n2. Dirseklerini omuz genişliğinde yerleştir\n3. Vücudunu düz bir çizgide tut\n4. 30-60 saniye tut',
        imageUrl: 'assets/exercises/plank.jpg',
        instructionVideoAsset: 'assets/exercises/plank.mp4',
        benefits: ['Güçlü karın kasları', 'Duruş iyileştirme', 'Denge artışı'],
      ),
      
      Exercise(
        id: 'crunches',
        name: 'Mekik',
        description: 'Klasik karın egzersizi',
        bodyRegions: ['Karın'],
        goals: ['Kas yapmak', 'Sıkılaşmak'],
        equipment: ['Vücut Ağırlığı ile Çalışıyorum'],
        environments: ['Evde çalışıyorum', 'Spor salonunda çalışıyorum', 'Hem evde hem salonda'],
        duration: 10,
        difficulty: 1,
        instructions: '1. Sırtüstü yat\n2. Dizlerini bük\n3. Ellerini başının arkasına koy\n4. Üst vücudunu kaldır ve indir',
        imageUrl: 'assets/exercises/crunches.jpg',
        instructionVideoAsset: 'assets/exercises/Crunches.mp4',
        benefits: ['Karın kasları güçlendirme', 'Kalori yakma'],
      ),

      // Göğüs egzersizleri
      Exercise(
        id: 'pushups',
        name: 'Şınav',
        description: 'Göğüs, omuz ve kol kasları için temel egzersiz',
        bodyRegions: ['Göğüs', 'Omuz', 'Tüm vücut'],
        goals: ['Kas yapmak', 'Sıkılaşmak', 'Genel sağlık'],
        equipment: ['Vücut Ağırlığı ile Çalışıyorum'],
        environments: ['Evde çalışıyorum', 'Spor salonunda çalışıyorum', 'Hem evde hem salonda'],
        duration: 15,
        difficulty: 2,
        instructions: '1. Yüzüstü pozisyonda başla\n2. Ellerini omuz genişliğinde yerleştir\n3. Vücudunu düz tut\n4. Göğsünü yere yaklaştır ve it',
        imageUrl: 'assets/exercises/pushups.jpg', 
        instructionVideoAsset: 'assets/exercises/Pushup.mp4',
        benefits: ['Göğüs kasları', 'Omuz gücü', 'Kol kasları'],
      ),

      Exercise(
        id: 'dumbbell_press',
        name: 'Dumbbell Göğüs Presi',
        description: 'Dumbbell ile göğüs kaslarını güçlendirme',
        bodyRegions: ['Göğüs', 'Omuz'],
        goals: ['Kas yapmak', 'Sıkılaşmak'],
        equipment: ['Dumbell'],
        environments: ['Evde çalışıyorum', 'Spor salonunda çalışıyorum', 'Hem evde hem salonda'],
        duration: 20,
        difficulty: 3,
        instructions: '1. Sırtüstü yat\n2. Dumbbellları göğüs seviyesinde tut\n3. Yukarı doğru it\n4. Kontrollü şekilde indir',
        imageUrl: 'assets/exercises/dumbelchestpress.jpg', 
        instructionVideoAsset: 'assets/exercises/dumbbell_press.mp4',
        benefits: ['Göğüs kasları', 'Omuz stabilizasyonu'],
      ),

      // Bacak egzersizleri
      Exercise(
        id: 'squats',
        name: 'Squat',
        description: 'Alt vücut için temel egzersiz',
        bodyRegions: ['Bacak', 'Tüm vücut'],
        goals: ['Kas yapmak', 'Sıkılaşmak', 'Genel sağlık'],
        equipment: ['Vücut Ağırlığı ile Çalışıyorum'],
        environments: ['Evde çalışıyorum', 'Spor salonunda çalışıyorum', 'Hem evde hem salonda'],
        duration: 15,
        difficulty: 2,
        instructions: '1. Ayaklarını omuz genişliğinde aç\n2. Ellerini öne uzat\n3. Kalçalarını geriye it\n4. Dizlerini bük ve çömel\n5. Tekrar kalk',
        imageUrl: 'assets/exercises/squat.jpg', 
        instructionVideoAsset: 'assets/exercises/Squat.mp4',
        benefits: ['Bacak kasları', 'Kalça gücü', 'Denge'],
      ),

      Exercise(
        id: 'lunges',
        name: 'Lunge',
        description: 'Tek bacak gücü ve denge egzersizi',
        bodyRegions: ['Bacak'],
        goals: ['Kas yapmak', 'Sıkılaşmak', 'Esneklik kazanmak'],
        equipment: ['Vücut Ağırlığı ile Çalışıyorum'],
        environments: ['Evde çalışıyorum', 'Spor salonunda çalışıyorum', 'Hem evde hem salonda'],
        duration: 12,
        difficulty: 2,
        instructions: '1. Ayakta dur\n2. Bir ayağını öne at\n3. Arka dizini yere yaklaştır\n4. Ön dizini bük\n5. Geri dön ve tekrarla',
        imageUrl: 'assets/exercises/lunge.jpg', 
        instructionVideoAsset: 'assets/exercises/Lunge.mp4',
        benefits: ['Bacak kasları', 'Denge', 'Esneklik'],
      ),

      // Sırt egzersizleri
      Exercise(
        id: 'pullups',
        name: 'Barfiks',
        description: 'Sırt ve kol kasları için mükemmel egzersiz',
        bodyRegions: ['Sırt', 'Omuz'],
        goals: ['Kas yapmak', 'Sıkılaşmak'],
        equipment: ['Barfiks Demiri'],
        environments: ['Evde çalışıyorum', 'Spor salonunda çalışıyorum', 'Hem evde hem salonda'],
        duration: 20,
        difficulty: 4,
        instructions: '1. Barfiks barına asıl\n2. Ellerini omuz genişliğinde tut\n3. Vücudunu yukarı çek\n4. Çeneni barın üzerine getir\n5. Kontrollü şekilde indir',
        imageUrl: 'assets/exercises/pullup.jpg',
        instructionVideoAsset: 'assets/exercises/Pullup.gif.mp4',
        benefits: ['Sırt kasları', 'Kol gücü', 'Omuz stabilizasyonu'],
      ),

      // Esneklik egzersizleri
      Exercise(
        id: 'yoga_stretch',
        name: 'Yoga Esneme',
        description: 'Tüm vücut esneklik ve rahatlama',
        bodyRegions: ['Tüm vücut'],
        goals: ['Esneklik kazanmak', 'Genel sağlık'],
        equipment: ['Vücut Ağırlığı ile Çalışıyorum'],
        environments: ['Evde çalışıyorum', 'Spor salonunda çalışıyorum', 'Hem evde hem salonda'],
        duration: 30,
        difficulty: 1,
        instructions: '1. Rahat bir pozisyonda otur\n2. Derin nefes al\n3. Yavaşça esneme hareketleri yap\n4. Her pozisyonda 30 saniye kal',
        imageUrl: 'assets/exercises/pullup.jpg', // Geçici olarak pullup.jpg kullanıyoruz
        benefits: ['Esneklik', 'Stres azaltma', 'Duruş iyileştirme'],
      ),

      // Kilo verme egzersizleri
      Exercise(
        id: 'jumping_jacks',
        name: 'Zıplama',
        description: 'Kardiyovasküler egzersiz',
        bodyRegions: ['Tüm vücut'],
        goals: ['Kilo vermek', 'Genel sağlık'],
        equipment: ['Vücut Ağırlığı ile Çalışıyorum'],
        environments: ['Evde çalışıyorum', 'Spor salonunda çalışıyorum', 'Hem evde hem salonda'],
        duration: 10,
        difficulty: 2,
        instructions: '1. Ayakta dur\n2. Ayaklarını birleştir\n3. Kollarını yukarı kaldır ve zıpla\n4. Ayaklarını omuz genişliğinde aç\n5. Tekrar zıpla ve başlangıç pozisyonuna dön',
        imageUrl: 'assets/exercises/jumpingjack.jpg',
        instructionVideoAsset: 'assets/exercises/Jump.mp4',
        benefits: ['Kalori yakma', 'Kardiyovasküler sağlık', 'Koordinasyon'],
      ),

      Exercise(
        id: 'running',
        name: 'Koşu',
        description: 'En etkili kardiyovasküler egzersiz',
        bodyRegions: ['Bacak', 'Tüm vücut'],
        goals: ['Kilo vermek', 'Genel sağlık'],
        equipment: ['Koşu Bandı'],
        environments: ['Evde çalışıyorum', 'Spor salonunda çalışıyorum'],
        duration: 30,
        difficulty: 3,
        instructions: '1. Koşu bandında başla\n2. Yavaş tempoda başla\n3. Kademeli olarak hızını artır\n4. Düzenli nefes al\n5. Soğuma için yavaşla',
        imageUrl: 'assets/fitness_bg.jpg', // Geçici olarak pullup.jpg kullanıyoruz
        benefits: ['Kalori yakma', 'Kardiyovasküler sağlık', 'Dayanıklılık'],
      ),
    ];
  }

  // Egzersizleri Firestore'a kaydet (admin için)
  Future<void> saveExercisesToFirestore() async {
    try {
      final exercises = _getDefaultExercises();
      final batch = _firestore.batch();
      
      for (final exercise in exercises) {
        final docRef = _firestore.collection(_collection).doc(exercise.id);
        batch.set(docRef, exercise.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Egzersizler kaydedilemedi: ${e.toString()}');
    }
  }
}
