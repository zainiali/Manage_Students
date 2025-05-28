import 'package:flutter/material.dart';

class SendRequestScreen extends StatelessWidget {
  const SendRequestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Request'),
      ),
      body: const Center(
        child: Text('This is the Send Request screen'),
      ),
    );
  }
}
