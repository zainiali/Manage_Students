import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SentRequestsScreen extends StatefulWidget {
  final String userId;

  const SentRequestsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<SentRequestsScreen> createState() => _SentRequestsScreenState();
}

class _SentRequestsScreenState extends State<SentRequestsScreen> {
  bool isLoading = true;
  List<dynamic> allRequests = [];

  @override
  void initState() {
    super.initState();
    fetchFriendRequests();
  }

  Future<void> fetchFriendRequests() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://devtechtop.com/store/public/api/all_user'),
        headers: {'Accept': 'application/json'},
        body: {'user_id': widget.userId},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        // Filter out requests where receiver is null or missing
        final filtered = (data['data'] as List)
            .where((request) => request['receiver'] != null)
            .toList();

        setState(() {
          allRequests = filtered;
          isLoading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to load requests');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void navigateToProfile(String userId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('$name\'s Profile')),
          body: Center(child: Text('Profile of user ID: $userId')),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sent Friend Requests'),
        backgroundColor: Colors.indigo,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allRequests.isEmpty
          ? const Center(child: Text('No sent friend requests found.'))
          : ListView.builder(
        itemCount: allRequests.length,
        itemBuilder: (context, index) {
          final request = allRequests[index];
          final receiver = request['receiver'];

          final name = receiver['name'] ?? 'Unknown';
          final email = receiver['email'] ?? '';
          final userId = receiver['id']?.toString() ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              onTap: () => navigateToProfile(userId, name),
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade100,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
              ),
              title: Text(name),
              subtitle: Text(email),
              trailing: const Text('Sent'),
            ),
          );
        },
      ),
    );
  }
}
