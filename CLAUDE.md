# baibars FleetCare — CT110 Fleet Health & Maintenance App

## What this project is

A mobile app (iOS + Android) for owners/operators of the **baibars CT110** autonomous agricultural UAV. Built and maintained by baibars Mekatronik Havacılık Sanayi A.Ş. (Mersin, Türkiye).

Core purposes:
1. Track airframe health and component maintenance per aircraft (serial-number based)
2. Sortie counter + flight-hour counter driving automatic maintenance reminders
3. Maintenance kit inventory tracking (the waterproof service kit shipped with each CT110)
4. Battery health tracking (34Ah 18S packs)
5. Flight parameter recommendations per crop/tree (dose, speed, altitude, swath)
6. "Cansu" — AI assistant (Claude API) for farmer-friendly support in Turkish
7. SHT-İHA regulatory compliance module (SHGM, Türkiye — new directive in force since 30.07.2026)
8. Sync everything to baibars cloud (backend)

## About baibars (company context — this shapes the app's voice)

- **baibars Mekatronik Havacılık Sanayi A.Ş.** is a Turkish civil UAV manufacturer, operating since 2015 with its factory in Mersin, Türkiye. It positions itself as **Türkiye'nin lider sivil İHA üreticisi** (Türkiye's leading civil UAV manufacturer).
- Core business: design and manufacture of autonomous agricultural UAVs — "yerli ve milli" (domestically designed and produced in Türkiye). Products carry CE and TSE certifications.
- Agricultural product line relevant to this app: **CT33s Pro, CT50s Pro, CT110**. This app launches CT110-first, but the data model must not hardcode CT110 assumptions — model-specific specs and maintenance rules live in data, not code, so CT33s Pro / CT50s Pro can be added later.
- Global footprint: branches in Türkiye, USA, UK, Spain and Japan; products and services delivered to 12+ countries, from Guatemala to Indonesia, France to Sudan. So the app must be built i18n-ready beyond TR/EN from day one (string architecture, RTL-safe layouts, metric units with room for locale formats).
- Brand promises the app must live up to:
  - **"Çiftçinin Gökyüzündeki Dostu"** (The Farmer's Friend in the Sky) — the app is the ground-side embodiment of this: a companion, not a technical burden.
  - **"Emeğinizi Ezmeyin"** (Don't crush your labor) — the product protects the farmer's effort; the app protects the product (maintenance = uptime = harvest saved).
  - **48-hour technical service commitment** — the app is the fastest channel into this service (Cansu escalation, service request flow).
- What baibars aims for: dependable, field-proven technology that pays for itself in the farmer's time, cost and resource management — not gadgetry. The app should feel the same: robust, honest, zero fluff.
- **Do NOT reference** baibars defense-related products, customers, pricing, discounts, suppliers or partnership/shareholding matters anywhere in the app UI, code comments, or seed data. This app is strictly the agricultural product line.

## App design direction (the "çizgi")

- **Personality:** sağlam, güvenilir, çiftçi dostu — like a well-made tool, not a tech toy. Confident and calm, never salesy inside the app.
- **Visual line:** follows the CT110 datasheet identity — deep green `#1B4D3E` and baibars blue `#1F4788` as primary surfaces, lime accent `#B5D334` for progress/success and highlights, generous white space, bold geometric headings (datasheet uses a bold rounded sans for statements and a mono-style face for product codes like CT110 — mirror that hierarchy: strong statement typography, technical values in tabular/mono style).
- **Field-first ergonomics:** the app is used outdoors, in sunlight, often with dirty or gloved hands. Big touch targets (min 48dp), high contrast, dark-on-light default with a true high-brightness readable palette, critical actions reachable one-handed, minimal typing (pickers, steppers, QR scan instead of serial typing).
- **Farmer-friendly language:** short sentences, everyday Turkish, no engineering jargon in UI copy ("Vida kontrolü zamanı geldi" not "Torsiyonel bağlantı elemanı periyodik muayenesi"). Numbers and units always explicit.
- **Trust through evidence:** every maintenance record shows photo + date + who signed it. Health statuses use plain traffic-light semantics (yeşil = uçuşa hazır, sarı = kontrol yaklaşıyor, kırmızı = uçma, önce kontrol).
- **Tone of notifications:** helpful reminders from a teammate, never alarmist, never spammy. One clear action per notification.
- **The app is part of the product:** a farmer who paid for a CT110 should feel the same build quality in the app — fast startup, works offline in the field, never loses entered data.

## Who the user is

- The developer (product owner) is a baibars engineer, not a professional programmer. Explain what you're doing in plain language. He communicates in Turkish and English — respond in whichever language he uses.
- End users of the app are **farmers and spray-service operators**. UI language: Turkish first, English second (i18n from day 1). UI copy must be simple and farmer-friendly — no unnecessary jargon.

## Brand & writing rules (STRICT)

- Company name is always lowercase: **baibars** — even at the start of a sentence. Never "Baibars" or "BAIBARS".
- Country is always written **Türkiye**, never "Turkey", including in English strings.
- Product name: **CT110** (exactly this casing).
- In Turkish UI text use **İHA**; in English text use **UAV**. "Drone" is acceptable only in marketing-style copy.
- The spreader is referred to as "serpme sistemimiz" / "our spreader".
- Brand color: `#1F4788` (baibars blue). Secondary: dark green `#1B4D3E` (from datasheet), accent lime `#B5D334`.
- Dates displayed as DD.MM.YYYY.

## Tech stack

- **Mobile:** Flutter (single codebase, Material 3, Turkish + English i18n via `flutter_localizations` / `intl`)
- **Backend:** Supabase (Postgres + Auth + Row Level Security + Storage + Edge Functions). This is "baibars cloud v0"; design so it can later migrate to self-hosted infrastructure.
- **AI (Cansu):** Claude API called **only from a Supabase Edge Function** — the Anthropic API key lives in Supabase secrets, NEVER in the mobile app, never committed to git.
- **Push notifications:** Firebase Cloud Messaging (for maintenance reminders).
- State management: Riverpod. Local cache/offline: drift or sqflite (fields often have no signal — offline-first is mandatory; sync when connectivity returns).

## Security & compliance (non-negotiable)

- KVKK (Turkish data protection law): collect the minimum personal data; farmer name/phone/field locations are personal data — encrypt at rest, never log them, provide account deletion.
- Row Level Security on every table: an operator sees only their own aircraft/fleet; baibars admin role sees fleet-wide analytics.
- No secrets in the repo. `.env` files gitignored. API keys in Supabase secrets only.
- SHT-İHA requires operators to protect hardware/software systems against cyber threats — follow OWASP MASVS basics (no plaintext token storage, certificate pinning for baibars cloud endpoints, jailbreak/root detection warning).

---

## Domain model — CT110 reference data

CT110 key specs (from BAI_CT110_DataSheet_2026_V3.2 — treat as source of truth):

| Item | Value |
|---|---|
| MTOW | 95 kg |
| Empty weight (no battery / with battery) | 31.5 kg / 45 kg |
| Spray tank | 50 L |
| Spreader tank | 70 L (max 50 kg granular, 0.5–6 mm) |
| Pumps | 2 × 30 L/min dual-impeller |
| Nozzles | 4 × centrifugal, 9 L/min each, droplet 50–500 µm |
| Spray swath | 6–10 m |
| Spread swath | 8–12 m |
| Flight time (loaded / unloaded) | 10 min / 18 min |
| Operation cycle | 9–12 min |
| Battery | 34Ah 18S |
| Operating temp | 0–40 °C |
| Protection | IP67 |
| Dimensions open / folded | 3128×3146×880 mm / 1200×684×880 mm |

### Maintenance rules (seed data — intervals marked TBD must be confirmed by baibars engineering before release)

Rule engine must support THREE interval types: **per sortie count**, **per flight hours**, **per calendar days** — and combinations (whichever comes first).

| Check item (TR label) | Interval | Type |
|---|---|---|
| Kol katlama aparatı vidası tork kontrolü | every **100 sorties** | sortie |
| Motor tork ve montaj cıvatası kontrolü | every **100 flight hours** | hours |
| Motor montaj yönü kontrolü (3° içe eğim — cant) | every motor/mount replacement + 100 h | hours/event |
| Şasi profil çatlak muayenesi (görsel + fotoğraf) | every 50 sorties (TBD) | sortie |
| Pompa çarkı aşınma kontrolü | every 100 h (TBD) | hours |
| Nozül disk kontrolü / değişimi | every 50 h (TBD) | hours |
| Pervane hasar kontrolü | every 25 sorties (TBD) | sortie |
| Akış metre kalibrasyonu | every 6 months | calendar |
| İniş takımı cıvata kontrolü | every 100 sorties (TBD) | sortie |
| Batarya sağlık değerlendirmesi | every 50 cycles | cycles |

Each completed check requires: checklist tick-off, optional torque value entry, **at least one photo**, and the signing user. This creates the digital service logbook per aircraft (also serves as audit evidence for SHGM inspections).

### Maintenance kit (shipped with each CT110 — waterproof case)

Kit is serialized and paired to an aircraft. Inventory items:
- Alyan anahtar takımı (full hex key set)
- Akış metre (flow meter)
- Yedek pompa (spare pump)
- Yedek nozüller (spare nozzles)
- Yedek pervaneler (spare propellers)

When a spare is consumed during maintenance, stock decrements; when stock ≤ min level, app suggests reordering from baibars (deep link / request form — no prices shown in app v1).

### Flight parameter presets (seed examples — agronomy team must validate)

Preset fields: crop/tree, growth stage, application type (spray/spread), dose (L/da or kg/da), speed (m/s, max 10), altitude above canopy (m), swath (m), droplet size (µm). Cansu can explain and adjust presets but always shows "baibars validated" vs "AI suggestion" labels distinctly.

---

## SHT-İHA compliance module (SHGM, in force 30.07.2026)

- Store per aircraft: SHGM registration number, QR code image, registration status.
- Store per pilot/user: license level (**P0 / P1 / P2** under the new directive), license expiry, reminders before expiry.
- Every flight is logged automatically (date, duration, pilot, aircraft, approximate location) → exportable audit report (PDF) for inspections.
- Insurance (Üçüncü Şahıs Mali Mesuliyet) policy number + expiry tracking with reminders.
- **İHATTYS adapter:** the national UAV traffic system is announced but not yet live. Build an abstract `RegulatoryAdapter` interface now with a stub implementation; when İHATTYS opens its API, only the adapter is implemented — no app rewrite.
- Do NOT hardcode legal interpretations; compliance texts live in remote config so baibars can update them without app releases.

---

## Cansu — AI assistant (Claude API)

- Persona: "Cansu", baibars'ın dijital tarım asistanı. Warm, plain Turkish, farmer-friendly. Never invents maintenance intervals or doses — if data is not in the database, she says she'll check with baibars technical service (48-hour service commitment).
- Architecture: Flutter chat UI → Supabase Edge Function `cansu-chat` → Claude API (`claude-sonnet-4-6`, max_tokens ~1000). Conversation history stored per user (KVKK: user can delete history).
- Context injection: the Edge Function includes the user's aircraft model, open maintenance tasks, battery health summary, and relevant preset data in the system prompt so answers are personalized.
- Guardrails in the system prompt: no pesticide medical/toxicology advice beyond label instructions; no flight-rule interpretations that contradict SHT-İHA; escalate safety-critical questions to baibars technical service.
- NOTE FOR DEVELOPER: Cansu will later connect to the existing "Cansu" assistant in the Luron AI project. Keep the AI layer behind a single `AiService` interface so the backend endpoint can be swapped.

---

## Database schema (create as Supabase migrations)

Tables (all with `created_at`, `updated_at`, RLS):

- `organizations` (operator companies / individual farmers)
- `users` (auth-linked; role: operator, technician, baibars_admin; pilot_license_level, license_expiry)
- `aircraft` (serial_no, model='CT110', shgm_registration_no, qr_image_url, org_id, total_sorties, total_flight_hours)
- `components` (aircraft_id, type, serial_no, installed_at, removed_at)
- `flights` (aircraft_id, pilot_id, started_at, ended_at, duration_min, sortie_count_increment=1, area_covered_da, params jsonb, location_geohash)
- `maintenance_rules` (component_type, label_tr, label_en, interval_type[sortie|hours|calendar|cycles], interval_value, checklist jsonb, is_tbd bool)
- `maintenance_tasks` (aircraft_id, rule_id, due_basis, status[open|done|overdue], completed_by, completed_at, torque_values jsonb, photo_urls[])
- `kits` (serial_no, aircraft_id)
- `kit_items` (kit_id, name_tr, name_en, qty, min_qty)
- `kit_consumptions` (kit_item_id, maintenance_task_id, qty, at)
- `batteries` (serial_no, aircraft_id, capacity_ah=34, config='18S', cycle_count, health_pct, last_cell_deviation_mv)
- `battery_logs` (battery_id, cycle, voltage_data jsonb, at)
- `crop_presets` (crop, stage, application_type, dose, dose_unit, speed_ms, altitude_m, swath_m, droplet_um, validated_by_baibars bool)
- `compliance_documents` (org_id or aircraft_id, type[insurance|permit|registration], number, valid_until)
- `ai_conversations` / `ai_messages` (user_id, role, content, created_at)
- `operation_audit_log` (append-only, for SHGM export)

---

## Build phases (work through these in order; finish and demo each before starting the next)

**Phase 0 — Scaffold**: Flutter project, Supabase project link, CI-less local run, folder structure, i18n TR/EN, theme with baibars colors, app icon placeholder. Deliver: app runs on the developer's phone showing a login screen.

**Phase 1 — Registry & counters**: Auth (email+OTP), organization + aircraft CRUD, manual flight/sortie entry (start/stop timer + manual add), sortie & flight-hour counters visible on aircraft card. Offline-first from this phase onward.

**Phase 2 — Maintenance engine**: rules seed data (table above), automatic task generation when counters cross thresholds, checklist UI with photo capture and torque entry, service logbook timeline per aircraft, FCM push reminders.

**Phase 3 — Kit inventory**: kit pairing, item stock, consumption flow linked to maintenance tasks, low-stock reorder suggestion.

**Phase 4 — Battery health**: battery registry, cycle logging, health trend chart, degradation warnings.

**Phase 5 — Flight parameters**: preset library, filtering by crop, "start flight with these parameters" flow feeding the flight log.

**Phase 6 — Cansu**: Edge Function + chat UI + context injection + guardrails. Streaming responses if straightforward.

**Phase 7 — SHT-İHA module**: registration/license/insurance tracking, expiry reminders, audit report PDF export, `RegulatoryAdapter` stub for İHATTYS.

**Phase 8 — Telemetry (design only for now)**: define a `TelemetryIngest` interface for future flight-controller data sync (protocol not yet confirmed with the avionics supplier). Do not implement hardware integration yet — mock it.

## Working agreements

- Small commits with clear messages. Explain each architectural decision in one or two sentences before writing the code.
- After each phase, produce a short Turkish summary of what was built and how to test it on a phone.
- Never invent baibars-specific numbers (intervals, doses, prices). If a value is missing, add it as `TBD` and list it in `docs/OPEN_QUESTIONS.md`.
- All user-facing strings go through i18n files — no hardcoded UI text.
