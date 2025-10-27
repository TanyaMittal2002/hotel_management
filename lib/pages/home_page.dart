// lib/pages/home_page.dart
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

  final List<Map<String, String>> sampleHotels = List.generate(6, (i) => {
    'id': '$i',
    'name': 'Sample Hotel ${i + 1}',
    'city': 'City ${i % 3 + 1}',
    'country': 'Country ${i % 2 + 1}'
  });

  Future<void> _goToSearch(String query) async {
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter search term')));
      return;
    }

    setState(() => _isLoading = true);

    // We don't need to prefetch here: SearchResultsPage will perform the API call using ApiService
    try {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchResultsPage(initialQuery: query, api: widget.api)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search navigation failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotels Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => _goToSearch(v),
              decoration: InputDecoration(
                hintText: 'Search by hotel name, city, state or country',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => _goToSearch(_controller.text.trim())),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: sampleHotels.length,
                  itemBuilder: (context, idx) {
                    final h = sampleHotels[idx];
                    return ListTile(
                      leading: const Icon(Icons.hotel),
                      title: Text(h['name']!),
                      subtitle: Text('${h['city']}, ${h['country']}'),
                      onTap: () => _goToSearch(h['name']!),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
