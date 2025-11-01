# My AI CoTeacher v2

A **privacy-first, offline-capable** classroom management system using **Computer Vision + GPS** for attendance, rotations, and evidence capture.

## 🎯 Quick Start

### 1. Start Infrastructure
```bash
docker-compose up -d
```

### 2. Setup Backend
```bash
cd services/gateway_bff
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
python main.py
```

API available at: http://localhost:8000/docs

## ✅ Week 1 Complete

- ✅ 7 API services with 40+ endpoints
- ✅ JWT authentication  
- ✅ Database with 9 tables
- ✅ Docker Compose setup
- ✅ Privacy-first design

See `EASIEST_PUSH_TO_GITHUB.md` for push instructions.

