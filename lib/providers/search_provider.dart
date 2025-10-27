import 'package:flutter_riverpod/legacy.dart';
import '../services/api_service.dart';

// simple state
class SearchState {
  final List<dynamic> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final int page;
  final String query;
  final String? error;

  SearchState({this.items = const [], this.loading = false, this.loadingMore = false, this.hasMore = false, this.page = 1, this.query = '', this.error});

  SearchState copyWith({List<dynamic>? items, bool? loading, bool? loadingMore, bool? hasMore, int? page, String? query, String? error}) {
    return SearchState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      query: query ?? this.query,
      error: error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final ApiService api;
  SearchNotifier(this.api): super(SearchState());

  Future<void> search(String q) async {
    state = state.copyWith(loading: true, query: q, page: 1, error: null);
    try {
      final searchCriteria = {
        "checkIn": DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T').first,
        "checkOut": DateTime.now().add(const Duration(days: 2)).toIso8601String().split('T').first,
        "rooms": 1,
        "adults": 2,
        "children": 0,
        "searchType": "citySearch",
        "searchQuery": [q],
        "accommodation": ["all"],
        "arrayOfExcludedSearchType": [],
        "highPrice": "3000000",
        "lowPrice": "0",
        "limit": 10,
        "preloaderList": [],
        "currency": "INR",
        "rid": 0
      };
      final res = await api.getSearchResultListOfHotels(searchCriteria: searchCriteria, page: 1, limit: 10);
      state = state.copyWith(loading: false, items: res['items'], hasMore: res['hasMore'], page: 1);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(loadingMore: true);
    try {
      final searchCriteria = {
        "checkIn": DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T').first,
        "checkOut": DateTime.now().add(const Duration(days: 2)).toIso8601String().split('T').first,
        "rooms": 1,
        "adults": 2,
        "children": 0,
        "searchType": "citySearch",
        "searchQuery": [state.query],
        "accommodation": ["all"],
        "arrayOfExcludedSearchType": [],
        "highPrice": "3000000",
        "lowPrice": "0",
        "limit": 10,
        "preloaderList": [],
        "currency": "INR",
        "rid": nextPage - 1
      };
      final res = await api.getSearchResultListOfHotels(searchCriteria: searchCriteria, page: nextPage, limit: 10);
      state = state.copyWith(loadingMore: false, items: [...state.items, ...res['items']], page: nextPage, hasMore: res['hasMore']);
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  void clear() => state = SearchState();
}

// Provider factory - must be created with ApiService instance
final searchNotifierProvider = StateNotifierProviderFamily<SearchNotifier, SearchState, ApiService>((ref, api) {
  return SearchNotifier(api);
});
