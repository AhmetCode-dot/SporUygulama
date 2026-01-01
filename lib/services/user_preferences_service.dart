import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_preferences.dart';

class UserPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'user_preferences';

  Future<UserPreferences?> getPreferences(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserPreferences.fromMap(doc.data()!);
  }

  Future<void> savePreferences(UserPreferences preferences) async {
    await _firestore
        .collection(_collection)
        .doc(preferences.userId)
        .set(preferences.toMap(), SetOptions(merge: true));
  }
}


