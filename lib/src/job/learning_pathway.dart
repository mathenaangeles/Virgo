import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class LearningPathway extends StatefulWidget {
  final String userId;
  final String jobId;

  const LearningPathway({Key? key, required this.userId, required this.jobId})
      : super(key: key);

  @override
  _LearningPathwayState createState() => _LearningPathwayState();
}

class _LearningPathwayState extends State<LearningPathway> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _learningPathway = [];
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchLearningPathway();
  }

  Future<void> _fetchLearningPathway() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Try fetching existing pathway data from Firestore
      final pathwayQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('jobs')
          .doc(widget.jobId)
          .collection('learning_pathway')
          .get();

      if (pathwayQuerySnapshot.docs.isNotEmpty) {
        _learningPathway = pathwayQuerySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'resource_name': data['resource_name'] ?? 'No title available',
            'link': data['link'] ?? 'No link available',
            'summary': data['summary'] ?? 'No summary available',
          };
        }).toList();

        setState(() {
          _hasError = false;
        });
      } else {
        // If no data found, regenerate pathway
        _regenerateLearningPathway();
      }
    } catch (e) {
      print("Error fetching learning pathway: $e");
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _regenerateLearningPathway() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/create_learning_pathway'),
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
        List<Map<String, dynamic>> pathway =
            List<Map<String, dynamic>>.from(responseData);

        setState(() {
          _learningPathway = pathway;
        });

        // Save the generated pathway to Firestore
        await _saveLearningPathwayToFirestore(pathway);
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

  Future<void> _saveLearningPathwayToFirestore(
      List<Map<String, dynamic>> pathway) async {
    final learningPathwayRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('jobs')
        .doc(widget.jobId)
        .collection('learning_pathway');

    // Delete existing learning pathway documents
    final existingDocs = await learningPathwayRef.get();
    for (var doc in existingDocs.docs) {
      await doc.reference.delete();
    }

    // Add the new resources to Firestore
    for (var resource in pathway) {
      await learningPathwayRef.add({
        'resource_name': resource['resource_name'],
        'link': resource['link'],
        'summary': resource['summary'],
      });
    }
  }

  // Function to open the URL in the browser
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
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
                        'ERROR: The learning pathway could not be fetched.'),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Regenerate Pathway Button at the top
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _regenerateLearningPathway,
                            child: const Text('Regenerate Pathway'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _learningPathway.isEmpty
                            ? const Text('No learning pathway found')
                            : Column(
                                children: _learningPathway.map((resource) {
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Make the course title clickable
                                          InkWell(
                                            onTap: () =>
                                                _launchURL(resource['link']),
                                            child: Text(
                                              resource['resource_name'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                              'Summary: ${resource['summary']}'),
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
