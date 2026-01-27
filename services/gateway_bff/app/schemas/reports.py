"""
=============================================================================
REPORT SCHEMAS - Pydantic models for analytics and reports APIs
=============================================================================

LEARNING GUIDE: Schema Design for Complex Data

KEY PRINCIPLES:
1. Each schema represents ONE data structure
2. Validation happens automatically (Pydantic)
3. Responses are JSON-serializable
4. Complex data = nested schemas
5. Optional fields use Optional[] with defaults
=============================================================================
"""

from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Dict
from datetime import datetime, date


# =============================================================================
# ATTENDANCE STATISTICS
# =============================================================================

class AttendanceStatsResponse(BaseModel):
    """Overall attendance statistics for a date range"""
    total_records: int = Field(..., description="Total attendance records")
    present_count: int = Field(..., description="Number of present records")
    absent_count: int = Field(..., description="Number of absent records")
    tardy_count: int = Field(..., description="Number of tardy records")
    excused_count: int = Field(..., description="Number of excused records")
    
    attendance_rate: float = Field(
        ..., description="Overall attendance rate percentage (0-100)"
    )
    average_attendance_rate: float = Field(
        ..., description="Average attendance rate per student"
    )
    
    date_range_days: int = Field(..., description="Number of days in date range")
    start_date: date
    end_date: date
    
    total_students: int = Field(..., description="Total unique students")
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "total_records": 150,
                "present_count": 140,
                "absent_count": 5,
                "tardy_count": 5,
                "excused_count": 0,
                "attendance_rate": 93.33,
                "average_attendance_rate": 92.5,
                "date_range_days": 30,
                "start_date": "2024-11-01",
                "end_date": "2024-11-30",
                "total_students": 25,
            }
        }
    )


# =============================================================================
# STUDENT ATTENDANCE SUMMARY
# =============================================================================

class StudentAttendanceSummaryItem(BaseModel):
    """Attendance summary for a single student"""
    student_id: str
    student_name: str
    total_days: int = Field(..., description="Total attendance records")
    present_days: int
    absent_days: int
    tardy_days: int
    excused_days: int
    
    attendance_rate: float = Field(
        ..., description="Student attendance rate percentage (0-100)"
    )
    last_attendance_date: Optional[datetime] = None
    
    at_risk: bool = Field(
        ..., 
        description="True if attendance rate below 80%"
    )


class StudentAttendanceSummaryResponse(BaseModel):
    """Response containing summaries for multiple students"""
    summaries: List[StudentAttendanceSummaryItem]
    total_students: int
    students_at_risk: int = Field(
        ..., description="Count of students with attendance below 80%"
    )
    date_range_days: int
    start_date: date
    end_date: date


# =============================================================================
# DAILY TRENDS
# =============================================================================

class DailyTrendPoint(BaseModel):
    """Single day's attendance trend data"""
    date: date
    present_count: int
    absent_count: int
    tardy_count: int
    total_count: int
    attendance_percentage: float


class DailyTrendResponse(BaseModel):
    """Daily attendance trends for charting"""
    trends: List[DailyTrendPoint]
    total_records: int
    date_range_days: int
    start_date: date
    end_date: date
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "trends": [
                    {
                        "date": "2024-11-01",
                        "present_count": 20,
                        "absent_count": 2,
                        "tardy_count": 3,
                        "total_count": 25,
                        "attendance_percentage": 80.0
                    },
                    {
                        "date": "2024-11-02",
                        "present_count": 22,
                        "absent_count": 1,
                        "tardy_count": 2,
                        "total_count": 25,
                        "attendance_percentage": 88.0
                    }
                ],
                "total_records": 50,
                "date_range_days": 30,
                "start_date": "2024-11-01",
                "end_date": "2024-11-30"
            }
        }
    )


# =============================================================================
# CLASS COMPARISONS
# =============================================================================

class ClassComparisonItem(BaseModel):
    """Attendance comparison for one class"""
    class_id: str
    class_name: str
    student_count: int
    attendance_rate: float
    present_count: int
    absent_count: int
    tardy_count: int
    total_records: int


class ClassComparisonResponse(BaseModel):
    """Attendance comparison across classes"""
    comparisons: List[ClassComparisonItem]
    highest_attendance_class: Optional[str] = None
    lowest_attendance_class: Optional[str] = None
    average_attendance_rate: float
    date_range_days: int
    start_date: date
    end_date: date


# =============================================================================
# ATTENDANCE PATTERNS & INSIGHTS
# =============================================================================

class AttendancePattern(BaseModel):
    """Identified attendance pattern"""
    pattern_type: str = Field(
        ..., 
        description="Type: 'consistent', 'declining', 'improving', 'sporadic'"
    )
    description: str
    severity: str = Field(
        ..., 
        description="'low', 'medium', 'high'"
    )
    affected_students: List[str] = Field(
        default_factory=list,
        description="List of student IDs affected"
    )


class AttendancePatternsResponse(BaseModel):
    """Identified patterns in attendance data"""
    patterns: List[AttendancePattern]
    period_duration_days: int
    risk_level: str = Field(
        ..., 
        description="Overall risk: 'low', 'medium', 'high'"
    )
    recommendations: List[str] = Field(
        default_factory=list,
        description="Recommendations based on patterns"
    )


# =============================================================================
# PERFORMANCE REPORT
# =============================================================================

class StudentPerformanceItem(BaseModel):
    """Performance metrics for a student"""
    student_id: str
    student_name: str
    attendance_rate: float
    attendance_trend: str = Field(
        ..., 
        description="'improving', 'stable', 'declining'"
    )
    recent_absences: int = Field(
        ..., 
        description="Absences in last 7 days"
    )
    performance_score: float = Field(
        ..., 
        description="0-100 based on attendance, trends, etc."
    )


class PerformanceReportResponse(BaseModel):
    """Overall performance report for students"""
    total_students: int
    students: List[StudentPerformanceItem]
    high_performers: List[StudentPerformanceItem]
    at_risk_students: List[StudentPerformanceItem]
    average_attendance_rate: float
    trend: str = Field(
        ..., 
        description="Overall trend: 'improving', 'stable', 'declining'"
    )


# =============================================================================
# EXPORT FORMATS
# =============================================================================

class ExportFormatRequest(BaseModel):
    """Request for exporting reports"""
    format: str = Field(
        default="csv",
        description="Export format: 'csv', 'pdf', 'json'"
    )
    start_date: date
    end_date: date
    class_id: Optional[str] = None
    include_trends: bool = True
    include_patterns: bool = True


class ExportFormatResponse(BaseModel):
    """Response after export generation"""
    export_id: str
    format: str
    status: str = Field(
        ..., 
        description="'completed', 'processing', 'failed'"
    )
    download_url: Optional[str] = None
    generated_at: datetime
    file_size_kb: Optional[float] = None


# =============================================================================
# COMPREHENSIVE REPORT
# =============================================================================

class ComprehensiveReportResponse(BaseModel):
    """Complete report with all analytics"""
    report_id: str
    generated_at: datetime
    period: str
    start_date: date
    end_date: date
    
    statistics: AttendanceStatsResponse
    student_summaries: StudentAttendanceSummaryResponse
    daily_trends: DailyTrendResponse
    class_comparisons: Optional[ClassComparisonResponse] = None
    patterns: Optional[AttendancePatternsResponse] = None
    performance: Optional[PerformanceReportResponse] = None
    
    model_config = ConfigDict(
        json_schema_extra={
            "description": "Complete analytics report combining all data sources"
        }
    )
