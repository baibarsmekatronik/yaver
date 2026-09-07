# FleetCare ↔ baibars Fleet Platform entegrasyonu

Kaynak: [`PLATFORM_ROADMAP.md`](PLATFORM_ROADMAP.md) (v1.1, 07.09.2026) —
FleetCare ile VK takip panosu tek ürüne birleşiyor: **tek backend, tek
veritabanı, iki istemci** (React web panosu + Flutter mobil uygulama).

Bu belge mobil tarafın buna nasıl uyduğunu, hangi kararların verildiğini ve
hangilerinin beklediğini tutar.

---

## 1. Mimari — mobil tarafın yeri

```
VK Open API → vk-collector (.NET) → PostgreSQL ─┬─ React web panosu
                                                └─ Flutter (FleetCare)
```

Mobil uygulama **VK'yı hiç görmez**. Yalnızca kendi veritabanımızı okur.
Yol haritasındaki "telemetri soyutlaması yok, collector VK'ya bağlı kalıyor"
kararı yalnızca backend'i ilgilendirir; mobil taraf zaten VK'dan yalıtılmıştır.

**Bağlantı noktası hazır:** ekranlar veri kaynağını değil `FleetRepository`
arayüzünü tanır. Platform istemcisi bu arayüzün ikinci bir uygulaması olarak
takılacak; ekran kodu değişmeyecek. Bugünkü `LocalFleetRepository` çevrimdışı
önbellek olarak kalır.

---

## 2. Varlık eşlemesi

| Platform (Postgres) | FleetCare (Flutter) | Durum |
|---|---|---|
| `drones.id` | `Aircraft.platformId` | ✅ eklendi |
| `drones.tenant_id` | `Aircraft.tenantId` | ✅ eklendi |
| `drones.model` | `Aircraft.model` | ✅ var |
| `drones.serial_no` | `Aircraft.serialNo` | ✅ var |
| `airframe_totals` | `Aircraft.deviceTotals` (`AirframeTotals`) | ✅ eklendi |
| `sorties` | `Flight` (`source = device`) | ✅ eklendi |
| `sorties.id` | `Flight.platformId` | ✅ eklendi |
| `telemetry` | — | Mobilde saklanmıyor; canlı takip/oynatma platformdan okunacak |
| `maintenance_rules` | Faz 2 | Ortak tablo olacak |
| `maintenance_events` | Faz 2 | ⚠️ isim çakışması — bkz. §4 |
| `audit_log` | Faz 7 | ⚠️ isim çakışması — bkz. §4 |

---

## 3. Sayaç kuralı (en kritik madde)

Yol haritasının sabit kuralı: **uçuş saatinin doğruluk kaynağı cihazın
bildirdiği `ftime` değeridir** — duvar saati değil.

Uygulamada sayaç bugüne kadar elle tutuluyordu. İkisi birleşince aynı uçuş
iki kere sayılabilirdi; sayaç bakım görevlerini tetiklediği için bu **yanlış
zamanda bakım uyarısı** demekti. Uygulanan kural:

```
Cihaz sayacı (airframe_totals) VARSA:
    toplam = cihaz sayacı + yalnızca ELLE girilen uçuşlar
    (cihazdan gelen sorti kayıtları cihaz sayacına zaten dahil;
     başlangıç sayacı da dahil olduğu için kullanılmaz)

Cihaz sayacı YOKSA:
    toplam = başlangıç sayacı + tüm uçuş kayıtları
```

Her uçuş kaydı artık `source` taşıyor: `manual` veya `device`. Güncelleme
öncesi kaydedilmiş uçuşlar `manual` sayılır — cihazdaki mevcut veri bozulmaz.

⚠️ **Açık soru:** cihaz sayacı varken elle girilen uçuşlar üstüne ekleniyor
(bağlantısız dönemde yapılan uçuşlar için). Kullanıcı cihazın zaten kaydettiği
bir uçuşu elle de girerse çift sayım olur. Kullanıcı arayüzünde uyarı mı,
yoksa cihaz bağlıyken elle giriş kapalı mı olsun — karar bekliyor.

---

## 4. Çakışmalar — karar bekliyor

CLAUDE.md ile yol haritası aynı şeylere farklı isimler veriyor. **Tek backend
tek veritabanı** hedefi için bunların teke inmesi gerekiyor.

| Konu | CLAUDE.md | Yol haritası | Not |
|---|---|---|---|
| Hava aracı tablosu | `aircraft` | `drones` | Web ve mobil aynı tabloyu okuyacak |
| Uçuş tablosu | `flights` | `sorties` | CLAUDE.md sürümünde ek alanlar var: `pilot_id`, `location_geohash`, `params jsonb` — birleşik şemada korunmalı |
| Bakım görevi | `maintenance_tasks` | `maintenance_events` | |
| Denetim kaydı | `operation_audit_log` | `audit_log` | |
| Roller | `operator`, `technician`, `baibars_admin` | `customer`, `ops`, `admin`, `gov_readonly` | Tek liste gerekiyor; `technician` yol haritasında yok |

**Dil kuralı çakışması:** yol haritası "müşteriye dönük metinde 'drone'
kullanılabilir" diyor; baibars yazım kuralı Türkçe metinde **İHA** diyor.
Uygulamada kural değiştirilmedi — arayüz "İHA" kullanmaya devam ediyor.
Değişmesi isteniyorsa yazım kuralının güncellenmesi gerekir.

**Faz 8 (telemetri) kapsamı daralıyor:** CLAUDE.md mobil tarafta bir
`TelemetryIngest` arayüzü öngörüyordu. Artık gereksiz — telemetriyi collector
topluyor, mobil uygulama sonucu `sorties` olarak okuyor. Faz 8 mobil tarafta
"canlı takip ekranı" olarak yeniden tanımlanmalı.

---

## 5. Bu turda mobil tarafta yapılanlar

- `Aircraft`: `platformId`, `tenantId`, `deviceTotals` alanları
- `Flight`: `source` (`manual` / `device`), `platformId` alanları
- Sayaç hesabı §3'teki kurala göre yeniden yazıldı
- Alan birimi dönüşümü (`AreaUnits`): mu → dekar (×0,6667), hektar ↔ dekar.
  Uygulama ve veritabanı her yerde dekar tutar; dönüşüm yalnızca veri girişi
  ve gösterimde yapılır
- Arayüz: sayaç cihazdan geliyorsa "Cihaz sayacı" göstergesi, cihazdan gelen
  uçuş kayıtlarında "Cihazdan" etiketi

Eski JSON kayıtlar yeni alanlar olmadan da okunuyor — güncelleme sonrası
cihazdaki veri kaybolmaz.

---

## 6. Mobil tarafın backend'den beklediği

Bunlar gelmeden mobil eşitleme yazılamaz:

1. **Şema ve uç noktalar.** Joseph'in Faz 0 paketindeki kesin tablo yapısı ve
   okuma uçları (tenant kapsamlı sorgular).
2. **Kimlik doğrulama kararı.** Supabase Auth mı, bağımsız mı; rol adları ve
   token biçimi. Mobil taraf Faz 1'de bunun üstüne oturacak.
3. **Eşitleme yönü.** Elle girilen uçuşlar platforma yazılacak mı, yoksa
   mobil yalnızca okuma mı yapacak? §3'teki çift sayım kararı buna bağlı.
4. **Alan birimi.** Platform `sorties` alanını hangi birimde tutuyor — mu mu,
   dönüştürülmüş dekar mı? Dönüşüm iki yerde yapılırsa değer iki kat şişer.
5. **`errorCode` tablosu.** Bakım tetikleyicisi olarak kullanılacak
   (yol haritası açık madde 5); mobil bildirimler buna bağlanacak.

Yol haritasındaki mevzuat ve VK kaynaklı açık maddeler (barındırma yeri,
İHATTYS spesifikasyonu, kota, SLA) mobil tarafı doğrudan bloke etmiyor.
