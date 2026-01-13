import 'package:couple_note/core/services/lib/core/local_storage_service.dart';
import 'package:couple_note/domain/usecases/couple/create_couple.dart';
import 'package:couple_note/domain/usecases/couple/delete_couple.dart';
import 'package:couple_note/domain/usecases/couple/get_all_couples.dart';
import 'package:couple_note/domain/usecases/couple/get_coupleId_by_user_id.dart';
import 'package:couple_note/domain/usecases/couple/get_couple_by_id.dart';
import 'package:couple_note/domain/usecases/couple/get_couple_by_user_id.dart';
import 'package:couple_note/domain/usecases/couple/get_couples_by_member.dart';
import 'package:couple_note/domain/usecases/couple/get_partner.dart';
import 'package:couple_note/domain/usecases/couple/update_couple.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:couple_note/domain/entities/couples.dart';
import 'package:flutter_riverpod/legacy.dart';

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

class CoupleViewModel extends StateNotifier<CoupleViewState> {
  final CreateCoupleUseCase createCoupleUseCase;
  final DeleteCoupleUseCase deleteCoupleUseCase;
  final GetAllCouplesUseCase getAllCouplesUseCase;
  final GetCoupleByIdUseCase getCoupleByIdUseCase;
  final GetCoupleIdByUserIdUseCase getCoupleIdByUserIdUseCase;
  final GetCouplesByMemberUseCase getCouplesByMemberUseCase;
  final UpdateCoupleUseCase updateCoupleUseCase;
  final LocalStorageService localStorageService;

  CoupleViewModel({
    required this.createCoupleUseCase,
    required this.deleteCoupleUseCase,
    required this.getAllCouplesUseCase,
    required this.getCoupleByIdUseCase,
    required this.getCoupleIdByUserIdUseCase,
    required this.getCouplesByMemberUseCase,
    required this.updateCoupleUseCase,
    required this.localStorageService,
  }) : super(const CoupleViewState());

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSelectedCouple() {
    state = state.copyWith(clearSelectedCouple: true);
  }

  Future<void> getAllCouples() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await getAllCouplesUseCase();

    if (result.isSuccess) {
      state = state.copyWith(couples: result.data ?? [], isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
    }
  }

  Future<void> getCoupleById(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await getCoupleByIdUseCase(id);

    if (result.isSuccess) {
      state = state.copyWith(selectedCouple: result.data, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
    }
  }

  Future<void> getCoupleByUserId(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // final result = await getCoupleByUserIdUseCase(userId);

    // if (result.isSuccess) {
    //   final couple = result.data;
    //   state = state.copyWith(
    //     selectedCouple: couple,
    //     isCouple: couple != null,
    //     isLoading: false,
    //   );
    // } else {
    //   state = state.copyWith(isLoading: false, errorMessage: result.message);
    // }
  }

  Future<void> getCouplesByMember(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await getCouplesByMemberUseCase(userId);

    if (result.isSuccess) {
      localStorageService.saveString(
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

    final result = await createCoupleUseCase(couple);

    if (result.isSuccess) {
      localStorageService.saveString(StorageKeys.coupleId, result.data!.id!);
      final updatedCouples = [...state.couples, couple];
      state = state.copyWith(
        couples: updatedCouples,
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

    final result = await updateCoupleUseCase(couple);

    if (result.isSuccess) {
      localStorageService.saveString(StorageKeys.coupleId, result.data!.id!);

      final updatedCouples = state.couples.map((c) {
        return c.id == couple.id ? couple : c;
      }).toList();

      state = state.copyWith(
        couples: updatedCouples,
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

  void selectCouple(CoupleEntity couple) {
    state = state.copyWith(selectedCouple: couple);
  }

  Future<void> refreshCouples() async {
    await getAllCouples();
  }

  bool isCoupleExists(String id) {
    return state.couples.any((couple) => couple.id == id);
  }

  CoupleEntity? getCoupleFromList(String id) {
    try {
      return state.couples.firstWhere((couple) => couple.id == id);
    } catch (e) {
      return null;
    }
  }
}
