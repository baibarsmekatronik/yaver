# baibars Fleet Platform — Roadmap v1.2 (Reconciliation)
**Purpose:** merge the two research tracks (Claude Advanced Research spec + ChatGPT deep-research report, both 07.09.2026) into one set of binding decisions for Joseph & Kerem. Where the two disagreed, the resolution and reason are recorded here. UI/menu structure, maintenance interval table and component inventory remain as in the Claude spec; this document changes the data layer, sortie semantics, tenancy, and the regulatory plan.

---

## 1. Decision updates

| # | Was (v1.1) | Now (v1.2) | Why |
|---|-----------|------------|-----|
| D1 | "No telemetry abstraction — stay VK-coupled" | **Thin canonical contract** between collector and DB. Not a multi-vendor abstraction layer: a naming/units/NULL/quality translation so `ftime`, `posAccur` etc. never leak past the normalizer. | Costs 4–6 pd; prevents full-product rewrite if VK changes field semantics or PX4 arrives. Preserves the spirit of the original decision (VK-first, no speculative engineering). |
| D2 | Flight hours = max device `ftime`, stale close + reconciled flag | Keep max-`ftime` as the measure, add **sortie completeness** (`provisional / confirmed / interrupted / reconciled`) and **dual airframe totals**: `flight_seconds_confirmed` + `flight_seconds_min_known`. Maintenance engine must alert on low-confidence counters, never silently under-count. | Connectivity loss before landing makes max ftime an *undercount*; a maintenance system must not quietly extend service intervals. |
| D3 | `drones.tenant_id` single column | **`aircraft_assignment` history table** (aircraft × tenant × valid_from/valid_to). Lifetime hours travel with the airframe; the previous owner's field/application records do not transfer. `drones.tenant_id` becomes a derived convenience of the *current* assignment. | Subscription product ⇒ second-hand sales, demo units, loaners, dealer stock are certainties, not edge cases. |
| D4 | "DB location is a pure deploy-time decision" | Schema stays portable (still true), but **managed-Supabase → self-hosted migration is real operational work**: JWT secrets, Auth tokens (users re-authenticate), storage, edge functions move separately. A **migration rehearsal** is now a production gate. | Supabase's own restore-from-platform documentation. |
| D5 | "Start İHATTYS work when SHGM publishes the spec" | **Start now.** SHGM's manufacturer integration application is already open (integration test form, undertaking/declaration, application/control forms published); conversion deadline for pre-directive aircraft is **31.07.2027**. | Passive waiting risks the deadline and the US-launch-adjacent credibility. |
| D6 | Maintenance: work-order close resets counter | **Reset semantics by action type:** `INSPECTED` resets the inspection interval baseline only; `REPLACED` closes the old `component_instance`, creates a new one at 0 h; `REPAIRED` resets only if the rule says so. Airframe lifetime never resets. Rules are **versioned** (`rule_version`, `effective_from`). | Otherwise closing a work order turns an 800-hour motor into a 0-hour motor. |

**Unchanged:** CT110-first; customer subscription product; merged FleetCare + dashboard; collector in Türkiye; PostgreSQL; React web + Flutter mobile; farmer UI = max five status concepts (state, battery, RTK, payload/spray, freshness); mu→dekar at display layer; KVKK pseudonymization; maintenance interval table (Claude spec) as seed data for `maintenance_rules` — flagged as *baibars-ratified defaults, not vendor instructions, not hard-coded*.

**Hard architecture boundary (new, regulatory):** the farmer platform **never sends flight commands**. Monitoring, history, maintenance, reporting only. The SHGM compliance module (Madde 23: envelope reduction, route change, landing, flight termination via İHATTYS) is a separate, certifiable control-station work package — outside this product.

---

## 2. Canonical telemetry contract (mini-spec)

- Normalizer sits between collector and DB. Upstream names stop there. Canonical names: `position.lat_deg/lon_deg`, `position.height_agl_m`, `battery.soc_pct/voltage_v`, `navigation.rtk_status (none|searching|float|fixed|unknown)`, `spray.active/flow_l_min/applied_volume_l`, `payload.liquid_remaining_l`, `flight.state (ground|takeoff|airborne|working|landing|unknown)`, `sortie.elapsed_device_s`, `health.source_error_codes[]`, `time.observed_at/received_at`.
- **NULL is a normal value.** Missing ≠ false, unknown temperature ≠ 0. No fake defaults, ever.
- **Altitude rule:** until VK confirms the datum, store `raw_altitude` + `raw_altitude_reference:"unknown"`; never populate `altitude_msl_m` by assumption. Same principle for `posAccur` until the unit is confirmed.
- Every sample carries quality metadata: `{source:"vk", schema_version, normalizer_version, observed_at, received_at, quality:{freshness, completeness, reconciled}}`.
- Raw upstream payload archived immutably (JSONB, access-restricted, 90-day hot retention) so semantics disputes are re-processable (`normalizer_version` enables replay).
- **Freshness display states** (product thresholds, calibrate after production measurement): 0–3 s *Canlı*, 3–15 s *Gecikiyor*, 15–60 s *Veri eski*, >60 s *Bağlantı yok*. A stale point is never shown as live; map popup says "Son bilinen konum — 41 sn önce."

## 3. Sortie ledger state machine

```
GROUNDED → (takeoff evidence) → OPEN
OPEN → (telemetry loss > stale window) → INTERRUPTED
OPEN → (landing evidence) → CLOSING → (3 stable grounded samples) → CONFIRMED
INTERRUPTED → (history/backfill) → RECONCILED
```
- Telemetry loss alone never means "landed." `last_seen + 60 s ≠ ground`.
- Reported "ilaçlandı" area derives only from `spray.active=true` segments or vendor-confirmed application state; telemetry gaps render as dashed gaps in playback, never interpolated as sprayed.
- Nightly reconciliation job consumes VK history endpoint (if granted — open item) to promote INTERRUPTED → RECONCILED. No backfill ⇒ the gap stays visibly incomplete forever; we never fabricate telemetry.

## 4. Schema patch
See `002_v1_2_patch.sql` (companion file): sortie completeness, dual airframe totals, `aircraft_assignment`, `component_instance`, versioned maintenance rules with `valid_reset_actions`, raw payload archive columns.

## 5. Regulatory actions (owner: Charles)

1. **Start the SHGM manufacturer integration application now** (forms already published: integration test, undertaking/declaration, application/control). Confirm current status of İHATTYS go-live.
2. **Get written SHGM confirmation** on whether Türkiye hosting of the tracking DB is mandated — neither research track found an explicit clause; do not assume either way.
3. Confirm CT110's class mapping (M-class / P0–P2 operation mapping) with SHGM; do not assume "every farmer flight is P2."
4. 31.07.2027: conversion deadline for pre-directive aircraft (registration, remote ID, geofence, compliance module, software certification, İHATTYS). Aircraft acquired after the directive: obligations start at acquisition — the 2027 date is not a grace period for new sales.
5. KVKK: per the Board's 18.02.2026 decision (2026/347), aydınlatma and açık rıza are separate; define the lawful basis per processing purpose — a single onboarding checkbox is not compliance. Cross-border transfer analysis required for any personal-data-linked telemetry reaching the Chinese upstream.

## 6. Production gates (all four must pass)

| Gate | Done means |
|---|---|
| **Data Core** | Collector runs with no dashboard open; restart produces zero duplicate sorties |
| **Trust** | Connectivity gaps never fabricate flights or landings; stale/live rendering correct; raw→normalized traceable |
| **Security** | Cross-tenant API/report/realtime/export attacks all fail closed (test with Customer B's known UUIDs, not just the UI) |
| **Production** | Production credentials + quota contract + real CT110 E2E + history/backfill verified + backup-restore rehearsal passed |

Sprint 1 deliverable (verbatim goal): *"We reliably collect the CT110 fleet with no dashboard open; we know every sample's source and age; we invent nothing during outages; and we have one global upstream quota budget."*

## 7. Effort & sequencing
ChatGPT estimate adopted as planning baseline: **72–107 person-days** backend scope (canonical contract 4–6, collector hardening 8–12, persistence 6–9, sortie ledger 6–9, auth+RLS 6–9, farmer API 6–9, live dashboard 7–10, history+reports 6–9, maintenance 7–10, offline sync 5–8, monitoring/security 5–7, migration/acceptance 6–9). Joseph solo ≈ 15–22 weeks; Kerem taking the React/UI track in parallel compresses calendar, not person-days. Vendor wait time excluded — which is why the VK asks (batch/quota, history endpoint, field dictionary with units/enums/error codes, timestamp semantics, altitude datum) must go out **this week**.

## 8. Updated VK onboarding pack (per-field, not just sample JSON)
For every field: unit, range, nullability, update rate, timestamp semantics, datum/reference, enum table, error-code dictionary, retention/backfill, quota, batch support, versioning/deprecation policy. Plus production endpoint, credentials, IP allowlist, written SLA, and commercial-redistribution permission (already on the Wenqing track).
