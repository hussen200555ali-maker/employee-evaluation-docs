# سجل التغييرات — حزمة CD-001 / توثيق الوحدات

## 2026-09-21 — CD-004 بند 9: إعادة تعيين كلمة المرور عبر Admin + إلزام التغيير + ر.ق 2 (شيفرة المصدر في جذر المشروع)
- `app/Models/User.php` — `updatePassword($userId, $newPassword, $mustChange = false)`: إعادة التعيين الإدارية تفعّل `must_change_password=1`، والتغيير العادي يمسحه إلى 0 (الحارس/السياسة/التاريخ كما في بند 11).
- `app/Controllers/Admin/UserController.php` — `resetPassword()` يستدعي `updatePassword(..., true)` ورسالة نجاح تُعلم بوجوب التغيير عند الدخول التالي.
- `app/Controllers/AuthController.php` — `login()`: بعد نجاح المصادقة، مستخدم `must_change_password=1` يُوجَّه إجباريًا إلى `/change-password` مع `Flash` توضيحي (الوجهة تُبنى في بند 10).
- **ر.ق 2 (إزالة استعادة كلمة المرور الميتة):** حذف رابط «نسيت كلمة المرور؟» (`href="#"`) + صف `form-options` الفارغ من `login.php`؛ حذف ملف `forgot-password.php` (0 بايت)؛ إزالة `'forgot-password'` من `skipRoutes` في `Auth::enforceCsrfToken` — الإعادة حصرية عبر Admin.
- `tests/cases/Core/AuthTest.php` — 4 اختبارات جديدة + استبدال `testEnforceCsrfTokenSkipsForgotPasswordPost` بـ `testEnforceCsrfTokenNoLongerSkipsForgotPassword`.
- إثبات: `php -l` نظيف + **AuthTest 43/43** + المجموعة الكاملة بلا انحدار (خط الأساس معروف).
- **توثيق:** `CD-004_IMPLEMENTATION.md` (بند 9) + `A1_Authentication_Unit_Documentation.md` (§8-10, G10, §10 سؤال 2, §11 P2 أُجيبوا بالحذف/الإزالة). التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-21 — CD-004 بند 11: سياسة كلمة المرور (شيفرة المصدر في جذر المشروع)
- `app/Core/Auth.php` — `PASSWORD_POLICY_MIN_LENGTH=8` + `PASSWORD_POLICY_HISTORY=3` + قائمة `PASSWORD_POLICY_COMMON` (أعلى 100) + `passwordPolicyRules()` + `validatePasswordPolicy()` (الطول/التنوع 3من4/السوداء/نبذ آخر 3) + `passwordReusedRecently()` + `recordPasswordHistory()` (prune إلى 3 عبر derived-table لتجاوز MySQL 1093) + `generateStrongPassword(12)` (CSPRNG يضمن الأنواع الأربعة).
- `app/Models/User.php` — الخاصية `lastPasswordErrors` + الحارس `guardPasswordChange()` + `updatePassword()` و`updateUser()` يفرضان السياسة ويسجّلان هاش القديم في `password_history`.
- `app/Controllers/Admin/UserController.php` — preflight بالسياسة في `store()`/`update()` (Flash برسائل موحّدة) و`resetPassword()` بمولّد `generateStrongPassword` واستجابة أخطاء موحّدة.
- `tests/cases/Core/AuthTest.php` — 9 اختبارات: القواعد المعتمدة، القبول، الرفض (فارغ/قصير/تنوع/سوداء)، نبذ آخر 3 + prune (الرابع الأقدم مسموح)، `updateUser` يفرض السياسة، توافق مولد بقوة مع السياسة بأكملها.
- إثبات: `php -l` نظيف + **AuthTest 40/40** + المجموعة الكاملة بلا انحدار (DatabaseTest 4/5، HelpersTest 2/3 خط أساس معروف).
- **توثيق:** `CD-004_IMPLEMENTATION.md` (بند 11) + `A1_Authentication_Unit_Documentation.md` (§10 سؤال 1 أُجيب + §11 توصية P2 + خارطة NIST/MFA→CD-005). التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-21 — إغلاق CD-004: اعتماد البند 6 + خطة C/B/A + سطور الإغلاق الإلزامية
- **إغلاق البند 6 (استيضاح المستشار)**: `git log` يُثبت التسلسل 6(`8a72979`)←7(`991e0bb`)←14(`0982b3e`) — البند 6 أُغلق قبل 7 و14؛ لا إعادة عمل. أدلة مُعادة التوكيد (القراءة الآنية): `php -l` نظيف لـ config.php/index.php/verify_phase1.php، غياب `config/app.php`+`performance.php`، حضور `storage/logs/php-error.log`+`storage/.htaccess`، grep بلا مراجع للملفين المحذوفين.
- **C — تذييل مرجعي تاريخي** بالنص الموحّد (مرجع تاريخي — الكود الفعلي يستخدم بحثًا ديناميكيًا عبر `roles.name='Admin' AND is_system_role=1`) في 4 مواضع: `CD-004_Execution_Plan.md:58`، `CD-004_IMPLEMENTATION.md:74`، `A1:246`، `docs/Phase_0_Documentation.md:46`. قرار المعتمد: لا تُذيَّل المواضع ذاتية التوثيق (CHANGELOG، سجل بند 14).
- **B — إعادة تحقق بند 14 بعد البند 6**: `AuthTest` **31/31** (DatabaseTest 4/5 وHelpersTest 2/3 خط أساس) + تكرر Live HTTP (بذرة → إشعار أساس → تدوير roles.id حتى 13 → إشعار عبر الدور الجديد Δ+1 → استعادة → تنظيف `USERS=0`) **PASS** — سُجّل في قسم بند 14.
- **A — سطور الإغلاق الإلزامية** «البند X مكتمل — Commit Y — إثبات في القسم Z» أُضيفت رجعيًا: المرحلة 0 (`1bdca31`)، 1 (`ab51405`)، 2 (`62499d3`)، 3 (`e0118ff`)، 4 (`6ce71d6`)، 5 (`19ce159`)، 6 (`8a72979`)، 7 (`991e0bb`)، 12 (`718c0e3`)، 14 (`0982b3e`).
- **OUT_OF_SCOPE**: #7 (`App.php:52` `if(DEBUG_MODE)` — غير حاجب، يُدرَج في CD-005) + #9 (نطاق بند 13 = تنظيف `csrf_tokens` فقط؛ إعادة المصادقة G13 مؤجلة لـA1-3 → CD-005).
- الاستئناف وفق الاعتماد: **المرحلة 3** (11→9→10). إثبات التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-21 — CD-004 بند 14: دور Admin ديناميكي (شيفرة المصدر في جذر المشروع)
- `app/Core/Auth.php` — `adminRoleIds()`: `roles.name='Admin' AND is_system_role=1` مع كاش ثابت لكل طلب وFallback آمن (لا إشعارات + `error_log('CD004_ITEM14…')` في `storage/logs/php-error.log`)، و`clearAdminRoleIdsCache()`؛ `notifyAdmins()` أعيدت كتابتها بـ`role_id IN (:rid…)` وتعود فورًا عند قائمة فارغة.
- `app/Core/CsrfGraceLogger.php` — `notifyAdmins` تستخدم `Auth::adminRoleIds()` (Remedy النطاق المعتمد للبند 14) لنفس النمط.
- `_emergency/create_api_keys_table.sql` + `_emergency/csrf_migration.sql` — `role_id=1` الصريح → `IN (SELECT id FROM roles WHERE name='Admin' AND is_system_role=1)`؛ أدوار HR/Manager/Staff بقيت ثوابت كما كانت.
- `tests/cases/Core/AuthTest.php` — `seedAdminUser` ديناميكي + أدوات تدوير/تنزيل دور Admin النظامي (`rotateAdminRole`/`restoreAdminRole`/`demoteSystemAdminRole`/`restoreSystemAdminRole`) و`notificationTitleCount`.
- الإثبات: grep شامل صفر + `php -l` نظيف + `AuthTest` 31/31 (وصول إشعار إدارة عبر معرّف جديد ≠ 1، وFallback بلا دور نظامي) + **Live HTTP** (تسجيل موقوف → إشعار؛ تدوير `roles.id` → إشعار عبر الدور الجديد ثم استعادة؛ تنظيف `USERS=0`) **PASS**.
- إعادة مرجعية «الاتفاقية»: معرّف الدور الترقيمي غير ثابت — المطابقة بالمعرّف فقط داخل نموذج عرض (radio) بلا كتابته في منطق التشغيل.
- **توثيق:** `CD-004_IMPLEMENTATION.md` (بند 14) + `CHANGELOG.md` (جذر/تسليم) + `A1_Authentication_Unit_Documentation.md` (3 مواضع). تفاصيل الإثبات الكاملة في `CD-004_IMPLEMENTATION.md`.

## 2026-09-16 — CD-004 بند 7: إصلاح حارس Admin/UserController (شيفرة المصدر في جذر المشروع)
- `app/Controllers/Admin/UserController.php` — `exit;` بعد `forbidden()` داخل `__construct`: سابقًا `return forbidden()` بلا `exit` يترك تنفيذ دالة الإدارة يستمر للمستخدم غير Admin (Remedy A1 §2 أ: الحارس القاصر Google-Bot-accessible).
- `tests/cases/Core/AuthTest.php` — `testAdminUserControllerGuardStopsNonAdmin` (subprocess: غير-Admin يتوقف عند 403 بلا «إدارة المستخدمين»؛ وAdmin يمر — `ADMIN_PASSED`).
- الإثبات: `php -l` + `AuthTest` 29/29 + Live HTTP (Staff → GET `/admin/users` 403 بلا محتوى إداري وPOST `update-role` 403 بلا `USER_ROLE_UPDATE`؛ Admin → GET 200 مع الصفحة؛ تنظيف `USERS=0`) PASS. **توثيق:** `CD-004_IMPLEMENTATION.md` (بند 7) + `CD-004_OUT_OF_SCOPE.md` (بند 8: قياس `runCli`).

## 2026-09-16 — CD-004 بند 6: إخفاء الأخطاء ودمج الإعدادات (شيفرة المصدر في جذر المشروع)
- `config/config.php` — دمج `app.php` + `performance.php` (ر.ق 1): `memory_limit=2048M`، `max_execution_time=600`، `BACKUP_BATCH_SIZE=100`؛ `DEBUG_MODE=false` + `display_errors=0` + `log_errors=1` + `error_log → storage/logs/php-error.log`؛ `opcache_reset()` مستبعد عمدًا من الدمج.
- حذف `config/app.php` + `config/performance.php` — لا `require` لهما في أي موضع (متحقق grep قبل/بعد).
- `public/index.php` — إزالة فرع `DEBUG_MODE` وطباعة الـ Trace (44–49) → `error_log` كامل + `http_response_code(500)` + صفحة عامة.
- `storage/logs/` + `storage/.htaccess` (`Require all denied` — حماية السجلات والنسخ من الوصول عبر الويب).
- `_emergency/verify_phase1.php` — فحوصات بند 6 في [2/8] + `PHP_BINARY` ليعمل بلا `php` على PATH.
- وثائق محدّثة: `07_Technical_Implementation_Details.md`, `10_Performance_Backup_API.md`, `99_Master_Handover_Report.md`, `A1_Authentication_Unit_Documentation.md` (إزالة مراجع app.php/performance.php وضبط DEBUG_MODE).
- إثبات: `php -l` + grep بلا مراجع + `AuthTest` 28/28 + اختبار خطأ متعمد (CLI/HTTP) سُجّل في `storage/logs/` وأُخفي من الشاشة + Live HTTP (login 200، storage→403، مسبار 500 صامت) + verify_phase1 [2/8] 10/10. التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-16 — CD-004 بند 4: الخروج عبر POST (شيفرة المصدر في جذر المشروع)
- `routes/web.php` — حذف `GET /logout` نهائيًا (أصبح 404) واستبداله بـ`POST /logout` (Remedy P2 في A1 §3.3) — يمنع Logout-CSRF عبر رابط مُضمَّن.
- `app/Controllers/AuthController.php` — `logout()`: `Auth::logout()` + `session_destroy()` + إتلاف كوكي الجلسة (EVALSESSID) عبر `setcookie(session_name(), '', time()-42000, ...)` ثم توجيه `/login`.
- `app/Views/layouts/header.php` — ربط الخروج من `<a href>` إلى نموذج POST مع `csrf_field()` (يُغطَّى بـ`Auth::enforceCsrfToken`).
- `tests/cases/Core/AuthTest.php` — `testLogoutRouteIsPostOnly` (تحقق Reflection من خريطة `$router`: لا `GET['logout']`، و`POST['logout']` صحيح).
- `appendices/routes_inventory.txt` — سطر logout حُدِّث إلى POST + تعليق البند.
- إثبات: `php -l` + `AuthTest` 28/28 + Live HTTP (GET /logout→404 والجلسة سليمة؛ POST بلا توكن→رفض CSRF والجلسة سليمة؛ POST بتوكن→302 `/login` مع `Set-Cookie: EVALSESSID=deleted; Max-Age=0` والجلسة ملغاة؛ نموذج header يحوي action/token) PASS. التفاصيل في `CD-004_IMPLEMENTATION.md`.

## 2026-09-15 — CD-004 بند 1: فحص users.status بعد password_verify (شيفرة المصدر في جذر المشروع)
- `app/Controllers/AuthController.php` — بعد نجاح كلمة المرور: `active` يكمل الدخول؛ `suspended`/`invited` يُرفضان مع `Audit::log` (`USER_LOGIN_SUSPENDED`/`USER_LOGIN_INVITED`) وإشعار `Auth::notifyAdmins` وفلاش وتوجيه `/login`. تدفق `invited` الكامل مؤجل إلى بند 10.
- `tests/cases/Core/AuthTest.php` — 3 اختبارات (رفض suspended/رفض invited/قبول active) عبر عملية فرعية + بذر/تنظيف مستخدمين مؤقتين.
- إثبات: `php -l` + `AuthTest` 27/27 (مرتان، بلا بقايا) + Live HTTP (suspended/invited → /login مع Audit+إشعار؛ active → /dashboard) PASS. التفاصيل في `CD-004_IMPLEMENTATION.md`.

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