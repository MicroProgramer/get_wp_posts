import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_wp_posts/screen_post_details.dart';
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart' as htmlToPdf;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as htmlDom;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'helpers.dart';

class WordPressPosts extends StatefulWidget {
  @override
  _WordPressPostsState createState() => _WordPressPostsState();
}

class _WordPressPostsState extends State<WordPressPosts> {
  List<dynamic> posts = [];
  int currentPage = 1;
  int totalPages = 1;
  int pdfsCreated = 0;
  int maxFileSize = 9000000;

  @override
  void initState() {
    super.initState();
    fetchWordPressPosts();
  }

  Future<void> fetchWordPressPosts() async {
    while (currentPage <= totalPages) {
      final response = await http.get(
        Uri.parse('$baseUrl/wp-json/wp/v2/posts?page=$currentPage&per_page=100'), // Replace with the correct URL of the website
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
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) => ScreenPostDetails(title: post['title']['rendered'].toString(), post: post)));
                  },
                  title: Text(post['title']['rendered']),
                  // You can display other post details here.
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.min,
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
            icon: Icon(Icons.copy),
            label: Text("Copy ${posts.length} links"),
          ),
          SizedBox(
            height: 10,
          ),
          FloatingActionButton.extended(
            onPressed: () {
              String bodies = '';
              posts.forEach((element) {
                bodies += (element['content']['rendered']).toString();
                bodies += '\n-----------------------------------------\n';
              });

              Clipboard.setData(ClipboardData(text: bodies)).then((value) {
                print('copied bodies');
              });
            },
            icon: Icon(Icons.copy),
            label: Text("Copy ${posts.length} Texts"),
          ),
          SizedBox(
            height: 10,
          ),
          FloatingActionButton.extended(
            onPressed: () async {
              var permissionStatus = await Permission.storage.request();
              print(permissionStatus);
              // if (!permissionStatus.isGranted) {
              //   return;
              // }

              final directoryPath = await getExternalPath();
              if (directoryPath.isEmpty) {
                return;
              }
              var folderPath = "$directoryPath/$baseUrl".replaceAll("https://", "");
              var saveDirectory = await Directory(folderPath).create(recursive: true);

              print(saveDirectory.path);

              Future.forEach(posts, (element) async {
                print(pdfsCreated++);
                RegExp symbolPattern = RegExp(r'[^\w\s]');
                var title = element['title']['rendered'].toString().replaceAll(symbolPattern, "").replaceAll(' ', '_');
                var name = '${title.substring(0, title.length > 50 ? 50 : title.length)}';
                var file = File("${saveDirectory.path}/${pdfsCreated}_$name.txt");
                var body = (element['content']['rendered']).toString();

                try {
                  // final newpdf = htmlToPdf.Document();
                  // var widgets = await htmlToPdf.HTMLToPdf().convert(body);
                  // newpdf.addPage(htmlToPdf.MultiPage(
                  //     maxPages: 20000000,
                  //     build: (context) {
                  //       return widgets;
                  //     }));

                  // var pdfData = await newpdf.save();
                  // await file.writeAsBytes(pdfData);

                  // var generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
                  //     body, saveDirectory.path, name);
                  var text = convertMixedContentToPlainText(body);
                  print(text);
                  await file.writeAsString(text);

                } catch (e) {
                  print("Exception: Not Saved: $title\n$e");
                }
              });
            },
            icon: Icon(Icons.download),
            label: Text("Export ${posts.length} Txts"),
          ),
          SizedBox(
            height: 10,
          ),
          FloatingActionButton.extended(
            onPressed: () async {
              var permissionStatus = await Permission.storage.request();
              print(permissionStatus);
              // if (!permissionStatus.isGranted) {
              //   return;
              // }

              final directoryPath = await getExternalPath();
              if (directoryPath.isEmpty) {
                return;
              }
              var folderPath = "$directoryPath/$baseUrl".replaceAll("https://", "");
              var saveDirectory = await Directory(folderPath).create(recursive: true);

              print(saveDirectory.path);

              List<String> mergedStringPosts = [];
              String tempPost = '';

              posts.forEach((element) {
                var body = (element['content']['rendered']).toString();
                var plainBody = convertMixedContentToPlainText(body);
                if ((tempPost + plainBody).length <= maxFileSize){
                  tempPost += plainBody;
                } else {
                  mergedStringPosts.add(tempPost);
                  tempPost = '';
                }
              });
              if (tempPost.isNotEmpty){
                mergedStringPosts.add(tempPost);
              }


              Future.forEach(mergedStringPosts, (element) async {
                print(pdfsCreated++);

                try {
                  // final newpdf = htmlToPdf.Document();
                  // var widgets = await htmlToPdf.HTMLToPdf().convert(body);
                  // newpdf.addPage(htmlToPdf.MultiPage(
                  //     maxPages: 20000000,
                  //     build: (context) {
                  //       return widgets;
                  //     }));

                  // var pdfData = await newpdf.save();
                  // await file.writeAsBytes(pdfData);

                  // var generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
                  //     body, saveDirectory.path, name);
                  var file = File("${saveDirectory.path}/$pdfsCreated.txt");
                  await file.writeAsString(element);

                } catch (e) {
                  print("Exception: Not Saved: $pdfsCreated\n$e");
                }
              });
            },
            icon: Icon(Icons.download),
            label: Text("Export merged Txts"),
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

  Future<String> getExternalPath() async {
    String path = "";
    var permission = Permission.storage;

    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 30) {
        path = "/storage/emulated/0/Download";
        permission = Permission.manageExternalStorage;
      } else {
        path = (await getExternalStorageDirectory())!.path;
      }
    } else {
      path = (await getApplicationDocumentsDirectory()).path;
    }
    var status = await permission.request();

    return status.isGranted ? path : "";
  }

  String convertHtmlToPlainText(String htmlString) {
    // Parse the HTML string
    final document = htmlParser.parse(htmlString);

    // Extract plain text
    final buffer = StringBuffer();
    for (final node in document.body?.nodes ?? []) {
      if (node is htmlDom.Text) {
        buffer.write(node.text);
      }
    }

    return buffer.toString();
  }

  String convertMixedContentToPlainText(String mixedString) {
    // Use regular expression to find HTML-like substrings
    final htmlRegex = RegExp(r'<[^>]*>');
    final htmlMatches = htmlRegex.allMatches(mixedString);

    // Replace HTML-like substrings with empty string
    final sanitizedString = mixedString.replaceAllMapped(htmlRegex, (match) {
      return '';
    });

    // Parse the sanitized string to remove HTML entities
    final document = htmlParser.parse(sanitizedString);

    // Extract plain text
    final buffer = StringBuffer();
    for (final node in document.body!.nodes) {
      if (node is htmlDom.Text) {
        buffer.write(node.text);
      }
    }

    return buffer.toString();
  }
}
