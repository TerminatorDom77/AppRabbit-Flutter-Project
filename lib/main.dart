import 'package:flutter/material.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';


void main() async{
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Image Searcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Image Search App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> images = [];
  String imageUrl = '';
  Map<String, dynamic> data = {};
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  String currentQuery = '';
  bool isLoading = false; //prevents spam fetching when user scrolls

  @override
  void initState(){
    super.initState();
    _scrollController.addListener((){
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200){
        fetchimages(currentQuery);
      }
    });
  }

  Future<void> fetchimages(String query) async {
    if (currentPage > 20 || isLoading){
      return;
    }
    if (query.trim().isEmpty){
      setState((){
        images.clear();
        currentPage = 1;
        currentQuery = '';
      });
      return;
    }
    isLoading = true;
    if (currentQuery != query){
      currentQuery = query;
      currentPage = 1;
    }
    final encodedQuery = Uri.encodeComponent(query);
    final apiKey = dotenv.env['PIXABAY_API_KEY'];
    final response = await http.get(Uri.parse('https://pixabay.com/api/?key=$apiKey&q=$encodedQuery&image_type=photo&per_page=30&page=$currentPage'));
    if (response.statusCode == 200){
      data = jsonDecode(response.body);
      setState(() {
        if (currentPage == 1){
          images.clear();
        }
        data['hits'].forEach((hit){
          images.add(hit['webformatURL']);
        });
        currentPage++;
      });
    }
    isLoading = false;

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Search for an image",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
                
                onChanged: (value){
                    fetchimages(value);
                }
              )
            ),
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.network(images[index]);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
