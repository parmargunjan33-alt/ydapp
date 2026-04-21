// lib/features/subscription/subscription_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/models/models.dart';

final subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(apiServiceProvider));
});

class SubscriptionRepository {
  final ApiService _api;
  SubscriptionRepository(this._api);

  Future<bool> checkSubscription(int semesterId) async {
    try {
      final res = await _api.checkSubscription(semesterId);
      // Handle both direct response and { "data": { ... } }
      final data = res['data'] is Map ? res['data'] : res;
      
      final isSub = data['is_subscribed'] ?? 
                    data['isSubscribed'] ?? 
                    data['status'] ??
                    data['subscribed'] ??
                    data['active'] ??
                    data['success'];
      
      final String subStr = isSub.toString().toLowerCase();
      return subStr == 'true' || 
             subStr == '1' || 
             subStr == 'active' || 
             subStr == 'subscribed' ||
             subStr == 'success';
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> createOrder(int semesterId) =>
      _api.createOrder(semesterId);

  Future<void> verifyPayment({
    required int semesterId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) =>
      _api.verifyPayment(
        semesterId: semesterId,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );

  Future<List<SubscriptionModel>> getMySubscriptions() async {
    final list = await _api.getMySubscriptions();
    return list
        .map((e) => SubscriptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubscriptionPriceModel> getSubscriptionPrice() async {
    final res = await _api.getSubscriptionPrice();
    return SubscriptionPriceModel.fromJson(res);
  }
}

// Providers
final subscriptionPriceProvider =
    FutureProvider<SubscriptionPriceModel>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).getSubscriptionPrice();
});

final subscriptionStatusProvider =
    FutureProvider.family<bool, int>((ref, semesterId) async {
  return ref
      .watch(subscriptionRepositoryProvider)
      .checkSubscription(semesterId);
});

final mySubscriptionsProvider =
    FutureProvider<List<SubscriptionModel>>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).getMySubscriptions();
});
