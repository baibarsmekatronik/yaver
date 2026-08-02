# Prototipi sunucuya bağlama — adım adım rehber

Bu rehber, Claude Design tarafındaki **baibars FleetCare** prototipinin
(`baibars FleetCare.dc.html`) bir sunucuya bağlanıp veri toplamasını sağlar.
Sunucu olarak projemizin hedef altyapısı **Supabase** kullanılır
(baibars cloud v0 — bkz. CLAUDE.md).

Toplam süre: yaklaşık 15 dakika. Kod yazmak gerekmez; kopyala-yapıştır yeterlidir.

## Genel resim

```
Claude Design prototipi (HTML/JS)
        │  fetch (HTTPS)
        ▼
Supabase REST API  ──►  Postgres tabloları
   (anon key + RLS)      aircraft / flights / prototype_events
```

Prototipteki bir butona basıldığında JavaScript, Supabase'in hazır REST
arayüzüne bir kayıt gönderir. Ayrı bir sunucu yazmaya gerek yoktur —
Supabase her tablo için otomatik API üretir.

## 1. Supabase projesi açın

1. [supabase.com](https://supabase.com) → **New project** (ücretsiz plan yeterli).
2. Bölge olarak Avrupa (ör. Frankfurt) seçin — Türkiye'ye en yakın bölge.
3. Proje açılınca **Settings → API** sayfasından iki değeri not edin:
   - **Project URL** (ör. `https://abcd1234.supabase.co`)
   - **anon public** anahtarı

## 2. Tabloları oluşturun

1. Supabase panelinde **SQL Editor**'ü açın.
2. Bu repodaki `supabase/migrations/0001_prototype_data_collection.sql`
   dosyasının içeriğini yapıştırıp **Run** deyin.
3. **Table Editor**'de üç tablo görünmeli: `aircraft`, `flights`,
   `prototype_events`. `aircraft` içinde bir adet demo CT110 hazırdır.

## 3. Bağlantı dosyasını prototipe ekleyin

1. Bu repodaki `prototype/fleetcare-api.js` dosyasını açın.
2. En üstteki `FLEETCARE_CONFIG` içine 1. adımda not ettiğiniz
   **Project URL** ve **anon** anahtarını yazın.
3. Dosyanın tamamını Claude Design projesine yeni bir dosya olarak ekleyin
   (ör. `fleetcare-api.js`, `support.js`'in yanına) ve prototip HTML'inde
   `support.js`'in yüklendiği yere şu satırı ekleyin:

   ```html
   <script src="fleetcare-api.js"></script>
   ```

## 4. Butonları sunucuya bağlayın

Prototipte veri toplamak istediğiniz her etkileşime tek satır eklenir:

```js
// Bakım tamamlandı butonu:
fleetcare.logEvent("maintenance_done", { kontrol: "pervane-hasar-kontrolu" });

// Sorti kaydet butonu (sayaçları sunucu otomatik artırır):
fleetcare.addFlight(ucakId, { durationMin: 11, areaDa: 20 });

// Ekran görüntüleme, tıklama vb. her şey için genel kayıt:
fleetcare.logEvent("screen_view", { ekran: "bakim-listesi" });
```

Çalışan tam örnek: `prototype/ornek-baglanti.html` — bu dosyayı tarayıcıda
açıp (aynı klasörde `fleetcare-api.js` doldurulmuş olmalı) butona bastığınızda
kaydın Supabase **Table Editor → flights** tablosuna düştüğünü görürsünüz.

## 5. Toplanan veriyi görüntüleme

- Anlık kontrol: Supabase **Table Editor** → `prototype_events` / `flights`.
- Sorgu ile: **SQL Editor** →
  `select event_type, count(*) from prototype_events group by 1;`

## Güvenlik notları (önemli)

- **anon** anahtarı herkese açık olacak şekilde tasarlanmıştır; prototipe
  koymak normaldir. **service_role** anahtarını asla prototipe koymayın.
- SQL dosyasındaki RLS politikaları **yalnızca demo** içindir (anon herkese
  yazma izni verir). Faz 1'de e-posta+OTP girişi geldiğinde bu politikalar
  kullanıcı-bazlı politikalarla değiştirilecek.
- KVKK: `payload` alanına ad-soyad, telefon, adres gibi kişisel veri yazmayın.

## Sonraki adım: prototip dosyasına doğrudan bağlama

Bu oturumda Claude Design projesinin dosyalarına uzaktan erişim yetkisi
yoktu; bu yüzden bağlantı katmanı genel fonksiyonlar olarak hazırlandı.
Prototipin **kendi butonlarına** birebir bağlamamı isterseniz iki yol var:

1. Claude Design'da projeyi açıp **"Send to Claude Code Web"** ile bu
   çalışma alanına gönderin — dosyalar buraya iner, ben butonları tek tek
   bağlarım.
2. Veya `baibars FleetCare.dc.html` içeriğini repoya `prototype/` klasörüne
   kopyalayın; sonraki oturumda bağlantıyı tamamlarım.
