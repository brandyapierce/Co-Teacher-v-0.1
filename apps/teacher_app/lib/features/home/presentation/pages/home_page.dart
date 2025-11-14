import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AttendanceTab(),
    const RotationsTab(),
    const EvidenceTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My AI CoTeacher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.face),
            tooltip: 'Face Enrollment',
            onPressed: () => context.push('/enrollment'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rotate_right),
            label: 'Rotations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Evidence',
          ),
        ],
      ),
    );
  }
}

// Placeholder tabs
class AttendanceTab extends StatelessWidget {
  const AttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Attendance Scanning',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Scan your classroom to take attendance automatically',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/attendance/scan');
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Attendance Scan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate to attendance history page
                context.push('/attendance/history');
              },
              icon: const Icon(Icons.history),
              label: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }
}

class RotationsTab extends StatelessWidget {
  const RotationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rotate_right, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Rotations', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Coming in Week 2', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class EvidenceTab extends StatelessWidget {
  const EvidenceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Evidence', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Coming in Week 2', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

