"""
=============================================================================
REPORTS ROUTER - RESTful endpoints for analytics and reports
=============================================================================

LEARNING GUIDE: Route Organization

KEY PRINCIPLES:
1. Routes are thin - they handle HTTP/validation, logic goes to services
2. Path parameters (/reports/:id) vs query params (?start_date=)
3. Response schemas validate output
4. Error handling returns appropriate HTTP status codes
5. Each endpoint does ONE thing
=============================================================================
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, date
from typing import Optional

from app.core.database import get_db
from app.services.analytics_service import AnalyticsService
from app.services.export_service import ExportService
from app.schemas.reports import (
    AttendanceStatsResponse,
    StudentAttendanceSummaryResponse,
    DailyTrendResponse,
    ClassComparisonResponse,
    AttendancePatternsResponse,
    PerformanceReportResponse,
    ComprehensiveReportResponse,
)

router = APIRouter(prefix="/api/v1/reports", tags=["reports"])


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def parse_date(date_str: Optional[str]) -> Optional[datetime]:
    """Parse ISO date string to datetime"""
    if not date_str:
        return None
    try:
        return datetime.fromisoformat(date_str)
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid date format: {date_str}. Use ISO format (YYYY-MM-DD)"
        )


def get_date_range(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
) -> tuple[datetime, datetime]:
    """
    Get date range for reports.
    
    Default: last 30 days
    """
    if end_date:
        end = parse_date(end_date)
    else:
        end = datetime.utcnow()
    
    if start_date:
        start = parse_date(start_date)
    else:
        start = end - timedelta(days=30)
    
    if start > end:
        raise HTTPException(
            status_code=400,
            detail="start_date must be before end_date"
        )
    
    return start, end


# =============================================================================
# STATISTICS ENDPOINTS
# =============================================================================

@router.get(
    "/attendance/stats",
    response_model=AttendanceStatsResponse,
    summary="Overall attendance statistics",
    description="Get aggregate attendance statistics for a date range",
)
async def get_attendance_stats(
    start_date: Optional[str] = Query(None, description="Start date (ISO format, default: 30 days ago)"),
    end_date: Optional[str] = Query(None, description="End date (ISO format, default: today)"),
    class_id: Optional[str] = Query(None, description="Optional class ID to filter"),
    db: Session = Depends(get_db),
):
    """
    Get attendance statistics.
    
    **Query Parameters:**
    - `start_date`: Optional start date (ISO format)
    - `end_date`: Optional end date (ISO format)
    - `class_id`: Optional class ID to filter to specific class
    
    **Returns:**
    - `total_records`: Total attendance records
    - `present_count`: Number of present records
    - `attendance_rate`: Overall percentage (0-100)
    - `total_students`: Unique students in range
    """
    start, end = get_date_range(start_date, end_date)
    
    service = AnalyticsService(db)
    stats = service.get_attendance_stats(start, end, class_id)
    
    return AttendanceStatsResponse(**stats)


@router.get(
    "/student-summaries",
    response_model=StudentAttendanceSummaryResponse,
    summary="Per-student attendance summaries",
    description="Get attendance breakdown for each student",
)
async def get_student_summaries(
    start_date: Optional[str] = Query(None, description="Start date (ISO format)"),
    end_date: Optional[str] = Query(None, description="End date (ISO format)"),
    class_id: Optional[str] = Query(None, description="Optional class ID to filter"),
    db: Session = Depends(get_db),
):
    """
    Get per-student attendance summaries.
    
    **Returns:**
    - `summaries`: List of student records with attendance breakdown
    - `students_at_risk`: Count of students below 80% attendance
    - `at_risk`: Boolean indicating if student is at risk (< 80% attendance)
    """
    start, end = get_date_range(start_date, end_date)
    
    service = AnalyticsService(db)
    data = service.get_student_summaries(start, end, class_id)
    
    return StudentAttendanceSummaryResponse(**data)


@router.get(
    "/daily-trends",
    response_model=DailyTrendResponse,
    summary="Daily attendance trends",
    description="Get daily attendance data for charting",
)
async def get_daily_trends(
    start_date: Optional[str] = Query(None, description="Start date (ISO format)"),
    end_date: Optional[str] = Query(None, description="End date (ISO format)"),
    class_id: Optional[str] = Query(None, description="Optional class ID to filter"),
    db: Session = Depends(get_db),
):
    """
    Get daily attendance trends for visualization.
    
    **Returns:**
    - `trends`: List of daily data points with attendance counts
    - One entry per day with present/absent/tardy counts
    """
    start, end = get_date_range(start_date, end_date)
    
    service = AnalyticsService(db)
    data = service.get_daily_trends(start, end, class_id)
    
    return DailyTrendResponse(**data)


@router.get(
    "/class-comparisons",
    response_model=ClassComparisonResponse,
    summary="Cross-class attendance comparison",
    description="Compare attendance rates across all classes",
)
async def get_class_comparisons(
    start_date: Optional[str] = Query(None, description="Start date (ISO format)"),
    end_date: Optional[str] = Query(None, description="End date (ISO format)"),
    db: Session = Depends(get_db),
):
    """
    Compare attendance statistics across classes.
    
    **Returns:**
    - `comparisons`: Sorted list (highest to lowest attendance)
    - `highest_attendance_class`: Class ID with best attendance
    - `lowest_attendance_class`: Class ID with worst attendance
    """
    start, end = get_date_range(start_date, end_date)
    
    service = AnalyticsService(db)
    data = service.get_class_comparisons(start, end)
    
    return ClassComparisonResponse(**data)


# =============================================================================
# INSIGHTS ENDPOINTS
# =============================================================================

@router.get(
    "/patterns",
    response_model=AttendancePatternsResponse,
    summary="Identify attendance patterns",
    description="Detect patterns and generate recommendations",
)
async def detect_patterns(
    start_date: Optional[str] = Query(None, description="Start date (ISO format)"),
    end_date: Optional[str] = Query(None, description="End date (ISO format)"),
    class_id: Optional[str] = Query(None, description="Optional class ID to filter"),
    db: Session = Depends(get_db),
):
    """
    Detect attendance patterns and generate recommendations.
    
    **Returns:**
    - `patterns`: List of identified patterns with affected students
    - `risk_level`: Overall risk assessment (low, medium, high)
    - `recommendations`: List of action recommendations
    """
    start, end = get_date_range(start_date, end_date)
    
    service = AnalyticsService(db)
    data = service.detect_patterns(start, end, class_id)
    
    return AttendancePatternsResponse(**data)


@router.get(
    "/performance",
    response_model=PerformanceReportResponse,
    summary="Student performance report",
    description="Generate performance scores and categorizations",
)
async def get_performance_report(
    start_date: Optional[str] = Query(None, description="Start date (ISO format)"),
    end_date: Optional[str] = Query(None, description="End date (ISO format)"),
    class_id: Optional[str] = Query(None, description="Optional class ID to filter"),
    db: Session = Depends(get_db),
):
    """
    Generate comprehensive performance report.
    
    **Returns:**
    - `students`: Complete list with performance scores
    - `high_performers`: Students with 95%+ attendance
    - `at_risk_students`: Students below 80% attendance
    - `trend`: Overall class trend (improving, stable, declining)
    """
    start, end = get_date_range(start_date, end_date)
    
    service = AnalyticsService(db)
    data = service.get_performance_report(start, end, class_id)
    
    return PerformanceReportResponse(**data)


# =============================================================================
# COMPREHENSIVE REPORT
# =============================================================================

@router.get(
    "/comprehensive",
    response_model=ComprehensiveReportResponse,
    summary="Complete analytics report",
    description="Get all analytics combined in one comprehensive report",
)
async def get_comprehensive_report(
    start_date: Optional[str] = Query(None, description="Start date (ISO format)"),
    end_date: Optional[str] = Query(None, description="End date (ISO format)"),
    class_id: Optional[str] = Query(None, description="Optional class ID to filter"),
    db: Session = Depends(get_db),
):
    """
    Get comprehensive report with all analytics.
    
    **Returns:**
    - Combines all other endpoints into one complete report
    - Useful for dashboard or full-page exports
    - Single request gets all data
    """
    start, end = get_date_range(start_date, end_date)
    
    service = AnalyticsService(db)
    
    # Load all data in parallel-like fashion
    stats = service.get_attendance_stats(start, end, class_id)
    summaries = service.get_student_summaries(start, end, class_id)
    trends = service.get_daily_trends(start, end, class_id)
    performance = service.get_performance_report(start, end, class_id)
    
    # Class comparisons only if no class filter
    comparisons = None
    if not class_id:
        comparisons = service.get_class_comparisons(start, end)
    
    # Patterns only if meaningful data
    patterns = None
    if summaries["total_students"] > 0:
        patterns = service.detect_patterns(start, end, class_id)
    
    # Period name
    period_days = (end - start).days
    if period_days == 1:
        period = "Daily"
    elif period_days <= 7:
        period = "Weekly"
    elif period_days <= 30:
        period = "Monthly"
    else:
        period = f"{period_days} Days"
    
    return ComprehensiveReportResponse(
        report_id=f"rpt_{start.timestamp():.0f}_{end.timestamp():.0f}",
        generated_at=datetime.utcnow(),
        period=period,
        start_date=start.date(),
        end_date=end.date(),
        statistics=AttendanceStatsResponse(**stats),
        student_summaries=StudentAttendanceSummaryResponse(**summaries),
        daily_trends=DailyTrendResponse(**trends),
        class_comparisons=ClassComparisonResponse(**comparisons) if comparisons else None,
        patterns=AttendancePatternsResponse(**patterns) if patterns else None,
        performance=PerformanceReportResponse(**performance),
    )


# =============================================================================
# EXPORT ENDPOINTS (placeholder for Phase 2)
# =============================================================================

@router.get(
    "/export/csv",
    summary="Export report to CSV",
    description="Generate downloadable CSV export",
)
async def export_to_csv(
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    class_id: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    """
    Export attendance report to CSV format.
    
    **Returns:**
    - `csv_content`: CSV data ready for download
    - `filename`: Suggested filename for download
    """
    start, end = get_date_range(start_date, end_date)
    
    analytics = AnalyticsService(db)
    export = ExportService(analytics)
    
    csv_content = export.generate_csv(start, end, class_id)
    
    # Generate filename
    period = (end - start).days
    filename = f"attendance_report_{period}days_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.csv"
    
    return {
        "filename": filename,
        "csv_content": csv_content,
        "status": "ready",
        "generated_at": datetime.utcnow().isoformat(),
    }


@router.get(
    "/export/pdf",
    summary="Export report to PDF",
    description="Generate downloadable PDF export",
)
async def export_to_pdf(
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    class_id: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    """
    Export attendance report to PDF format.
    
    **Returns:**
    - `json_data`: Data formatted for PDF generation
    - `filename`: Suggested filename for download
    
    **Note**: PDF generation can be done client-side or via external service
    """
    start, end = get_date_range(start_date, end_date)
    
    analytics = AnalyticsService(db)
    export = ExportService(analytics)
    
    json_data = export.generate_json_data(start, end, class_id)
    summary = export.get_export_summary(start, end, class_id)
    
    period = (end - start).days
    filename = f"attendance_report_{period}days_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.pdf"
    
    return {
        "filename": filename,
        "data": json_data,
        "summary": summary,
        "status": "ready_for_pdf_generation",
        "generated_at": datetime.utcnow().isoformat(),
    }
