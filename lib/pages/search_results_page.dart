import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SearchResultsPage extends StatefulWidget {
  final String initialQuery;
  final ApiService api;
  const SearchResultsPage({
    required this.initialQuery,
    required this.api,
    super.key,
  });

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
      // ✅ If matches exist locally, use them immediately
      setState(() {
        _hotels = localMatches;
        _isLoading = false;
      });
      return;
    }

    // 🛰️ Otherwise call API safely
    try {
      await widget.api.ensureVisitorToken();
      final results = await widget.api.searchHotels(query);
      setState(() {
        _hotels = results.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      // ✅ Instead of crashing, show clean UI
      setState(() {
        _error = 'No results found for "$query" (offline or sample mode).';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getLocalSampleHotels(String query) {
    final lower = query.toLowerCase();
    final sampleHotels = List.generate(6, (i) => {
      'id': '$i',
      'hotelName': 'Sample Hotel ${i + 1}',
      'city': 'City ${i % 3 + 1}',
      'country': 'Country ${i % 2 + 1}',
      'isSample': true,
    });

    return sampleHotels
        .where((h) {
      final hotelName = (h['hotelName'] ?? '').toString().toLowerCase();
      final city = (h['city'] ?? '').toString().toLowerCase();
      final country = (h['country'] ?? '').toString().toLowerCase();
      return hotelName.contains(lower) ||
          city.contains(lower) ||
          country.contains(lower);
    })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Results')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, textAlign: TextAlign.center))
          : _hotels.isEmpty
          ? const Center(child: Text('No hotels found'))
          : ListView.builder(
        itemCount: _hotels.length,
        itemBuilder: (context, index) {
          final h = _hotels[index];
          final name = h['hotelName'] ?? h['name'] ?? 'Unnamed';
          final city = h['city'] ?? '';
          final isSample = h['isSample'] == true;
          return ListTile(
            leading: const Icon(Icons.hotel),
            title: Text(name),
            subtitle: Text(
              '$city${isSample ? " (Sample Data)" : ""}',
            ),
          );
        },
      ),
    );
  }
}
