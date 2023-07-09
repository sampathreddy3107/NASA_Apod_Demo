import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class APODScreen extends StatefulWidget {
  @override
  _APODScreenState createState() => _APODScreenState();
}

class _APODScreenState extends State<APODScreen> {
  late String searchDate;
  List<Map<String, dynamic>> favoriteList = [];
  Map<String, dynamic>? apodData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteData = prefs.getStringList('favorites');

    if (favoriteData != null) {
      setState(() {
        favoriteList = favoriteData.map((fav) => json.decode(fav) as Map<String, dynamic>).toList();
      });
    }
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteData = favoriteList.map((fav) => json.encode(fav)).toList();
    prefs.setStringList('favorites', favoriteData);
  }

  Future<void> fetchAPOD(String date) async {
    setState(() {
      isLoading = true;
    });

    final url = 'https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY&date=$date';

    try {
      final response = await http.get(Uri.parse(url));
      final jsonData = json.decode(response.body);

      setState(() {
        apodData = jsonData;
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching APOD: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void addToFavorites() {
    if (apodData != null) {
      setState(() {
        favoriteList.add(apodData!);
        saveFavorites();
      });
    }
  }

  void removeFromFavorites(int index) {
    setState(() {
      favoriteList.removeAt(index);
      saveFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NASA APOD'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchDate = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Search Date (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  fetchAPOD(searchDate);
                },
                child: Text('Search'),
              ),
              SizedBox(height: 20),
              if (isLoading)
                CircularProgressIndicator()
              else if (apodData != null)
                Column(
                  children: [
                    CachedNetworkImage(
                      imageUrl: apodData!['url'],
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                    SizedBox(height: 20),
                    ListTile(
                      title: Text(
                        apodData!['title'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Text(
                            apodData!['date'],
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(apodData!['explanation']),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: addToFavorites,
                      child: Text('Add to Favorites'),
                    ),
                  ],
                ),
              SizedBox(height: 20),
              Text(
                'Favorite Listings:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              if (favoriteList.isEmpty)
                Text('No favorites yet.'),
              for (int i = 0; i < favoriteList.length; i++)
                ListTile(
                  title: Text(
                    favoriteList[i]['title'],
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(favoriteList[i]['date']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => removeFromFavorites(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
