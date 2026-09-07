# FleetCare ↔ baibars Fleet Platform entegrasyonu

Güncel kaynak: [`PLATFORM_ROADMAP.md`](PLATFORM_ROADMAP.md) — **v1.2**
(07.09.2026, iki araştırma izinin uzlaştırılması).
Önceki sürüm arşivde: [`PLATFORM_ROADMAP_V1_1.md`](PLATFORM_ROADMAP_V1_1.md).
Çakışan yerlerde **v1.2 geçerlidir**.

FleetCare ile VK takip panosu tek üründe birleşiyor: **tek backend, tek
veritabanı, iki istemci** (React web panosu + Flutter mobil uygulama).
Bu belge mobil tarafın buna nasıl uyduğunu, hangi kararların uygulandığını ve
hangilerinin beklediğini tutar.

---

## 1. Mimari — mobil tarafın yeri

```
VK Open API → collector → normalizer → PostgreSQL ─┬─ React web panosu
                                                   └─ Flutter (FleetCare)
```

Mobil uygulama **VK'yı hiç görmez**; yalnızca kendi veritabanımızı okur.
v1.2 (D1) collector ile veritabanı arasına ince bir **kanonik sözleşme**
koyuyor: `ftime`, `posAccur` gibi üretici adları normalizer'ı geçemez.
Mobil taraf zaten yalnızca kanonik adları görecek.

**Bağlantı noktası hazır:** ekranlar veri kaynağını değil `FleetRepository`
arayüzünü tanır. Platform istemcisi bu arayüzün ikinci bir uygulaması olarak
takılacak; ekran kodu değişmeyecek. Bugünkü `LocalFleetRepository` çevrimdışı
önbellek olarak kalır.

### Kesin sınır (yeni, mevzuat kaynaklı)

> Çiftçi platformu **asla uçuş komutu göndermez.** İzleme, geçmiş, bakım,
> raporlama — hepsi bu kadar.

SHGM uyum modülü (Madde 23: zarf daraltma, rota değişikliği, indirme, uçuş
sonlandırma) ayrı ve sertifikalandırılabilir bir kontrol istasyonu iş
paketidir; bu ürünün dışındadır. **Bu uygulamaya komut/kontrol arayüzü
eklenmeyecek.**

---

## 2. Varlık eşlemesi

| Platform (Postgres) | FleetCare (Flutter) | Durum |
|---|---|---|
| `drones.id` | `Aircraft.platformId` | ✅ |
| `drones.model` / `serial_no` | `Aircraft.model` / `serialNo` | ✅ |
| `airframe_totals.flight_seconds_confirmed` | `AirframeTotals.flightSecondsConfirmed` | ✅ v1.2 |
| `airframe_totals.flight_seconds_min_known` | `AirframeTotals.flightSecondsMinKnown` | ✅ v1.2 |
| `sorties` | `Flight` (`source = device`) | ✅ |
| `sorties.completeness` | `Flight.completeness` | ✅ v1.2 |
| `maintenance_rules` | `MaintenanceRule` + `maintenanceRulesSeed` | ✅ v1.2 |
| `maintenance_rules.valid_reset_actions` | `MaintenanceRule.validResetActions` | ✅ v1.2 |
| `maintenance_rules.rule_version` / `effective_from` | aynı adlarla | ✅ v1.2 |
| `aircraft_assignment` | `Aircraft.tenantId` (yalnızca *güncel* atama) | ⚠️ bkz. §5 |
| `component_instance` | — | Faz 2 |
| `telemetry` | — | Mobilde saklanmıyor; canlı takip platformdan okunacak |
| `audit_log` | — | Faz 7 |

---

## 3. Sayaç kuralı (en kritik madde)

Platformun sabit kuralı: **uçuş saatinin doğruluk kaynağı cihazın bildirdiği
`ftime` değeridir** — duvar saati değil.

v1.2 (D2) bunu bir adım ileri götürüyor. Uçuş bitmeden bağlantı koparsa son
bilinen `ftime` gerçek süreden **azdır**. Tek sayaçla çalışmak bakım aralığını
sessizce uzatır — bir bakım sistemi bunu yapmamalıdır. Bu yüzden sayaç ikili:

```
flight_seconds_confirmed  → temiz kapanmış sortiler
flight_seconds_min_known  → kesintili sortiler dahil, "en az bu kadar"

gerçek süre ≥ min_known ≥ confirmed
```

Uygulanan kural:

```
Cihaz sayacı VARSA:
    süre    = min_known + elle girilen uçuşlar     ← eksik saymamak için alt sınır
    sorti   = cihaz sortileri + elle girilen uçuşlar
    (cihazdan gelen sorti kayıtları cihaz sayacına zaten dahil;
     başlangıç sayacı da dahil olduğu için kullanılmaz)

Cihaz sayacı YOKSA:
    başlangıç sayacı + tüm uçuş kayıtları
```

`min_known > confirmed` olduğunda ya da kesintili bir uçuş kaydı bulunduğunda
arayüz **"Sayaç eksik olabilir"** uyarısı gösterir. Sessizce eksik saymak
yasak: v1.2 "maintenance engine must alert on low-confidence counters, never
silently under-count" diyor.

Her uçuş kaydı `source` (`manual`/`device`) ve `completeness`
(`provisional`/`confirmed`/`interrupted`/`reconciled`) taşır. Güncelleme
öncesi kaydedilmiş uçuşlar `manual` + `confirmed` sayılır — cihazdaki mevcut
veri bozulmaz.

---

## 4. Bakım kuralları artık veri (v1.2, D6)

Aralıklar koddan çıkarıldı. `MaintenanceRule` veriden okunur;
`maintenanceRulesSeed` yalnızca ilk kurulum tohumudur. baibars bir aralığı
güncellediğinde **uygulama yeniden yayınlanmayacak.**

D6'nın sıfırlama kuralı Faz 2'nin tasarımını değiştiriyor:

| İşlem | Etkisi |
|---|---|
| `INSPECTED` | Yalnızca o kuralın muayene başlangıcı sıfırlanır |
| `REPLACED` | Eski `component_instance` kapanır, yenisi 0 saatten başlar |
| `REPAIRED` | Yalnızca kural izin veriyorsa sıfırlar |
| — | **Gövde ömrü asla sıfırlanmaz** |

Kurallar sürümlü (`ruleVersion`, `effectiveFrom`): aralık değiştiğinde geçmiş
kayıtlar hangi sürüme göre kapandığını bilmeli.

⚠️ **Karar bekliyor:** v1.2 bakım tablosunu "baibars onaylı varsayılan" diye
niteliyor; CLAUDE.md ise beş aralığı **TBD** olarak işaretliyor. Tohum veride
TBD işaretleri **korundu** (onaysız aralık çiftçiye kesin bilgi gibi
gösterilmiyor). Onaylandıysa işaretler kaldırılmalı.

---

## 5. Karar bekleyenler

### 5.1 v1.2'nin getirdikleri

- **İkinci el / demo / bayi stoğu (D3).** Platformda `aircraft_assignment`
  geçmiş tablosu var: gövde ömrü hava aracıyla taşınır, önceki sahibin tarla
  ve uygulama kayıtları taşınmaz. Mobil tarafta `Aircraft.tenantId` yalnızca
  *güncel* atamayı gösteriyor. Sahiplik değişince telefondaki yerel uçuş
  kayıtlarına ne olacak — silinecek mi, arşivlenecek mi? Karar gerekiyor.
- **Bakım tablosu TBD işaretleri** — bkz. §4.
- **`002_v1_2_patch.sql` elimize ulaşmadı.** v1.2 §4 bu dosyaya atıf yapıyor;
  şema alan adlarını ondan doğrulamak gerekiyor.

### 5.2 v1.1'den devreden, hâlâ açık

CLAUDE.md ile yol haritası aynı şeylere farklı isimler veriyor. **Tek
veritabanı** hedefi için teke inmeleri gerekiyor:

| Konu | CLAUDE.md | Yol haritası |
|---|---|---|
| Hava aracı tablosu | `aircraft` | `drones` |
| Uçuş tablosu | `flights` | `sorties` |
| Bakım görevi | `maintenance_tasks` | `maintenance_events` |
| Denetim kaydı | `operation_audit_log` | `audit_log` |
| Roller | operator, technician, baibars_admin | customer, ops, admin, gov_readonly |

CLAUDE.md'deki `flights` tablosunda yol haritasında olmayan alanlar var
(`pilot_id`, `location_geohash`, `params`). Bunlar SHT-İHA denetim raporu için
gerekli — birleşik şemada korunmalı.

**Dil kuralı çakışması:** yol haritası "müşteriye dönük metinde 'drone'
kullanılabilir" diyor; baibars yazım kuralı Türkçe metinde **İHA** diyor.
Uygulama "İHA" kullanmaya devam ediyor; değişecekse yazım kuralı güncellenmeli.

---

## 6. Henüz uygulanmayan, kaydedilen tasarım kuralları

Bunlar canlı takip ekranı yazılırken bağlayıcıdır:

**Tazelik durumları** (v1.2 §2 — üretim ölçümünden sonra kalibre edilecek):

| Yaş | Gösterim |
|---|---|
| 0–3 sn | Canlı |
| 3–15 sn | Gecikiyor |
| 15–60 sn | Veri eski |
| >60 sn | Bağlantı yok |

Eski bir nokta asla canlı gibi gösterilmez; harita balonu "Son bilinen konum —
41 sn önce" der.

**Diğer kurallar:**
- **NULL normal bir değerdir.** Eksik ≠ false, bilinmeyen sıcaklık ≠ 0.
  Sahte varsayılan yok.
- **İrtifa:** VK datum'u doğrulayana kadar `raw_altitude` +
  `raw_altitude_reference:"unknown"`; varsayımla `altitude_msl_m` doldurulmaz.
  Aynı ilke `posAccur` birimi için de geçerli.
- **Çiftçi arayüzü en fazla beş durum kavramı** taşır: durum, batarya, RTK,
  ilaçlama/yük, tazelik.
- **İlaçlanan alan** yalnızca `spray.active=true` bölümlerinden türetilir;
  telemetri boşlukları oynatmada kesik çizgi olarak görünür, asla ilaçlanmış
  gibi doldurulmaz.
- Alan birimi gösterimde mu → dekar (×0,6667).

---

## 7. Mobil tarafın backend'den beklediği

1. **`002_v1_2_patch.sql`** ve Joseph'in Faz 0 paketindeki kesin tablo yapısı.
2. **Kimlik doğrulama kararı.** Supabase Auth mı, bağımsız mı; rol adları ve
   token biçimi.
3. **Eşitleme yönü.** Elle girilen uçuşlar platforma yazılacak mı, yoksa mobil
   yalnızca okuma mı yapacak?
4. **Alan birimi.** Platform `sorties` alanını mu mu, dönüştürülmüş dekar mı
   tutuyor — dönüşüm iki yerde yapılırsa değer iki kat şişer.
5. **`errorCode` sözlüğü.** Bakım tetikleyicisi olacak; mobil bildirimler
   buna bağlanacak.
6. **Sahiplik devri akışı** (D3) — bkz. §5.1.

Mevzuat ve VK kaynaklı açık maddeler (barındırma yeri, İHATTYS başvurusu,
kota, SLA) mobil tarafı doğrudan bloke etmiyor.
