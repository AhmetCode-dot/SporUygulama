# Admin Paneli Kullanım Kılavuzu

## Genel Bakış

Bu proje için kapsamlı bir admin paneli oluşturulmuştur. Admin paneli, Flutter Web üzerinden çalışır ve Firebase Firestore kullanarak tüm verileri yönetmenize olanak sağlar.

## Özellikler

### 1. Dashboard (Ana Sayfa)
- **Genel İstatistikler**: Toplam kullanıcı, antrenman, egzersiz sayıları
- **Günlük/Haftalık İstatistikler**: Bugünkü ve bu haftaki antrenman sayıları
- **Popüler Egzersizler**: En çok yapılan egzersizler listesi

### 2. Kullanıcı Yönetimi
- **Kullanıcı Listesi**: Tüm kullanıcıları görüntüleme
- **Arama**: Email adresine göre kullanıcı arama
- **Kullanıcı Detayları**: 
  - Profil bilgileri (yaş, cinsiyet, boy, kilo, BMI)
  - Antrenman istatistikleri
  - Antrenman geçmişi
- **Admin Yetkisi**: Kullanıcıları admin yapma/kaldırma
- **Kullanıcı Silme**: Kullanıcı ve tüm verilerini silme

### 3. Egzersiz Yönetimi
- **Egzersiz Listesi**: Tüm egzersizleri görüntüleme
- **Arama**: Egzersiz adına göre arama
- **Egzersiz Ekleme**: Yeni egzersiz ekleme
- **Egzersiz Düzenleme**: Mevcut egzersizleri güncelleme
- **Egzersiz Silme**: Egzersiz silme

## Kurulum ve Kullanım

### 1. İlk Admin Kullanıcısı Oluşturma

Admin paneline giriş yapabilmek için bir kullanıcıyı admin yapmanız gerekir. Bunu yapmak için:

1. Firebase Console'a gidin
2. Firestore Database'e gidin
3. `users` koleksiyonunda bir kullanıcı dokümanı bulun veya oluşturun
4. O dokümanda `isAdmin: true` alanını ekleyin

**Örnek:**
```json
{
  "isAdmin": true,
  "equipment": [...],
  "environment": "..."
}
```

### 2. Admin Paneline Erişim

#### Web'de Çalıştırma:
```bash
flutter run -d chrome --web-port=8080
```

Sonra tarayıcıda şu URL'ye gidin:
```
http://localhost:8080/#/admin/login
```

#### Mobil Uygulamadan Erişim:
Mobil uygulamada normal login yapın, sonra admin route'una yönlendirin:
```dart
Navigator.pushNamed(context, '/admin/login');
```

### 3. Admin Paneli Route'ları

- `/admin/login` - Admin giriş sayfası
- `/admin/dashboard` - Admin dashboard (otomatik yönlendirme)

## Veritabanı Yapısı

### Admin Yetkilendirme

Admin kontrolü `users/{userId}` koleksiyonunda `isAdmin: true` alanı ile yapılır.

### Firestore Koleksiyonları

1. **users**: Kullanıcı tercihleri ve admin bilgileri
   - `isAdmin`: boolean (admin kontrolü için)
   - `equipment`: array (kullanıcının ekipmanları)
   - `environment`: string (çalışma ortamı)

2. **user_profiles**: Kullanıcı profil bilgileri
   - `email`, `height`, `weight`, `age`, `gender`, `bmi`

3. **workout_sessions**: Antrenman oturumları
   - `userId`, `date`, `exerciseIds`, `exerciseNames`, `totalDuration`

4. **exercises**: Egzersizler (admin tarafından yönetilir)
   - `id`, `name`, `description`, `bodyRegions`, `goals`, `equipment`, vb.

## Güvenlik

### Firestore Rules

Firestore rules güncellenmiştir ve admin yetkileri için özel kontroller içerir:

- Admin kullanıcılar tüm kullanıcıları görebilir
- Admin kullanıcılar tüm antrenmanları görebilir
- Sadece admin kullanıcılar egzersiz ekleyebilir/düzenleyebilir/silebilir
- Admin kullanıcılar diğer kullanıcıları admin yapabilir

### Güvenlik Önerileri

1. **İlk Admin Oluşturma**: İlk admin kullanıcısını Firebase Console'dan manuel olarak oluşturun
2. **Admin Sayısı**: Çok fazla admin kullanıcı oluşturmayın
3. **Şifre Güvenliği**: Admin hesapları için güçlü şifreler kullanın
4. **Firestore Rules**: Firestore rules'ı düzenli olarak kontrol edin

## Geliştirme Notları

### Yeni Özellik Ekleme

1. **Yeni Admin Sayfası**: `lib/views/admin/` klasörüne yeni sayfa ekleyin
2. **Admin Service**: `lib/services/admin_service.dart` dosyasına yeni metodlar ekleyin
3. **Route Ekleme**: `lib/main.dart` dosyasına yeni route ekleyin

### Test Etme

Admin panelini test etmek için:

1. Bir test kullanıcısı oluşturun
2. Firebase Console'dan o kullanıcıyı admin yapın
3. Admin panelinde giriş yapın
4. Tüm özellikleri test edin

## Sorun Giderme

### "Bu hesap admin yetkisine sahip değil" Hatası

- Kullanıcının `users/{userId}` dokümanında `isAdmin: true` alanının olduğundan emin olun
- Firestore rules'ın doğru deploy edildiğinden emin olun

### Egzersiz Ekleyemiyorum

- Admin yetkilerinizin olduğundan emin olun
- Firestore rules'ı kontrol edin
- Firebase Console'dan manuel olarak test edin

### Kullanıcıları Göremiyorum

- Firestore'da `user_profiles` koleksiyonunun var olduğundan emin olun
- Firestore rules'ın admin okuma yetkilerini içerdiğinden emin olun

## İletişim ve Destek

Sorularınız için proje yöneticinize başvurun.

