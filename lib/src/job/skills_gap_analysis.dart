import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SkillsGapAnalysis extends StatefulWidget {
  final String userId;
  final String jobId;

  const SkillsGapAnalysis({Key? key, required this.userId, required this.jobId})
      : super(key: key);

  @override
  _SkillsGapAnalysisState createState() => _SkillsGapAnalysisState();
}

class _SkillsGapAnalysisState extends State<SkillsGapAnalysis> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _skillsGapAnalysis = [];
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchSkillsGapAnalysis();
  }

  Future<void> _fetchSkillsGapAnalysis() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final gapQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('jobs')
          .doc(widget.jobId)
          .collection('skills_gap_analysis')
          .get();
      if (gapQuerySnapshot.docs.isNotEmpty) {
        _skillsGapAnalysis = gapQuerySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'skill_gap': data['skill_gap'] ?? 'Unknown skill gap',
            'description': data['description'] ?? 'No description provided',
            'recommendations': data['recommendations'] is List
                ? List<String>.from(data['recommendations'])
                : ['No recommendations available'],
          };
        }).toList();

        setState(() {
          _hasError = false;
        });
      } else {
        print(
            "No documents in 'skills_gap_analysis' collection; regenerating.");
        _regenerateSkillsGapAnalysis();
      }
    } catch (e) {
      print("Error fetching skills gap analysis: $e");
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _regenerateSkillsGapAnalysis() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/analyze_skills_gap'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': widget.userId,
          'jobId': widget.jobId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<Map<String, dynamic>> analysis =
            List<Map<String, dynamic>>.from(responseData['analysis']);

        setState(() {
          _skillsGapAnalysis = analysis;
        });

        await _saveSkillsGapAnalysisToFirestore(analysis);
      } else {
        setState(() {
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSkillsGapAnalysisToFirestore(
      List<Map<String, dynamic>> analysis) async {
    final skillsGapRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('jobs')
        .doc(widget.jobId)
        .collection('skills_gap_analysis');

    final existingDocs = await skillsGapRef.get();
    for (var doc in existingDocs.docs) {
      await doc.reference.delete();
    }

    for (var gap in analysis) {
      await skillsGapRef.add({
        'skill_gap': gap['skill_gap'],
        'description': gap['description'],
        'recommendations': gap['recommendations'],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? const Center(
                    child: Text(
                        'ERROR: The skill gap analysis could not be fetched.'),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          onPressed: _regenerateSkillsGapAnalysis,
                          child: const Text('Regenerate Analysis'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _skillsGapAnalysis.isEmpty
                            ? const Text('No skill gap analysis found')
                            : Column(
                                children: _skillsGapAnalysis.map((gap) {
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Skill Gap',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(gap['skill_gap'] ?? ''),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Description',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(gap['description'] ?? ''),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Recommendations',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: gap['recommendations']
                                                .map<Widget>((rec) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8.0),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text("• "),
                                                          Expanded(
                                                            child: Text(rec),
                                                          ),
                                                        ],
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
