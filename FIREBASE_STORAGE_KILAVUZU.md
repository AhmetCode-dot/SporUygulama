# Firebase Storage Kullanım Kılavuzu

Bu kılavuz, Firebase Storage'ı projeye nasıl entegre edeceğinizi adım adım açıklar.

## 📋 İçindekiler

1. [Firebase Console'da Storage'ı Aktifleştirme](#1-firebase-consoleda-storageı-aktifleştirme)
2. [Storage Rules'ı Deploy Etme](#2-storage-rulesı-deploy-etme)
3. [Paketleri Yükleme](#3-paketleri-yükleme)
4. [Kullanım](#4-kullanım)

---

## 1. Firebase Console'da Storage'ı Aktifleştirme

### Adım 1: Firebase Console'a Git
1. [Firebase Console](https://console.firebase.google.com/)'a giriş yap
2. Projeni seç: `spor-uygulama-4ddf2`

### Adım 2: Storage'ı Aktifleştir
1. Sol menüden **"Storage"** seçeneğine tıkla
2. **"Get started"** butonuna tıkla
3. **Production mode** seçeneğini seç (güvenlik kuralları zaten hazır)
4. **"Next"** → **"Done"** tıkla

### Adım 3: Storage Bucket'ı Kontrol Et
- Storage bucket adı: `spor-uygulama-4ddf2.firebasestorage.app`
- Bu bilgi `firebase_options.dart` dosyasında zaten mevcut

---

## 2. Storage Rules'ı Deploy Etme

Storage security rules dosyası (`storage.rules`) hazır. Deploy etmek için:

```bash
firebase deploy --only storage
```

### Rules Özeti:
- ✅ **Egzersiz görselleri**: Herkes okuyabilir, sadece admin yazabilir (max 10MB)
- ✅ **Egzersiz videoları**: Herkes okuyabilir, sadece admin yazabilir (max 50MB)
- ✅ **Profil fotoğrafları**: Herkes okuyabilir, kullanıcı sadece kendi fotoğrafını yükleyebilir (max 5MB)

---

## 3. Paketleri Yükleme

Paketler zaten `pubspec.yaml`'a eklendi. Yüklemek için:

```bash
flutter pub get
```

### Eklenen Paketler:
- `firebase_storage: ^11.6.0`
- `file_picker: ^6.1.1`

---

## 4. Kullanım

### Admin Panelinde Görsel/Video Yükleme

1. **Admin Paneline Git**: `/admin` route'una git
2. **Egzersiz Ekle/Düzenle**: "Egzersizler" → "Yeni Egzersiz" veya mevcut egzersizi düzenle
3. **Görsel Yükle**:
   - "Görsel URL" alanının yanındaki **"Yükle"** butonuna tıkla
   - Bilgisayarından bir görsel seç
   - Yükleme ilerlemesi gösterilir
   - Yükleme tamamlandığında URL otomatik olarak alana yazılır
4. **Video Yükle**:
   - "Video URL" alanının yanındaki **"Yükle"** butonuna tıkla
   - Bilgisayarından bir video seç
   - Yükleme ilerlemesi gösterilir
   - Yükleme tamamlandığında URL otomatik olarak alana yazılır

### Manuel URL Girişi

Firebase Storage URL'si veya başka bir HTTP URL'si de girebilirsin:
- Firebase Storage URL: `https://firebasestorage.googleapis.com/v0/b/...`
- HTTP URL: `https://example.com/image.jpg`
- Asset path: `assets/exercises/plank.jpg`

### Kod Örnekleri

#### StorageService Kullanımı

```dart
import 'package:spor_uygulama/services/storage_service.dart';

final storageService = StorageService();

// Görsel yükle
final imageUrl = await storageService.uploadExerciseImage(
  file: fileBytes, // Uint8List (web) veya File (mobil)
  exerciseId: 'exercise123',
  onProgress: (progress) {
    print('İlerleme: ${(progress * 100).toStringAsFixed(1)}%');
  },
);

// Video yükle
final videoUrl = await storageService.uploadExerciseVideo(
  file: fileBytes,
  exerciseId: 'exercise123',
  onProgress: (progress) {
    print('İlerleme: ${(progress * 100).toStringAsFixed(1)}%');
  },
);
```

---

## 📁 Dosya Yapısı

Firebase Storage'da dosyalar şu şekilde organize edilir:

```
exercises/
  ├── images/
  │   └── {exerciseId}/
  │       └── {timestamp}.jpg
  └── videos/
      └── {exerciseId}/
          └── {timestamp}.mp4
users/
  └── {userId}/
      └── profile/
          └── {timestamp}.jpg
```

---

## 🔒 Güvenlik

- ✅ Sadece admin kullanıcılar egzersiz görseli/video yükleyebilir
- ✅ Kullanıcılar sadece kendi profil fotoğraflarını yükleyebilir
- ✅ Dosya boyutu limitleri: Görsel 10MB, Video 50MB, Profil 5MB
- ✅ Content type kontrolü: Sadece image/video dosyaları kabul edilir

---

## ⚠️ Önemli Notlar

1. **Maliyet**: Firebase Storage ücretlidir. Ücretsiz kotası:
   - 5 GB depolama
   - 1 GB/ay indirme
   - 20,000/ay işlem

2. **Alternatif**: Eğer maliyet endişen varsa, ücretsiz CDN'ler kullanabilirsin:
   - Cloudinary (25GB ücretsiz)
   - Imgur (sınırsız)
   - GitHub (repo'da saklama)

3. **Mevcut Asset'ler**: Mevcut asset path'ler (`assets/exercises/...`) hala çalışıyor. Firebase Storage'a geçiş zorunlu değil.

---

## 🐛 Sorun Giderme

### "Permission denied" hatası
- Storage rules'ı deploy ettin mi? `firebase deploy --only storage`
- Admin yetkisine sahip misin? `user_roles` koleksiyonunu kontrol et

### Dosya yüklenmiyor
- Dosya boyutu limiti aşıyor mu? (Görsel: 10MB, Video: 50MB)
- Dosya formatı doğru mu? (Görsel: image/*, Video: video/*)
- İnternet bağlantısı var mı?

### URL görünmüyor
- Yükleme tamamlandı mı? Progress bar'ı kontrol et
- Firestore'da `imageUrl` veya `instructionVideoAsset` alanı güncellendi mi?

---

## 📞 Destek

Sorun yaşarsan:
1. Firebase Console'da Storage sekmesini kontrol et
2. Browser console'da hata mesajlarını kontrol et
3. `storage.rules` dosyasını kontrol et

---

**Hazırlayan**: AI Assistant  
**Tarih**: 2024  
**Versiyon**: 1.0

