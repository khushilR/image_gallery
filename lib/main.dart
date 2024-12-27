import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Image Gallery',
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.blue,
      ),
      home: const GalleryScreen(),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<Map<String, dynamic>> _images = [];
  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  bool _isLoading = false;
  final String _apiKey =
      '47860842-b117ac626ec73a1865b3f6f78'; // Replace with your API key.

  @override
  void initState() {
    super.initState();
    _fetchImages();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchImages() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      for (int i = 0; i < 3; i++) { // Loop to fetch 3 pages at once
        final url =
            'https://pixabay.com/api/?key=$_apiKey&image_type=photo&per_page=20&page=$_page';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);

          // Explicitly cast the hits to List<Map<String, dynamic>?>
          final List<Map<String, dynamic>> hits =
          List<Map<String, dynamic>>.from(data['hits']);

          setState(() {
            _images.addAll(hits);
            _page++; // Increment page for the next loop iteration
          });
        } else {
          debugPrint('API Error: ${response.statusCode}');
          break; // Stop the loop if there's an error
        }
      }
    } catch (e) {
      debugPrint('API Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      // Trigger fetching more images when close to the bottom
      _fetchImages();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Image Gallery'),
      ),
      body: _images.isEmpty
          ? _isLoading
              ? _loader(60)
              : const Center(child: Text('No images found.'))
          : _grid(),
    );
  }

  Widget _grid() {
    final crossAxisCount = (MediaQuery.of(context).size.width / 150).floor();
    return RefreshIndicator(
      onRefresh: () async{
        _fetchImages();
      },
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 15),
        physics: const BouncingScrollPhysics(),
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 1 / 1.2,
        ),
        itemCount: _images.length,
        itemBuilder: (context, index) {
          final image = _images[index];
          return Card(
            elevation: 7,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: image['webformatURL'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _loader(50),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _rowWidget("${image['likes']} Likes",
                          CupertinoIcons.heart_fill, Colors.red),
                      _rowWidget("${image['views']} Views",
                          Icons.remove_red_eye_sharp, Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _rowWidget(String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor,
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(
              fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500),
        )
      ],
    );
  }
  
  Widget _loader(double size){
    return Center(
      child: Lottie.asset("assets/load.json",
          width: size, height: size),
    );
  }
}
