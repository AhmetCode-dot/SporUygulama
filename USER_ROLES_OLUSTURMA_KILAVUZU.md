# user_roles Koleksiyonu Oluşturma Kılavuzu

## 📋 Adım Adım Talimatlar

### Yöntem 1: Firebase Console'dan Manuel Oluşturma (İlk Admin İçin)

#### Adım 1: Firebase Console'a Giriş Yap
1. Tarayıcınızda şu adrese git: https://console.firebase.google.com
2. Projenizi seç: `spor-uygulama-4ddf2`

#### Adım 2: Firestore Database'e Git
1. Sol menüden **"Firestore Database"** seçeneğine tıkla
2. Eğer ilk kez açıyorsan, "Test modunda başlat" veya "Production modunda başlat" seçeneğini seç

#### Adım 3: Koleksiyon Oluştur
1. **"Koleksiyon başlat"** (Start collection) butonuna tıkla
2. Koleksiyon ID'sini gir: **`user_roles`**
3. **"Sonraki"** (Next) butonuna tıkla

#### Adım 4: İlk Dokümanı Oluştur (Admin Kullanıcı İçin)
1. **Doküman ID'si**: Admin olmasını istediğin kullanıcının **user ID**'sini gir
   - Kullanıcı ID'sini bulmak için:
     - Firestore'da `user_profiles` koleksiyonuna git
     - Admin yapmak istediğin kullanıcının doküman ID'sini kopyala
     - Örnek: `abc123xyz456` gibi bir ID

2. **Alanları ekle** (Add field):
   
   **Alan 1: userId**
   - Alan adı: `userId`
   - Tip: `string`
   - Değer: Kullanıcı ID'si (doküman ID'si ile aynı)
   - Örnek: `abc123xyz456`

   **Alan 2: roles**
   - Alan adı: `roles`
   - Tip: `array`
   - Değer: `["admin"]` (array içinde string olarak "admin" yaz)
   - Nasıl eklenir:
     1. Tip olarak "array" seç
     2. Array içine tıkla
     3. "Add item" butonuna tıkla
     4. Tip: `string`, Değer: `admin`
     5. Kaydet

   **Alan 3: createdAt**
   - Alan adı: `createdAt`
   - Tip: `timestamp`
   - Değer: Şu anki tarih ve saat (otomatik doldurulur veya manuel seç)
   - Nasıl eklenir:
     1. Tip olarak "timestamp" seç
     2. Takvimden bugünün tarihini seç
     3. Saati ayarla

   **Alan 4: assignedBy** (Opsiyonel)
   - Alan adı: `assignedBy`
   - Tip: `string`
   - Değer: `manual` veya başka bir admin kullanıcı ID'si
   - Örnek: `manual` veya `admin_user_id`

#### Adım 5: Dokümanı Kaydet
1. Tüm alanları ekledikten sonra **"Kaydet"** (Save) butonuna tıkla
2. Doküman oluşturuldu!

#### Örnek Doküman Yapısı:
```json
{
  "userId": "abc123xyz456",
  "roles": ["admin"],
  "createdAt": "2024-01-15T10:30:00Z",
  "assignedBy": "manual"
}
```

---

### Yöntem 2: Migration Script ile Otomatik Oluşturma

Eğer zaten `users` koleksiyonunda `isAdmin: true` olan kullanıcılar varsa:

#### Adım 1: Admin Paneline Giriş Yap
1. Uygulamayı çalıştır: `flutter run -d chrome --web-port=8080`
2. Admin paneline git: `http://localhost:8080/#/admin/login`
3. Admin hesabıyla giriş yap (eski sistemde admin olan bir hesap)

#### Adım 2: Migration Butonunu Kullan
1. **"Kullanıcılar"** sekmesine git
2. Üstte **"Admin Rolleri Migration"** kartını gör
3. **"Çalıştır"** butonuna tıkla
4. Onay dialog'unda **"Evet, Devam Et"** seçeneğini seç
5. Migration otomatik olarak çalışacak ve tüm admin kullanıcıları `user_roles` koleksiyonuna taşınacak

#### Adım 3: Sonuçları Kontrol Et
- Migration tamamlandığında sonuçlar gösterilecek
- Firebase Console'dan `user_roles` koleksiyonunu kontrol et

---

## 🔍 Koleksiyonun Doğru Oluşturulduğunu Kontrol Etme

### Firebase Console'dan Kontrol:
1. Firestore Database'e git
2. `user_roles` koleksiyonunu bul
3. Dokümanları kontrol et:
   - ✅ `userId` alanı var mı?
   - ✅ `roles` array'i var mı ve içinde `"admin"` var mı?
   - ✅ `createdAt` timestamp var mı?

### Uygulamadan Kontrol:
1. Admin paneline giriş yap
2. Kullanıcılar listesinde admin kullanıcıların **"Admin"** badge'i olduğunu gör
3. Admin yetkilerini test et (egzersiz ekleme, kullanıcı yönetimi)

---

## 📝 Örnek Senaryolar

### Senaryo 1: İlk Admin Oluşturma
Eğer hiç admin yoksa ve ilk admin'i oluşturmak istiyorsan:

1. Firebase Console > Firestore > `user_profiles` koleksiyonuna git
2. Admin yapmak istediğin kullanıcının doküman ID'sini kopyala
3. `user_roles` koleksiyonunu oluştur (yukarıdaki adımları takip et)
4. Doküman ID'si olarak kopyaladığın kullanıcı ID'sini kullan
5. Alanları ekle ve kaydet

### Senaryo 2: Mevcut Admin'leri Taşıma
Eğer `users` koleksiyonunda zaten `isAdmin: true` olan kullanıcılar varsa:

1. Admin paneline giriş yap (eski sistemde admin olan bir hesap)
2. Migration butonunu kullan
3. Tüm admin kullanıcılar otomatik olarak taşınacak

### Senaryo 3: Yeni Admin Ekleme
Eğer `user_roles` koleksiyonu zaten varsa ve yeni admin eklemek istiyorsan:

**Seçenek A: Admin Panelinden**
1. Admin paneline giriş yap
2. Kullanıcılar sekmesine git
3. Kullanıcıya tıkla
4. "Admin Yap" butonuna tıkla

**Seçenek B: Firebase Console'dan**
1. `user_roles` koleksiyonuna git
2. Yeni doküman ekle (kullanıcı ID'si ile)
3. Alanları ekle (yukarıdaki adımları takip et)

---

## ⚠️ Önemli Notlar

1. **Doküman ID'si = Kullanıcı ID'si**: `user_roles/{userId}` formatında olmalı
2. **roles Array**: Mutlaka array tipinde olmalı ve içinde `"admin"` string'i olmalı
3. **createdAt**: Timestamp tipinde olmalı
4. **Firestore Rules**: Rules'ın deploy edildiğinden emin ol (zaten yaptık)

---

## 🐛 Sorun Giderme

### "Permission denied" hatası alıyorsan:
- Firestore rules'ın deploy edildiğinden emin ol
- `firebase deploy --only firestore:rules` komutunu çalıştır

### Admin yetkisi çalışmıyorsa:
- `user_roles/{userId}` dokümanının var olduğunu kontrol et
- `roles` array'inde `"admin"` değerinin olduğunu kontrol et
- Doküman ID'sinin kullanıcı ID'si ile eşleştiğini kontrol et

### Migration butonu görünmüyorsa:
- Admin paneline giriş yaptığından emin ol
- Kullanıcılar sekmesine gittiğinden emin ol
- Sayfayı yenile (F5)

---

## 📸 Görsel Adımlar (Firebase Console)

### 1. Koleksiyon Oluşturma
```
Firestore Database > Start collection > Collection ID: "user_roles" > Next
```

### 2. Doküman Oluşturma
```
Document ID: [kullanıcı_id] > Add field
```

### 3. Alan Ekleme Örneği
```
Field name: "roles"
Field type: "array"
Value: ["admin"] (array içinde string "admin")
```

---

## ✅ Kontrol Listesi

Migration'dan önce:
- [ ] Firestore rules deploy edildi
- [ ] Admin paneline giriş yapılabiliyor (eski sistem)
- [ ] `user_profiles` koleksiyonunda kullanıcılar var

Migration sırasında:
- [ ] Migration butonuna tıklandı
- [ ] Onay dialog'unda "Evet" seçildi
- [ ] Migration tamamlandı mesajı görüldü

Migration sonrası:
- [ ] `user_roles` koleksiyonu oluşturuldu
- [ ] Admin kullanıcılar `user_roles` koleksiyonunda
- [ ] Admin paneline giriş yapılabiliyor (yeni sistem)
- [ ] Admin yetkileri çalışıyor

---

## 🎯 Hızlı Başlangıç

**En hızlı yöntem:**
1. Admin paneline giriş yap (eski sistemde admin olan hesap)
2. Kullanıcılar sekmesine git
3. Migration butonuna tıkla
4. Tamamlandı! ✅

Eğer hiç admin yoksa:
1. Firebase Console > Firestore
2. `user_roles` koleksiyonunu oluştur
3. İlk admin dokümanını manuel ekle (yukarıdaki adımları takip et)

