"""Create face templates and enrollment tables

Revision ID: 001_initial_enrollment
Revises:
Create Date: 2024-11-26 10:00:00.000000

This migration creates the face_templates table for storing student face embeddings
used by the Computer Vision pipeline for face enrollment and attendance recognition.
"""

from sqlalchemy import Table, Column, Integer, String, Text, DateTime, Float, ForeignKey
from sqlalchemy.orm import declarative_base

# This is a reference for manual migration if needed
# In production, use: alembic upgrade head

Base = declarative_base()

def create_face_templates_table():
    """Create the face_templates table"""
    return Table(
        'face_templates',
        Base.metadata,
        Column('id', Integer, primary_key=True, index=True),
        Column('student_id', String, ForeignKey('students.id'), nullable=False),
        Column('embedding_data', Text, nullable=False),  # Pickled embedding
        Column('created_at', DateTime, nullable=False),
        Column('updated_at', DateTime, nullable=False),
    )
