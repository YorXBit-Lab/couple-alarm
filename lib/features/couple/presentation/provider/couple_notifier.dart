import 'package:couple_note/core/services/local_storage_service.dart';
import 'package:couple_note/core/providers/global_providers.dart';
import 'package:couple_note/features/couple/domain/usecases/create_couple.dart';
import 'package:couple_note/features/couple/domain/usecases/delete_couple.dart';
import 'package:couple_note/features/couple/domain/usecases/get_all_couples.dart';
import 'package:couple_note/features/couple/domain/usecases/get_coupleId_by_user_id.dart';
import 'package:couple_note/features/couple/domain/usecases/get_couple_by_id.dart';
import 'package:couple_note/features/couple/domain/usecases/get_couples_by_member.dart';
import 'package:couple_note/features/couple/domain/usecases/update_couple.dart';
import 'package:couple_note/features/couple/domain/entities/couples.dart';
import 'package:couple_note/features/couple/presentation/provider/couple_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'couple_notifier.g.dart';

class CoupleViewState {
  final List<CoupleEntity> couples;
  final CoupleEntity? selectedCouple;
  final bool isCouple;
  final bool isLoading;
  final String? errorMessage;

  const CoupleViewState({
    this.couples = const [],
    this.selectedCouple,
    this.isCouple = false,
    this.isLoading = false,
    this.errorMessage,
  });

  CoupleViewState copyWith({
    List<CoupleEntity>? couples,
    CoupleEntity? selectedCouple,
    bool? isLoading,
    String? errorMessage,
    bool? isCouple,
    bool clearSelectedCouple = false,
    bool clearError = false,
  }) {
    return CoupleViewState(
      couples: couples ?? this.couples,
      selectedCouple: clearSelectedCouple
          ? null
          : (selectedCouple ?? this.selectedCouple),
      isCouple: isCouple ?? this.isCouple,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@Riverpod(keepAlive: true)
class CoupleNotifier extends _$CoupleNotifier {
  late CreateCoupleUseCase _createCoupleUseCase;
  late DeleteCoupleUseCase _deleteCoupleUseCase;
  late GetAllCouplesUseCase _getAllCouplesUseCase;
  late GetCoupleByIdUseCase _getCoupleByIdUseCase;
  late GetCoupleIdByUserIdUseCase _getCoupleIdByUserIdUseCase;
  late GetCouplesByMemberUseCase _getCouplesByMemberUseCase;
  late UpdateCoupleUseCase _updateCoupleUseCase;
  late LocalStorageService _localStorageService;

  @override
  CoupleViewState build() {
    _createCoupleUseCase = ref.read(createCoupleUseCaseProvider);
    _deleteCoupleUseCase = ref.read(deleteCoupleUseCaseProvider);
    _getAllCouplesUseCase = ref.read(getAllCouplesUseCaseProvider);
    _getCoupleByIdUseCase = ref.read(getCoupleByIdUseCaseProvider);
    _getCoupleIdByUserIdUseCase = ref.read(getCoupleIdByUserIdUseCaseProvider);
    _getCouplesByMemberUseCase = ref.read(getCouplesByMemberUseCaseProvider);
    _updateCoupleUseCase = ref.read(updateCoupleUseCaseProvider);
    _localStorageService = ref.read(localStorageServiceProvider);
    return const CoupleViewState();
  }

  void clearError() => state = state.copyWith(clearError: true);

  void clearSelectedCouple() =>
      state = state.copyWith(clearSelectedCouple: true);

  Future<void> getAllCouples() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getAllCouplesUseCase();
    if (result.isSuccess) {
      state = state.copyWith(couples: result.data ?? [], isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
    }
  }

  Future<void> getCoupleById(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getCoupleByIdUseCase(id);
    if (result.isSuccess) {
      state = state.copyWith(selectedCouple: result.data, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
    }
  }

  Future<void> getCoupleByUserId(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    state = state.copyWith(isLoading: false);
  }

  Future<void> getCouplesByMember(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _getCouplesByMemberUseCase(userId);
    if (result.isSuccess) {
      _localStorageService.saveString(
        StorageKeys.coupleId,
        result.data!.first.id!,
      );
      state = state.copyWith(couples: result.data ?? [], isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
    }
  }

  Future<bool> createCouple(CoupleEntity couple) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _createCoupleUseCase(couple);
    if (result.isSuccess) {
      _localStorageService.saveString(StorageKeys.coupleId, result.data!.id!);
      state = state.copyWith(
        couples: [...state.couples, couple],
        selectedCouple: couple,
        isCouple: true,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
      return false;
    }
  }

  Future<bool> updateCouple(CoupleEntity couple) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _updateCoupleUseCase(couple);
    if (result.isSuccess) {
      _localStorageService.saveString(StorageKeys.coupleId, result.data!.id!);
      state = state.copyWith(
        couples: state.couples.map((c) => c.id == couple.id ? couple : c).toList(),
        selectedCouple: state.selectedCouple?.id == couple.id
            ? couple
            : state.selectedCouple,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
      return false;
    }
  }

  void selectCouple(CoupleEntity couple) =>
      state = state.copyWith(selectedCouple: couple);

  Future<void> refreshCouples() => getAllCouples();

  bool isCoupleExists(String id) =>
      state.couples.any((couple) => couple.id == id);

  CoupleEntity? getCoupleFromList(String id) {
    try {
      return state.couples.firstWhere((couple) => couple.id == id);
    } catch (_) {
      return null;
    }
  }
}
