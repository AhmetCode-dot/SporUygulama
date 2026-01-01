# Firebase Hosting ile Görsel/Video Yükleme Kılavuzu

## 📋 Genel Bakış

Firebase Hosting kullanarak görselleri/videoları yükleyip, URL'lerini Firestore'a kaydedeceğiz. Bu tamamen ücretsizdir (10GB depolama + 360MB/gün transfer).

---

## 🚀 Adım 1: Firebase Hosting'i Kurma

### 1.1 Firebase CLI Kurulumu

**Windows için:**
```bash
# PowerShell'de çalıştırın
npm install -g firebase-tools
```

**Kurulumu kontrol edin:**
```bash
firebase --version
```

### 1.2 Firebase'e Giriş Yapma

```bash
firebase login
```

Tarayıcı açılacak, Google hesabınızla giriş yapın.

### 1.3 Projeyi Başlatma

Proje klasörünüzde çalıştırın:
```bash
firebase init hosting
```

**Sorular ve cevaplar:**

1. **"What do you want to use as your public directory?"**
   - Cevap: `public` (Enter'a basın)

2. **"Configure as a single-page app?"**
   - Cevap: `No` (N)

3. **"Set up automatic builds and deploys with GitHub?"**
   - Cevap: `No` (N)

4. **"File public/index.html already exists. Overwrite?"**
   - Cevap: `No` (N)

Bu işlem `firebase.json` ve `.firebaserc` dosyalarını oluşturur.

---

## 📁 Adım 2: Klasör Yapısını Oluşturma

### 2.1 Public Klasörü Oluşturma

Proje kök dizininde `public` klasörü oluşturun (eğer yoksa):

```
spor_uygulama/
├── public/
│   ├── exercises/
│   │   ├── images/
│   │   └── videos/
│   └── users/
│       └── profiles/
├── lib/
├── assets/
└── ...
```

### 2.2 Klasörleri Oluşturma (PowerShell)

```powershell
# Proje kök dizininde çalıştırın
New-Item -ItemType Directory -Path "public\exercises\images" -Force
New-Item -ItemType Directory -Path "public\exercises\videos" -Force
New-Item -ItemType Directory -Path "public\users\profiles" -Force
```

---

## 🖼️ Adım 3: Görselleri/Videoları Yükleme

### 3.1 Görselleri Kopyalama

Mevcut görsellerinizi `public/exercises/images/` klasörüne kopyalayın:

**Örnek:**
```
public/exercises/images/
├── pushups.jpg
├── squats.jpg
├── plank.jpg
└── ...
```

### 3.2 Videoları Kopyalama

Videoları `public/exercises/videos/` klasörüne kopyalayın:

**Örnek:**
```
public/exercises/videos/
├── pushups.mp4
├── squats.mp4
└── ...
```

**Not:** Video dosyaları büyük olabilir. Firebase Hosting'in 10GB limitini aşmamaya dikkat edin.

---

## 🚀 Adım 4: Firebase Hosting'e Deploy Etme

### 4.1 Deploy Komutu

```bash
firebase deploy --only hosting
```

**İlk deploy biraz zaman alabilir (5-10 dakika).**

### 4.2 Deploy Sonrası

Deploy tamamlandığında şu şekilde bir URL alırsınız:

```
✔ Deploy complete!

Hosting URL: https://spor-uygulama-4ddf2.web.app
```

---

## 🔗 Adım 5: URL'leri Alma

### 5.1 URL Formatı

Deploy edilen görsellerin URL'leri şu formatta olacak:

```
https://spor-uygulama-4ddf2.web.app/exercises/images/pushups.jpg
https://spor-uygulama-4ddf2.web.app/exercises/videos/pushups.mp4
```

### 5.2 URL'leri Test Etme

Tarayıcıda URL'yi açarak görselin/videonun yüklendiğini kontrol edin:

```
https://spor-uygulama-4ddf2.web.app/exercises/images/pushups.jpg
```

---

## 💾 Adım 6: URL'leri Firestore'a Kaydetme

### 6.1 Firebase Console'dan (Manuel)

1. **Firebase Console'a gidin**: https://console.firebase.google.com
2. **Projenizi seçin**: `spor-uygulama-4ddf2`
3. **Firestore Database'e gidin**
4. **`exercises` koleksiyonunu açın**
5. **Bir egzersiz dokümanını açın** (ör: `pushups`)
6. **`imageUrl` alanını ekleyin/güncelleyin**:
   ```
   imageUrl: "https://spor-uygulama-4ddf2.web.app/exercises/images/pushups.jpg"
   ```
7. **`videoUrl` alanını ekleyin/güncelleyin** (varsa):
   ```
   videoUrl: "https://spor-uygulama-4ddf2.web.app/exercises/videos/pushups.mp4"
   ```

### 6.2 Admin Panelinden (Otomatik - Gelecekte)

Admin panelinde görsel yükleme özelliği eklendiğinde, görseli seçip otomatik olarak:
1. `public/exercises/images/` klasörüne kopyalanır
2. Firebase Hosting'e deploy edilir
3. URL Firestore'a kaydedilir

---

## 🔄 Adım 7: Yeni Görsel/Video Ekleme

### 7.1 Yeni Dosya Ekleme

1. Görseli/videoyu `public/exercises/images/` veya `public/exercises/videos/` klasörüne koyun
2. Deploy edin:
   ```bash
   firebase deploy --only hosting
   ```
3. URL'yi Firestore'a kaydedin

### 7.2 Toplu Deploy

Tüm dosyaları bir kerede deploy edebilirsiniz:

```bash
firebase deploy --only hosting
```

---

## 📝 Adım 8: Admin Panelinde Kullanım (Gelecek)

Admin panelinde görsel yükleme özelliği eklendiğinde:

1. Admin görseli seçer
2. Görsel `public/exercises/images/` klasörüne kaydedilir
3. Firebase Hosting'e otomatik deploy edilir
4. URL Firestore'a kaydedilir

**Not:** Bu özellik için ek bir servis yazılması gerekir (Cloud Functions veya manuel deploy).

---

## 🎯 Örnek: Şınav Egzersizi İçin

### 1. Görseli Yükleme
```
public/exercises/images/pushups.jpg
```

### 2. Deploy Etme
```bash
firebase deploy --only hosting
```

### 3. URL'yi Alma
```
https://spor-uygulama-4ddf2.web.app/exercises/images/pushups.jpg
```

### 4. Firestore'a Kaydetme
Firebase Console'da `exercises/pushups` dokümanında:
```json
{
  "id": "pushups",
  "name": "Şınav",
  "imageUrl": "https://spor-uygulama-4ddf2.web.app/exercises/images/pushups.jpg",
  ...
}
```

---

## ⚙️ Adım 9: firebase.json Yapılandırması

`firebase.json` dosyanız şu şekilde olmalı:

```json
{
  "hosting": {
    "public": "public",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

**Not:** Eğer sadece statik dosyalar (görseller/videolar) host edecekseniz, `rewrites` kısmını kaldırabilirsiniz.

---

## 🔍 Adım 10: URL'leri Kontrol Etme

### 10.1 Tarayıcıda Test

URL'yi tarayıcıda açarak görselin/videonun yüklendiğini kontrol edin:

```
https://spor-uygulama-4ddf2.web.app/exercises/images/pushups.jpg
```

### 10.2 Uygulamada Test

Uygulamayı çalıştırın ve egzersiz görsellerinin yüklendiğini kontrol edin.

---

## 📊 Firebase Hosting Limitleri

### Ücretsiz Plan (Spark Plan)
- ✅ **10 GB depolama**
- ✅ **360 MB/gün transfer**
- ✅ **Sınırsız istek**

### Ücretli Plan (Blaze Plan)
- 💰 **10 GB ücretsiz**, sonrası $0.026/GB
- 💰 **360 MB/gün ücretsiz**, sonrası $0.15/GB

**Not:** Küçük-orta projeler için ücretsiz plan yeterlidir.

---

## 🛠️ Sorun Giderme

### Sorun 1: "firebase: command not found"
**Çözüm:**
```bash
npm install -g firebase-tools
```

### Sorun 2: "Permission denied"
**Çözüm:**
```bash
firebase login
```

### Sorun 3: "No Firebase project found"
**Çözüm:**
```bash
firebase use --add
```
Projenizi seçin: `spor-uygulama-4ddf2`

### Sorun 4: Görseller yüklenmiyor
**Çözüm:**
1. `public` klasörünün doğru yerde olduğunu kontrol edin
2. Dosya isimlerinde Türkçe karakter olmamasına dikkat edin
3. Deploy'u tekrar deneyin

### Sorun 5: URL çalışmıyor
**Çözüm:**
1. URL'yi tarayıcıda test edin
2. Dosya yolunun doğru olduğunu kontrol edin
3. Firestore'da URL'nin doğru kaydedildiğini kontrol edin

---

## 🎨 İpuçları

### 1. Dosya İsimlendirme
- Türkçe karakter kullanmayın: `şınav.jpg` ❌ → `pushups.jpg` ✅
- Boşluk kullanmayın: `push ups.jpg` ❌ → `pushups.jpg` ✅
- Küçük harf kullanın: `PushUps.jpg` ❌ → `pushups.jpg` ✅

### 2. Görsel Optimizasyonu
- Görselleri optimize edin (küçük boyut = hızlı yükleme)
- WebP formatı kullanın (daha küçük boyut)
- Maksimum 1920x1080 çözünürlük yeterlidir

### 3. Video Optimizasyonu
- Videoları sıkıştırın (MP4 formatı)
- Maksimum 1080p çözünürlük
- 10-30 saniye arası kısa videolar

### 4. Toplu İşlemler
Tüm görselleri bir kerede deploy edin:
```bash
firebase deploy --only hosting
```

---

## 📚 Sonraki Adımlar

1. ✅ Görselleri `public/exercises/images/` klasörüne koyun
2. ✅ `firebase deploy --only hosting` komutunu çalıştırın
3. ✅ URL'leri Firestore'a kaydedin
4. ✅ Uygulamada test edin

---

## 🎉 Tamamlandı!

Artık Firebase Hosting kullanarak görsellerinizi/videolarınızı yükleyebilir ve URL'lerini Firestore'a kaydedebilirsiniz!

**Sorularınız varsa sormaktan çekinmeyin!** 🚀

