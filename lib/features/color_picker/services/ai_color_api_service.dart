import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ColorPalette {
  final String slug;
  final String name;
  final List<String> colors;
  final List<String> tags;
  final int likes;
  final String url;

  ColorPalette({
    required this.slug,
    required this.name,
    required this.colors,
    required this.tags,
    required this.likes,
    required this.url,
  });

  factory ColorPalette.fromJson(Map<String, dynamic> json) {
    return ColorPalette(
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      colors: List<String>.from(json['colors'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      likes: json['likes'] ?? 0,
      url: json['url'] ?? '',
    );
  }
}

class ApiResponse {
  final List<ColorPalette> data;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  ApiResponse({
    required this.data,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List)
        .map((item) => ColorPalette.fromJson(item as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    return ApiResponse(
      data: dataList,
      page: meta['page'] ?? 1,
      perPage: meta['perPage'] ?? 20,
      total: meta['total'] ?? 0,
      totalPages: meta['totalPages'] ?? 0,
    );
  }
}

class AiColorApiService {
  static const String _baseUrl = 'https://www.ai-color.app/api/v1';

  Future<ApiResponse> getPalettes({
    String? tag,
    String? query,
    String sort = 'popular',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/palettes').replace(
        queryParameters: {
          if (tag != null) 'tag': tag,
          if (query != null && query.isNotEmpty) 'q': query,
          'sort': sort,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.fromJson(json);
      } else {
        throw Exception('Failed to load palettes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching palettes: $e');
    }
  }

  Future<ColorPalette?> getColorDetails(String hex) async {
    try {
      final uri = Uri.parse('$_baseUrl/colors/$hex');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ColorPalette.fromJson(json);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}

// Riverpod providers
final aiColorApiProvider = Provider((ref) => AiColorApiService());

final apiPalettesProvider = FutureProvider.family<
    ApiResponse,
    ({String? tag, String? query, String sort, int page, int limit})>((
  ref,
  params,
) async {
  final service = ref.watch(aiColorApiProvider);
  return service.getPalettes(
    tag: params.tag,
    query: params.query,
    sort: params.sort,
    page: params.page,
    limit: params.limit,
  );
});

final apiPaletteSearchProvider =
    StateProvider<String>((ref) => '');

final apiPaletteSortProvider =
    StateProvider<String>((ref) => 'popular');

final apiPalettePageProvider =
    StateProvider<int>((ref) => 1);

final apiPaletteTagProvider =
    StateProvider<String?>((ref) => null);
