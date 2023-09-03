import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class ScreenPostDetails extends StatelessWidget {
  String title;
  dynamic post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Html(data: (post['content']['rendered']).toString()),
    );
  }

  ScreenPostDetails({
    required this.title,
    required this.post,
  });
}
