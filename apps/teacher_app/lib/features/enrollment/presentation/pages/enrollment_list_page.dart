import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Using mock CV service for now due to TFLite Windows compilation issues
import '../../../../shared/data/services/cv_service_mock.dart';

/// Page showing list of enrolled students and enrollment management
class EnrollmentListPage extends StatefulWidget {
  const EnrollmentListPage({super.key});

  @override
  State<EnrollmentListPage> createState() => _EnrollmentListPageState();
}

class _EnrollmentListPageState extends State<EnrollmentListPage> {
  final CVServiceMock _cvService = CVServiceMock();
  List<String> _enrolledStudents = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadEnrolledStudents();
  }
  
  Future<void> _loadEnrolledStudents() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _cvService.initialize();
      final students = await _cvService.getEnrolledStudents();
      
      if (mounted) {
        setState(() {
          _enrolledStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }
  
  Future<void> _deleteStudent(String studentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Enrollment'),
        content: Text('Are you sure you want to delete enrollment for student $studentId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _cvService.deleteFaceTemplate(studentId);
        await _loadEnrolledStudents();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enrollment deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting enrollment: $e')),
          );
        }
      }
    }
  }
  
  void _startEnrollment() {
    // For demo, use a simple dialog to get student info
    // In production, this would select from a list of students
    showDialog(
      context: context,
      builder: (context) {
        String studentId = '';
        String studentName = '';
        
        return AlertDialog(
          title: const Text('New Enrollment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  hintText: 'e.g., S12345',
                ),
                onChanged: (value) => studentId = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  hintText: 'e.g., John Doe',
                ),
                onChanged: (value) => studentName = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (studentId.isNotEmpty && studentName.isNotEmpty) {
                  Navigator.pop(context);
                  context.push(
                    '/enrollment/capture',
                    extra: {
                      'studentId': studentId,
                      'studentName': studentName,
                    },
                  ).then((_) => _loadEnrolledStudents());
                }
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Enrollment'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrolledStudents.isEmpty
              ? _buildEmptyState()
              : _buildEnrolledList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startEnrollment,
        icon: const Icon(Icons.add),
        label: const Text('Enroll Student'),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Students Enrolled',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the button below to enroll your first student.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEnrolledList() {
    return ListView.builder(
      itemCount: _enrolledStudents.length,
      itemBuilder: (context, index) {
        final studentId = _enrolledStudents[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text('Student ID: $studentId'),
            subtitle: const Text('Face template enrolled'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Enrolled',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteStudent(studentId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

