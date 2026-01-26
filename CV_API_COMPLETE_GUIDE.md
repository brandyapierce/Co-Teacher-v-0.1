# CV Enrollment API Endpoints - Complete Guide

## Base URL
```
http://localhost:8000/api/v1
```

## Authentication
All endpoints except health checks require JWT Bearer token in header:
```
Authorization: Bearer <your_jwt_token>
```

---

## Enrollment Endpoints

### 1. Enroll Student (Multi-Pose)
**POST** `/enrollment/enroll`

Enroll a student with a face image. Can be called multiple times for multi-pose enrollment.

**Request:**
```
Content-Type: multipart/form-data

Parameters:
- student_id (string, required): Student ID
- image_data (file, required): Image file (JPEG/PNG)
- pose_index (integer, optional, default=0): Which pose this is (0-4)
```

**Response (200):**
```json
{
  "success": true,
  "message": "Face enrolled successfully (pose 0)",
  "confidence": 0.95,
  "student_id": "STU001",
  "template_id": 1,
  "is_enrolled": true
}
```

**Errors:**
- 404: Student not found
- 400: Invalid image format
- 500: Enrollment failed

**Example with curl:**
```bash
curl -X POST http://localhost:8000/api/v1/enrollment/enroll \
  -H "Authorization: Bearer your_token" \
  -F "student_id=STU001" \
  -F "image_data=@face_image.jpg" \
  -F "pose_index=0"
```

---

### 2. Check Enrollment Status
**GET** `/enrollment/status/{student_id}`

Check if a student is enrolled and get their enrollment details.

**Request:**
```
URL: /enrollment/status/STU001
```

**Response (200):**
```json
{
  "success": true,
  "message": "Student is enrolled",
  "confidence": 1.0,
  "student_id": "STU001",
  "template_id": 1,
  "is_enrolled": true
}
```

**Example with curl:**
```bash
curl -X GET http://localhost:8000/api/v1/enrollment/status/STU001 \
  -H "Authorization: Bearer your_token"
```

---

### 3. Unenroll Student
**DELETE** `/enrollment/unenroll/{student_id}`

Remove a student's face template enrollment.

**Response (200):**
```json
{
  "success": true,
  "message": "Student unenrolled",
  "student_id": "STU001"
}
```

**Example with curl:**
```bash
curl -X DELETE http://localhost:8000/api/v1/enrollment/unenroll/STU001 \
  -H "Authorization: Bearer your_token"
```

---

### 4. Get Class Enrollment List
**GET** `/enrollment/list/{class_id}`

Get enrollment status for all students in a class.

**Request:**
```
URL: /enrollment/list/CLASS001
```

**Response (200):**
```json
{
  "class_id": "CLASS001",
  "total_students": 25,
  "enrolled_students": 18,
  "students": [
    {
      "student_id": "STU001",
      "first_name": "John",
      "last_name": "Doe",
      "is_enrolled": true,
      "enrolled_at": "2024-11-26T10:30:00"
    },
    {
      "student_id": "STU002",
      "first_name": "Jane",
      "last_name": "Smith",
      "is_enrolled": false,
      "enrolled_at": null
    }
  ]
}
```

---

### 5. Get Enrollment Progress
**GET** `/enrollment/progress/{class_id}`

Get enrollment progress metrics for a class.

**Response (200):**
```json
{
  "class_id": "CLASS001",
  "total_students": 25,
  "enrolled": 18,
  "progress_percent": 72.0
}
```

---

### 6. Get CV System Statistics
**GET** `/enrollment/stats`

Get system-wide CV statistics.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "enrolled_students": 45,
    "total_attendance_records": 1250,
    "confidence_threshold": 0.6,
    "embedding_dimension": 128
  }
}
```

---

## Attendance Scanning Endpoints

### 7. Scan Attendance with CV
**POST** `/attendance/scan`

Process a camera image for attendance scanning. Detects faces and matches against enrolled templates.

**Request:**
```
Content-Type: multipart/form-data

Parameters:
- teacher_id (string, required): Teacher taking attendance
- image_data (file, required): Image from camera
- class_id (string, optional): Filter to class
- location (string, optional): Location information
```

**Response (200):**
```json
{
  "detected_students": [
    {
      "student_id": "STU001",
      "first_name": "John",
      "last_name": "Doe",
      "confidence": 0.92,
      "face_box": [40, 50, 120, 150],
      "recorded_at": "2024-11-26T09:00:00"
    }
  ],
  "total_detected": 1,
  "scan_time": "2024-11-26T09:00:00"
}
```

---

### 8. Manual Attendance Record
**POST** `/attendance/manual-record`

Manually record attendance for a student (no CV matching).

**Request:**
```
Content-Type: application/x-www-form-urlencoded

Parameters:
- student_id (string, required)
- teacher_id (string, required)
- location (string, optional)
```

**Response (200):**
```json
{
  "success": true,
  "message": "Attendance recorded for John Doe",
  "record_id": 1234,
  "recorded_at": "2024-11-26T09:00:00"
}
```

---

### 9. Get Attendance Records
**GET** `/attendance/records/{student_id}`

Get attendance records for a specific student.

**Query Parameters:**
- days (integer, optional, default=30): Number of days to look back

**Request:**
```
URL: /attendance/records/STU001?days=30
```

**Response (200):**
```json
[
  {
    "id": 1,
    "student_id": "STU001",
    "scan_time": "2024-11-26T09:00:00",
    "confidence": 0.92,
    "status": "present",
    "location": "Room 101"
  },
  {
    "id": 2,
    "student_id": "STU001",
    "scan_time": "2024-11-25T09:05:00",
    "confidence": 0.88,
    "status": "present",
    "location": "Room 101"
  }
]
```

---

### 10. Get Class Attendance Summary
**GET** `/attendance/class-summary/{class_id}`

Get attendance summary for an entire class.

**Query Parameters:**
- date (string, optional): Filter by date (YYYY-MM-DD format)

**Request:**
```
URL: /attendance/class-summary/CLASS001?date=2024-11-26
```

**Response (200):**
```json
{
  "class_id": "CLASS001",
  "date_filter": "2024-11-26",
  "summary": [
    {
      "student_id": "STU001",
      "name": "John Doe",
      "present": true,
      "records_count": 1,
      "last_record": "2024-11-26T09:00:00"
    },
    {
      "student_id": "STU002",
      "name": "Jane Smith",
      "present": false,
      "records_count": 0,
      "last_record": null
    }
  ],
  "total_students": 25,
  "present_count": 23,
  "attendance_rate": 92.0
}
```

---

## Error Handling

All endpoints follow consistent error response format:

```json
{
  "detail": "Error message describing what went wrong"
}
```

**Common HTTP Status Codes:**
- 200: Success
- 400: Bad request (invalid parameters)
- 401: Unauthorized (missing/invalid token)
- 404: Not found (student, class, etc.)
- 422: Validation error
- 500: Server error

---

## Database Schema

### face_templates Table
```sql
CREATE TABLE face_templates (
  id INTEGER PRIMARY KEY,
  student_id VARCHAR FOREIGN KEY REFERENCES students(id),
  embedding_data TEXT NOT NULL,  -- Pickled 128D embedding
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### attendance_records Table
```sql
CREATE TABLE attendance_records (
  id INTEGER PRIMARY KEY,
  student_id VARCHAR FOREIGN KEY REFERENCES students(id),
  teacher_id VARCHAR NOT NULL,
  scan_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  confidence FLOAT NOT NULL,  -- 0.0-1.0
  location VARCHAR,
  status VARCHAR DEFAULT 'present'  -- present, absent, late
);
```

---

## Testing the API

### 1. Get Authentication Token
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"teacher@example.com","password":"password"}'
```

### 2. Enroll a Student
```bash
# First, get a test image
# Then:
curl -X POST http://localhost:8000/api/v1/enrollment/enroll \
  -H "Authorization: Bearer <token>" \
  -F "student_id=STU001" \
  -F "image_data=@test_face.jpg" \
  -F "pose_index=0"
```

### 3. Check Enrollment
```bash
curl -X GET http://localhost:8000/api/v1/enrollment/status/STU001 \
  -H "Authorization: Bearer <token>"
```

### 4. Test Attendance Scan
```bash
curl -X POST http://localhost:8000/api/v1/attendance/scan \
  -H "Authorization: Bearer <token>" \
  -F "teacher_id=TEACH001" \
  -F "image_data=@classroom_photo.jpg" \
  -F "class_id=CLASS001"
```

---

## Implementation Notes

- **Confidence Threshold**: Default is 0.6. Matching faces with confidence ≥ 0.6 are considered matches.
- **Embedding Dimension**: 128-D vectors for optimal performance-accuracy tradeoff.
- **Image Processing**: Images are automatically resized and normalized.
- **Temporal Smoothing**: Multiple enrollments for same student are averaged for robustness.
- **Privacy**: All embeddings are encrypted with AES-256 (planned for Phase 2).

---

## Future Enhancements

1. **Batch Operations**: Support bulk enrollment and scanning
2. **Confidence Tuning**: Per-class configurable thresholds
3. **Audit Logging**: Track all enrollments and attendance changes
4. **Reporting**: Advanced attendance analytics and reporting
5. **Webhooks**: Real-time notifications for attendance events
