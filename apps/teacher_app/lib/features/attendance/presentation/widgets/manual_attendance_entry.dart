import 'package:flutter/material.dart';

/// Widget for manually entering attendance when face detection fails
class ManualAttendanceEntry extends StatefulWidget {
  final List<StudentInfo> students;
  final Function(String studentId, String studentName, String status, String? notes) onSubmit;
  final VoidCallback onCancel;

  const ManualAttendanceEntry({
    super.key,
    required this.students,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<ManualAttendanceEntry> createState() => _ManualAttendanceEntryState();
}

class _ManualAttendanceEntryState extends State<ManualAttendanceEntry> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  List<StudentInfo> _filteredStudents = [];
  StudentInfo? _selectedStudent;
  String _selectedStatus = 'present';
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _filteredStudents = widget.students;
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = widget.students.where((student) {
        final matchesSearch = student.name.toLowerCase().contains(query);
        final matchesFilter = _selectedFilter == null || 
            student.name.toUpperCase().startsWith(_selectedFilter!);
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _applyAlphaFilter(String? letter) {
    setState(() {
      _selectedFilter = letter;
      _filterStudents();
    });
  }

  void _submit() {
    if (_selectedStudent != null) {
      widget.onSubmit(
        _selectedStudent!.id,
        _selectedStudent!.name,
        _selectedStatus,
        _notesController.text.isEmpty ? null : _notesController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Manual Attendance Entry',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search student name...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),

            // Alphabetical Filter
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('All', null),
                  const SizedBox(width: 8),
                  ...List.generate(26, (index) {
                    final letter = String.fromCharCode(65 + index); // A-Z
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(letter, letter),
                    );
                  }),
                ],
              ),
            ),

            const Divider(height: 1),

            // Student List
            Expanded(
              child: _filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No students found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        final isSelected = _selectedStudent?.id == student.id;
                        
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            child: Text(
                              _getInitials(student.name),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: student.grade != null
                              ? Text('Grade ${student.grade}')
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedStudent = student;
                            });
                          },
                        );
                      },
                    ),
            ),

            // Selected Student Details
            if (_selectedStudent != null) ...[
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected: ${_selectedStudent!.name}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Status Selection
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildStatusChip('Present', 'present', Colors.green),
                        _buildStatusChip('Absent', 'absent', Colors.red),
                        _buildStatusChip('Tardy', 'tardy', Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes Field
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add any notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedStudent != null ? _submit : null,
                      child: const Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _applyAlphaFilter(value),
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedStatus = value;
        });
      },
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }
}

/// Student info model for manual entry
class StudentInfo {
  final String id;
  final String name;
  final String? grade;

  const StudentInfo({
    required this.id,
    required this.name,
    this.grade,
  });
}

