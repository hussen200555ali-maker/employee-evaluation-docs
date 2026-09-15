# سجل التغييرات — حزمة CD-001 / توثيق الوحدات

## 2026-09-15 — CD-004 بند 2: قفل محاولات الدخول (شيفرة المصدر في جذر المشروع)
- `app/Core/Auth.php` — ثوابت ومساعدات القفل (`MAX_LOGIN_ATTEMPTS=5`, `LOCKOUT_WINDOW_SECONDS=900`, `countLoginFailures`, `isLoginLocked`, `logLoginAttempt`, `clearLoginAttempts`, `loginDelaySeconds`, `notifyLoginLocked`) عبر جدول `login_attempts` المترحّل (بند 0).
- `app/Controllers/AuthController.php` — منع الدخول قبل التحقق للحساب المقفول؛ تسجيل الفشل + تأخير متدرج 1/2/4/8ث؛ القفل عند 5 فاشلة/15د مع `USER_LOGIN_LOCKED` وإشعار محذر لـAdmin؛ النجاح يمسح المحاولات.
- `tests/cases/Core/AuthTest.php` — 3 اختبارات جديدة.
- إثبات: `php -l` + `AuthTest` 24/24 + Live HTTP (failCount 1→5، أوقات رصدت 1/2/4/8/8ث، إشعار للمشرف، الطلبان #6/#7 مرفوضان مع بقاء العد=5). التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-15 — CD-004 بند 12: إزالة «تذكرني» (شيفرة المصدر في جذر المشروع)
- `app/Views/auth/login.php` — حذف checkbox «تذكرني» (كان بلا `name`)؛ بقيت `form-options` مع رابط «نسيت كلمة المرور؟».
- إثبات: `php -l` نظيف + Live HTTP (لا `name="remember"` في صفحة الدخول، ورابط forgot-password حاضر). التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-15 — CD-004 بند 3: CSRF صفحة الدخول (شيفرة المصدر في جذر المشروع)
- `app/Core/Auth.php` — `generateCsrfToken`/`validateCsrfToken` يعملان **قبل المصادقة** (الجلسة أولًا؛ DB طبقة ثانية للمصادقين عبر `self::check()`)؛ إزالة `'login'` من `$skipRoutes` في `enforceCsrfToken` → POST /login يخضع الآن لفحص CSRF.
- `app/Views/auth/login.php` — `csrf_field()` داخل نموذج الدخول.
- `tests/cases/Core/AuthTest.php` — استبدال اختبار السلوك القديم (المسبب لـ`exit()` الصامت في المشغّل) باختبارَي السلوك الجديد.
- إثبات: `php -l` + محاكاة توكن ما قبل المصادقة PASS + Live HTTP (GET يحوي التوكن؛ إعادة استخدام عبر إعادة التحميل؛ POST بتوكن صحيح → /login، بدون/خاطئ → رفض) + `AuthTest` 21/21. التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-15 — CD-004 بند 5: تحصين الجلسة (شيفرة المصدر في جذر المشروع)
- `config/config.php` — إعدادات جلسة موحّدة قبل `session_start()`: `session_name('EVALSESSID')`, `gc_maxlifetime=1800`, `cookie_httponly=1`, `cookie_samesite=Strict`, `use_strict_mode=1`, `use_only_cookies=1`, `cookie_lifetime=0` + إزالة السطر الفارغ الفاتح.
- `public/index.php` — تحميل الإعدادات قبل `session_start()` (كان بعده فيُبطل فعاليتها) + تحويل الترميز CP-1256→UTF-8 (معكوس وحرفي).
- إثبات: `php -l` نظيف + smoke فعّال + `AuthTest` 20/20. التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-15 — CD-004 المرحلة 0: ترحيل قاعدة بيانات A1
- `CD-004_Execution_Plan.md` — خطة تنفيذ الوحدة A1 معتمدة (قرار كبير المستشارين 2026-09-15، 5 ملاحظات إلزامية).
- `CD-004_IMPLEMENTATION.md` — سجل تنفيذ يُحدَّث بعد كل بند؛ أُنجِزت المرحلة 0 (ترحيل DB + Dry Run لخطة التراجع + تحقق DROP password_resets).
- `CD-004_OUT_OF_SCOPE.md` — سجل ما خارج النطاق (ملاحظة الـENUM + فشلان سابقان في اختبارات غیر مرتبطة).
- `database/migrations/2026_09_15_A1_authentication.sql` — login_attempts + password_history + users(must_change_password, permissions_version) + DROP password_resets. انحدار خفيف: AuthTest 20/20.

## 2026-09-15 — CD-003: التوثيق التفصيلي للوحدة A1
- `A1_Authentication_Unit_Documentation.md` + `.pdf` — دراسة قراءة فقط لوحدة المصادقة والدخول والجلسات بالأقسام الأحد عشر (نظرة عامة، الملفات والمكونات، دورة العمل، الشاشات، قواعد العمل، الأمان الحالي، نقاط القوة، نقاط الضعف، الفجوات، الأسئلة المفتوحة، التوصيات).
- تأكيد نتائج `13_Security.md`: لا قفل محاولات، لا فحص لحالة الحساب عند الدخول، حارس `Admin\UserController` مكسور، وجلسة غير محصّنة (`config/performance.php` غير محمّل).
- إعلان صريح: لقطات الشاشات غير متوفرة (MySQL متوقف لاستعادة حالة الاستضافة الأصلية) — تُوثَّق الشاشات من مصدر العرض.

## 2026-09-15 — CD-001: حزمة التوثيق الكاملة v1.0
- الوثائق 01–15 + `00_INDEX` + `00_COVER` + `99_Master_Handover_Report` + `appendices/` (schema, routes_inventory, views_inventory, live_data_snapshot).

---

**نهاية سجل التغييرات — CD-001/CD-003/CD-004**