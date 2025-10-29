import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SearchResultsPage extends StatefulWidget {
  final String initialQuery;
  final ApiService api;
  const SearchResultsPage({required this.initialQuery, required this.api, super.key});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _hotels = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final query = widget.initialQuery.trim();
    final localMatches = _getLocalSampleHotels(query);

    if (localMatches.isNotEmpty) {
      setState(() {
        _hotels = localMatches;
        _isLoading = false;
      });
      return;
    }

    try {
      await widget.api.ensureVisitorToken();
      final results = await widget.api.searchHotels(query);
      setState(() {
        _hotels = results.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      setState(() {
        _error = 'No results found for "$query".';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getLocalSampleHotels(String query) {
    final lower = query.toLowerCase();
    final sampleHotels = [
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

    return sampleHotels
        .where((h) =>
    h['name']!.toLowerCase().contains(lower) ||
        h['city']!.toLowerCase().contains(lower) ||
        h['country']!.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "${widget.initialQuery}"'),
        backgroundColor: const Color(0xFF4A148C),
        elevation: 2,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7B1FA2), Color(0xFFCE93D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _error != null
            ? Center(
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _hotels.length,
          itemBuilder: (context, index) {
            final h = _hotels[index];
            return Card(
              color: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 6,
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
                            h['name'] ?? 'Unnamed',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.deepPurple),
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
            );
          },
        ),
      ),
    );
  }
}