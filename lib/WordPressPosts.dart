import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_wp_posts/screen_post_details.dart';
import 'package:http/http.dart' as http;


class WordPressPosts extends StatefulWidget {
  @override
  _WordPressPostsState createState() => _WordPressPostsState();
}

class _WordPressPostsState extends State<WordPressPosts> {
  List<dynamic> posts = [];
  int currentPage = 1;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    fetchWordPressPosts();
  }

  Future<void> fetchWordPressPosts() async {
    while (currentPage <= totalPages) {
      final response = await http.get(
        Uri.parse(
            'https://ahmadiyyafactcheckblog.com/wp-json/wp/v2/posts?page=$currentPage&per_page=100'), // Replace with the correct URL of the website
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          posts.addAll(data);
          currentPage++;
          totalPages = int.parse(response.headers['x-wp-totalpages']!);
        });
      } else {
        throw Exception('Failed to load WordPress posts');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WordPress Posts'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text("Posts fetched"),
            trailing: Text("${posts.length}"),
            subtitle: Text("Fetched pages: $currentPage, Total Pages: $totalPages"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (BuildContext context, int index) {
                final post = posts[index];
                return ListTile(
                  onTap: (){
                    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => ScreenPostDetails(title: post['title']['rendered'].toString(), post: post)));
                  },
                  title: Text(post['title']['rendered']),
                  // You can display other post details here.
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton.extended(
            onPressed: () {
              String links = '';
              posts.forEach((element) {
                links += element['link'].toString();
                links += '\n';
              });
              Clipboard.setData(ClipboardData(text: convertStringToHTML(links))).then((value) {
                print('copied links');
              });
            },
            icon: Icon(Icons.copy), label: Text("Copy ${posts.length} links"),
          ),
          FloatingActionButton.extended(onPressed: (){


            String bodies = '';
            posts.forEach((element) {
              bodies += (element['content']['rendered']).toString();
              bodies += '\n-----------------------------------------\n';
            });


            Clipboard.setData(ClipboardData(text: bodies)).then((value) {
              print('copied bodies');
            });

          }, icon: Icon(Icons.copy),
            label: Text("Copy ${posts.length} Texts"),
          )
        ],
      ),
    );
  }

  String convertStringToHTML(String inputString) {
    List<String> lines = inputString.split('\n');
    StringBuffer htmlBuffer = StringBuffer();

    // Add the HTML start tag and head with content
    htmlBuffer.write('<!DOCTYPE html>');
    htmlBuffer.write('<html>');
    htmlBuffer.write('<head>');
    htmlBuffer.write('<title>Posts Links</title>');
    htmlBuffer.write('</head>');
    htmlBuffer.write('<body>');

    htmlBuffer.write('<ul>');

    for (var line in lines) {
      var trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty) {
        htmlBuffer.write('<li>');
        htmlBuffer.write('<a href="$trimmedLine" target="_blank">$trimmedLine</a>');
        htmlBuffer.write('</li>');
      }
    }

    htmlBuffer.write('</ul>');

    // Close the HTML body and HTML tags
    htmlBuffer.write('</body>');
    htmlBuffer.write('</html>');

    return htmlBuffer.toString();
  }
}
