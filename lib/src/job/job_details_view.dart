import 'package:flutter/material.dart';
import 'package:virgo/src/job/cover_letter.dart';
import 'package:virgo/src/job/interview_questions.dart';
import 'package:virgo/src/job/learning_pathway.dart';
import 'package:virgo/src/job/skills_gap_analysis.dart';
import 'job.dart';

class JobDetailsView extends StatefulWidget {
  static const routeName = '/job_details';

  const JobDetailsView({super.key});

  @override
  _JobDetailsViewState createState() => _JobDetailsViewState();
}

class _JobDetailsViewState extends State<JobDetailsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Job job;
  late String userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      job = args['job'];
      userId = args['userId'];
    } else {
      print('ERROR: Job or user could not be found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(job.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Job Description'),
            Tab(text: 'Skill Gap Analysis'),
            Tab(text: 'Learning Pathway'),
            Tab(text: 'Interview'),
            Tab(text: 'Cover Letter'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Job Description Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job.company,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                SkillsGapAnalysis(userId: userId, jobId: job.jobId),
                LearningPathway(userId: userId, jobId: job.jobId),
                InterviewQuestions(userId: userId, jobId: job.jobId),
                CoverLetter(userId: userId, jobId: job.jobId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
