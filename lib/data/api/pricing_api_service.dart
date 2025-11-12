import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import '../../app/constants/app_constants.dart';
import '../../shared/models/card.dart';

final pricingApiServiceProvider = Provider<PricingApiService>((ref) {
  return PricingApiService();
});

class PricingApiService {
  late final Dio _dio;

  PricingApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.cardmarketApiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: false, // Don't log sensitive price data
      responseBody: false,
    ));
  }

  Future<CardPrice?> getCardPrice(String cardId) async {
    try {
      // Primary: Try optcgapi.com pricing
      final optcgPrice = await _getOptcgPrice(cardId);
      if (optcgPrice != null) return optcgPrice;

      // Fallback: Try Cardmarket API
      final cardmarketPrice = await _getCardmarketPrice(cardId);
      return cardmarketPrice;

    } catch (e) {
      print('Error fetching price for $cardId: $e');
      return null;
    }
  }

  Future<CardPrice?> _getOptcgPrice(String cardId) async {
    try {
      final response = await _dio.get(
        'https://api.optcgapi.com/v1/cards/$cardId/price',
        options: Options(
          baseUrl: 'https://api.optcgapi.com',
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        return CardPrice(
          cardId: cardId,
          priceEur: (data['price_eur'] as num?)?.toDouble() ?? 0.0,
          priceUsd: (data['price_usd'] as num?)?.toDouble(),
          dateRecorded: DateTime.now(),
          source: 'optcgapi',
        );
      }
      return null;
    } catch (e) {
      print('OP-TCG API pricing failed: $e');
      return null;
    }
  }

  Future<CardPrice?> _getCardmarketPrice(String cardId) async {
    try {
      // This would use Cardmarket API via RapidAPI or similar
      // For now, return mock data
      throw UnimplementedError('Cardmarket API integration requires subscription');
    } catch (e) {
      print('Cardmarket API pricing failed: $e');
      return null;
    }
  }

  Future<List<CardPrice>> getBatchPrices(List<String> cardIds) async {
    final List<CardPrice> prices = [];

    for (final cardId in cardIds) {
      try {
        final price = await getCardPrice(cardId);
        if (price != null) {
          prices.add(price);
        }

        // Respect rate limits
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('Failed to get price for $cardId: $e');
      }
    }

    return prices;
  }

  Future<bool> updateAllPrices(List<String> cardIds) async {
    try {
      int successCount = 0;
      final batchSize = 50;

      for (int i = 0; i < cardIds.length; i += batchSize) {
        final batch = cardIds.skip(i).take(batchSize).toList();
        final prices = await getBatchPrices(batch);

        // Here you would save prices to database
        // This would interact with the database service

        successCount += prices.length;

        // Respect rate limits between batches
        if (i + batchSize < cardIds.length) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      return successCount > 0;
    } catch (e) {
      throw Exception('Price update failed: $e');
    }
  }

  Future<Map<String, double>> getCollectionValue(List<String> cardIds) async {
    final Map<String, double> values = {};

    for (final cardId in cardIds) {
      try {
        final price = await getCardPrice(cardId);
        if (price != null) {
          values[cardId] = price.priceEur;
        }

        // Small delay to respect rate limits
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        print('Failed to get value for $cardId: $e');
      }
    }

    return values;
  }

  // Mock pricing service for development
  Future<CardPrice?> getMockPrice(String cardId, {String? rarity}) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 200));

    // Generate realistic prices based on rarity as specified in planning
    double basePrice;
    double maxPrice;

    if (rarity != null) {
      switch (rarity.toUpperCase()) {
        case 'C': // Common
          basePrice = 1.0;
          maxPrice = 5.0;
          break;
        case 'U': // Uncommon
          basePrice = 3.0;
          maxPrice = 8.0;
          break;
        case 'R': // Rare
          basePrice = 8.0;
          maxPrice = 20.0;
          break;
        case 'SR': // Super Rare
          basePrice = 20.0;
          maxPrice = 60.0;
          break;
        case 'SEC': // Secret Rare
          basePrice = 60.0;
          maxPrice = 200.0;
          break;
        case 'L': // Leader
        case 'SP': // Special
          basePrice = 2.0;
          maxPrice = 15.0;
          break;
        default:
          basePrice = 1.0;
          maxPrice = 50.0;
      }
    } else {
      // Fallback to ID-based pricing if rarity unknown
      basePrice = 1.0;
      maxPrice = 50.0;
    }

    // Add random variation (±30% for realistic prices)
    final hash = cardId.hashCode;
    final randomFactor = 0.7 + (hash.abs() % 60) / 100.0; // 0.7 to 1.3
    final price = basePrice + (hash.abs() % (maxPrice - basePrice).toInt()) * randomFactor;

    // Some trending cards get premium pricing
    final isTrending = (hash.abs() % 10) == 0; // 10% chance
    final finalPrice = isTrending ? price * 1.5 : price;

    return CardPrice(
      cardId: cardId,
      priceEur: double.parse(finalPrice.toStringAsFixed(2)),
      priceUsd: double.parse((finalPrice * 1.1).toStringAsFixed(2)), // EUR to USD conversion
      dateRecorded: DateTime.now().subtract(Duration(hours: hash.abs() % 24)), // Random timestamp within 24h
      source: 'mock',
    );
  }

  // Enhanced mock price method that accepts Card object
  Future<CardPrice?> getMockPriceForCard(Card card) async {
    return await getMockPrice(card.id, rarity: card.rarity);
  }

  void dispose() {
    _dio.close();
  }
}