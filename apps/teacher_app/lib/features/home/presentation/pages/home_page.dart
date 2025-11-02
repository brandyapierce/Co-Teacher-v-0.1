import 'package:flutter/material.dart';

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Attendance', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Coming in Week 2', style: Theme.of(context).textTheme.bodyMedium),
        ],
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
          Icon(Icons.rotate_right, size: 64, color: Colors.grey),
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
          Icon(Icons.camera_alt, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Evidence', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Coming in Week 2', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

