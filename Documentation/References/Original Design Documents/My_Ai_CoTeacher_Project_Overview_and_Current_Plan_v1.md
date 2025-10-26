# My AI CoTeacher — Project Overview & Current Plan (v1)

**Folder:** `C:\Users\kidsg\Desktop\My AI CoTeacher`  
**Audience:** founders, early engineers, school pilot partners  
**Focus:** Teacher & Student experience (Parent/Admin in scope for visibility & custody)

---

## 1) What We’re Building (Problem → Vision → Outcomes)

### The Problem
Early education teachers juggle instruction, assessment, documentation, ratios/coverage, parent comms, and logistics—often *during* instruction. Parents lack timely, trustworthy insight and control over their child’s data.

### The Vision
**My CoTeacher** is a calm, on‑device‑first assistant that handles *everything but the human interaction*. It observes, organizes, and nudges so teachers can focus on kids. Parents get transparency and control; admins get operational calm.

### Core Outcomes
- **Teacher attention back to kids** (10‑second interactions, batch the rest).
- **Evidence captured once → reused everywhere** (standards, milestones, meetings).
- **Safe, explainable AI** (on-device CV, consent, clear “why” for each suggestion).
- **Parent‑controlled data** (future integration: DID/VC + encrypted vault; scoped, revocable access).

---

## 2) User Scope (MVP/PoC)

- **Teacher (primary):** Today View, CV Attendance/Lineup, Rotations, Small‑Group pane, Evidence capture, Debriefer, point‑of‑use accommodations.
- **Student:** Morning check‑in, station guidance, practice (finger‑trace → stylus → keyboard), mood taps.
- **Parent (read‑only for MVP):** Daily digest (attendance, top moments, enrichment suggestion); pickup custody confirmation.
- **Admin (light):** Dismissal/Custody dashboard, coverage notifications (later).

Reference user stories in the project canvas: `User_story_teacher_1/2.md`, `User_story_parent_1.md`, `User_story_Admin_1.md`.

---

## 3) Operating Principles

- **CV + GPS only** for PoC/MVP (no QR/barcodes).  
- **Offline‑first** classroom UX; sync on reconnect.  
- **Privacy by design:** no raw faces stored by default; explain‑why for each flag; opt‑in media to parents; explicit consent for CV.  
- **Low cognitive load:** 10‑sec actions, silent‑mode during instruction, batch later.  
- **Interoperable:** OneRoster import; clear exports; later Digital Twin bridge.

---

## 4) Architecture Slice (PoC/MVP)

**Clients**
- Teacher Tablet (Flutter), Student Tablet (Flutter), Parent Mobile + Web (Flutter web or React), Admin Web (Next.js minimal).

**Edge / On‑Device AI**
- Face detection + embeddings + **re‑identification** (temporal smoothing), handwriting/shape assists, visual checkpoints (door/line/circle markers), food plate (later).

**Location**
- GPS geofences for campus perimeter & pickup loop. Indoors → CV checkpoints.

**Services (minimal set)**
- API Gateway/BFF, Auth (OIDC + RBAC/ABAC), Roster/SIS Adapter (OneRoster), Attendance & Location, Rotations/Timers, Evidence & Media (redaction + retention policy), Insights (rule‑based with explain‑why), Messaging (daily digest), Realtime (WebSockets).

**Data Plane**
- PostgreSQL (core entities), Object storage (media + redacted derivatives), Redis (cache/queues), Event bus (Redis Streams now; Kafka/NATS later).

**MLOps**
- MLflow registry/experiments, Label Studio (annotation), on‑device packaging (TFLite/ONNX RT Mobile), monitoring (Evidently later).

Diagrams in repo:
- `CoTeacher_System_Diagram_v1_CV_GPS.md` (Mermaid).

---

## 5) PoC & MVP Definition

### PoC (4–6 weeks)
- **CV Attendance:** 20–25 students, ≤120s, ≥97% precision/recall in typical classroom lighting/angles.
- **Lineup/Recess:** CV name‑to‑face and return‑scan ≥98% match; GPS geofence toggles campus state within ≤30s of boundary crossing.
- **Rotations:** Students receive destinations + timers; ≥90% arrive ≤60s.
- **Evidence → Suggestion:** 80% accepted/retagged in ≤2 taps.
- **Offline:** 30 minutes offline without data loss; successful sync later.

### MVP (next 8–12 weeks)
- Rule‑based insights expanded (reading/math/behavior prompts).
- IEP/504 accommodations surfaced at point‑of‑use (read‑only from SIS).
- Parent daily digest (attendance, top 3 moments, enrichment).
- Custody/Dismissal hub: CV lineup + GPS pickup closure.

---

## 6) Work Plan (Tasks & Acceptance Criteria)

### Week 1 — Foundations & Tooling
- Mono‑repo, CI/CD, signed builds.
- Dev infra: Postgres, object store, Redis; seed school/class.
- Auth (OIDC), roles/tenants; OneRoster sample import.
- **Gather references**: MediaPipe, TFLite/ONNX RT Mobile, OpenCV, CoreLocation & FusedLocation, OneRoster schema.

**AC:** Authenticated apps list classes/students; campus geofence polygon defined.

### Week 2 — CV Enrollment & Today View
- Teacher Today skeleton (agenda, timers, flags, tasks).
- Student face template capture (3–5 poses); encrypted at rest; consent audit.
- On‑device pipeline: detect → embed → match (temporal smoothing).

**AC:** 95%+ enrolled with stable embeddings; consent recorded.

### Week 3 — Attendance (CV Only) & GPS
- Live scan across room/circle; multi‑face tracking; confidence + temporal consistency; quick confirm UI.
- GPS geofence: On‑Campus / Off‑Campus transitions & pickup loop region.
- Late/sick reconciliation UI.

**AC:** Attendance ≤120s; ≥97% P/R; GPS toggles within ≤30s boundary crossing.

### Week 4 — Rotations & CV Checkpoints
- Rotations panel; Start; timers; conflicts (accommodations).
- Student destination screen with countdown + arrival tap.
- Visual checkpoint recognition at doors/lines (distinct markers, not codes).

**AC:** ≥90% arrive ≤60s; transitions logged via CV checkpoint events.

### Week 5 — Evidence → Suggestion
- Photo + voice note capture; redaction pipeline; retention policy (ephemeral unless parent saves).
- Rules engine v1 (participation prompts, handwriting hints); explain‑why panel.
- Accept/retag ≤2 taps.

**AC:** 80% processed ≤2 taps; teachers rate usefulness ≥70% in pilot survey.

### Week 6 — Debriefer, Offline, Hardening
- Debriefer (wins/issues, milestones, tomorrow prep).
- Offline soak, conflict resolution, retry queue.
- Threat model; verify no raw face uploads by default; audit trails.

**AC:** End‑of‑day ≤3 minutes; zero data loss in offline test.

### Weeks 7–18 — MVP Extensions
- Weeks 7–9: Expand rule sets; point‑of‑use accommodations; small‑group checklists.
- Weeks 10–12: Custody (CV lineup + GPS pickup); student practice modules.
- Weeks 13–15: Bright Ideas; lesson repo v1 (versioning, remix provenance).
- Weeks 16–18: Nutrition v1 (parent breakfast/dinner photo parse); accessibility pass; localization; performance hardening.

---

## 7) Roles & Responsibilities (early team)

- **Mobile Lead (Flutter):** teacher/student apps, camera pipelines, offline cache.
- **CV/Edge AI Engineer:** embeddings, re‑ID, checkpoints, perf on NPU/GPU.
- **Backend Engineer (FastAPI or Node):** BFF, services, DB schemas, events, messaging.
- **Data/ML Engineer:** labeling, rules engine, on‑device packaging, metrics.
- **Design/Research:** low‑fi wireframes, accessibility, teacher cognitive load tests.
- **PM/Founder:** pilot logistics, consent artifacts, SIS export coordination.

---

## 8) Risks & Mitigations

- **Indoor GPS limits:** perimeter/pickup only; CV checkpoints indoors.
- **Lighting/occlusion:** UI guidance for scan posture; multi‑pose templates; low‑confidence prompts.
- **Privacy:** default redact; encrypted templates; explicit consent flows; role‑based redaction; audit logs.
- **Perf variance:** minimum tablet spec with NPU/GPU; frame‑rate throttling; progressive models.
- **Teacher overload:** batch notifications; silent mode; strict 10‑sec interaction budget.

---

## 9) Success Metrics (Pilot)

- Attendance accuracy (P/R), time‑to‑complete, confirm actions per day.
- Rotation punctuality; suggestion acceptance rate; perceived helpfulness.
- Offline resilience; zero missed custody during recess/pickup.
- Teacher time on screen vs with kids (self‑report + spot observations).

---

## 10) Repo & Standards

```
/apps
  /teacher_app (Flutter)
  /student_app (Flutter)
  /parent_web (Flutter web or React)
  /admin_web (Next.js minimal)
/services
  /gateway_bff (FastAPI or Node/Express)
  /auth
  /roster
  /attendance_location
  /rotations
  /evidence_media
  /insights_rules
  /messaging_digest
/infra
  /terraform
  /k8s
/docs
  CoTeacher_System_Diagram_v1_CV_GPS.md
  CoTeacher_MVP_PoC_Plan_Teacher_Student_v1_CV_GPS.md
```

**Code standards:** typed APIs (OpenAPI), unit/integration tests, linters/formatters, commit hooks, build signing, SAST/DAST in CI.

---

## 11) References to Gather (first sprint)

- MediaPipe (face detection/landmarks), ONNX Runtime Mobile / TFLite docs, OpenCV pre/post examples.  
- Android FusedLocation / iOS CoreLocation geofencing guides.  
- 1EdTech OneRoster CSV + REST schemas.  
- FERPA/COPPA best‑practice summaries for consent/retention.

---

## 12) Next Steps

1) Kick off Week 1 tasks; load OneRoster sample; define geofence; consent UX draft.  
2) Lock minimum device spec list; procure pilot tablets.  
3) Schedule teacher interviews for scan posture and cognitive‑load validation.  
4) Draft pilot evaluation rubric and observer checklist.

---

# APPENDIX — “Perfect Prompt” for Sonnet 4.5 in Cursor (to build PoC/MVP)

> Paste this into Cursor with your repo open. Adjust paths as needed.

```
You are Sonnet 4.5 acting as a **principal engineer** for “My AI CoTeacher.”
Goal: deliver a PoC (4–6 weeks) and MVP (next 8–12) focused on **Teacher + Student** experiences, using **Computer Vision + GPS only** (no QR/barcodes), offline-first, privacy-by-design.

## Constraints & Principles
- On-device CV for attendance/lineup; GPS geofences for campus & pickup; CV checkpoints indoors (door/line/circle markers).
- Default **no raw face uploads**; store local encrypted templates; only derived events leave device unless parent saves.
- 10‑second interaction rule; silent mode during instruction.
- Explain-Why on every suggestion; rule-based insights v1.
- Interop: OneRoster import for roster data.

## Tech Targets
- Mobile apps: **Flutter** (teacher_app, student_app). Camera pipelines + offline cache.
- Admin web minimal: **Next.js** (dismissal dashboard later).
- Backend: **FastAPI** (Python) gateway/BFF + services; **PostgreSQL**; **Redis** (cache/queues); **object storage**; **WebSockets** (FastAPI/Socket.IO).
- CV runtimes: **MediaPipe + ONNX Runtime Mobile** (or TFLite) + **OpenCV** pre/post.
- Location: **CoreLocation** (iOS) + **FusedLocationProvider** (Android) geofences.

## Deliverables (create now unless file exists)
1. Mono-repo scaffold:
   - /apps/teacher_app (Flutter)
   - /apps/student_app (Flutter)
   - /services/gateway_bff (FastAPI)
   - /services/attendance_location
   - /services/rotations
   - /services/evidence_media
   - /services/insights_rules
   - /services/messaging_digest
   - /infra/{terraform,k8s}
   - /docs/ (include system diagram + plan)
2. Define **OpenAPI** for core endpoints: auth, roster, attendance, rotations, evidence, insights, messaging.
3. Implement PoC flows:
   - Teacher Today View skeleton with timers & Attendance Scan CTA.
   - On-device CV pipeline: detect→embed→re-ID with temporal smoothing; local encrypted store for face templates.
   - Attendance POST writes event {student_id, confidence, time}; unresolved → confirm UI.
   - Rotations service + student destination screens; timers + arrival pings.
   - Evidence capture upload → redaction worker → store redacted derivative.
   - Nightly parent digest (attendance + top 3 artifacts + enrichment suggestion).
4. Offline-first data layer (queue + conflict resolution), telemetry logging, feature flags.
5. **Consent UX** and audit logging for CV enrollment (3–5 poses per student).

## Acceptance Criteria (PoC)
- Attendance for 20–25 students in ≤120s with ≥97% precision/recall under typical lighting/angles.
- Geofence toggles On/Off Campus within ≤30s boundary crossing.
- One full rotation: ≥90% students arrive in ≤60s; events logged.
- Evidence → suggestion: accept/retag ≤2 taps; explain-why visible.

## What to do next
- Generate file/folder scaffolds, starter code, and README instructions.
- Produce minimal working code for CV enrollment & attendance loop with stub models and dependency injection for later swap.
- Add sample OneRoster CSV and importer.
- Emit a **task list** (markdown checklist) mapped to the plan’s Week 1–6 items with pointers to files to edit.
- Keep code idiomatic, typed, and testable; add unit tests for key utilities.
- When you need secrets/keys, create .env.example entries and reference them via dependency injection.
- Output a short summary of what you created and how to run it locally (dev containers optional).
```

---

**Files you already have (download if needed):**
- `CoTeacher_System_Diagram_v1_CV_GPS.md`
- `CoTeacher_MVP_PoC_Plan_Teacher_Student_v1_CV_GPS.md`

**End of document.**