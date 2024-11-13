import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InterviewQuestions extends StatefulWidget {
  final String userId;
  final String jobId;

  InterviewQuestions({required this.userId, required this.jobId});

  @override
  _InterviewQuestionsState createState() => _InterviewQuestionsState();
}

class _InterviewQuestionsState extends State<InterviewQuestions> {
  List<String> _interviewQuestions = [];
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchInterviewQuestions();
  }

  // Fetch interview questions from Firestore (array field)
  Future<void> _fetchInterviewQuestions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final jobDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('jobs')
          .doc(widget.jobId)
          .get();

      if (jobDoc.exists) {
        final data = jobDoc.data();
        if (data != null && data.containsKey('interview_questions')) {
          // Cast the interview_questions field as a List<String>
          _interviewQuestions =
              List<String>.from(data['interview_questions'] ?? []);

          setState(() {
            _hasError = false;
          });
        } else {
          print("No interview questions found in Firestore, regenerating.");
          _regenerateInterviewQuestions();
        }
      } else {
        print("Job data not found.");
        setState(() {
          _hasError = true;
        });
      }
    } catch (e) {
      print("Error fetching interview questions: $e");
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Regenerate interview questions using API
  Future<void> _regenerateInterviewQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/generate_interview_questions'),
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
        List<String> questions =
            List<String>.from(responseData['interview_questions']);

        setState(() {
          _interviewQuestions = questions;
        });

        await _saveInterviewQuestionsToFirestore(questions);
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

  // Save the regenerated questions to Firestore (as an array field)
  Future<void> _saveInterviewQuestionsToFirestore(
      List<String> questions) async {
    try {
      final jobRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('jobs')
          .doc(widget.jobId);

      await jobRef.update({
        'interview_questions': questions,
      });
    } catch (e) {
      print("Error saving interview questions to Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // No app bar
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _regenerateInterviewQuestions,
              child: Text('Regenerate Questions'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _hasError
                    ? Center(child: Text('An error occurred, try again later.'))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _interviewQuestions.length,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  _interviewQuestions[index],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
