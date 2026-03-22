import 'package:flutter/material.dart';
import '../services/project_service.dart';

class ProjectHubScreen extends StatefulWidget {
  final String groupId;

  const ProjectHubScreen({super.key, required this.groupId});

  @override
  State<ProjectHubScreen> createState() => _ProjectHubScreenState();
}

class _ProjectHubScreenState extends State<ProjectHubScreen>
    with SingleTickerProviderStateMixin {
  final ProjectService projectService = ProjectService();
  late TabController _tabController;

  List allProjects = [];
  List activeProjects = [];
  List completedProjects = [];
  List requestProjects = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    loadProjects();
  }

  Future<void> loadProjects() async {
    final all = await projectService.getProjects(widget.groupId);
    final active = await projectService.getProjectsByStatus(
      widget.groupId,
      'Active',
    );
    final completed = await projectService.getProjectsByStatus(
      widget.groupId,
      'Completed',
    );
    final requests = await projectService.getProjectsByStatus(
      widget.groupId,
      'Request',
    );

    setState(() {
      allProjects = all;
      activeProjects = active;
      completedProjects = completed;
      requestProjects = requests;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Hub'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProjectList(allProjects),
          _buildProjectList(activeProjects),
          _buildProjectList(completedProjects),
          _buildProjectList(requestProjects),
        ],
      ),
    );
  }

  Widget _buildProjectList(List projects) {
    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(label: Text(project['category'] ?? '')),
                    const Spacer(),
                    Text('${project['completion'] ?? 0}%'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  project['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(
                      (project['members'] as List<dynamic>?)?.length ?? 0,
                      (i) => CircleAvatar(
                        child: Text(
                          (project['members'][i] as String).substring(0, 1),
                        ),
                      ),
                    ),
                    if (((project['members'] as List<dynamic>?)?.length ?? 0) >
                        3)
                      Text(
                        '+${(project['members'] as List<dynamic>?)!.length - 3}',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Next: ${project['next_step'] ?? ''}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
