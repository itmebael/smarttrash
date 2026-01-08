import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/smart_bin_model.dart';
import '../services/smart_bin_service.dart';

// Service provider
final smartBinServiceProvider = Provider<SmartBinService>((ref) {
  return SmartBinService();
});

// Smart bins state notifier
class SmartBinsNotifier extends StateNotifier<AsyncValue<List<SmartBinModel>>> {
  SmartBinsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadSmartBins();
  }

  final SmartBinService _service;

  Future<void> loadSmartBins() async {
    try {
      state = const AsyncValue.loading();
      final bins = await _service.getLatestSmartBinStatus();
      state = AsyncValue.data(bins);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadSmartBins();
  }
}

// Smart bins provider
final smartBinsProvider =
    StateNotifierProvider<SmartBinsNotifier, AsyncValue<List<SmartBinModel>>>(
  (ref) => SmartBinsNotifier(ref.watch(smartBinServiceProvider)),
);

// Smart bins with location only
final smartBinsWithLocationProvider = FutureProvider<List<SmartBinModel>>((ref) async {
  final service = ref.watch(smartBinServiceProvider);
  return await service.getSmartBinsWithLocation();
});

// Smart bins needing attention
final smartBinsNeedingAttentionProvider = FutureProvider<List<SmartBinModel>>((ref) async {
  final service = ref.watch(smartBinServiceProvider);
  return await service.getSmartBinsNeedingAttention();
});

// Real-time smart bins stream
final smartBinsStreamProvider = StreamProvider<List<SmartBinModel>>((ref) {
  final service = ref.watch(smartBinServiceProvider);
  return service.watchSmartBins();
});

// Count of bins by status
final binStatusCountsProvider = Provider<Map<SmartBinStatus, int>>((ref) {
  final binsAsync = ref.watch(smartBinsProvider);
  
  return binsAsync.when(
    data: (bins) {
      final counts = <SmartBinStatus, int>{};
      for (var status in SmartBinStatus.values) {
        counts[status] = bins.where((bin) => bin.status == status).length;
      }
      return counts;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});












