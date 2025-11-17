import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/student_list_cubit.dart';
import '../providers/student_list_state.dart';
import '../widgets/student_card.dart';

/// Student list page showing all students
/// 
/// EDUCATIONAL NOTE - Complete Feature Page:
/// This page demonstrates:
/// - BLoC state management
/// - Pull-to-refresh
/// - Search functionality
/// - Empty states
/// - Error handling
/// - List rendering

class StudentListPage extends StatelessWidget {
  const StudentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StudentListCubit(),
      child: const _StudentListView(),
    );
  }
}

class _StudentListView extends StatefulWidget {
  const _StudentListView();

  @override
  State<_StudentListView> createState() => _StudentListViewState();
}

class _StudentListViewState extends State<_StudentListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    context.read<StudentListCubit>().updateSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<StudentListCubit>().refreshStudents();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<StudentListCubit>().clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),

          // Student list
          Expanded(
            child: BlocBuilder<StudentListCubit, StudentListState>(
              builder: (context, state) {
                // Loading state
                if (state.isLoading && state.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading students...'),
                      ],
                    ),
                  );
                }

                // Error state
                if (state.hasError && state.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage ?? 'Failed to load students',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<StudentListCubit>().loadStudents();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                // Empty state
                if (state.filteredStudents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          state.searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.people_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.searchQuery.isNotEmpty
                              ? 'No students match "${state.searchQuery}"'
                              : 'No students found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Add students to get started',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Success state - show list
                return RefreshIndicator(
                  onRefresh: () => context.read<StudentListCubit>().refreshStudents(),
                  child: Column(
                    children: [
                      // Results count
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              '${state.filteredCount} student${state.filteredCount == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            if (state.searchQuery.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(state.searchQuery),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                  _searchController.clear();
                                  context.read<StudentListCubit>().clearSearch();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Student list
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.filteredStudents.length,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemBuilder: (context, index) {
                            final student = state.filteredStudents[index];
                            return StudentCard(
                              student: student,
                              index: index,
                              onTap: () {
                                // TODO: Navigate to student detail
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Tapped: ${student.fullName}'),
                                  ),
                                );
                              },
                              onDelete: () async {
                                // Show confirmation
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Student?'),
                                    content: Text(
                                      'Are you sure you want to delete ${student.fullName}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true && context.mounted) {
                                  final success = await context
                                      .read<StudentListCubit>()
                                      .deleteStudent(student.id);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Student deleted'
                                              : 'Failed to delete student',
                                        ),
                                        backgroundColor:
                                            success ? Colors.green : Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add student page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add student feature coming soon!')),
          );
        },
        tooltip: 'Add Student',
        child: const Icon(Icons.add),
      ),
    );
  }
}

