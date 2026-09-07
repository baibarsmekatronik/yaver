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
| "Bakım yaklaşıyor" uyarısının çıkma anı | her kuralda ayrı `warnBefore` (100'lük aralıklarda 10) | Bakım aralığı değil, uyarı eşiği. Artık koda gömülü değil, kural verisinde |
| Tazelik gösterim eşikleri | 0–3 sn Canlı / 3–15 sn Gecikiyor / 15–60 sn Veri eski / >60 sn Bağlantı yok | Yol haritası v1.2; üretim ölçümünden sonra kalibre edilecek. Canlı takip ekranı yazılınca uygulanacak |

## Platform birleşmesi (07.09.2026 kararı)

FleetCare ile VK takip panosu tek ürüne birleşiyor. Mobil tarafın hizalaması,
çakışan tablo/rol adları ve backend'den beklenenler ayrı belgede:
[`PLATFORM_INTEGRATION.md`](PLATFORM_INTEGRATION.md).

Karar bekleyen başlıklar oradaki §5 ve §7'de listeli. En acil olanlar:

- **Bakım tablosu TBD işaretleri.** Yol haritası v1.2 tabloyu "baibars onaylı
  varsayılan" diye niteliyor; CLAUDE.md beş aralığı TBD olarak işaretliyor.
  Tohum veride TBD korundu — onay verildiyse kaldırılmalı.
- **Cihaz sayacı varken elle uçuş girişi.** Cihazın zaten kaydettiği bir sortiyi
  kullanıcı elle de girerse sayaç çift sayar. Uyarı mı verilsin, elle giriş
  kapatılsın mı?
- **Sahiplik devri (v1.2 D3).** İkinci el satışta gövde ömrü taşınıyor ama
  önceki sahibin kayıtları taşınmıyor. Telefondaki yerel uçuş kayıtlarına ne
  olacak — silinsin mi, arşivlensin mi?
- **Tek tablo/rol adı listesi.** `aircraft`/`drones`, `maintenance_tasks`/
  `maintenance_events`, `operation_audit_log`/`audit_log`, rol adları.
- **Alan birimi.** Platform `sorties` alanını mu mu dekar mı tutuyor —
  dönüşüm iki yerde yapılırsa değer iki kat şişer.
- **`002_v1_2_patch.sql` elimize ulaşmadı** (v1.2 §4 atıf yapıyor).

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
