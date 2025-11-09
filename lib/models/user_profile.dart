class UserProfile {
  final String userId;
  final String email;
  final double height; // metre cinsinden
  final double weight; // kg cinsinden
  final int age;
  final String gender;
  final double bmi;

  UserProfile({
    required this.userId,
    required this.email,
    required this.height,
    required this.weight,
    required this.age,
    required this.gender,
    required this.bmi,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'height': height,
      'weight': weight,
      'age': age,
      'gender': gender,
      'bmi': bmi,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      height: (map['height'] ?? 0.0).toDouble(),
      weight: (map['weight'] ?? 0.0).toDouble(),
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      bmi: (map['bmi'] ?? 0.0).toDouble(),
    );
  }

  String getBmiCategory() {
    if (bmi < 18.5) {
      return 'Zayıf';
    } else if (bmi >= 18.5 && bmi < 25) {
      return 'Sağlıklı';
    } else if (bmi >= 25 && bmi < 30) {
      return 'Şişman';
    } else if (bmi >= 30 && bmi < 40) {
      return 'Obez';
    } else {
      return 'Aşırı Obez (Morbid Obez)';
    }
  }
} 