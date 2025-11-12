import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/card.dart';
import '../../../../shared/models/collection.dart';
import '../../../../data/database/database_service.dart';
import '../../../../data/api/card_api_service.dart';
import '../../../../data/api/pricing_api_service.dart';

class CardDetailData {
  final Card card;
  final CollectionItem? collectionItem;
  final CardPrice? price;

  CardDetailData({
    required this.card,
    this.collectionItem,
    this.price,
  });
}

class CardDetailNotifier extends StateNotifier<AsyncValue<CardDetailData>> {
  final String cardId;
  final DatabaseService _databaseService;
  final CardApiService _cardApiService;
  final PricingApiService _pricingApiService;

  CardDetailNotifier({
    required this.cardId,
    required DatabaseService databaseService,
    required CardApiService cardApiService,
    required PricingApiService pricingApiService,
  })  : _databaseService = databaseService,
        _cardApiService = cardApiService,
        _pricingApiService = pricingApiService,
        super(const AsyncValue.loading());

  Future<void> loadCardDetails() async {
    state = const AsyncValue.loading();

    try {
      // Try to get card from database first
      Card? card = await _databaseService.getCardById(cardId);

      // If not in database, fetch from API
      if (card == null) {
        card = await _cardApiService.getCardById(cardId);
        if (card != null) {
          await _databaseService.insertCard(card);
        }
      }

      if (card == null) {
        throw Exception('Card not found');
      }

      // Get collection status
      final collectionItem = await _databaseService.getCollectionItem(cardId);

      // Get pricing information
      final price = await _pricingApiService.getMockPrice(cardId);

      state = AsyncValue.data(CardDetailData(
        card: card,
        collectionItem: collectionItem,
        price: price,
      ));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addToCollection() async {
    final currentState = state;
    if (currentState is! AsyncValue<CardDetailData>) return;

    try {
      final card = currentState.value!.card;
      final existingItem = currentState.value!.collectionItem;

      if (existingItem == null) {
        // Add new item to collection
        final collectionItem = CollectionItem(
          cardId: cardId,
          quantity: 1,
          dateAdded: DateTime.now(),
          lastUpdated: DateTime.now(),
          favorite: false,
        );

        await _databaseService.insertCollectionItem(collectionItem);

        // Update state with new collection item
        state = AsyncValue.data(CardDetailData(
          card: card,
          collectionItem: collectionItem,
          price: currentState.value!.price,
        ));
      } else {
        // Update existing item quantity
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
          lastUpdated: DateTime.now(),
        );

        await _databaseService.updateCollectionItem(updatedItem);

        // Update state with updated collection item
        state = AsyncValue.data(CardDetailData(
          card: card,
          collectionItem: updatedItem,
          price: currentState.value!.price,
        ));
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleFavorite() async {
    final currentState = state;
    if (currentState is! AsyncValue<CardDetailData>) return;

    try {
      final card = currentState.value!.card;
      var collectionItem = currentState.value!.collectionItem;

      if (collectionItem == null) {
        // Create collection item if it doesn't exist
        collectionItem = CollectionItem(
          cardId: cardId,
          quantity: 1,
          dateAdded: DateTime.now(),
          lastUpdated: DateTime.now(),
          favorite: true,
        );
        await _databaseService.insertCollectionItem(collectionItem);
      } else {
        // Toggle favorite status
        final updatedItem = collectionItem.copyWith(
          favorite: !collectionItem.favorite,
          lastUpdated: DateTime.now(),
        );
        await _databaseService.updateCollectionItem(updatedItem);
        collectionItem = updatedItem;
      }

      // Update state
      state = AsyncValue.data(CardDetailData(
        card: card,
        collectionItem: collectionItem,
        price: currentState.value!.price,
      ));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final cardDetailProvider = StateNotifierProvider.family<CardDetailNotifier, AsyncValue<CardDetailData>, String>((ref, cardId) {
  return CardDetailNotifier(
    cardId: cardId,
    databaseService: ref.watch(databaseServiceProvider),
    cardApiService: ref.watch(cardApiServiceProvider),
    pricingApiService: ref.watch(pricingApiServiceProvider),
  );
});

// Database service provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Card API service provider
final cardApiServiceProvider = Provider<CardApiService>((ref) {
  return CardApiService();
});

// Pricing API service provider
final pricingApiServiceProvider = Provider<PricingApiService>((ref) {
  return PricingApiService();
});