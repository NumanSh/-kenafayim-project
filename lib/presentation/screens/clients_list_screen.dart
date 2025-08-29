import "package:flutter/material.dart";

class ClientsListScreen extends StatelessWidget {
  final String? mentorId;
  final bool isAdmin;
  const ClientsListScreen({Key? key, this.mentorId, this.isAdmin = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("אמנים")),
      body: const Center(child: Text("מסך רשימת אמנים - תוכן יתווסף בהמשך")),
    );
  }
}

