import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../settings/settings_view.dart';
import 'job_details_view.dart';
import 'job.dart';

class JobListView extends StatefulWidget {
  static const routeName = '/';
  const JobListView({super.key});
  @override
  _JobListViewState createState() => _JobListViewState();
}

class _JobListViewState extends State<JobListView> {
  List<Job> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final jobRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jobs');
      final jobSnapshot = await jobRef.get();

      if (mounted) {
        setState(() {
          _jobs =
              jobSnapshot.docs.map((doc) => Job.fromFirestore(doc)).toList();
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddJobDialog(BuildContext context, String userId) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final companyController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Job Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter the job title...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'The job title is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: companyController,
                        decoration: const InputDecoration(
                          hintText: 'Enter the company name...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'The company name is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          hintText: 'Enter the job description...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'The job description is required.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add Job'),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final title = titleController.text;
                  final company = companyController.text;
                  final description = descriptionController.text;
                  await _addJobToFirestore(userId, title, company, description);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job added successfully.')),
                  );
                  _fetchJobs();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addJobToFirestore(
      String userId, String title, String company, String description) async {
    try {
      final jobRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jobs');

      await jobRef.add({
        'title': title,
        'company': company,
        'description': description,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('ERROR: $e');
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      String userId, String jobId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Job'),
          content: const Text('Are you sure you want to delete this job?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteJobFromFirestore(userId, jobId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteJobFromFirestore(String userId, String jobId) async {
    try {
      final jobRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jobs')
          .doc(jobId);

      await jobRef.delete();
      setState(() {
        _jobs.removeWhere((job) => job.jobId == jobId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job deleted successfully.')),
      );
    } catch (e) {
      print('ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? const Center(child: Text('No Jobs Found'))
              : ListView.builder(
                  itemCount: _jobs.length,
                  itemBuilder: (BuildContext context, int index) {
                    final job = _jobs[index];
                    return ListTile(
                      title: Text(job.title),
                      leading: const CircleAvatar(
                        child: Icon(Icons.work),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(userId, job.jobId);
                        },
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          JobDetailsView.routeName,
                          arguments: {
                            'job': job,
                            'userId': userId,
                          },
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (userId.isNotEmpty) {
            _showAddJobDialog(context, userId);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
