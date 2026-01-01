# Firestore Rules Deploy Kılavuzu

## Permission Denied Hatası Çözümü

"Permission denied" hatası alıyorsanız, Firestore rules'ı güncellemeniz gerekiyor.

## Yöntem 1: Firebase Console'dan (Önerilen)

1. **Firebase Console'a gidin**: https://console.firebase.google.com
2. **Projenizi seçin**: `spor-uygulama-4ddf2`
3. **Firestore Database'e gidin**: Sol menüden "Firestore Database"
4. **Rules sekmesine tıklayın**: Üst menüden "Rules"
5. **Mevcut rules'ı silin ve yeni rules'ı yapıştırın**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function: Kullanıcının admin olup olmadığını kontrol et
    function isAdmin() {
      return request.auth != null &&
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.get('isAdmin', false) == true;
    }
    
    // Users koleksiyonu - kullanıcılar kendi verilerini yazabilir/okuyabilir, admin tümünü görebilir
    match /users/{userId} {
      allow read: if request.auth != null && (request.auth.uid == userId || isAdmin());
      allow write: if request.auth != null && (request.auth.uid == userId || isAdmin());
    }
    
    // User profiles koleksiyonu - kullanıcılar kendi profillerini yazabilir/okuyabilir, admin tümünü görebilir
    match /user_profiles/{userId} {
      allow read: if request.auth != null && (request.auth.uid == userId || isAdmin());
      allow write: if request.auth != null && (request.auth.uid == userId || isAdmin());
    }
    
    // Workout sessions koleksiyonu - kullanıcılar sadece kendi antrenmanlarını yazabilir/okuyabilir, admin tümünü görebilir
    match /workout_sessions/{sessionId} {
      allow read: if request.auth != null && (
        resource.data.userId == request.auth.uid || isAdmin()
      );
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth != null && (
        resource.data.userId == request.auth.uid || isAdmin()
      );
    }
    
    // Exercises koleksiyonu - herkes okuyabilir, sadece admin yazabilir
    match /exercises/{exerciseId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
  }
}
```

6. **"Publish" butonuna tıklayın**
7. **Birkaç saniye bekleyin** (rules deploy olacak)

## Yöntem 2: Firebase CLI ile

Eğer Firebase CLI kuruluysa:

1. `firebase.json` dosyasını güncelleyin (aşağıdaki içeriği ekleyin)
2. Terminal'de şu komutu çalıştırın:
   ```bash
   firebase deploy --only firestore:rules
   ```

### firebase.json Güncellemesi

`firebase.json` dosyasına şunu ekleyin:

```json
{
  "firestore": {
    "rules": "firestore.rules"
  },
  "flutter": {
    ...
  }
}
```

## Admin Kullanıcısı Oluşturma

Rules'ı deploy ettikten sonra, bir kullanıcıyı admin yapmanız gerekiyor:

1. **Firebase Console → Firestore Database**
2. **`users` koleksiyonuna gidin**
3. **Kullanıcı ID'si ile doküman oluşturun** (veya mevcut olanı düzenleyin)
4. **Şu alanı ekleyin**:
   ```json
   {
     "isAdmin": true
   }
   ```

**ÖNEMLİ**: Kullanıcı ID'si, Firebase Authentication'daki User UID ile aynı olmalı!

## Test Etme

1. Admin paneline giriş yapın
2. Console'da (F12) hata var mı kontrol edin
3. Dashboard'da veriler görünüyor mu kontrol edin

## Sorun Giderme

### Hala "Permission denied" alıyorum
- Rules'ı deploy ettiniz mi? (Publish butonuna tıkladınız mı?)
- Kullanıcı admin mi? (`users/{userId}` dokümanında `isAdmin: true` var mı?)
- Kullanıcı ID'si doğru mu? (Firebase Auth'daki UID ile aynı mı?)

### Rules'ı test etmek için
Firebase Console → Firestore Database → Rules → "Rules Playground" sekmesini kullanabilirsiniz.

