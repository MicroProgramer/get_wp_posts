import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ScreenPostDetails extends StatelessWidget {
  String title;
  dynamic post;

  @override
  Widget build(BuildContext context) {
    var htmlString = (post['content']['rendered']).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: WebViewWidget(
        controller: WebViewController()..loadHtmlString(htmlString),
      ),
    );
  }

  ScreenPostDetails({
    required this.title,
    required this.post,
  });
}
