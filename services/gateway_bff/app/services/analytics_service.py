"""
=============================================================================
ANALYTICS SERVICE - Business logic for attendance analytics and reports
=============================================================================

LEARNING GUIDE: Service Layer for Complex Calculations

KEY PRINCIPLES:
1. Services encapsulate business logic separate from routes
2. Query data from models, compute results
3. Return raw data (routes handle formatting)
4. Reusable across multiple endpoints
5. Easy to test in isolation
=============================================================================
"""

from datetime import datetime, timedelta, date
from typing import List, Dict, Tuple, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.attendance import AttendanceRecord, Student
from app.models.classes import Class as ClassModel


class AnalyticsService:
    """Service for computing attendance analytics and statistics"""
    
    def __init__(self, db: Session):
        self.db = db
    
    # =========================================================================
    # CORE STATISTICS
    # =========================================================================
    
    def get_attendance_stats(
        self,
        start_date: datetime,
        end_date: datetime,
        class_id: Optional[str] = None,
    ) -> Dict:
        """
        Compute attendance statistics for date range.
        
        Args:
            start_date: Start of date range
            end_date: End of date range
            class_id: Optional class filter
            
        Returns:
            Dictionary with attendance stats
        """
        query = self.db.query(AttendanceRecord)
        
        # Filter by date range
        query = query.filter(
            AttendanceRecord.scan_time >= start_date,
            AttendanceRecord.scan_time <= end_date,
        )
        
        # Filter by class if provided
        if class_id:
            query = query.join(Student).filter(
                Student.class_id == class_id
            )
        
        records = query.all()
        
        # Count by status
        status_counts = {}
        for record in records:
            status = (record.status or "unknown").lower()
            status_counts[status] = status_counts.get(status, 0) + 1
        
        total_records = len(records)
        present_count = status_counts.get("present", 0)
        absent_count = status_counts.get("absent", 0)
        tardy_count = status_counts.get("tardy", 0) + status_counts.get("late", 0)
        excused_count = status_counts.get("excused", 0)
        
        # Calculate rates
        attendance_rate = (present_count / total_records * 100) if total_records > 0 else 0
        
        # Get unique students
        total_students = 0
        if class_id:
            total_students = self.db.query(Student).filter(
                Student.class_id == class_id
            ).count()
        else:
            total_students = self.db.query(func.count(func.distinct(Student.id))).join(
                AttendanceRecord
            ).filter(
                AttendanceRecord.scan_time >= start_date,
                AttendanceRecord.scan_time <= end_date,
            ).scalar() or 0
        
        # Calculate average attendance rate per student
        average_attendance_rate = 0.0
        if total_students > 0 and total_records > 0:
            average_attendance_rate = (present_count / (total_students * (end_date - start_date).days + 1)) * 100
        
        date_range_days = max((end_date - start_date).days, 1)
        
        return {
            "total_records": total_records,
            "present_count": present_count,
            "absent_count": absent_count,
            "tardy_count": tardy_count,
            "excused_count": excused_count,
            "attendance_rate": round(attendance_rate, 2),
            "average_attendance_rate": round(average_attendance_rate, 2),
            "date_range_days": date_range_days,
            "start_date": start_date.date(),
            "end_date": end_date.date(),
            "total_students": total_students,
        }
    
    # =========================================================================
    # STUDENT SUMMARIES
    # =========================================================================
    
    def get_student_summaries(
        self,
        start_date: datetime,
        end_date: datetime,
        class_id: Optional[str] = None,
    ) -> Dict:
        """
        Get attendance summary for each student.
        
        Returns:
            Dictionary with per-student summaries and risk assessment
        """
        query = self.db.query(AttendanceRecord).filter(
            AttendanceRecord.scan_time >= start_date,
            AttendanceRecord.scan_time <= end_date,
        )
        
        if class_id:
            query = query.join(Student).filter(
                Student.class_id == class_id
            )
        
        records = query.all()
        
        # Group by student
        student_data: Dict[str, Dict] = {}
        
        for record in records:
            student_id = record.student_id or "unknown"
            
            if student_id not in student_data:
                student = self.db.query(Student).filter(
                    Student.id == student_id
                ).first()
                
                student_data[student_id] = {
                    "student_id": student_id,
                    "student_name": student.name if student else "Unknown",
                    "present_days": 0,
                    "absent_days": 0,
                    "tardy_days": 0,
                    "excused_days": 0,
                    "last_attendance_date": None,
                }
            
            status = (record.status or "unknown").lower()
            if status == "present":
                student_data[student_id]["present_days"] += 1
            elif status == "absent":
                student_data[student_id]["absent_days"] += 1
            elif status in ["tardy", "late"]:
                student_data[student_id]["tardy_days"] += 1
            elif status == "excused":
                student_data[student_id]["excused_days"] += 1
            
            # Track last attendance
            record_date = record.scan_time
            last = student_data[student_id]["last_attendance_date"]
            if last is None or record_date > last:
                student_data[student_id]["last_attendance_date"] = record_date
        
        # Calculate rates and identify at-risk
        summaries = []
        at_risk_count = 0
        
        for student_id, data in student_data.items():
            total = (
                data["present_days"] + data["absent_days"] + 
                data["tardy_days"] + data["excused_days"]
            )
            
            attendance_rate = (data["present_days"] / total * 100) if total > 0 else 0
            at_risk = attendance_rate < 80
            
            if at_risk:
                at_risk_count += 1
            
            summaries.append({
                "student_id": student_id,
                "student_name": data["student_name"],
                "total_days": total,
                "present_days": data["present_days"],
                "absent_days": data["absent_days"],
                "tardy_days": data["tardy_days"],
                "excused_days": data["excused_days"],
                "attendance_rate": round(attendance_rate, 2),
                "last_attendance_date": data["last_attendance_date"],
                "at_risk": at_risk,
            })
        
        # Sort by name
        summaries.sort(key=lambda x: x["student_name"])
        
        date_range_days = max((end_date - start_date).days, 1)
        
        return {
            "summaries": summaries,
            "total_students": len(summaries),
            "students_at_risk": at_risk_count,
            "date_range_days": date_range_days,
            "start_date": start_date.date(),
            "end_date": end_date.date(),
        }
    
    # =========================================================================
    # DAILY TRENDS
    # =========================================================================
    
    def get_daily_trends(
        self,
        start_date: datetime,
        end_date: datetime,
        class_id: Optional[str] = None,
    ) -> Dict:
        """
        Get daily attendance trends for charting.
        
        Returns:
            Dictionary with daily trend data points
        """
        query = self.db.query(AttendanceRecord).filter(
            AttendanceRecord.scan_time >= start_date,
            AttendanceRecord.scan_time <= end_date,
        )
        
        if class_id:
            query = query.join(Student).filter(
                Student.class_id == class_id
            )
        
        records = query.all()
        
        # Group by date
        daily_data: Dict[date, Dict] = {}
        
        for record in records:
            record_date = record.scan_time.date()
            
            if record_date not in daily_data:
                daily_data[record_date] = {
                    "present": 0,
                    "absent": 0,
                    "tardy": 0,
                    "total": 0,
                }
            
            status = (record.status or "unknown").lower()
            daily_data[record_date]["total"] += 1
            
            if status == "present":
                daily_data[record_date]["present"] += 1
            elif status == "absent":
                daily_data[record_date]["absent"] += 1
            elif status in ["tardy", "late"]:
                daily_data[record_date]["tardy"] += 1
        
        # Build trend points and sort by date
        trends = []
        for trend_date in sorted(daily_data.keys()):
            data = daily_data[trend_date]
            total = data["total"]
            attendance_pct = (data["present"] / total * 100) if total > 0 else 0
            
            trends.append({
                "date": trend_date,
                "present_count": data["present"],
                "absent_count": data["absent"],
                "tardy_count": data["tardy"],
                "total_count": total,
                "attendance_percentage": round(attendance_pct, 2),
            })
        
        total_records = len(records)
        date_range_days = max((end_date - start_date).days, 1)
        
        return {
            "trends": trends,
            "total_records": total_records,
            "date_range_days": date_range_days,
            "start_date": start_date.date(),
            "end_date": end_date.date(),
        }
    
    # =========================================================================
    # CLASS COMPARISONS
    # =========================================================================
    
    def get_class_comparisons(
        self,
        start_date: datetime,
        end_date: datetime,
    ) -> Dict:
        """
        Get attendance statistics compared across classes.
        
        Returns:
            Dictionary with per-class comparison data
        """
        classes = self.db.query(ClassModel).all()
        
        comparisons = []
        total_attendance_rates = []
        
        for class_obj in classes:
            stats = self.get_attendance_stats(
                start_date, end_date, class_id=class_obj.id
            )
            
            summaries = self.get_student_summaries(
                start_date, end_date, class_id=class_obj.id
            )
            
            comparison = {
                "class_id": class_obj.id,
                "class_name": class_obj.name,
                "student_count": stats["total_students"],
                "attendance_rate": stats["attendance_rate"],
                "present_count": stats["present_count"],
                "absent_count": stats["absent_count"],
                "tardy_count": stats["tardy_count"],
                "total_records": stats["total_records"],
            }
            
            comparisons.append(comparison)
            total_attendance_rates.append(stats["attendance_rate"])
        
        # Sort by attendance rate (descending)
        comparisons.sort(key=lambda x: x["attendance_rate"], reverse=True)
        
        highest_class = comparisons[0]["class_id"] if comparisons else None
        lowest_class = comparisons[-1]["class_id"] if comparisons else None
        avg_attendance = (
            sum(total_attendance_rates) / len(total_attendance_rates)
            if total_attendance_rates
            else 0
        )
        
        date_range_days = max((end_date - start_date).days, 1)
        
        return {
            "comparisons": comparisons,
            "highest_attendance_class": highest_class,
            "lowest_attendance_class": lowest_class,
            "average_attendance_rate": round(avg_attendance, 2),
            "date_range_days": date_range_days,
            "start_date": start_date.date(),
            "end_date": end_date.date(),
        }
    
    # =========================================================================
    # PATTERN DETECTION
    # =========================================================================
    
    def detect_patterns(
        self,
        start_date: datetime,
        end_date: datetime,
        class_id: Optional[str] = None,
    ) -> Dict:
        """
        Detect attendance patterns and generate recommendations.
        
        Returns:
            Dictionary with patterns and recommendations
        """
        summaries = self.get_student_summaries(start_date, end_date, class_id)
        stats = self.get_attendance_stats(start_date, end_date, class_id)
        
        patterns = []
        recommendations = []
        risk_level = "low"
        
        # Check for high absence rate
        absence_rate = stats["absent_count"] / stats["total_records"] * 100 if stats["total_records"] > 0 else 0
        if absence_rate > 15:
            risk_level = "high"
            patterns.append({
                "pattern_type": "high_absence_rate",
                "description": f"High absence rate detected: {absence_rate:.1f}%",
                "severity": "high",
                "affected_students": [s["student_id"] for s in summaries["summaries"] if s["absent_days"] > 0],
            })
            recommendations.append("Consider investigating reasons for high absences")
            recommendations.append("Send notifications to parents/guardians of frequently absent students")
        
        # Check for students at risk
        at_risk = summaries["students_at_risk"]
        if at_risk > 0:
            if risk_level != "high":
                risk_level = "medium"
            patterns.append({
                "pattern_type": "at_risk_students",
                "description": f"{at_risk} students with attendance below 80%",
                "severity": "high",
                "affected_students": [s["student_id"] for s in summaries["summaries"] if s["at_risk"]],
            })
            recommendations.append("Identify and support at-risk students")
            recommendations.append("Consider one-on-one check-ins with struggling students")
        
        # Check for tardy pattern
        tardy_rate = stats["tardy_count"] / stats["total_records"] * 100 if stats["total_records"] > 0 else 0
        if tardy_rate > 10:
            patterns.append({
                "pattern_type": "tardy_pattern",
                "description": f"Recurring tardiness: {tardy_rate:.1f}% of records",
                "severity": "medium",
                "affected_students": [s["student_id"] for s in summaries["summaries"] if s["tardy_days"] > 0],
            })
            recommendations.append("Review morning procedures and entry policies")
            recommendations.append("Communicate tardiness expectations to students and families")
        
        date_range_days = max((end_date - start_date).days, 1)
        
        return {
            "patterns": patterns,
            "period_duration_days": date_range_days,
            "risk_level": risk_level,
            "recommendations": recommendations,
        }
    
    # =========================================================================
    # PERFORMANCE REPORT
    # =========================================================================
    
    def get_performance_report(
        self,
        start_date: datetime,
        end_date: datetime,
        class_id: Optional[str] = None,
    ) -> Dict:
        """
        Generate comprehensive performance report for students.
        
        Returns:
            Dictionary with performance metrics and categorization
        """
        summaries = self.get_student_summaries(start_date, end_date, class_id)
        
        students = []
        high_performers = []
        at_risk = []
        
        for summary in summaries["summaries"]:
            # Calculate trend (simplified: present days trend)
            recent_records = self.db.query(AttendanceRecord).filter(
                AttendanceRecord.student_id == summary["student_id"],
                AttendanceRecord.scan_time >= (end_date - timedelta(days=7)),
                AttendanceRecord.scan_time <= end_date,
            ).all()
            
            recent_present = sum(1 for r in recent_records if r.status and r.status.lower() == "present")
            recent_total = len(recent_records)
            recent_rate = (recent_present / recent_total * 100) if recent_total > 0 else 0
            
            # Determine trend
            overall_rate = summary["attendance_rate"]
            if recent_rate > overall_rate + 5:
                trend = "improving"
            elif recent_rate < overall_rate - 5:
                trend = "declining"
            else:
                trend = "stable"
            
            # Recent absences (last 7 days)
            recent_absences = self.db.query(AttendanceRecord).filter(
                AttendanceRecord.student_id == summary["student_id"],
                AttendanceRecord.scan_time >= (end_date - timedelta(days=7)),
                AttendanceRecord.scan_time <= end_date,
                AttendanceRecord.status == "absent",
            ).count()
            
            # Performance score (0-100)
            performance_score = (
                (overall_rate / 100 * 60) +  # Attendance rate (60% weight)
                (min(10 - recent_absences, 10) / 10 * 25) +  # Recent absences (25% weight)
                (25 if trend == "improving" else (15 if trend == "stable" else 5))  # Trend (15% weight)
            )
            
            student = {
                "student_id": summary["student_id"],
                "student_name": summary["student_name"],
                "attendance_rate": summary["attendance_rate"],
                "attendance_trend": trend,
                "recent_absences": recent_absences,
                "performance_score": round(performance_score, 2),
            }
            
            students.append(student)
            
            if overall_rate >= 95:
                high_performers.append(student)
            elif summary["at_risk"]:
                at_risk.append(student)
        
        # Calculate overall trend
        overall_rates = [s["attendance_rate"] for s in students]
        if overall_rates:
            avg_rate = sum(overall_rates) / len(overall_rates)
            recent_avg = sum([s["attendance_rate"] for s in students if s["attendance_trend"] == "improving"]) / len([s for s in students if s["attendance_trend"] == "improving"]) if any(s["attendance_trend"] == "improving" for s in students) else avg_rate
            
            if recent_avg > avg_rate:
                overall_trend = "improving"
            elif recent_avg < avg_rate:
                overall_trend = "declining"
            else:
                overall_trend = "stable"
        else:
            overall_trend = "stable"
        
        return {
            "total_students": len(students),
            "students": students,
            "high_performers": high_performers,
            "at_risk_students": at_risk,
            "average_attendance_rate": round(sum(overall_rates) / len(overall_rates) if overall_rates else 0, 2),
            "trend": overall_trend,
        }
