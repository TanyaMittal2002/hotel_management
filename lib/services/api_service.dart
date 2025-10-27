// lib/services/api_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL WITHOUT trailing slash to make joining paths predictable
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.mytravaly.com/public/v1'));
  late SharedPreferences _prefs;

  // Auth token constant (as provided)
  static const String _authToken = '71523fdd8d26f585315b4233e39d9263';

  ApiService();

  /// Must be called once before using other methods.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure a visitor token exists (registers device if missing)
  Future<void> ensureVisitorToken() async {
    final token = _prefs.getString('visitortoken');
    if (token == null || token.isEmpty) {
      debugPrint('No visitortoken found -> registering device');
      final payload = _makeSampleDeviceRegisterPayload();
      await deviceRegister(payload);
    } else {
      debugPrint('Existing visitor token: $token');
    }
  }

  /// Build the deviceRegister payload exactly as API expects (use sample values)
  Map<String, dynamic> _makeSampleDeviceRegisterPayload() {
    return {
      "action": "deviceRegister",
      "deviceRegister": {
        "deviceModel": "RMX3521",
        "deviceFingerprint":
        "realme/RMX3521/RE54E2L1:13/RKQ1.211119.001/S.f1bb32-7f7fa_1:user/release-keys",
        "deviceBrand": "realme",
        "deviceId": "RE54E2L1",
        "deviceName": "RMX3521_11_C.10",
        "deviceManufacturer": "realme",
        "deviceProduct": "RMX3521",
        "deviceSerialNumber": "unknown"
      }
    };
  }

  /// Device registration - saves visitortoken to SharedPreferences on success.
  Future<Map<String, dynamic>> deviceRegister(Map<String, dynamic> data) async {
    try {
      // POST to root path '/' so final URL -> baseUrl + '/'
      final resp = await _dio.post(
        '/',
        data: data,
        options: Options(headers: {
          'authtoken': _authToken,
          'Content-Type': 'application/json',
        }),
      );

      debugPrint('deviceRegister response raw: ${resp.data}');

      if (resp.data is Map && resp.data['visitorToken'] != null) {
        final token = resp.data['visitorToken'].toString();
        await _prefs.setString('visitortoken', token);
        debugPrint('Saved visitor token: $token');
      } else if (resp.data is Map && resp.data['data'] != null && resp.data['data']['visitorToken'] != null) {
        // Some APIs wrap under data
        final token = resp.data['data']['visitorToken'].toString();
        await _prefs.setString('visitortoken', token);
        debugPrint('Saved visitor token (from data): $token');
      } else {
        debugPrint('Warning: no visitorToken in response: ${jsonEncode(resp.data)}');
      }

      return resp.data is Map ? Map<String, dynamic>.from(resp.data) : {'data': resp.data};
    } on DioException catch (e) {
      debugPrint('deviceRegister failed: ${e.response?.data ?? e.message}');
      throw Exception('Device registration failed: ${e.response?.data ?? e.message}');
    }
  }

  /// Search using getSearchResultListOfHotels API (main search endpoint).
  /// `query` should be user input (hotel name / city / etc).
  Future<List<dynamic>> searchHotels(String query, {int page = 1, int limit = 5}) async {
    if (query.isEmpty) return [];

    final token = _prefs.getString('visitortoken') ?? '';
    if (token.isEmpty) throw Exception('visitortoken missing - device not registered');

    // Step 1: Auto-complete search
    final autoData = {
      "action": "searchAutoComplete",
      "searchAutoComplete": {
        "inputText": query,
        "searchType": ["byCity", "byState", "byCountry", "byPropertyName"],
        "limit": 5
      }
    };

    try {
      final autoResp = await _dio.post(
        '/',
        data: autoData,
        options: Options(headers: {
          'authtoken': _authToken,
          'visitortoken': token,
          'Content-Type': 'application/json',
        }),
      );

      debugPrint('AutoComplete resp: ${autoResp.data}');
      if (autoResp.data is! Map) throw Exception('Invalid autoComplete response');

      final data = autoResp.data['data'];
      if (data == null || data['autoCompleteList'] == null) {
        throw Exception('No autocomplete data available');
      }

      final autoList = data['autoCompleteList'] as Map<String, dynamic>;

      // Collect all lists of results
      List<dynamic> allResults = [];
      for (var type in autoList.keys) {
        final list = autoList[type]?['listOfResult'];
        if (list is List && list.isNotEmpty) {
          allResults.addAll(list);
        }
      }

      if (allResults.isEmpty) {
        throw Exception('No matching hotels or locations found for "$query"');
      }

      // Extract first usable hotel ID or name
      final firstHotel = allResults.first;
      final firstHotelId = firstHotel['id'] ??
          firstHotel['hotelId'] ??
          firstHotel['propertyId'] ??
          firstHotel['hotelCode'] ??
          firstHotel['hotelName'] ??
          '';

      if (firstHotelId.toString().isEmpty) {
        throw Exception('No valid hotel ID found in auto-complete results');
      }

      // Step 2: Search hotels by that ID
      final searchCriteria = {
        "checkIn": DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T').first,
        "checkOut": DateTime.now().add(const Duration(days: 2)).toIso8601String().split('T').first,
        "rooms": 1,
        "adults": 2,
        "children": 0,
        "searchType": "hotelIdSearch",
        "searchQuery": [firstHotelId],
        "accommodation": ["all", "hotel"],
        "arrayOfExcludedSearchType": ["street"],
        "highPrice": "3000000",
        "lowPrice": "0",
        "limit": min(limit, 5),
        "preloaderList": [],
        "currency": "INR",
        "rid": page - 1
      };

      final body = {
        "action": "getSearchResultListOfHotels",
        "getSearchResultListOfHotels": {"searchCriteria": searchCriteria}
      };

      final resp = await _dio.post(
        '/',
        data: body,
        options: Options(headers: {
          'authtoken': _authToken,
          'visitortoken': token,
          'Content-Type': 'application/json',
        }),
      );

      debugPrint('searchHotels resp: ${resp.data}');

      final respData = resp.data;
      if (respData is Map) {
        final d = respData['data'] ?? respData;
        if (d is Map && d['items'] is List) {
          return List<dynamic>.from(d['items']);
        }
      }

      throw Exception('No valid hotel data found');
    } on DioException catch (e) {
      debugPrint('searchHotels error: ${e.response?.data ?? e.message}');
      throw Exception('Search failed: ${e.response?.data ?? e.message}');
    }
  }

  /// More generic pagination helper that returns items + meta if available.
  Future<Map<String, dynamic>> getSearchResultListOfHotels({
    required Map<String, dynamic> searchCriteria,
    int page = 1,
    int limit = 10,
  }) async {
    final token = _prefs.getString('visitortoken') ?? '';
    if (token.isEmpty) throw Exception('visitortoken missing');

    final criteria = Map<String, dynamic>.from(searchCriteria);
    criteria['limit'] = limit;
    criteria['rid'] = page - 1;

    final body = {"action": "getSearchResultListOfHotels", "getSearchResultListOfHotels": {"searchCriteria": criteria}};

    try {
      final resp = await _dio.post(
        '/',
        data: body,
        options: Options(headers: {
          'authtoken': _authToken,
          'visitortoken': token,
          'Content-Type': 'application/json',
        }),
      );

      debugPrint('getSearchResultListOfHotels resp: ${resp.data}');

      final data = resp.data;
      List items = [];
      int totalPages = 1;

      if (data is Map) {
        final d = data['data'] ?? data;
        if (d is Map) {
          // try common shapes
          items = List.from(d['items'] ?? d['hotels'] ?? d['results'] ?? []);
          final meta = d['meta'] ?? d['pagination'] ?? {};
          if (meta is Map) {
            totalPages = (meta['total_pages'] ?? meta['last_page'] ?? totalPages) as int;
          }
        } else if (d is List) {
          items = List.from(d);
        }
      } else if (data is List) {
        items = List.from(data);
      }

      return {'items': items, 'page': page, 'totalPages': totalPages, 'hasMore': page < totalPages};
    } on DioException catch (e) {
      debugPrint('getSearchResultListOfHotels error: ${e.response?.data ?? e.message}');
      throw Exception('Search failed: ${e.response?.data ?? e.message}');
    }
  }

  /// Optional: get raw app settings
  Future<Map<String, dynamic>> appSettings() async {
    final resp = await _dio.post(
      '/appSetting/',
      options: Options(headers: {'authtoken': _authToken}),
    );
    if (resp.data is Map<String, dynamic>) {
      return resp.data;
    } else {
      return {'data': resp.data};
    }
  }
}
