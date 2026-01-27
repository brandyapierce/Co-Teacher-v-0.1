"""
=============================================================================
EXPORT SERVICE - Generate downloadable reports in various formats
=============================================================================

LEARNING GUIDE: Export Generation

KEY PRINCIPLES:
1. Generate export data from analytics service
2. Format according to requested format (CSV, PDF)
3. Return file paths or file contents
4. Handle large datasets efficiently
=============================================================================
"""

import io
import csv
from datetime import datetime
from typing import List, Dict, Optional

from app.services.analytics_service import AnalyticsService


class ExportService:
    """Service for generating report exports"""
    
    def __init__(self, analytics_service: AnalyticsService):
        self.analytics = analytics_service
    
    # =========================================================================
    # CSV EXPORT
    # =========================================================================
    
    def generate_csv(
        self,
        start_date: datetime,
        end_date: datetime,
        class_id: Optional[str] = None,
        include_stats: bool = True,
        include_students: bool = True,
        include_trends: bool = True,
    ) -> str:
        """
        Generate CSV export of attendance data.
        
        Returns:
            CSV content as string
        """
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Header
        writer.writerow(["Co-Teacher Attendance Report"])
        writer.writerow([f"Generated: {datetime.utcnow().isoformat()}"])
        writer.writerow([f"Period: {start_date.date()} to {end_date.date()}"])
        if class_id:
            writer.writerow([f"Class ID: {class_id}"])
        writer.writerow([])  # Blank line
        
        # Overall statistics section
        if include_stats:
            stats = self.analytics.get_attendance_stats(start_date, end_date, class_id)
            
            writer.writerow(["Overall Statistics"])
            writer.writerow(["Metric", "Value"])
            writer.writerow(["Total Records", stats["total_records"]])
            writer.writerow(["Present", stats["present_count"]])
            writer.writerow(["Absent", stats["absent_count"]])
            writer.writerow(["Tardy", stats["tardy_count"]])
            writer.writerow(["Excused", stats["excused_count"]])
            writer.writerow(["Attendance Rate (%)", f"{stats['attendance_rate']:.2f}"])
            writer.writerow(["Total Students", stats["total_students"]])
            writer.writerow([])  # Blank line
        
        # Student summaries section
        if include_students:
            summaries_data = self.analytics.get_student_summaries(start_date, end_date, class_id)
            
            writer.writerow(["Student Attendance Summary"])
            writer.writerow([
                "Student Name",
                "Total Days",
                "Present",
                "Absent",
                "Tardy",
                "Excused",
                "Attendance Rate (%)",
                "At Risk"
            ])
            
            for summary in summaries_data["summaries"]:
                writer.writerow([
                    summary["student_name"],
                    summary["total_days"],
                    summary["present_days"],
                    summary["absent_days"],
                    summary["tardy_days"],
                    summary["excused_days"],
                    f"{summary['attendance_rate']:.2f}",
                    "Yes" if summary["at_risk"] else "No"
                ])
            
            writer.writerow([])  # Blank line
        
        # Daily trends section
        if include_trends:
            trends_data = self.analytics.get_daily_trends(start_date, end_date, class_id)
            
            writer.writerow(["Daily Attendance Trends"])
            writer.writerow([
                "Date",
                "Present",
                "Absent",
                "Tardy",
                "Total",
                "Attendance Rate (%)"
            ])
            
            for trend in trends_data["trends"]:
                writer.writerow([
                    str(trend["date"]),
                    trend["present_count"],
                    trend["absent_count"],
                    trend["tardy_count"],
                    trend["total_count"],
                    f"{trend['attendance_percentage']:.2f}"
                ])
        
        return output.getvalue()
    
    # =========================================================================
    # JSON EXPORT
    # =========================================================================
    
    def generate_json_data(
        self,
        start_date: datetime,
        end_date: datetime,
        class_id: Optional[str] = None,
    ) -> Dict:
        """
        Generate JSON export data.
        
        Returns:
            Dictionary that can be JSON serialized
        """
        stats = self.analytics.get_attendance_stats(start_date, end_date, class_id)
        summaries = self.analytics.get_student_summaries(start_date, end_date, class_id)
        trends = self.analytics.get_daily_trends(start_date, end_date, class_id)
        
        return {
            "report_metadata": {
                "generated_at": datetime.utcnow().isoformat(),
                "start_date": str(start_date.date()),
                "end_date": str(end_date.date()),
                "class_id": class_id,
            },
            "statistics": stats,
            "student_summaries": summaries["summaries"],
            "daily_trends": trends["trends"],
        }
    
    # =========================================================================
    # SUMMARY STATISTICS FOR EXPORT
    # =========================================================================
    
    def get_export_summary(
        self,
        start_date: datetime,
        end_date: datetime,
        class_id: Optional[str] = None,
    ) -> Dict:
        """
        Get summary statistics useful for export info.
        
        Returns:
            Dictionary with counts and basic stats
        """
        stats = self.analytics.get_attendance_stats(start_date, end_date, class_id)
        summaries_data = self.analytics.get_student_summaries(start_date, end_date, class_id)
        
        return {
            "total_records": stats["total_records"],
            "total_students": stats["total_students"],
            "students_at_risk": summaries_data["students_at_risk"],
            "attendance_rate": stats["attendance_rate"],
            "period_days": stats["date_range_days"],
            "start_date": str(start_date.date()),
            "end_date": str(end_date.date()),
        }
