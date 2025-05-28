import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'friends_list_screen.dart'; // Assuming you have this file
import 'package:flutter_animate/flutter_animate.dart';

class AllUsersScreen extends StatefulWidget {
  final String? userId;
  const AllUsersScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool isLoading = true;
  Map<String, TextEditingController> descriptionControllers = {};
  TextEditingController searchController = TextEditingController();
  Set<String> expandedUsers = {};
  Set<String> sentRequests = {};

  @override
  void initState() {
    super.initState();
    fetchAllUsers(widget.userId);
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    for (var controller in descriptionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredUsers = users.where((user) =>
      user['name'].toString().toLowerCase().contains(query) ||
          user['email'].toString().toLowerCase().contains(query)).toList();
    });
  }

  Future<void> fetchAllUsers(String? userId) async {
    setState(() => isLoading = true);
    try {
      Map<String, String> body = {};
      if (userId != null && userId.isNotEmpty && userId != 'default') {
        body['user_id'] = userId;
      }
      final response = await http.post(
        Uri.parse('https://devtechtop.com/store/public/api/all_user'),
        headers: {'Accept': 'application/json'},
        body: body,
      );
      final data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['data'] is List) {
        setState(() {
          users = data['data'];
          filteredUsers = users;
          sentRequests.clear();

          for (var controller in descriptionControllers.values) {
            controller.dispose();
          }
          descriptionControllers.clear();

          for (var user in users) {
            String id = user['id'].toString();
            descriptionControllers[id] = TextEditingController();

            if (user['is_request_sent'] == true || user['request_status'] == 'pending') {
              sentRequests.add(id);
            }
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to load users')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> sendFriendRequest({
    required String senderId,
    required String receiverId,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://devtechtop.com/store/public/api/scholar_request/insert'),
        headers: {'Accept': 'application/json'},
        body: {
          'sender_id': senderId,
          'receiver_id': receiverId,
          'description': description,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          descriptionControllers[receiverId]?.clear();
          sentRequests.add(receiverId); // Mark request as sent
          expandedUsers.remove(receiverId); // Close input box after sending
        });

        // Show success dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Request Sent'),
            content: Text(data['message'] ?? 'Request sent successfully.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
            ],
          ),
        );
      } else {
        // Build error message
        String errorMsg = '';
        if (data['errors'] != null && data['errors'] is Map) {
          data['errors'].forEach((key, value) {
            errorMsg += '$key: ${value.join(', ')}\n';
          });
        } else {
          errorMsg = data['message'] ?? 'Unknown error';
        }

        // Show error dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Failed'),
            content: Text(errorMsg),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
            ],
          ),
        );
      }
    } catch (e) {
      // Exception dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exception'),
          content: Text('Exception: $e'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('All Users',
            style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.indigo),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (widget.userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SentRequestsScreen(userId: widget.userId!)),
                );
              }
            },
            icon: const Icon(Icons.people, color: Colors.indigo),
            label: const Text('Requests', style: TextStyle(color: Colors.indigo)),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => fetchAllUsers(widget.userId),
              child: ListView.builder(
                itemCount: filteredUsers.length,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final userId = user['id'].toString();
                  final userName = user['name'] ?? '';
                  final userEmail = user['email'] ?? '';
                  final userShift = user['shift'] ?? 'N/A';
                  final userDegree = user['degree'] ?? 'N/A';
                  final isExpanded = expandedUsers.contains(userId);

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.indigo.shade100,
                                child: Text(
                                  userName.isNotEmpty
                                      ? userName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(userName,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Text(userEmail),
                                    Text('Shift: $userShift'),
                                    Text('Degree: $userDegree'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: isExpanded
                                ? Column(
                              key: ValueKey('expanded_$userId'),
                              children: [
                                TextField(
                                  controller:
                                  descriptionControllers[userId],
                                  decoration: const InputDecoration(
                                    hintText: "Enter description...",
                                    filled: true,
                                    fillColor: Color(0xFFF4F4F4),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ).animate().fade().slideX(),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => setState(() =>
                                          expandedUsers.remove(userId)),
                                      child: const Text("Cancel"),
                                    ).animate().scale(),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        final description =
                                        descriptionControllers[
                                        userId]!
                                            .text
                                            .trim();
                                        if (description.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Please enter a description')));
                                          return;
                                        }
                                        sendFriendRequest(
                                          senderId: widget.userId!,
                                          receiverId: userId,
                                          description: description,
                                        );
                                      },
                                      icon: const Icon(Icons.send),
                                      label: const Text("Send"),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.indigo,
                                        shape:
                                        RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(
                                                8)),
                                      ),
                                    ).animate().shake(),
                                  ],
                                ),
                              ],
                            )
                                : sentRequests.contains(userId)
                                ? Align(
                              key: ValueKey('pending_$userId'),
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.white),
                                label: const Text("Pending"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(8)),
                                ),
                              ),
                            ).animate().fade()
                                : Align(
                              key: ValueKey('button_$userId'),
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => setState(() =>
                                    expandedUsers.add(userId)),
                                icon: const Icon(Icons.send),
                                label: const Text("Send Request"),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.indigo,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(8)),
                                ),
                              ).animate().scale(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
