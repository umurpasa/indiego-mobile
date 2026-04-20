// Backend'in Product endpoint'lerinden dönen JSON'ı temsil eden modeller.
// Sayısal Type değeri (0 = Game, 1 = GameAsset) enum'a dönüştürülüyor;
// PreviewImagesJson gibi string-olarak-saklanan listeler burada parse ediliyor.
//
// İki ayrı sınıf var çünkü iki farklı backend response'u var:
//   - Product       => GET /api/v1/Product           (liste/grid kartları)
//   - ProductDetail => GET /api/v1/Product/{id}     (detay sayfası)

import 'dart:convert';

enum ProductType { game, gameAsset }

ProductType productTypeFromJson(dynamic value) {
  if (value is int) {
    return value == 1 ? ProductType.gameAsset : ProductType.game;
  }
  if (value is String) {
    if (value.toLowerCase().contains('asset')) return ProductType.gameAsset;
    return ProductType.game;
  }
  return ProductType.game;
}

// GET /api/v1/Product içindeki PagedResponse<GetAllProductsViewModel>'in
// tek bir item'ını temsil eder. Liste ekranlarında kart için yeterli.
class Product {
  final int id;
  final String name;
  final String description;
  final ProductType type;
  final double price;
  final String currency;
  final String? coverImageUrl;
  // Backend bu alanı PreviewImagesJson string olarak veriyor; constructor'da parse'lıyoruz.
  final List<String> previewImages;
  final String? directLink;
  final String? barcode;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.price,
    required this.currency,
    required this.coverImageUrl,
    required this.previewImages,
    required this.directLink,
    required this.barcode,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      type: productTypeFromJson(json['type']),
      price: _toDouble(json['price']),
      currency: (json['currency'] ?? 'USD') as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      previewImages: _parsePreviewImages(json['previewImagesJson']),
      directLink: json['directLink'] as String?,
      barcode: json['barcode'] as String?,
    );
  }
}

// GET /api/v1/Product/{id}'den dönen ProductDetailDto.
// Liste DTO'sundan farklı olarak rating, reviewCount, downloadCount,
// seller adı, kategori ve tag bilgilerini taşır.
class ProductDetail {
  final int id;
  final String name;
  final String description;
  final ProductType type;
  final double price;
  final String currency;
  final bool isFree;
  final String? coverImageUrl;
  final List<String> previewImages;
  final String? directLink;
  final String? barcode;
  final String? sellerStoreName;
  final int downloadCount;
  final double averageRating;
  final int reviewCount;
  final List<String> tags;
  final List<ProductCategory> categories;

  ProductDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.price,
    required this.currency,
    required this.isFree,
    required this.coverImageUrl,
    required this.previewImages,
    required this.directLink,
    required this.barcode,
    required this.sellerStoreName,
    required this.downloadCount,
    required this.averageRating,
    required this.reviewCount,
    required this.tags,
    required this.categories,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final previewRaw = json['previewImages'];
    List<String> previews;
    if (previewRaw is List) {
      previews = previewRaw.map((e) => e.toString()).toList();
    } else if (previewRaw is String) {
      previews = _parsePreviewImages(previewRaw);
    } else {
      previews = const [];
    }

    final tagsRaw = json['tags'];
    final tags = tagsRaw is List
        ? tagsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final categoriesRaw = json['categories'];
    final categories = categoriesRaw is List
        ? categoriesRaw
            .whereType<Map<String, dynamic>>()
            .map(ProductCategory.fromJson)
            .toList()
        : <ProductCategory>[];

    return ProductDetail(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      type: productTypeFromJson(json['type']),
      price: _toDouble(json['price']),
      currency: (json['currency'] ?? 'USD') as String,
      isFree: (json['isFree'] ?? false) as bool,
      coverImageUrl: json['coverImageUrl'] as String?,
      previewImages: previews,
      directLink: json['directLink'] as String?,
      barcode: json['barcode'] as String?,
      sellerStoreName: json['sellerStoreName'] as String?,
      downloadCount: (json['downloadCount'] ?? 0) as int,
      averageRating: _toDouble(json['averageRating']),
      reviewCount: (json['reviewCount'] ?? 0) as int,
      tags: tags,
      categories: categories,
    );
  }
}

class ProductCategory {
  final int id;
  final String name;
  ProductCategory({required this.id, required this.name});

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        id: (json['id'] ?? 0) as int,
        name: (json['name'] ?? '') as String,
      );
}

// PagedResponse<T> sarmalayıcısını parse eder; sadece data listesini değil,
// totalCount/hasNextPage gibi alanları da gerekirse okumak için
// yardımcı bir wrapper.
class PagedResult<T> {
  final List<T> data;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final bool hasNextPage;

  PagedResult({
    required this.data,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.hasNextPage,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final raw = json['data'];
    final items = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(itemParser).toList()
        : <T>[];
    return PagedResult<T>(
      data: items,
      pageNumber: (json['pageNumber'] ?? 1) as int,
      pageSize: (json['pageSize'] ?? items.length) as int,
      totalCount: (json['totalCount'] ?? items.length) as int,
      hasNextPage: (json['hasNextPage'] ?? false) as bool,
    );
  }
}

// --- yardımcı dönüştürmeler ---

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

// Backend PreviewImages alanını JSON string olarak saklıyor:
//   "[\"https://...\",\"https://...\"]"
// Bunu güvenli şekilde parse'lar; bozuk/eksik veride boş liste döner.
List<String> _parsePreviewImages(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List) return raw.map((e) => e.toString()).toList();
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {/* JSON değilse görmezden gel */}
  }
  return const [];
}
