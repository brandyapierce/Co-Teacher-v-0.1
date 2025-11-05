#!/usr/bin/env python3
"""Import sample data into database"""

from app.utils.oneroster_importer import OneRosterImporter

def main():
    print("Starting data import...")
    importer = OneRosterImporter()
    
    # Import teachers
    print("Importing teachers...")
    teachers_result = importer.import_teachers('sample_data/teachers.csv')
    print(f"Teachers - Imported: {teachers_result['imported']}, Errors: {teachers_result['errors']}")
    
    # Import students
    print("Importing students...")
    students_result = importer.import_students('sample_data/students.csv')
    print(f"Students - Imported: {students_result['imported']}, Errors: {students_result['errors']}")
    
    importer.close()
    print("Data import complete!")

if __name__ == "__main__":
    main()

