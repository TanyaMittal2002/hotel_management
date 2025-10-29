import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'search_results_page.dart';

class HomePage extends StatefulWidget {
  final ApiService api;
  const HomePage({required this.api, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, String>> sampleHotels = [
    {
      'id': '1',
      'name': 'The Grand Orchid',
      'city': 'Jaipur',
      'country': 'India',
      'image': 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=600&q=80'
    },
    {
      'id': '2',
      'name': 'Sunset Paradise Resort',
      'city': 'Maldives',
      'country': 'Maldives',
      'image': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80'
    },
    {
      'id': '3',
      'name': 'Mountain View Lodge',
      'city': 'Manali',
      'country': 'India',
      'image': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80'
    },
    {
      'id': '4',
      'name': 'Blue Lagoon Hotel',
      'city': 'Goa',
      'country': 'India',
      'image': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80'
    },
    {
      'id': '5',
      'name': 'Royal Continental',
      'city': 'Dubai',
      'country': 'UAE',
      'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=600&q=80'
    },
    {
      'id': '6',
      'name': 'Lakeview Palace',
      'city': 'Udaipur',
      'country': 'India',
      'image': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80'
    },
  ];

  Future<void> _goToSearch(String query) async {
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search term')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SearchResultsPage(initialQuery: query, api: widget.api),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFFCE93D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Find Your Perfect Stay",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) => _goToSearch(v),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search by hotel, city, or country',
                    prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.white))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: sampleHotels.length,
                      itemBuilder: (context, idx) {
                        final h = sampleHotels[idx];
                        return Card(
                          color: Colors.white.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 6,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _goToSearch(h['name']!),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(16)),
                                  child: Image.network(
                                    h['image']!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          h['name']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${h['city']}, ${h['country']}',
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
