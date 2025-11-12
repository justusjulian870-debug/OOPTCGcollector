import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/card.dart';
import '../../../services/image_service.dart';
import '../../../app/constants/app_constants.dart';
import '../../../features/card_detail/providers/card_detail_provider.dart';

class CollectionGrid extends ConsumerWidget {
  final List<CollectionItem> collectionItems;
  final Map<String, CardPrice?> prices;
  final bool isLoading;
  final Function(String cardId, int quantity)? onQuantityChanged;
  final Function(String cardId)? onFavoriteToggle;
  final Function(String cardId)? onCardTap;

  const CollectionGrid({
    super.key,
    required this.collectionItems,
    required this.prices,
    this.isLoading = false,
    this.onQuantityChanged,
    this.onFavoriteToggle,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 0.8,
        crossAxisSpacing: AppConstants.cardSpacing * 1.5,
        mainAxisSpacing: AppConstants.cardSpacing * 1.5,
      ),
      itemCount: collectionItems.length,
      itemBuilder: (context, index) {
        final item = collectionItems[index];
        return CollectionCardWidget(
          collectionItem: item,
          price: prices[item.cardId],
          onTap: () => context.go('/cardDetail/${item.cardId}'),
          onQuantityChanged: (quantity) => onQuantityChanged?.call(item.cardId, quantity),
          onFavoriteToggle: () => onFavoriteToggle?.call(item.cardId),
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 768) {
      return 3; // Tablet
    } else if (width >= 600) {
      return 2; // Large phone
    } else {
      return 2; // Phone
    }
  }
}

class CollectionCardWidget extends ConsumerWidget {
  final CollectionItem collectionItem;
  final CardPrice? price;
  final VoidCallback? onTap;
  final Function(int quantity)? onQuantityChanged;
  final VoidCallback? onFavoriteToggle;

  const CollectionCardWidget({
    super.key,
    required this.collectionItem,
    this.price,
    this.onTap,
    this.onQuantityChanged,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardDetailState = ref.watch(cardDetailProvider(collectionItem.cardId));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: cardDetailState.when(
                        data: (cardDetail) => cardDetail.card.buildThumbnailImage(),
                        loading: () => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (_, __) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (collectionItem.favorite)
                    Positioned(
                      top: 8.w,
                      right: 8.w,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 24.w,
                      ),
                    ),
                  if (collectionItem.quantity > 1)
                    Positioned(
                      top: 8.w,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'x${collectionItem.quantity}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        cardDetailState.when(
                          data: (cardDetail) => Text(
                            cardDetail.card.name,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          loading: () => Text(
                            collectionItem.cardId,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          error: (_, __) => Text(
                            collectionItem.cardId,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          collectionItem.cardId,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        if (price != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '€${price!.priceEur.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                              ),
                              if (price!.priceUsd != null)
                                Text(
                                  '\$${price!.priceUsd!.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                            ],
                          ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: collectionItem.quantity > 1
                                  ? () => onQuantityChanged?.call(collectionItem.quantity - 1)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: collectionItem.quantity > 1
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${collectionItem.quantity}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => onQuantityChanged?.call(collectionItem.quantity + 1),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Icon(
                            collectionItem.favorite ? Icons.favorite : Icons.favorite_border,
                            color: collectionItem.favorite ? Colors.red : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}