import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/card.dart';
import '../../../shared/models/collection.dart';
import '../../../app/constants/app_constants.dart';
import '../../../services/image_service.dart';
import '../../../features/card_detail/providers/card_detail_provider.dart';

class CardList extends ConsumerWidget {
  final List<Card> cards;
  final bool isLoading;
  final VoidCallback? onLoadMore;

  const CardList({
    super.key,
    required this.cards,
    this.isLoading = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification &&
            scrollNotification.metrics.extentAfter < 200 &&
            onLoadMore != null &&
            !isLoading) {
          onLoadMore!();
        }
        return false;
      },
      child: GridView.builder(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: 0.72,
          crossAxisSpacing: AppConstants.cardSpacing * 1.5,
          mainAxisSpacing: AppConstants.cardSpacing * 1.5,
        ),
        itemCount: cards.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= cards.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final card = cards[index];
          return CardWidget(card: card);
        },
      ),
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

class CardWidget extends ConsumerWidget {
  final Card card;

  const CardWidget({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardDetailState = ref.watch(cardDetailProvider(card.id));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        onTap: () {
          context.go('/cardDetail/${card.id}');
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: card.buildThumbnailImage(),
                    ),
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
                            Text(
                              card.name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              card.id,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (card.setCode != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  card.setCode!,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (card.rarity != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRarityColor(card.rarity!).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  card.rarity!,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: _getRarityColor(card.rarity!),
                                    fontWeight: FontWeight.bold,
                                  ),
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
            // Collection Status Indicator
            Positioned(
              top: 8,
              right: 8,
              child: cardDetailState.when(
                data: (cardDetail) => _buildCollectionIndicator(cardDetail.collectionItem),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionIndicator(CollectionItem? collectionItem) {
    if (collectionItem == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            collectionItem.favorite ? Icons.star : Icons.check_circle,
            color: Colors.white,
            size: 12.w,
          ),
          if (collectionItem.quantity > 1) ...[
            SizedBox(width: 2.w),
            Text(
              '${collectionItem.quantity}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'C':
        return Colors.grey;
      case 'U':
        return Colors.green;
      case 'R':
        return Colors.blue;
      case 'SR':
        return Colors.purple;
      case 'SEC':
        return Colors.orange;
      case 'L':
        return Colors.red;
      case 'SP':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}