# 🎯 Execution Plan - Week 1.5 Validation & Fixes

**Master Protocol**: ✅ ENGAGED  
**Date**: November 1, 2025  
**Phase**: Week 1 Complete → Week 2 Preparation

---

## 📊 Current State Assessment

### ✅ What Exists
- **Backend**: Complete (7 API services, all models, schemas)
- **Infrastructure**: Docker Compose config, Dockerfile, requirements.txt
- **Documentation**: Comprehensive guides created
- **Git**: All code pushed to GitHub (46 files)

### ❌ What's Missing
- **Docker Desktop**: Not installed (blocks backend testing)
- **Flutter App**: Directory doesn't exist (needs full scaffold)
- **CV Models**: Not downloaded
- **Database**: Not running (needs Docker or local install)

---

## 🚀 Recommended Execution Strategy

### Strategy: Parallel Track Approach

**Track 1**: Backend Validation (Requires Docker)  
**Track 2**: Flutter App Creation (No dependencies)  
**Track 3**: CV Model Research (No dependencies)

**Recommendation**: Start Track 2 (Flutter) while Docker setup is optional.

---

## 📋 Detailed Execution Plan

### TRACK 1: Backend Testing (Optional - Requires Docker)

#### Step 1: Install Docker Desktop
**Time**: 30 minutes  
**Priority**: Medium (can skip if focusing on Flutter)

**Instructions**:
1. Download: https://www.docker.com/products/docker-desktop
2. Install Docker Desktop for Windows
3. Restart computer
4. Verify: `docker --version`

#### Step 2: Start Backend Services
**Time**: 10 minutes

```bash
# Start infrastructure
docker-compose up -d

# Verify
docker-compose ps
```

#### Step 3: Setup Backend API
**Time**: 15 minutes

```bash
cd services/gateway_bff
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
python main.py
```

#### Step 4: Test API
**Time**: 30 minutes
- Visit: http://localhost:8000/docs
- Test: http://localhost:8000/health
- Test login endpoint
- Verify all 7 services

**Status**: ⏸️ BLOCKED until Docker installed

---

### TRACK 2: Flutter App Creation (RECOMMENDED TO START)

**Time**: 2-3 hours  
**Priority**: HIGH (needed for Week 2)  
**Blockers**: NONE

#### Phase 2.1: Create App Scaffold (30 min)

**Files to Create**:
```
apps/teacher_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── config/
│   │   ├── di/
│   │   ├── router/
│   │   └── theme/
│   ├── features/
│   │   ├── auth/
│   │   ├── attendance/
│   │   ├── rotations/
│   │   └── evidence/
│   └── shared/
└── pubspec.yaml
```

#### Phase 2.2: Fix DI Container (1 hour)

**Create**: `apps/teacher_app/lib/core/di/injection_container.dart`

**Minimal Implementation**:
- Setup GetIt
- Register only existing services (CV, Location, Offline Queue)
- Remove all non-existent module references
- Open Hive boxes properly

#### Phase 2.3: Fix Router (30 min)

**Create**: `apps/teacher_app/lib/core/router/app_router.dart`

**Minimal Routes**:
- `/splash` → SplashPage
- `/login` → LoginPage
- `/home` → HomePage (with tabs)

#### Phase 2.4: Create Auth Pages (1 hour)

**Create**:
- `splash_page.dart` - Simple loading screen
- `login_page.dart` - Email/password form

#### Phase 2.5: Verify Compilation (30 min)

```bash
cd apps/teacher_app
flutter pub get
flutter analyze
flutter run --no-build
```

---

### TRACK 3: CV Model Research & Download (1 hour)

#### Step 1: MediaPipe Model (15 min)
**Model**: MediaPipe Face Detection  
**URL**: https://github.com/google/mediapipe  
**File**: Download face detection model files  
**Location**: `apps/teacher_app/assets/models/mediapipe/`

#### Step 2: ONNX Embedding Model (15 min)
**Model**: ArcFace or MobileFaceNet (mobile-optimized)  
**URL**: https://github.com/onnx/models  
**File**: ONNX model file (.onnx)  
**Location**: `apps/teacher_app/assets/models/onnx/`

#### Step 3: Update pubspec.yaml (5 min)
Add models to assets section

#### Step 4: Document Integration (10 min)
Create integration guide

---

## 🎯 IMMEDIATE NEXT STEPS (In Order)

### Step 1: Create Flutter App Scaffold ✅ START HERE
**Why**: No blockers, enables Week 2 work  
**Time**: 30 minutes  
**Action**: I'll create the complete Flutter app structure

### Step 2: Fix DI Container
**Time**: 1 hour  
**Action**: Create minimal working DI setup

### Step 3: Fix Router & Create Pages
**Time**: 1.5 hours  
**Action**: Create router and minimal auth pages

### Step 4: Verify Flutter Compilation
**Time**: 30 minutes  
**Action**: Test that app compiles and runs

### Step 5: (Optional) Setup Docker & Test Backend
**Time**: 1 hour  
**Action**: Install Docker, start services, test API

### Step 6: Download CV Models
**Time**: 1 hour  
**Action**: Research and download MediaPipe + ONNX models

---

## 📝 Task Log Updates

**Current Session Actions**:
1. ✅ Master Protocol engaged
2. ✅ Task log created
3. ✅ Execution plan created
4. 🔨 Starting Flutter app scaffold creation

---

**Protocol**: MASTER  
**Status**: ACTIVE  
**Next Action**: Create Flutter app scaffold

