# CoTeacher — MVP & PoC Plan (Teacher + Student Experience, **CV + GPS Only**)

*Version: v1 (CV/GPS rewrite — removes QR/barcodes entirely)*

This plan scopes a PoC and MVP centered on the **teacher** and **student** experiences using **Computer Vision (on-device)** and **GPS/geofencing** (no QR codes, no barcodes). It then breaks the work into small, achievable tasks. The **first tasks** include gathering tools, SDKs, and reference materials.

---

## 0) Scope, Assumptions, Non‑Goals

**Scope (this phase):**
- Teacher tablet app: Today View, **CV-based** Attendance/Lineup Scan, Rotations/Stations, Small‑Group Pane, Evidence Capture, Daily Debriefer.
- Student tablet app: Morning check‑in, station guidance, light practice (finger‑trace → stylus → keyboard), mood taps.
- Baseline **rule‑based** Insights for flags and differentiation suggestions.
- Parent daily digest (read‑only) to close the loop.
- Offline‑first operation with queued sync.
- **Location:** Campus arrival/departure via **GPS geofencing**; within‑class/line/recess location via **CV checkpoints** (e.g., door/circle/lineup scans).

**Assumptions:**
- 1–2 pilot classrooms (PreK–3) with school‑owned tablets meeting minimum spec (adequate CPU/NPU for on‑device inference).
- Explicit parent consent for **face templates** and CV-based recognition (with clear opt‑out and redaction policies).
- School network allows WebRTC and websockets; GPS usable at campus perimeter (acknowledging indoor limitations).

**Non‑Goals (now):**
- No QR/barcodes anywhere.
- No diagnostic ML (screeners only; explainable indicators).
- No full state reporting exports or financials.
- No public chains/NFTs for PII (use DID/VC + encrypted vault later).

---

## 1) Outcomes & Success Metrics

**PoC (4–6 weeks):**
- **Attendance (CV only):** Teacher completes attendance for 20–25 students in ≤120s with **≥97% precision/recall** across typical classroom lighting/angles.
- **Lineup & Recess (CV + GPS):** Name‑to‑face lineup verification and return‑scan achieve **≥98% match rate**; campus **GPS geofence** reliably toggles *On Campus* / *Off Campus* states within **≤30s** of boundary crossing.
- **Rotation Cycle:** One full rotation runs with student tablets receiving destinations and timers; **≥90%** arrive at stations in ≤60s.
- **Evidence Capture → Suggestion:** Teacher can accept/retag a suggestion in **≤2 taps** 80% of time.
- **Offline test:** 30 minutes without Wi‑Fi; all data syncs with no loss once reconnected.

**MVP (next 8–12 weeks):**
- + Expanded **rule‑based insights** (participation, handwriting hints, pacing prompts).
- + Parent daily digest (attendance, top 3 moments, optional enrichment suggestion).
- + IEP/504 accommodation reminder shows **at point of use** (read‑only from SIS).
- + Custody/Dismissal hub (basic) with **CV lineup checks** and **GPS‑based** custody closure at pickup perimeter.

---

## 2) Architecture Slice for PoC/MVP (CV + GPS Only)

- **Edge‑first CV:** On‑device face detection/embedding + person re‑identification (re‑ID) for robust angles; store **face templates locally** with encryption; upload only derived confirmations unless parent saves artifacts.
- **GPS:** Device geofencing for campus perimeter, pickup loop, and playground areas (outdoor). Indoors, rely on **CV checkpoints** (doorway/circle/line markers) instead of beacons/QR.
- **Minimal services:** Auth, Roster/SIS adapter, Attendance & Location, Rotations, Evidence & Media (redaction + retention), Insights (rules), Messaging (digest), Realtime, API Gateway/BFF.
- **Data stores:** PostgreSQL, Object Storage, Redis, Event Bus (or Redis streams initially), Search (optional later).

---

## 3) Tools, SDKs, Datasets (gather early)

- **On‑device CV:** MediaPipe (Face Detection, Face Landmarks), TFLite or ONNX Runtime Mobile for face embedding & re‑ID; OpenCV (pre/post‑proc).

- **Face/Person Models:** MobileFaceNet/FaceNet variants (distilled), person re‑ID (lightweight, e.g., OSNet‑x0.25 adapted to mobile).

- **Handwriting/shape assist:** classical contour features + shallow CNN for letter formation v1;

- **Food plate (MVP+):** semantic/instance segmentation distilled to mobile (later).

- **GPS/Geofencing:** Android FusedLocationProvider + iOS CoreLocation with region monitoring (school‑defined polygons).

- **SIS interop:** 1EdTech OneRoster sample CSV + schema docs.

- **MLOps:** MLflow (exp/registry), Label Studio (masking & annotation), Weights & Biases (optional).

- **Infra:** Kubernetes or serverless containers; Postgres; S3‑compatible object store; Redis; GitHub Actions.

- **Design:** Figma with accessibility tokens; Mermaid for flows.


**First tasks include pulling official docs for:** MediaPipe, TFLite/ONNX Runtime, OpenCV, Android/iOS geofencing, and OneRoster.

---

## 4) CV Enrollment & Privacy Enablers (Pre‑PoC)

- **Consent flow:** Parent signs digital consent for CV attendance with clear purposes, retention, and opt‑out.

- **Template capture:** Collect **3–5 reference poses per student** (front, slight left/right, with classroom lighting) on teacher’s tablet; encrypt at rest.

- **Redaction policy:** Save **no raw faces** by default; keep only match events and confidence scores. Artifacts saved to parent vault only if parent opts in.

- **Confidence thresholds:** Require threshold (e.g., 0.8+) **and** temporal consistency (≥2 frames) to mark present; otherwise prompt teacher confirm.


---

## 5) Work Breakdown — PoC (Weeks 1–6)

### Week 1 — Foundations & Tooling
- [ ] T-001 Mono‑repo scaffolding (apps: teacher, student; services; infra).

- [ ] T-002 CI/CD pipelines (lint/test/build), signed builds.

- [ ] T-003 Provision Postgres, object storage, Redis; seed test school & class.

- [ ] T-004 Auth (OIDC) with roles/tenants; import **OneRoster sample**.

- [ ] T-005 Pull docs & SDKs: MediaPipe, TFLite/ONNX, OpenCV, CoreLocation/FusedLocation, OneRoster.


**AC:** Authenticated apps list classes/students from seed; GPS geofence placeholder defined (campus polygon).

### Week 2 — CV Enrollment & Today View
- [ ] T-101 Teacher Today View skeleton (agenda, timers, flags, tasks).

- [ ] CV-101 Student face template capture (3–5 poses), encrypted local storage; consent logging.

- [ ] CV-102 Face detection → embedding pipeline (on‑device); match API (local).


**AC:** 95%+ of enrolled students produce stable embeddings; consent captured and auditable.

### Week 3 — Attendance Scan (CV only) & GPS Geofence
- [ ] CV-201 Live camera scan across room/circle; multi‑face track & match with temporal smoothing.

- [ ] LOC-201 Geofencing: *On Campus* state when crossing boundary; pickup loop region defined.

- [ ] T-102 Reconciliation panel for late/sick notes; manual override UI.


**AC:** Attendance for 20–25 students in ≤120s; ≥97% precision/recall under normal lighting/angles; *On Campus* toggles within ≤30s of entry/exit.

### Week 4 — Rotations & Stations (CV checkpoints for line/door)
- [ ] T-201 Rotations panel (suggested groups, Start Rotation, timers).

- [ ] S-201 Student destination screen with countdown + arrival tap.

- [ ] CV-202 Door/line marker recognition to register transitions (visual markers, not codes; CV features on distinct patterns/shapes/colors).

- [ ] GAM-201 Achievement pings for timely arrival.


**AC:** ≥90% of students arrive at stations in ≤60s with CV door/line confirmations logged.

### Week 5 — Evidence Capture → Suggestion
- [ ] T-301 Evidence capture: photo + voice note; media pipeline writes, redacts faces by default.

- [ ] IN-301 Rules engine v1 (YAML) for prompts (participation, handwriting hints).

- [ ] T-302 Suggestion accept/retag in ≤2 taps.


**AC:** 80% of suggestions processed in ≤2 taps during pilot.

### Week 6 — Debriefer, Offline, and Pilot Hardening
- [ ] T-401 Daily Debriefer (wins/issues, milestones, tomorrow prep).

- [ ] OFF-101 Offline soak test (30 min), conflict resolution, retry queue.

- [ ] SEC-101 Threat model; confirm no raw face uploads by default; audit trails.


**AC:** End‑of‑day workflow completes in ≤3 minutes; zero data loss in offline test.

---

## 6) Work Breakdown — MVP (Weeks 7–18)

### Weeks 7–9 — Insights & IEP Surface
- [ ] IN-401 Expand rule sets (reading/math/behavior prompts).

- [ ] T-501 Point‑of‑use accommodation reminders from SIS (read‑only).

- [ ] T-502 Small‑group pane checklists and mini‑rubrics.


**AC:** 10 high‑confidence strategies mapped to standards; >70% perceived helpfulness (teacher survey).

### Weeks 10–12 — Custody & Dismissal (CV + GPS)
- [ ] CUST-101 Lineup and exit scans via CV (doorway/line markers + face match).

- [ ] CUST-102 GPS pickup loop confirmation to close custody; chaperone confirm on teacher/admin tablet.

- [ ] S-301 Practice modules (finger trace → stylus → keyboard).


**AC:** No missed student during recess/carpool in pilot logs; pickup custody closed via GPS confirm; >90% students complete practice step.

### Weeks 13–15 — Community Seed & Content Repo v1
- [ ] COM-101 Bright Ideas (curated list from lessons repo).

- [ ] LES-101 Lesson repo (versioning, remix provenance) minimal.


**AC:** Teachers can favorite and insert one idea into a unit with supply list auto‑gen.

### Weeks 16–18 — Nutrition v1 (Parent Photo) + Hardening
- [ ] NUT-101 Parent breakfast/dinner photo parse; allergens; basic nutrition card.

- [ ] PRIV-201 Ephemeral media deletion job; audit trail.

- [ ] QA-201 Accessibility pass; localization; performance.


**AC:** Nutrition card accuracy acceptable in >80% cases with human confirm.

---

## 7) Risks & Mitigations (CV + GPS Only)

- **Indoor GPS unreliability:** Use GPS for **perimeter/pickup** only; inside buildings, rely on **CV checkpoints** (door/line/circle scans) and timestamps.

- **CV identity errors:** Require confidence thresholds + temporal consistency + teacher confirm UI; allow quick override.

- **Lighting/angles/occlusion:** UI guidance for scan posture; request 3–5 pose templates; prompt extra scan on low confidence.

- **Privacy:** Default to no raw face uploads; encrypt local templates; clear consent + opt-out.

- **Device performance:** Minimum spec with NPU/GPU acceleration; frame‑rate throttling and progressive models.


---

## 8) Deliverables & Review Gates

- **Design:** wireframes for Today View, Attendance (CV), Rotations, Small‑group, Debriefer; student destination.

- **Tech:** running PoC in test classroom; observability dashboards; privacy review report.

- **Review Gates:** end of Week 3 (CV attendance demo), Week 6 (PoC sign‑off), Week 12 (custody demo), Week 18 (MVP demo).


---

## 9) Backlog Seeds (Next Wave)

- Person re‑ID improvements; plate segmentation (on‑device); Digital Twin Bridge (DID/VC); screening referrals; Live lunch WebRTC; Coverage & Ratios; Dismissal bus aide mode.