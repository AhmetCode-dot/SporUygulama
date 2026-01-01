# Firebase Hosting - Hızlı Başlangıç 🚀

## ⚡ 5 Dakikada Kurulum

### 1. Firebase CLI Kurulumu

**PowerShell'de çalıştırın:**
```powershell
npm install -g firebase-tools
```

**Kurulumu kontrol edin:**
```powershell
firebase --version
```

### 2. Firebase'e Giriş

```powershell
firebase login
```

Tarayıcı açılacak, Google hesabınızla giriş yapın.

### 3. Projeyi Bağlama

```powershell
firebase use --add
```

**Sorular:**
- **"Which project do you want to add?"**
  - `spor-uygulama-4ddf2` seçin
- **"What alias do you want to use for this project?"**
  - `default` (Enter'a basın)

### 4. Klasörler Hazır ✅

Klasörler zaten oluşturuldu:
- ✅ `public/exercises/images/` - Görseller için
- ✅ `public/exercises/videos/` - Videolar için

### 5. Görselleri Kopyalama

Mevcut görsellerinizi `public/exercises/images/` klasörüne kopyalayın:

**Örnek:**
```
public/exercises/images/
├── pushups.jpg
├── squats.jpg
└── plank.jpg
```

### 6. Deploy Etme

```powershell
firebase deploy --only hosting
```

**İlk deploy 5-10 dakika sürebilir.**

### 7. URL'leri Alma

Deploy tamamlandığında URL'ler şu formatta olacak:

```
https://spor-uygulama-4ddf2.web.app/exercises/images/pushups.jpg
https://spor-uygulama-4ddf2.web.app/exercises/videos/pushups.mp4
```

### 8. Firestore'a Kaydetme

Firebase Console'da `exercises` koleksiyonunda:

1. Bir egzersiz dokümanını açın (ör: `pushups`)
2. `imageUrl` alanını ekleyin:
   ```
   https://spor-uygulama-4ddf2.web.app/exercises/images/pushups.jpg
   ```
3. `videoUrl` alanını ekleyin (varsa):
   ```
   https://spor-uygulama-4ddf2.web.app/exercises/videos/pushups.mp4
   ```

---

## 📝 Örnek: Şınav Egzersizi

### 1. Görseli Kopyalama
```
assets/exercises/pushups.jpg → public/exercises/images/pushups.jpg
```

### 2. Deploy
```powershell
firebase deploy --only hosting
```

### 3. Firestore'a Kaydetme
Firebase Console → Firestore → `exercises/pushups`:
```json
{
  "imageUrl": "https://spor-uygulama-4ddf2.web.app/exercises/images/pushups.jpg"
}
```

### 4. Test
Tarayıcıda açın:
```
https://spor-uygulama-4ddf2.web.app/exercises/images/pushups.jpg
```

---

## 🔄 Yeni Görsel Ekleme

1. Görseli `public/exercises/images/` klasörüne koyun
2. Deploy edin:
   ```powershell
   firebase deploy --only hosting
   ```
3. URL'yi Firestore'a kaydedin

---

## ⚠️ Önemli Notlar

### Dosya İsimlendirme
- ❌ Türkçe karakter: `şınav.jpg`
- ✅ İngilizce: `pushups.jpg`
- ❌ Boşluk: `push ups.jpg`
- ✅ Tire/alt çizgi: `push-ups.jpg` veya `push_ups.jpg`

### Dosya Boyutu
- Görseller: Maksimum 1-2 MB (optimize edin)
- Videolar: Maksimum 10-20 MB (kısa videolar)

### Toplu Deploy
Tüm görselleri bir kerede deploy edin:
```powershell
firebase deploy --only hosting
```

---

## 🆘 Sorun Giderme

### "firebase: command not found"
```powershell
npm install -g firebase-tools
```

### "Permission denied"
```powershell
firebase login
```

### "No Firebase project found"
```powershell
firebase use --add
```
`spor-uygulama-4ddf2` seçin

---

## 📚 Detaylı Kılavuz

Daha detaylı bilgi için `FIREBASE_HOSTING_GUIDE.md` dosyasına bakın.

---

**Hazırsınız! 🎉**

