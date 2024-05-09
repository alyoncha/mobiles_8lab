import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

Future<List<New>> fetchNews(http.Client client) async {
  final response = await client.get(
    Uri.parse(
      'https://kubsau.ru/api/getNews.php?key=6df2f5d38d4e16b5a923a6d4873e2ee295d0ac90',
    ),
  );
  String jsonString = response.body.toString();
  return compute(parseNews, jsonString);
}

List<New> parseNews(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<New>((json) => New.fromJson(json)).toList();
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class New {
  final String title;
  final String date;
  final String text;
  final String icon;
  final String url;
  const New({
    required this.title,
    required this.date,
    required this.text,
    required this.icon,
    required this.url,
  });
  factory New.fromJson(Map<String, dynamic> json) {
    return New(
      title: json['TITLE'] as String,
      url: json['DETAIL_PAGE_URL'] as String,
      date: json['ACTIVE_FROM'] as String,
      text: json['PREVIEW_TEXT'] as String,
      icon: json['PREVIEW_PICTURE_SRC'] as String,
    );
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Лента новостей КубГАУ';
    return const MaterialApp(
      title: appTitle,
      home: MyHomePage(title: appTitle),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<List<New>>(
        future: fetchNews(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            var errorText = snapshot.error.toString();
            return Center(child: Text(errorText));
          } else if (snapshot.hasData) {
            return NewsList(News: snapshot.data!);
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

class NewsList extends StatelessWidget {
  const NewsList({Key? key, required this.News}) : super(key: key);
  final List<New> News;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: News.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(children: [
                          Image.network(News[index].icon),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    News[index].date,
                                    style: const TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    News[index].title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Flexible(
                                    child: Text(
                                  News[index].text,
                                  textAlign: TextAlign.start,
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
