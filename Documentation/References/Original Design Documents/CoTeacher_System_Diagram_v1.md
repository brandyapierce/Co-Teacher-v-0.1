# CoTeacher — System Diagram (v1, **CV + GPS Only**)

This diagram highlights the PoC/MVP slice using **on-device Computer Vision** and **GPS/geofencing**. There are **no QR/barcodes** anywhere in the flow.

```mermaid
flowchart LR
  %% Clients
  subgraph Clients
    T[Teacher Tablet App]
    S[Student Tablet App]
    P[Parent Mobile/Web]
    A[Admin Web]
  end

  %% Edge AI (CV-only)
  subgraph EdgeAI[On-Device / Edge AI (CV-only)]
    CV1[Face Detect + Embeddings + Re-ID]
    CV2[Work Scan / Handwriting Assist]
    CV3[Door/Line/Circle Checkpoints (visual markers, not codes)]
  end

  T -->|Camera/Mic| EdgeAI
  S -->|Camera/Mic| EdgeAI

  %% Location (GPS perimeter)
  subgraph Location[Location Services]
    GPS[Campus Geofences (Perimeter & Pickup Loop)]
  end

  T <--> GPS
  S <--> GPS

  %% API Gateway & Realtime
  GW[API Gateway / BFFs]
  RT[Realtime (WebSockets)]
  NT[Notifications (Push/SMS/Email)]
  T <--> RT
  S <--> RT
  P <--> RT
  A <--> RT

  T <--> GW
  S <--> GW
  P <--> GW
  A <--> GW

  %% Services (PoC/MVP slice emphasized)
  subgraph Services[Core Backend Microservices]
    AUTH[Auth (OIDC, RBAC/ABAC, Tenants)]
    ROSTER[Roster/SIS Adapter (OneRoster)]
    ATT[Attendance & Location (CV + GPS)]
    ROT[Rotations/Stations]
    EVID[Evidence & Media Pipeline (Redact/Retain)]

    INSG[Insights (Rules + Explain-Why)]
    MSG[Messaging/Translation]
    CUST[Custody/Dismissal (CV lineup + GPS pickup)]
    REP[Reporting/Analytics]
    COM[Community / Bright Ideas]
  end

  GW --> AUTH
  GW --> ROSTER
  GW --> ATT
  GW --> ROT
  GW --> EVID
  GW --> INSG
  GW --> MSG
  GW --> CUST
  GW --> REP
  GW --> COM

  %% Data Plane
  subgraph DataPlane[Data Plane]
    PG[(PostgreSQL: Core Data)]
    OBJ[(Object Store: Media/Artifacts)]
    TS[(Time-Series: Events/Telemetry)]
    VEC[(Vector DB: Content/Strategy Retrieval)]
    REDIS[(Redis: Cache/Queues)]
    SRCH[(Search: OpenSearch/Elastic)]
  end

  ATT <-->|CRUD| PG
  ROT <-->|CRUD| PG
  INSG --> PG
  EVID --> OBJ
  ATT --> TS
  MSG --> REDIS
  INSG --> VEC
  COM --> SRCH

  %% Eventing & Workflows
  subgraph Async[Eventing & Orchestration]
    BUS[[Event Bus (Kafka/NATS)]]
    WF[[Workflow (Temporal)]]
    LOGS[[Observability (OTel + Grafana/Loki)]]
  end

  Services <---> BUS
  BUS --> WF
  Services --> LOGS
  RT --> BUS

  %% MLOps (server-side assist + edge packaging)
  subgraph MLOps
    REG[[Model Registry (MLflow/W&B)]]
    SERV[[Model Serving (Triton/KFServing)]]
    LABL[[Labeling (CVAT/Label Studio)]]
    FEAT[[Feature Store (Feast)]]
    MON[[Model Monitoring (Evidently/WhyLabs)]]
  end

  INSG <--> SERV
  INSG <--> FEAT
  SERV <--> REG
  MON ---> INSG

  %% Parent Vault (future integration preserved)
  subgraph Vault[Parent-Controlled Data Vault (Future Phase)]
    DID[DIDs/VCs (Keys & Credentials)]
    PDV[(Encrypted Personal Data Vault)]
    CONS[Consent Receipts (Permissioned Ledger)]
  end

  %% Bridge is out-of-scope for PoC/MVP but kept in design
  DTV[Digital Twin Bridge]:::faded
  classDef faded fill:#eee,stroke:#bbb,color:#999;

  DTV -. future .- PDV
  DTV -. future .- DID
  DTV -. future .- CONS

  %% Notifications
  Services --> NT

  %% Edge loops back to apps
  EdgeAI --> T
  EdgeAI --> S
```