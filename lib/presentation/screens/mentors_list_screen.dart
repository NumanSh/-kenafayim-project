import "package:flutter/material.dart";

class MentorsListScreen extends StatelessWidget {
  const MentorsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("מנחים")),
      body: const Center(child: Text("מסך רשימת מנחים - תוכן יתווסף בהמשך")),
    );
  }
}

