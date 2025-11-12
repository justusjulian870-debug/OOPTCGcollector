import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../shared/models/card.dart';
import '../../../../shared/models/collection.dart';
import '../../../../services/image_service.dart';
import '../providers/card_detail_provider.dart';

class CardDetailScreen extends ConsumerStatefulWidget {
  final String cardId;

  const CardDetailScreen({
    super.key,
    required this.cardId,
  });

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cardDetailProvider(widget.cardId).notifier).loadCardDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardDetailState = ref.watch(cardDetailProvider(widget.cardId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show menu options
            },
          ),
        ],
      ),
      body: cardDetailState.when(
        data: (cardDetail) => _buildCardContent(cardDetail),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.w,
                color: Colors.grey,
              ),
              SizedBox(height: 16.h),
              Text(
                'Failed to load card',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  ref.read(cardDetailProvider(widget.cardId).notifier).loadCardDetails();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: cardDetailState.when(
        data: (cardDetail) => _buildBottomActionBar(cardDetail),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCardContent(CardDetailData cardDetail) {
    final card = cardDetail.card;
    final collectionItem = cardDetail.collectionItem;
    final price = cardDetail.price;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Image Section
          _buildCardImage(card),
          SizedBox(height: 24.h),

          // Card Name and ID
          Text(
            card.name,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${card.setCode ?? 'Unknown Set'} • ${card.id}',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16.h),

          // Price Section
          if (price != null) _buildPriceSection(price),
          SizedBox(height: 16.h),

          // Card Details Grid
          _buildCardDetailsGrid(card),
          SizedBox(height: 16.h),

          // Card Text
          if (card.cardText != null && card.cardText!.isNotEmpty) ...[
            Text(
              'Card Text',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                card.cardText!,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],

          SizedBox(height: 100.h), // Space for bottom action bar
        ],
      ),
    );
  }

  Widget _buildCardImage(Card card) {
    return Center(
      child: Container(
        width: 200.w,
        height: 280.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: card.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: card.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildImagePlaceholder(card),
                )
              : _buildImagePlaceholder(card),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(Card card) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 48.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8.h),
          Text(
            card.id,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(CardPrice price) {
    final now = DateTime.now();
    final difference = now.difference(price.dateRecorded);
    String timeAgo;

    if (difference.inHours < 1) {
      timeAgo = 'Updated just now';
    } else if (difference.inHours < 24) {
      timeAgo = 'Updated ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      timeAgo = 'Updated ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '€${price.priceEur.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Mock Price',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetailsGrid(Card card) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildDetailRow([
            _buildDetailItem('Cost', card.cost?.toString() ?? '-'),
            _buildDetailItem('Power', card.power?.toString() ?? '-'),
            _buildDetailItem('Counter', card.counter?.toString() ?? '-'),
          ]),
          _buildDivider(),
          _buildDetailRow([
            _buildDetailItem('Color', card.color ?? '-'),
            _buildDetailItem('Type', card.type ?? '-'),
            _buildDetailItem('Rarity', card.rarity ?? '-'),
          ]),
        ],
      ),
    );
  }

  Widget _buildDetailRow(List<Widget> items) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: items.map((item) => Expanded(child: item)).toList(),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Divider(
        height: 1,
        color: Colors.grey[300],
      ),
    );
  }

  Widget _buildBottomActionBar(CardDetailData cardDetail) {
    final collectionItem = cardDetail.collectionItem;
    final isInCollection = collectionItem != null;

    return Container(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Favorite Button
            IconButton(
              onPressed: () {
                ref.read(cardDetailProvider(widget.cardId).notifier).toggleFavorite();
              },
              icon: Icon(
                isInCollection && collectionItem!.favorite
                    ? Icons.star
                    : Icons.star_border,
                color: isInCollection && collectionItem!.favorite
                    ? Colors.amber
                    : Colors.grey,
                size: 32.w,
              ),
            ),

            SizedBox(width: 16.w),

            // Add to Collection Button
            Expanded(
              child: ElevatedButton(
                onPressed: isInCollection
                    ? null
                    : () {
                        ref.read(cardDetailProvider(widget.cardId).notifier).addToCollection();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInCollection ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                child: Text(
                  isInCollection
                      ? 'In Collection (${collectionItem!.quantity})'
                      : 'Add to Collection',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}