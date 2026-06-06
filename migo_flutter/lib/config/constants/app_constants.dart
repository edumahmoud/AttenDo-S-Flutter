/// Application-wide constants for the AttenDo student app.
class AppConstants {
  AppConstants._();

  // ─── App Identity ───
  static const String appName = 'AttenDo';
  static const String appNameAr = 'أتيندو';
  static const String appVersion = '0.2.0';

  // ─── Supabase ───
  static const String supabaseUrl = 'https://tuoxwggvafuuabugdduh.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR1b3h3Z2d2YWZ1dWFidWdkZHVoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwODk2MDQsImV4cCI6MjA5MTY2NTYwNH0.nXGlyVrpHwza93jN40EYgewV7fxmh4FSApp9yk1GLAA';

  // ─── API ───
  // رابط خادم Next.js اللي عليه الـ API routes
  // غيّره لرابط المشروع النشر بتاعك (مثلاً: https://attendo.vercel.app)
  static const String apiBaseUrl = 'https://tuoxwggvafuuabugdduh.supabase.co';

  // ─── Socket ───
  // رابط خادم Socket.IO للمحادثة الفورية
  static const String socketUrl = 'https://tuoxwggvafuuabugdduh.supabase.co';

  // ─── Storage Keys ───
  static const String authStorageKey = 'attendo_auth';
  static const String authDataKey = 'auth_data';
  static const String appStoreKey = 'attendo_app_store';
  static const String localeKey = 'attendo_locale';
  static const String themeKey = 'attendo_theme';
  static const String themeModeKey = 'app_theme_mode';

  // ─── Timeouts ───
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 15);

  // ─── Supabase Storage Buckets ───
  static const String avatarsBucket = 'avatars';
  static const String assignmentsBucket = 'assignments';
  static const String materialsBucket = 'materials';

  // ─── Navigation ───
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double sidebarExpandedWidth = 264;
  static const double sidebarCollapsedWidth = 68;
  static const double headerHeight = 64;
  static const double bottomNavHeight = 64;

  // ─── Pagination ───
  static const int defaultPageSize = 20;

  // ─── Attendance ───
  static const double gpsMaxDistanceMeters = 50;

  // ─── User Roles ───
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleAdmin = 'admin';
  static const String roleSuperadmin = 'superadmin';

  // ─── Attendance Status ───
  static const String attendancePresent = 'present';
  static const String attendanceAbsent = 'absent';
  static const String attendanceLate = 'late';
  static const String attendanceExcused = 'excused';

  // ─── File Limits ───
  static const int maxFileSizeMB = 10;
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;
  static const int maxAvatarSizeMB = 5;
  static const int maxAvatarSizeBytes = maxAvatarSizeMB * 1024 * 1024;

  // ─── Password ───
  static const int passwordMinLength = 6;
  static const int usernameMinLength = 3;

  // ─── Date Formats ───
  static const String dateFormatAr = 'yyyy/MM/dd';
  static const String dateFormatEn = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormatAr = 'yyyy/MM/dd HH:mm';
  static const String dateTimeFormatEn = 'dd/MM/yyyy HH:mm';

  // ─── Quiz ───
  static const int quizDefaultDurationMinutes = 30;

  // ─── Summary ───
  static const int summaryTimeoutSeconds = 120;

  // ─── Chat ───
  static const int chatMessageMaxLength = 2000;
}
