# baibars FleetCare

**CT110 filo sağlığı ve bakım uygulaması** — baibars Mekatronik Havacılık Sanayi A.Ş.

> Çiftçinin Gökyüzündeki Dostu — yerde de yanınızda.

baibars FleetCare, CT110 otonom tarımsal İHA sahiplerinin ve operatörlerinin
hava aracı sağlığını, bakım takvimini, batarya durumunu ve mevzuat
yükümlülüklerini tek yerden takip etmesini sağlayan mobil uygulamadır
(iOS + Android).

## Özellikler (faz planı)

| Faz | Kapsam | Durum |
|---|---|---|
| 0 | İskelet: tema, i18n (TR/EN), giriş ekranı | ✅ Tamamlandı |
| 1 | Kayıt & sayaçlar: kimlik doğrulama, hava aracı CRUD, sorti/uçuş saati | ⬜ |
| 2 | Bakım motoru: kural tabanlı görevler, kontrol listesi + fotoğraf, servis defteri | ⬜ |
| 3 | Kit envanteri: yedek parça stoğu, tüketim akışı | ⬜ |
| 4 | Batarya sağlığı: döngü kaydı, trend grafiği | ⬜ |
| 5 | Uçuş parametreleri: ürün/ağaç bazlı hazır ayarlar | ⬜ |
| 6 | Cansu: yapay zekâ asistanı (Claude API, Supabase Edge Function) | ⬜ |
| 7 | SHT-İHA modülü: tescil, lisans, sigorta, denetim raporu | ⬜ |
| 8 | Telemetri (yalnızca tasarım): `TelemetryIngest` arayüzü | ⬜ |

## Teknoloji

- **Mobil:** Flutter (Material 3, TR/EN i18n)
- **Durum yönetimi:** Riverpod
- **Backend:** Supabase (Postgres + Auth + RLS + Storage + Edge Functions)
- **Yapay zekâ (Cansu):** Claude API — yalnızca Supabase Edge Function üzerinden
- **Bildirimler:** Firebase Cloud Messaging
- **Çevrimdışı:** drift (saha koşulları için offline-first)

## Geliştirme

```bash
# Bağımlılıkları indir
flutter pub get

# i18n dosyalarını üret
flutter gen-l10n

# Çalıştır
flutter run

# Test ve analiz
flutter test
flutter analyze
```

## Güvenlik notları

- `.env` dosyaları git'e girmez; API anahtarları yalnızca Supabase secrets içinde tutulur.
- Anthropic API anahtarı hiçbir koşulda mobil uygulamada bulunmaz.
- KVKK: en az kişisel veri; ad/telefon/tarla konumu şifreli saklanır, loglanmaz.

## Açık sorular

Doğrulanması gereken değerler (bakım aralıkları vb.) için:
[`docs/OPEN_QUESTIONS.md`](docs/OPEN_QUESTIONS.md)
