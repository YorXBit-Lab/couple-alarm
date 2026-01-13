import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/lib/core/local_storage_service.dart';
import 'package:couple_note/core/services/lib/core/services/cloudfare_r2_service.dart';
import 'package:couple_note/core/services/lib/core/services/upload_avatar_service.dart';
import 'package:couple_note/core/utils/utils.dart';
import 'package:couple_note/data/models/user_tab_model.dart';
import 'package:couple_note/data/repositories/invitation_repository_impl.dart';
import 'package:couple_note/data/repositories/reminder_repository_impl.dart';
import 'package:couple_note/domain/entities/couples.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:couple_note/domain/repositories/invitation_repository.dart';
import 'package:couple_note/domain/repositories/reminder_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/domain/usecases/couple/create_couple.dart';
import 'package:couple_note/domain/usecases/couple/delete_couple.dart';
import 'package:couple_note/domain/usecases/couple/get_all_couples.dart';
import 'package:couple_note/domain/usecases/couple/get_coupleId_by_user_id.dart';
import 'package:couple_note/domain/usecases/couple/get_couple_by_id.dart';
import 'package:couple_note/domain/usecases/couple/get_couple_by_user_id.dart';
import 'package:couple_note/domain/usecases/couple/get_couples_by_member.dart';
import 'package:couple_note/domain/usecases/couple/get_partner.dart';
import 'package:couple_note/domain/usecases/couple/update_couple.dart';
import 'package:couple_note/domain/usecases/reminder/create_reminder.dart';
import 'package:couple_note/domain/usecases/reminder/delete_reminder.dart';
import 'package:couple_note/domain/usecases/reminder/get_reminder_by_id.dart';
import 'package:couple_note/domain/usecases/reminder/get_reminders_by_user.dart';
import 'package:couple_note/domain/usecases/reminder/toggle_reminder_status.dart';
import 'package:couple_note/domain/usecases/reminder/update_reminder.dart';
import 'package:couple_note/presentation/viewmodels/couple_viewmodel.dart';
import 'package:couple_note/providers/auth_provider.dart';
import 'package:couple_note/providers/connect_provider.dart';
import 'package:couple_note/providers/couple_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences phải được override trong main()');
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

// UseCases
final createCoupleUseCaseProvider = Provider<CreateCoupleUseCase>((ref) {
  return CreateCoupleUseCase(ref.read(coupleRepositoryProvider));
});

final getPartnerUseCaseProvider = Provider<GetPartnerUseCase>((ref) {
  return GetPartnerUseCase(ref.read(coupleRepositoryProvider));
});

final deleteCoupleUseCaseProvider = Provider<DeleteCoupleUseCase>((ref) {
  return DeleteCoupleUseCase(ref.read(coupleRepositoryProvider));
});

final getAllCouplesUseCaseProvider = Provider<GetAllCouplesUseCase>((ref) {
  return GetAllCouplesUseCase(ref.read(coupleRepositoryProvider));
});

final getCoupleByIdUseCaseProvider = Provider<GetCoupleByIdUseCase>((ref) {
  return GetCoupleByIdUseCase(ref.read(coupleRepositoryProvider));
});

final getCoupleByUserIdUseCaseProvider = Provider<GetCoupleByUserIdUseCase>((
  ref,
) {
  return GetCoupleByUserIdUseCase(ref.read(coupleRepositoryProvider));
});

final getCoupleIdByUserIdUseCaseProvider = Provider<GetCoupleIdByUserIdUseCase>(
  (ref) {
    return GetCoupleIdByUserIdUseCase(ref.read(coupleRepositoryProvider));
  },
);

final getCouplesByMemberUseCaseProvider = Provider<GetCouplesByMemberUseCase>((
  ref,
) {
  return GetCouplesByMemberUseCase(ref.read(coupleRepositoryProvider));
});

final updateCoupleUseCaseProvider = Provider<UpdateCoupleUseCase>((ref) {
  return UpdateCoupleUseCase(ref.read(coupleRepositoryProvider));
});

final coupleViewModelProvider =
    StateNotifierProvider<CoupleViewModel, CoupleViewState>((ref) {
      return CoupleViewModel(
        createCoupleUseCase: ref.read(createCoupleUseCaseProvider),
        deleteCoupleUseCase: ref.read(deleteCoupleUseCaseProvider),
        getAllCouplesUseCase: ref.read(getAllCouplesUseCaseProvider),
        getCoupleByIdUseCase: ref.read(getCoupleByIdUseCaseProvider),
        getCoupleIdByUserIdUseCase: ref.read(
          getCoupleIdByUserIdUseCaseProvider,
        ),
        getCouplesByMemberUseCase: ref.read(getCouplesByMemberUseCaseProvider),
        updateCoupleUseCase: ref.read(updateCoupleUseCaseProvider),
        localStorageService: ref.read(localStorageServiceProvider),
      );
    });

final couplesProvider = Provider<List<CoupleEntity>>((ref) {
  return ref.watch(coupleViewModelProvider).couples;
});

final selectedCoupleProvider = Provider<CoupleEntity?>((ref) {
  return ref.watch(coupleViewModelProvider).selectedCouple;
});

final coupleLoadingProvider = Provider<bool>((ref) {
  return ref.watch(coupleViewModelProvider).isLoading;
});

final coupleErrorProvider = Provider<String?>((ref) {
  return ref.watch(coupleViewModelProvider).errorMessage;
});

// reminder

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ReminderRepositoryImpl(
    firestore,
    ref.read(connectivityServiceProvider),
  );
});
// reminder Use Cases
final createReminderUseCaseProvider = Provider<CreateReminder>((ref) {
  return CreateReminder(ref.read(reminderRepositoryProvider));
});

final deleteReminderUseCaseProvider = Provider<DeleteReminder>((ref) {
  return DeleteReminder(ref.read(reminderRepositoryProvider));
});

final getReminderByIdUseCaseProvider = Provider<GetReminderById>((ref) {
  return GetReminderById(ref.read(reminderRepositoryProvider));
});

final getRemindersByUserUseCaseProvider = Provider<GetRemindersByUser>((ref) {
  return GetRemindersByUser(ref.read(reminderRepositoryProvider));
});

final updateReminderUseCaseProvider = Provider<UpdateReminder>((ref) {
  return UpdateReminder(ref.read(reminderRepositoryProvider));
});

final toggleReminderStatusUseCaseProvider =
    Provider<ToggleReminderStatusUseCase>((ref) {
      return ToggleReminderStatusUseCase(ref.read(reminderRepositoryProvider));
    });

final tabsProvider = Provider.family<List<UserTab>, (UserEntity?, String)>((
  ref,
  params,
) {
  final (partner, localeCode) = params;

  return [
    UserTab(key: 'mine', label: TransKeys.mine.tr(), icon: Icons.person),
    UserTab(key: 'partner', label: getName(partner), icon: Icons.favorite),
    UserTab(key: 'couple', label: 'Couple', icon: Icons.people_alt_rounded),
  ];
});

final r2StorageServiceProvider = Provider<R2StorageService>((ref) {
  return R2StorageService();
});

final avatarUploadServiceProvider = Provider<AvatarUploadService>((ref) {
  final r2Service = ref.read(r2StorageServiceProvider);
  return AvatarUploadService(r2Service);
});

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return InvitationRepositoryImpl(
    firestore,
    ref.read(userRepositoryProvider),
    ref.read(coupleRepositoryProvider),
  );
});
