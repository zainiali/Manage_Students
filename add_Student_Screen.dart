import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class Student {
  final String studentId;
  final String studentName;
  final String studentDepartment;
  final String? studentPhoto;

  Student({
    required this.studentId,
    required this.studentName,
    required this.studentDepartment,
    this.studentPhoto,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name'] ?? 'Unknown',
      studentDepartment: json['student_department'] ?? 'Unknown',
      studentPhoto: json['student_photo'],
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StudentScreen(),
    );
  }
}

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  List<Student> students = [];
  bool isLoading = false;

  final idController = TextEditingController();
  final nameController = TextEditingController();
  final deptController = TextEditingController();

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  @override
  void dispose() {
    idController.dispose();
    nameController.dispose();
    deptController.dispose();
    super.dispose();
  }

  Future<void> fetchStudents() async {
    setState(() => isLoading = true);
    final url = Uri.parse('https://api.cscollaborators.online/api/student_data');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        List data;
        if (jsonResponse is List) {
          data = jsonResponse;
        } else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
          data = jsonResponse['data'];
        } else {
          data = [];
        }

        setState(() {
          students = data.map((json) => Student.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch students')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching students: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> addStudent() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('https://api.cscollaborators.online/api/store_students');

    var request = http.MultipartRequest('POST', url);
    request.fields['student_id'] = idController.text.trim();
    request.fields['student_name'] = nameController.text.trim();
    request.fields['student_department'] = deptController.text.trim();

    if (_selectedImage != null) {
      String mimeType = _selectedImage!.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      request.files.add(await http.MultipartFile.fromPath(
        'student_photo',
        _selectedImage!.path,
        contentType: MediaType('image', mimeType),
      ));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student Added')),
        );
        idController.clear();
        nameController.clear();
        deptController.clear();
        setState(() {
          _selectedImage = null;
        });
        await fetchStudents();
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to add student';
        if (errorData is Map && errorData.containsKey('errors')) {
          errorMessage = errorData['errors'].values.expand((list) => list).join('\n');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteStudent(String studentId) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('https://api.cscollaborators.online/api/student/$studentId');

    final response = await http.delete(url);

    if (response.statusCode == 200 || response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student Deleted')),
      );
      await fetchStudents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete student')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }


  void _confirmDelete(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.studentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              deleteStudent(student.studentId.toString()); // Ensure it's a string
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar(Student student) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.7),
            blurRadius: 8,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        student.studentName.isNotEmpty ? student.studentName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 36,
          color: Color(0xFF0072FF),
        ),
      ),
    );
  }

  void _showImageZoom(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1,
            maxScale: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    width: 300,
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 300,
                  height: 300,
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentCard(Student student, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.blue.withOpacity(0.3),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        leading: GestureDetector(
          onTap: () {
            if (student.studentPhoto != null && student.studentPhoto!.isNotEmpty) {
              _showImageZoom(
                'https://api.cscollaborators.online/${student.studentPhoto!.replaceAll(' ', '%20')}',
              );
            }
          },
          child: student.studentPhoto != null && student.studentPhoto!.isNotEmpty
              ? Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: const Offset(2, 3),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(
                  'https://api.cscollaborators.online/${student.studentPhoto!.replaceAll(' ', '%20')}',
                ),
                fit: BoxFit.cover,
              ),
            ),
          )
              : _buildPlaceholderAvatar(student),
        ),
        title: Text(
          student.studentName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0072FF),
            fontSize: 20,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ID: ${student.studentId}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                "Dept: ${student.studentDepartment}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 32),
          onPressed: () => _confirmDelete(student),
          tooltip: 'Delete Student',
        ),
      ),
    );
  }

  void _openAddStudentDialog() {
    idController.clear();
    nameController.clear();
    deptController.clear();
    setState(() {
      _selectedImage = null;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: deptController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade100,
                    ),
                    child: _selectedImage == null
                        ? const Center(
                      child: Text(
                        'Tap to select photo',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (idController.text.trim().isEmpty ||
                    nameController.text.trim().isEmpty ||
                    deptController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                await addStudent();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade100, // Changed from blue to light indigo
        foregroundColor: Colors.indigo.shade900, // Changed from white to dark indigo
        title: const Text('Student Management'),
        actions: [
          IconButton(
            onPressed: fetchStudents,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh List',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddStudentDialog,
        label: const Text('Add Student'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF0072FF), // original blue
      ),
      body: isLoading && students.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
          ? Center(
        child: Text(
          'No students found.',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchStudents,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 100, top: 10),
          itemCount: students.length,
          itemBuilder: (context, index) {
            return _buildStudentCard(students[index], theme);
          },
        ),
      ),
    );
  }
}
