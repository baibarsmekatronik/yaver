# Açık sorular — baibars mühendislik / agronomi onayı bekleyen değerler

Uygulamada `TBD` işaretli hiçbir değer, onaylanmadan "baibars doğrulamış" gibi gösterilmez.

## Bakım aralıkları (mühendislik onayı gerekli)

| Kontrol kalemi | Taslak aralık | Durum |
|---|---|---|
| Şasi profil çatlak muayenesi | her 50 sorti | **TBD** |
| Pompa çarkı aşınma kontrolü | her 100 uçuş saati | **TBD** |
| Nozül disk kontrolü / değişimi | her 50 uçuş saati | **TBD** |
| Pervane hasar kontrolü | her 25 sorti | **TBD** |
| İniş takımı cıvata kontrolü | her 100 sorti | **TBD** |

Onaylı olanlar (CLAUDE.md / datasheet kaynaklı):
- Kol katlama aparatı vidası tork kontrolü — her 100 sorti
- Motor tork ve montaj cıvatası kontrolü — her 100 uçuş saati
- Motor montaj yönü kontrolü (3° içe eğim) — her motor/mount değişimi + 100 saat
- Akış metre kalibrasyonu — her 6 ay
- Batarya sağlık değerlendirmesi — her 50 döngü

## Uçuş parametresi hazır ayarları (agronomi onayı gerekli)

- Tüm ürün/ağaç bazlı doz–hız–irtifa–iş genişliği değerleri agronomi ekibi
  doğrulamadan `validated_by_baibars = false` olarak işaretlenir ve arayüzde
  "AI önerisi" etiketiyle ayrışır.

## Arayüz eşikleri (bakım aralığı değil — baibars onayı ile değişebilir)

| Konu | Şimdiki değer | Not |
|---|---|---|
| "Bakım yaklaşıyor" uyarısının çıkma anı | kontrole **10 sorti** veya **10 saat** kala | Bakım aralığı değil, yalnızca uyarı eşiği. `AircraftSummary.warnBeforeSorties` / `warnBeforeHours` |

## Platform birleşmesi (07.09.2026 kararı)

FleetCare ile VK takip panosu tek ürüne birleşiyor. Mobil tarafın hizalaması,
çakışan tablo/rol adları ve backend'den beklenenler ayrı belgede:
[`PLATFORM_INTEGRATION.md`](PLATFORM_INTEGRATION.md).

Karar bekleyen başlıklar oradaki §4 ve §6'da listeli. En acil olanı:

- **Cihaz sayacı varken elle uçuş girişi.** Cihazın zaten kaydettiği bir sortiyi
  kullanıcı elle de girerse sayaç çift sayar. Uyarı mı verilsin, elle giriş
  kapatılsın mı?
- **Tek tablo/rol adı listesi.** `aircraft`/`drones`, `maintenance_tasks`/
  `maintenance_events`, `operation_audit_log`/`audit_log`, rol adları.
- **Alan birimi.** Platform `sorties` alanını mu mu dekar mı tutuyor —
  dönüşüm iki yerde yapılırsa değer iki kat şişer.

## Teknik / entegrasyon

- **İHATTYS API:** henüz yayında değil; `RegulatoryAdapter` stub olarak kalacak.
- **Telemetri protokolü:** aviyonik tedarikçisiyle teyit edilmedi; Faz 8'de yalnızca arayüz tanımlanacak.
- **Cansu ↔ Luron AI bağlantısı:** mevcut Cansu asistanına geçiş için uç nokta bilgisi bekleniyor; `AiService` arayüzü arkasında tutulacak.
- **Yerel depolama (bilinçli sapma):** CLAUDE.md drift/sqflite diyor. Faz 1'de veri
  `FleetRepository` arayüzünün arkasında basit bir yerel depoda (JSON) tutuluyor;
  kod üretimi gerektirmediği ve web dahil her platformda ek kurulum istemediği için
  seçildi. Veri hacmi büyüdüğünde ya da karmaşık sorgu gerektiğinde yalnızca
  `LocalFleetRepository` drift ile değiştirilecek. Onayınıza sunulur.
- **Supabase proje bilgileri:** üretim projesi URL + anon key (bulut senkronu için gerekli).
- **FCM yapılandırması:** Firebase proje kaydı (Faz 2 öncesi gerekli).
