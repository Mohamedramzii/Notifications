import 'package:flutter/material.dart';

class NewPage extends StatelessWidget {
  const NewPage({
    Key? key,
    required this.info,
  }) : super(key: key);
  final String info;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(info),
      ),
    );
  }
}
