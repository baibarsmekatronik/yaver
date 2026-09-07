# baibars Fleet Platform — Roadmap v1.0
**Decision: FleetCare and the VK tracking dashboard merge into a single product.**
One backend, one database, two clients (web dashboard + mobile app). Prepared for Kerem & Joseph — 07.09.2026.

---

## Architecture (target)

```
VK Open API (China)
      │  HMAC-signed polling (Joseph's .NET service — kept as-is)
      ▼
vk-collector (.NET worker, hosted in Türkiye)
      │  writes
      ▼
PostgreSQL  ←— location-portable by design (see note)
      │
      ├── React web dashboard  (live map, fleet, history, maintenance)
      ├── Flutter mobile app   (existing FleetCare client)
      └── İHATTYS feed adapter (stub now, implemented when SHGM publishes the spec)
```

**Database portability note:** Supabase is managed PostgreSQL and is self-hostable. We design one Postgres schema now; whether it runs on the current Supabase project or a self-hosted instance in Türkiye is a **deploy-time decision**, taken once the regulation is clarified. No code depends on the answer. Development starts today.

---

## Phases

**Phase 0 — Persistence (start now, regulation-agnostic)**
- Convert the demo backend into a background worker (IHostedService): fleet poll every 5 s; telemetry poll only for airborne units (`flying=1`), adaptive interval within the 100 req/min quota.
- Schema: `drones`, `telemetry` (time-series, 90 d raw → downsample), `sorties`, `airframe_totals`, `maintenance_rules`, `maintenance_events`, `audit_log`.
- Sortie close-out: on `flying` 1→0, record max device-reported `ftime` (never wall clock — survives connectivity gaps). Nightly reconciliation against VK history endpoint if VK provides one.

**Phase 1 — Dashboard on our own DB**
- UI reads our DB, not VK → unlimited concurrent users, quota-independent.
- Total flight hours, total sorties, total treated area per airframe.
- Unit conversion at display layer: mu → dekar (×0.6667) default, hectare selectable.
- Flight history & playback from stored telemetry.

**Phase 2 — Maintenance (merged with FleetCare model)**
- Rules engine: component + threshold + counter type (flight hours / sorties / errorCode trigger).
- Counters fed from `airframe_totals`; threshold breach → `maintenance_events` + alert; work-order close resets the component counter.
- Align data model with the existing FleetCare Phase 1–8 spec so mobile and web share entities.

**Phase 3 — Government access (blocked on regulation)**
- Most likely model: data feed into İHATTYS (SHGM-operated central platform; integration spec not yet published; compliance transition runs to 31.07.2027).
- Design now: `gov_readonly` role, operator-ID pseudonymization (KVKK), audit logging of every external access. Implement the adapter when the spec lands.

---

## Open items

**Regulatory (owner: Charles)**
1. Does SHT-İHA require the tracking data/platform to be hosted in Türkiye, or only that İHATTYS receives the feed? → determines DB location.
2. İHATTYS integration spec: data fields, protocol, frequency, onboarding process for manufacturers.

**VK / Sans Lee**
3. Historical / sortie query endpoint (API access to the 3-year retention)?
4. Batch telemetry endpoint or quota increase for production (100 req/min caps live tracking at ~1 airborne unit at 1 Hz).
5. `errorCode` value table (needed as maintenance triggers) and `posAccur` unit.
6. Production credential issuance + IP allowlist procedure (we will supply the Türkiye server IP).

**Engineering (Kerem & Joseph)**
7. Hosting proposal for collector + DB in Türkiye (provider, cost, ops).
8. Retention/downsampling policy sizing at fleet scale.
9. Auth approach for the merged product (Supabase Auth vs. standalone), roles: `admin`, `ops`, `gov_readonly`.

---

## Design rules (fixed)
- AppKey never leaves the backend; single signer, single nonce source, single rate-limit budget (as in the demo).
- Device-reported `ftime` is the source of truth for flight hours.
- No raw operator identity in any external-facing view (KVKK).
- Every schema decision must run unchanged on managed Supabase **and** self-hosted Postgres in Türkiye.

---

# Addendum v1.1 — Decisions of 07.09.2026

## Locked decisions
1. **Commercial model: customer subscription product.** Customers (farmers / co-ops) see their own fleet: live tracking, flight hours, treated area, maintenance status. This is a revenue line, not only a compliance cost.
2. **Scope: CT110 first.** Other CT-series models join after v1; schema is model-aware already (`drones.model`, `maintenance_rules.model`).
3. **No telemetry abstraction for now.** Collector stays VK-coupled — accepted tech debt. Revisit trigger: the day PX4 pilot hardware exists.

## What decision 1 changes
- `tenant_id` activates in Phase 1: every sold drone is assigned to a customer account at delivery; a customer sees only their own drones. baibars ops role sees all.
- Auth: Supabase Auth is the natural fit (the merged FleetCare product already lives on Supabase) — customer accounts, role claims (`customer`, `ops`, `admin`, later `gov_readonly`).
- KVKK: customer onboarding needs consent flow; operator IDs stay pseudonymized outside ops.
- Customer-facing UI language: plain, farmer-friendly Turkish ("drone" is fine in customer-facing text).
- **New legal item for the Wenqing/commercial track: written permission for commercial redistribution of platform data to end customers as a paid service.** Distinct from the white-label/custom-frontend permissions already requested.
- **SLA chain: we cannot promise customers more uptime than VK gives us.** VK's written SLA moves from nice-to-have to commercial prerequisite.
- Pricing/packaging: management decision — out of engineering scope, flagged only as a dependency for launch.

## Next actions
| Owner | Action |
|---|---|
| Joseph | Integrate Phase 0 package (Npgsql, schema, worker) against sandbox; run the three test scenarios in PHASE0-README |
| Kerem | Local Postgres + dev environment; start Phase 1 dashboard reading our DB (tenant-scoped queries from day one) |
| Charles | Add commercial-redistribution + SLA items to the Wenqing/commercial thread; push SHT-İHA hosting question |
| Sans Lee (ask) | History endpoint, batch telemetry / production quota, errorCode table, production credentials + IP allowlist |
