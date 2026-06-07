---
Task ID: 1
Agent: Main Agent
Task: فحص وتحويل مشروع Migo (AttenDo) Next.js إلى تطبيق Flutter لواجهة الطالب

Work Log:
- استنساخ الريبو من GitHub (https://github.com/edumahmoud/migo.git)
- فحص شامل لهيكل المشروع (SPA بنظام توجيه Zustand)
- استخراج الهوية البصرية (ألوان ocean blue + teal accent + amber)
- تحديد 16 قسم لواجهة الطالب
- فهم نظام المصادقة (Supabase Auth) وقاعدة البيانات (Supabase PostgreSQL)
- تثبيت Flutter SDK 3.44.1
- إنشاء مشروع Flutter مع البنية models/views/controllers
- بناء نظام التصميم (Theme + Colors + Typography)
- بناء 17 ملف Models مطابق لأنواع TypeScript
- بناء 9 Services (Supabase, Auth, API, AI, Socket, Notification, File, Storage)
- بناء 17 Controllers مع Riverpod StateNotifier
- بناء Routes مع GoRouter + StatefulShellRoute
- بناء 3 شاشات مصادقة (تسجيل دخول/تسجيل/استعادة كلمة مرور)
- بناء شل الداشبورد (AppBar + Sidebar + BottomNav)
- بناء 16 شاشة لأقسام الطالب
- بناء 7 مكونات مشتركة
- نظام i18n مع 450+ مفتاح ترجمة عربي/إنجليزي
- إصلاح جميع التحذيرات والأخطاء (0 errors, 0 warnings)

Stage Summary:
- المشروع النهائي: 106 ملف Dart، 33,669 سطر كود، ~1.1MB
- صفر أخطاء تحليل (فقط info-level hints)
- الحفاظ على نفس الهوية البصرية (ocean blue, teal accent, RTL)
- نفس أدوات الاتصال بقاعدة البيانات (Supabase + API routes)
- تطبيق كامل لواجهة الطالب مع 16 قسم
