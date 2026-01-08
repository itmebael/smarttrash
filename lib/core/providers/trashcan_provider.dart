import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trashcan_model.dart';
import '../services/trashcan_service.dart';

// Service provider
final trashcanServiceProvider = Provider<TrashcanService>((ref) {
  return TrashcanService();
});

// Trashcans state notifier
class TrashcansNotifier extends StateNotifier<AsyncValue<List<TrashcanModel>>> {
  TrashcansNotifier(this._service) : super(const AsyncValue.loading()) {
    loadTrashcans();
  }

  final TrashcanService _service;

  Future<void> loadTrashcans() async {
    try {
      state = const AsyncValue.loading();
      final trashcans = await _service.getAllTrashcans();
      state = AsyncValue.data(trashcans);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadTrashcans();
  }

  Future<void> updateStatus(String id, TrashcanStatus status, double fillLevel) async {
    await _service.updateTrashcanStatus(id, status, fillLevel);
    await loadTrashcans();
  }

  Future<void> markAsEmptied(String id) async {
    await _service.markAsEmptied(id);
    await loadTrashcans();
  }
}

// Trashcans provider
final trashcansProvider =
    StateNotifierProvider<TrashcansNotifier, AsyncValue<List<TrashcanModel>>>(
  (ref) => TrashcansNotifier(ref.watch(trashcanServiceProvider)),
);

// Trashcans needing attention
final trashcansNeedingAttentionProvider = FutureProvider<List<TrashcanModel>>((ref) async {
  final service = ref.watch(trashcanServiceProvider);
  return await service.getTrashcansNeedingAttention();
});

// Trashcans with low battery
final trashcansLowBatteryProvider = FutureProvider<List<TrashcanModel>>((ref) async {
  final service = ref.watch(trashcanServiceProvider);
  return await service.getTrashcansWithLowBattery();
});

// Real-time trashcans stream
final trashcansStreamProvider = StreamProvider<List<TrashcanModel>>((ref) {
  final service = ref.watch(trashcanServiceProvider);
  return service.watchTrashcans();
});

// Trashcan statistics
final trashcanStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.watch(trashcanServiceProvider);
  return await service.getTrashcanStatistics();
});

// Count of trashcans by status
final trashcanStatusCountsProvider = Provider<Map<TrashcanStatus, int>>((ref) {
  final trashcansAsync = ref.watch(trashcansProvider);
  
  return trashcansAsync.when(
    data: (trashcans) {
      final counts = <TrashcanStatus, int>{};
      for (var status in TrashcanStatus.values) {
        counts[status] = trashcans.where((t) => t.status == status).length;
      }
      return counts;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});







