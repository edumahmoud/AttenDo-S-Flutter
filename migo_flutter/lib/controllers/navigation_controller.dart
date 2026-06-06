import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Student Section Enum ───

enum StudentSection {
  dashboard,
  subjects,
  summaries,
  tracking,
  assignments,
  files,
  videos,
  teachers,
  chat,
  todos,
  calendar,
  reports,
  notifications,
  settings,
}

// ─── Navigation State ───

class NavigationState {
  final StudentSection currentSection;
  final String? selectedSubjectId;
  final String courseTab;
  final bool sidebarOpen;
  final StudentSection? previousSection;

  const NavigationState({
    this.currentSection = StudentSection.dashboard,
    this.selectedSubjectId,
    this.courseTab = 'overview',
    this.sidebarOpen = true,
    this.previousSection,
  });

  NavigationState copyWith({
    StudentSection? currentSection,
    String? selectedSubjectId,
    String? courseTab,
    bool? sidebarOpen,
    StudentSection? previousSection,
    bool clearSubjectId = false,
    bool clearPreviousSection = false,
  }) {
    return NavigationState(
      currentSection: currentSection ?? this.currentSection,
      selectedSubjectId:
          clearSubjectId ? null : (selectedSubjectId ?? this.selectedSubjectId),
      courseTab: courseTab ?? this.courseTab,
      sidebarOpen: sidebarOpen ?? this.sidebarOpen,
      previousSection:
          clearPreviousSection ? null : (previousSection ?? this.previousSection),
    );
  }
}

// ─── Navigation Controller ───

class NavigationController extends StateNotifier<NavigationState> {
  NavigationController() : super(const NavigationState());

  void setSection(StudentSection section) {
    state = state.copyWith(
      previousSection: state.currentSection,
      currentSection: section,
    );
  }

  void selectSubject(String subjectId) {
    state = state.copyWith(
      selectedSubjectId: subjectId,
      currentSection: StudentSection.subjects,
    );
  }

  void setCourseTab(String tab) {
    state = state.copyWith(courseTab: tab);
  }

  void toggleSidebar() {
    state = state.copyWith(sidebarOpen: !state.sidebarOpen);
  }

  void goBack() {
    if (state.previousSection != null) {
      state = state.copyWith(
        currentSection: state.previousSection!,
        clearPreviousSection: true,
      );
    } else {
      state = state.copyWith(currentSection: StudentSection.dashboard);
    }
  }
}

// ─── Provider ───

final navigationControllerProvider =
    StateNotifierProvider<NavigationController, NavigationState>((ref) {
  return NavigationController();
});
