# Admin Roles Debug Kılavuzu

## 🔍 Sorun Tespiti

Eğer "Bu hesap admin yetkisine sahip değil" hatası alıyorsan, şu kontrolleri yap:

### 1. Firebase Console'dan Kontrol Et

Firestore Database > `user_roles` koleksiyonuna git ve dokümanı kontrol et:

**✅ Doğru Format:**
```json
{
  "userId": "abc123xyz456",
  "roles": ["admin"],  // ← Array içinde string
  "createdAt": "2024-01-15T10:30:00Z",  // ← String veya Timestamp
  "assignedBy": "manual"
}
```

**❌ Yanlış Formatlar:**
```json
// YANLIŞ 1: isAdmin alanı kullanılmamalı
{
  "userId": "abc123xyz456",
  "isAdmin": true  // ← Bu alan kullanılmıyor!
}

// YANLIŞ 2: roles string olarak değil, array olmalı
{
  "userId": "abc123xyz456",
  "roles": "admin"  // ← Array değil, string!
}

// YANLIŞ 3: roles array içinde yanlış değer
{
  "userId": "abc123xyz456",
  "roles": ["Admin"]  // ← Büyük harf! "admin" olmalı (küçük harf)
}
```

### 2. Doküman ID'si Kontrolü

**ÖNEMLİ:** Doküman ID'si, kullanıcının Firebase Auth UID'si ile **tam olarak eşleşmeli**!

- Firebase Console > Authentication > Users
- Kullanıcının UID'sini kopyala
- Firestore > `user_roles` koleksiyonunda doküman ID'sinin bu UID ile eşleştiğini kontrol et

### 3. Console Loglarını Kontrol Et

Uygulamayı çalıştır ve terminal'de şu logları ara:

```
🔍 Getting user role for userId: [user_id]
📄 Document exists: true/false
📋 Document data: {...}
📋 roles field: [...]
✅ UserRole created: isAdmin=true/false, roles=[...]
```

### 4. Yaygın Hatalar ve Çözümleri

#### Hata 1: "Document does not exist"
**Sebep:** Doküman ID'si yanlış veya doküman oluşturulmamış
**Çözüm:** 
- Firebase Console'dan dokümanın var olduğunu kontrol et
- Doküman ID'sinin kullanıcı UID'si ile eşleştiğini kontrol et

#### Hata 2: "roles field is null or empty"
**Sebep:** `roles` alanı eksik veya boş array
**Çözüm:**
- Firebase Console'dan dokümanı aç
- `roles` alanının var olduğunu kontrol et
- `roles` array'inin içinde `"admin"` string'i olduğunu kontrol et

#### Hata 3: "roles is not an array"
**Sebep:** `roles` alanı string olarak kaydedilmiş
**Çözüm:**
- Firebase Console'dan dokümanı düzenle
- `roles` alanını sil
- Yeni `roles` alanı ekle, tip: `array`
- Array içine `"admin"` string'i ekle

#### Hata 4: "isAdmin check returns false"
**Sebep:** `roles` array'inde `"admin"` yok veya yanlış yazılmış
**Çözüm:**
- `roles` array'inde `"admin"` olduğunu kontrol et (küçük harf!)
- `"Admin"`, `"ADMIN"`, `"admin "` gibi yazımlar çalışmaz, sadece `"admin"` çalışır

## 🛠️ Hızlı Düzeltme

### Senaryo 1: Doküman Yok
1. Firebase Console > Firestore > `user_roles`
2. Yeni doküman ekle
3. Doküman ID'si: Kullanıcının UID'si
4. Alanları ekle (yukarıdaki doğru formatı kullan)

### Senaryo 2: Doküman Var Ama Yanlış Format
1. Firebase Console > Firestore > `user_roles` > Dokümanı aç
2. `roles` alanını kontrol et
3. Eğer yanlışsa:
   - `roles` alanını sil
   - Yeni `roles` alanı ekle (tip: `array`)
   - Array içine `"admin"` ekle

### Senaryo 3: Doküman ID'si Yanlış
1. Firebase Console > Authentication > Users
2. Kullanıcının UID'sini kopyala
3. Firestore > `user_roles` koleksiyonunda doküman ID'sini kontrol et
4. Eğer farklıysa:
   - Yeni doküman oluştur (doğru UID ile)
   - Eski dokümanı sil

## 📝 Doğru Doküman Örneği

Firebase Console'da `user_roles/{userId}` dokümanı şöyle görünmeli:

```
Document ID: abc123xyz456  (kullanıcının UID'si)

Fields:
┌─────────────┬──────────┬─────────────────────┐
│ Field       │ Type     │ Value               │
├─────────────┼──────────┼─────────────────────┤
│ userId      │ string   │ abc123xyz456        │
│ roles       │ array    │ ["admin"]           │
│ createdAt   │ timestamp│ 2024-01-15 10:30:00 │
│ assignedBy  │ string   │ manual              │
└─────────────┴──────────┴─────────────────────┘
```

## ✅ Test Etme

1. Uygulamayı çalıştır
2. Admin paneline giriş yap
3. Terminal'de logları kontrol et
4. Eğer hala hata varsa, logları paylaş

