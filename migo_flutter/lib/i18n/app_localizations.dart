import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ar.dart';
import 'en.dart';
import '../config/constants/app_constants.dart';

// ─── Supported Locales ───

/// Locales supported by the app.
const List<Locale> supportedLocales = [
  Locale('ar'), // Arabic (primary, RTL)
  Locale('en'), // English (LTR)
];

/// Default locale (Arabic).
const Locale defaultLocale = Locale('ar');

/// Returns `TextDirection.rtl` for Arabic, `TextDirection.ltr` otherwise.
TextDirection textDirectionForLocale(Locale locale) {
  return locale.languageCode == 'ar'
      ? TextDirection.rtl
      : TextDirection.ltr;
}

// ─── Translation Map ───

/// All translation maps keyed by language code.
const Map<String, Map<String, dynamic>> _translationMaps = {
  'ar': ar,
  'en': en,
};

// ─── Lookup Helper ───

/// Resolves a dot-separated [key] like `'auth.login.welcome'`
/// from a nested [map]. Returns `null` if not found.
String? _lookup(Map<String, dynamic> map, String key) {
  final parts = key.split('.');
  dynamic current = map;
  for (final part in parts) {
    if (current is! Map<String, dynamic>) return null;
    if (!current.containsKey(part)) return null;
    current = current[part];
  }
  return current is String ? current : null;
}

// ─── Localizations Class ───

/// Provides localized strings for the AttenDo student app.
class AppLocalizations {
  final Locale locale;
  final Map<String, dynamic> _translations;

  AppLocalizations(this.locale)
      : _translations = _translationMaps[locale.languageCode] ?? ar;

  /// Shortcut: `AppLocalizations.of(context)`.
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(defaultLocale);
  }

  /// Whether this locale is RTL.
  bool get isRTL => locale.languageCode == 'ar';

  /// The text direction for this locale.
  TextDirection get textDirection =>
      isRTL ? TextDirection.rtl : TextDirection.ltr;

  /// Translate a key, optionally with [args] for interpolation.
  ///
  /// Uses `{key}` placeholders in translation strings:
  /// ```dart
  /// t('common.minutesAgo', args: {'n': '5'}) // "منذ 5 دقيقة"
  /// ```
  String t(String key, {Map<String, String>? args}) {
    var value = _lookup(_translations, key);
    // Fallback to Arabic if key not found in current locale
    value ??= _lookup(ar, key);
    if (value == null) return key;

    if (args != null) {
      for (final entry in args.entries) {
        value = value!.replaceAll('{${entry.key}}', entry.value);
      }
    }

    return value!;
  }

  // ─── Convenience Accessors ───

  /// Common translations.
  String get appName => t('app.title');
  String get appTagline => t('app.tagline');

  // Navigation
  String get navDashboard => t('nav.dashboard');
  String get navSubjects => t('nav.subjects');
  String get navSummaries => t('nav.summaries');
  String get navChat => t('nav.chat');
  String get navSettings => t('nav.settings');
  String get navTracking => t('nav.tracking');
  String get navTeachers => t('nav.teachers');
  String get navAssignments => t('nav.assignments');
  String get navFiles => t('nav.files');
  String get navVideos => t('nav.videos');
  String get navNotifications => t('nav.notifications');
  String get navReports => t('nav.reports');
  String get navCalendar => t('nav.calendar');
  String get navTodos => t('nav.todos');

  // Common
  String get commonSave => t('common.save');
  String get commonCancel => t('common.cancel');
  String get commonDelete => t('common.delete');
  String get commonEdit => t('common.edit');
  String get commonClose => t('common.close');
  String get commonSearch => t('common.search');
  String get commonLoading => t('common.loading');
  String get commonError => t('common.errorUnexpected');
  String get commonRetry => t('common.retry');
  String get commonConfirm => t('common.confirm');
  String get commonBack => t('common.back');
  String get commonNext => t('common.next');
  String get commonPrevious => t('common.previous');
  String get commonNoData => t('common.noData');
  String get commonViewAll => t('common.viewAll');
  String get commonRefresh => t('common.refresh');
}

// ─── Delegate ───

/// [LocalizationsDelegate] for [AppLocalizations].
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ar' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      Future.value(AppLocalizations(locale));

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

// ─── Riverpod Providers ───

/// Provider that holds the current locale.
///
/// Defaults to Arabic. Persist changes via [AppConstants.localeKey].
final localeProvider = StateProvider<Locale>((ref) => defaultLocale);

/// Provider that returns [AppLocalizations] for the current locale.
final localizationsProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations(locale);
});

/// Provider that returns the current [TextDirection] based on locale.
final textDirectionProvider = Provider<TextDirection>((ref) {
  final locale = ref.watch(localeProvider);
  return textDirectionForLocale(locale);
});
