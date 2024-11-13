import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CoverLetter extends StatefulWidget {
  final String userId;
  final String jobId;

  CoverLetter({required this.userId, required this.jobId});

  @override
  _CoverLetterState createState() => _CoverLetterState();
}

class _CoverLetterState extends State<CoverLetter> {
  String? coverLetter;
  bool isLoading = false;

  // Function to call the API to generate the cover letter
  Future<void> generateCoverLetter() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('http://your-server-url/write_cover_letter'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'userId': widget.userId,
        'jobId': widget.jobId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        coverLetter = _removeQuotes(data['cover_letter']);
        isLoading = false;
      });

      // Save the generated cover letter to Firestore
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('jobs')
          .doc(widget.jobId)
          .set({
        'cover_letter': coverLetter,
      }, SetOptions(merge: true));
    } else {
      setState(() {
        isLoading = false;
      });
      print('Error generating cover letter: ${response.body}');
    }
  }

  @override
  void initState() {
    super.initState();
    loadCoverLetter();
  }

  // Function to load the cover letter from Firestore
  Future<void> loadCoverLetter() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('jobs')
        .doc(widget.jobId)
        .get();

    if (doc.exists) {
      setState(() {
        coverLetter = _removeQuotes(doc['cover_letter']);
      });
    }
  }

  // Helper function to remove leading and trailing quotes
  String _removeQuotes(String text) {
    if (text.startsWith('"') && text.endsWith('"')) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }

  // Function to copy the cover letter to clipboard
  void copyToClipboard() {
    if (coverLetter != null) {
      Clipboard.setData(ClipboardData(text: coverLetter!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cover letter copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: isLoading ? null : generateCoverLetter,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
            ),
            child: isLoading
                ? CircularProgressIndicator()
                : Text('Regenerate Cover Letter'),
          ),
          SizedBox(height: 16.0),
          if (coverLetter != null)
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        coverLetter!.replaceAll(r'\n', '\n'),
                        style: TextStyle(fontSize: 16.0, height: 1.5),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  ElevatedButton.icon(
                    onPressed: copyToClipboard,
                    icon: Icon(Icons.copy),
                    label: Text("Copy to Clipboard"),
                  ),
                ],
              ),
            )
          else if (isLoading)
            Center(child: CircularProgressIndicator())
          else
            Text(
              'No cover letter generated yet. Please click "Regenerate Cover Letter" to generate one.',
              style: TextStyle(fontSize: 16.0),
            ),
        ],
      ),
    );
  }
}
