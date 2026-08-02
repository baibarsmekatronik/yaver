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

## Teknik / entegrasyon

- **İHATTYS API:** henüz yayında değil; `RegulatoryAdapter` stub olarak kalacak.
- **Telemetri protokolü:** aviyonik tedarikçisiyle teyit edilmedi; Faz 8'de yalnızca arayüz tanımlanacak.
- **Cansu ↔ Luron AI bağlantısı:** mevcut Cansu asistanına geçiş için uç nokta bilgisi bekleniyor; `AiService` arayüzü arkasında tutulacak.
- **Supabase proje bilgileri:** üretim projesi URL + anon key (Faz 1 öncesi gerekli).
- **FCM yapılandırması:** Firebase proje kaydı (Faz 2 öncesi gerekli).
