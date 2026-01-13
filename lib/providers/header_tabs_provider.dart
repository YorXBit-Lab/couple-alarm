import 'package:couple_note/data/models/user_tab_model.dart';
import 'package:couple_note/presentation/viewmodels/header_tab_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final headerTabsViewModelProvider =
    StateNotifierProvider.family<
      HeaderTabsViewModel,
      HeaderTabsState,
      HeaderTabsConfig
    >((ref, config) {
      return HeaderTabsViewModel(config.userTabs, config.initialTab);
    });

class HeaderTabsConfig {
  final List<UserTab> userTabs;
  final String initialTab;

  const HeaderTabsConfig({required this.userTabs, required this.initialTab});
}
