import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings_controller.dart';
import '../authentication/login.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => Login()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _uploadResume(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) return;

      var file = result.files.single;
      String userId = FirebaseAuth.instance.currentUser!.uid;
      Uint8List? fileBytes = file.bytes;

      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR: Unable to read the file as bytes')),
        );
        return;
      }
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('resumes/$userId.pdf');
      UploadTask uploadTask = ref.putData(fileBytes);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'resumeUrl': downloadUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your resume was uploaded successfully.')),
      );

      final apiUrl = Uri.parse('http://127.0.0.1:5000/extract_resume');
      await http.post(apiUrl,
          body: jsonEncode({'resumeUrl': downloadUrl, 'userId': userId}),
          headers: {
            'Content-Type': 'application/json',
          });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ERROR: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<ThemeMode>(
                  value: controller.themeMode,
                  onChanged: controller.updateThemeMode,
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System Theme'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light Theme'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark Theme'),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _signOut(context),
                  child: const Text('Logout'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _uploadResume(context),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: const Text('Upload Resume'),
            ),
            const SizedBox(height: 10),
            Text(
              'Please note that if you upload a new resume, it will replace the existing one and overwrite the data below based on whatever is extracted from the new document.',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('ERROR: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Text('No user data available');
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                var name = userData['name'] ?? 'N/A';
                var skills = userData['skills'] ?? [];
                var resumeUrl = userData['resumeUrl'];

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(name),
                        const SizedBox(height: 10),
                        const Text(
                          'Skills',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(skills.join(", ")),
                        const SizedBox(height: 20),
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('education')
                              .get(),
                          builder: (context, eduSnapshot) {
                            if (eduSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (eduSnapshot.hasError) {
                              return Text('ERROR: ${eduSnapshot.error}');
                            }

                            var education = eduSnapshot.data?.docs
                                    .map((doc) =>
                                        doc.data() as Map<String, dynamic>)
                                    .toList() ??
                                [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                const Text(
                                  'Education',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...education.map((edu) => Text(
                                    '- ${edu['degree']}, ${edu['institution']}')),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('experience')
                              .get(),
                          builder: (context, expSnapshot) {
                            if (expSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (expSnapshot.hasError) {
                              return Text('ERROR: ${expSnapshot.error}');
                            }

                            var experience = expSnapshot.data?.docs
                                    .map((doc) =>
                                        doc.data() as Map<String, dynamic>)
                                    .toList() ??
                                [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                const Text(
                                  'Experience',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...experience.map((exp) => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '- ${exp['role']}, ${exp['company']}'),
                                        Text(
                                          '${exp['responsibilities']}',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    )),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        resumeUrl != null && resumeUrl.isNotEmpty
                            ? GestureDetector(
                                onTap: () async {
                                  if (await canLaunch(resumeUrl)) {
                                    await launch(resumeUrl);
                                  }
                                },
                                child: Text(
                                  'Click to download resume',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              )
                            : Text(
                                'No resume uploaded',
                                style: TextStyle(color: Colors.grey),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
