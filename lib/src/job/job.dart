import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String jobId;
  final String title;
  final String description;
  final String company;

  Job({
    required this.jobId,
    required this.title,
    required this.description,
    required this.company,
  });

  factory Job.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Job(
      jobId: doc.id,
      description: data['description'] ?? '',
      title: data['title'] ?? '',
      company: data['company'] ?? '',
    );
  }
}
