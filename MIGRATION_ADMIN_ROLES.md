# Admin Rolleri Migration Kılavuzu

## 📋 Ne Yapıldı?

Admin yetkilendirmesi artık ayrı bir koleksiyonda (`user_roles`) tutuluyor. Önceden `users/{userId}` koleksiyonunda `isAdmin: true` alanı ile kontrol ediliyordu.

## 🔄 Yeni Yapı

### Koleksiyon: `user_roles/{userId}`
```json
{
  "userId": "user123",
  "roles": ["admin"],
  "createdAt": "2024-01-01T00:00:00Z",
  "assignedBy": "admin456",
  "lastModified": "2024-01-01T00:00:00Z"
}
```

### Avantajlar
- ✅ Gelecekte farklı roller eklenebilir (moderator, premium, vb.)
- ✅ Çoklu rol desteği
- ✅ Daha temiz mimari (kullanıcı verileri ve yetkilendirme ayrı)
- ✅ İzin bazlı kontrol için hazır

## 🚀 Migration Adımları

### 1. Firestore Rules'ı Deploy Et
```bash
firebase deploy --only firestore:rules
```

### 2. Migration Script'i Çalıştır

#### Seçenek A: Admin Panelinden (Önerilen)
1. Admin paneline giriş yap
2. Kullanıcılar sekmesine git
3. Migration butonuna tıkla (eklenmesi gerekiyor)

#### Seçenek B: Manuel Migration
Firebase Console'dan:
1. `users` koleksiyonuna git
2. `isAdmin: true` olan kullanıcıları bul
3. Her biri için `user_roles/{userId}` dokümanı oluştur:
   ```json
   {
     "userId": "user_id_buraya",
     "roles": ["admin"],
     "createdAt": "2024-01-01T00:00:00Z",
     "assignedBy": "migration"
   }
   ```

#### Seçenek C: Script ile (Geliştirme)
```dart
import 'lib/scripts/migrate_admin_roles.dart';

final migration = AdminRoleMigration();
await migration.migrateAdminRoles();
```

### 3. Test Et
1. Admin paneline giriş yap
2. Kullanıcılar listesinde admin kullanıcıların "Admin" badge'i olduğunu kontrol et
3. Admin yetkilerinin çalıştığını test et (egzersiz ekleme, kullanıcı yönetimi)

### 4. Temizlik (Opsiyonel)
Eski `isAdmin` alanlarını kaldırmak için:
```dart
await migration.cleanupOldAdminFields();
```

⚠️ **Dikkat**: Temizlik işlemini yalnızca migration'ın başarılı olduğundan emin olduktan sonra yapın!

## 📝 Yeni Admin Ekleme

### Admin Panelinden
1. Kullanıcılar sekmesine git
2. Kullanıcıya tıkla
3. "Admin Yap" butonuna tıkla

### Kod ile
```dart
final userRoleService = UserRoleService();
await userRoleService.makeAdmin(userId, assignedBy: currentAdminId);
```

## 🔍 Kontrol

### Kullanıcının admin olup olmadığını kontrol et
```dart
final userRoleService = UserRoleService();
final isAdmin = await userRoleService.isAdmin(userId);
```

### Tüm admin kullanıcıları listele
```dart
final adminIds = await userRoleService.getAllAdminUserIds();
```

## ⚠️ Önemli Notlar

1. **Firestore Rules**: Migration'dan önce mutlaka yeni rules'ı deploy edin!
2. **İlk Admin**: İlk admin kullanıcısını manuel olarak `user_roles` koleksiyonuna eklemeniz gerekebilir
3. **Geriye Dönük Uyumluluk**: Eski `users` koleksiyonundaki `isAdmin` alanları artık kullanılmıyor, ancak temizlik yapmadan önce migration'ın başarılı olduğundan emin olun

## 🐛 Sorun Giderme

### "Permission denied" hatası
- Firestore rules'ın deploy edildiğinden emin olun
- `user_roles` koleksiyonu için rules'ın doğru olduğunu kontrol edin

### Admin yetkisi çalışmıyor
- `user_roles/{userId}` dokümanının var olduğunu kontrol edin
- `roles` array'inde `"admin"` değerinin olduğunu kontrol edin
- Firestore rules'ın güncel olduğunu kontrol edin

## 📚 İlgili Dosyalar

- `lib/models/user_role.dart` - UserRole modeli
- `lib/services/user_role_service.dart` - UserRoleService
- `lib/services/admin_service.dart` - AdminService (güncellendi)
- `firestore.rules` - Firestore güvenlik kuralları (güncellendi)
- `lib/scripts/migrate_admin_roles.dart` - Migration script'i

