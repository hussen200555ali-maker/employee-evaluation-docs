# CD-004 — سجل التنفيذ (الوحدة A1)

وفق الملاحظة الإلزامية 2: يُحدَّث **بعد كل بند**، لا في النهاية. تنسيق كل إدخال: الوصف، الملفات، إثبات، التاريخ.

---

## المرحلة 0 — ترحيل قاعدة البيانات (يوم 1)

| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `database/migrations/2026_09_15_A1_authentication.sql` + نسخة `CD-001_delivery/database/migrations/` |

### Dry Run لخطة التراجع (ملاحظة إلزامية 3)
نُفِّذ قبل المرحلة 0 — غير مدمر، وأثبت عمل مسارَي النسخ/الاسترجاع:
1. **النسخ (Backup)**: `mysqldump --single-transaction --routines --triggers` اكتمل بدون أخطاء (خروج 0، stderr فارغ، حجم 884,711 بايت) وأنتج ملفًا ذي رأس سليم `-- MariaDB dump 10.19 Distrib 10.4.32`، ويحتوي جداول `notifications`/`password_resets`/`users` ويخلو من الجدولين الجديدين (الوضع قبل الترحيل). ✔
2. **الاسترجاع (Restore)**: عميل `mysql.exe` يتصل بنفس الاعتماديات وينفذ استعلامًا (SELECT 1) بنجاح — مسار `mysql -uroot employee_evaluation_mvc < dump` جاهز وظيفيًا. ✔
3. **الملفات**: نسخ `config/app.php`, `config/config.php`, `config/performance.php`, `app/Views/auth/forgot-password.php` إلى `_emergency/rollback/CD-004/2026-09-15/` (هيكل config/ + views/) وقراءتها. ✔
**الخلاصة**: خطة التراجع جاهزة وقابلة للتطبيق؛ يُعاد Dry Run قبل كل مرحلة بتحديث النسخ.

### التحقق قبل DROP password_resets (ملاحظة إلزامية 5)
| البند | النتيجة |
|---|---|
| عدد الصفوف | 0 (فارغ) — لا خسارة بيانات |
| مراجع FK من جداول أخرى (`information_schema.KEY_COLUMN_USAGE` حيث `REFERENCED_TABLE_NAME='password_resets'`) | **0 مرجع** |
| مراجع كود تشغيلي PHP | لا يوجد (تحقق grep مسبق: `password_resets` لا يظهر إلا في SQL dumps ونسخ البنية `_emergency/` والوثائق) |
| بنية الجدول | `email PK, token, created_at` — بلا `expires_at`/`used` (لا يُستخدم في أي تدفق) |
| الاستنتاج | **DROP آمن** — تحقق موثق قبل التنفيذ |

### النسخ الاحتياطي (قبل الترحيل)
| الأصل | الوجهة |
|---|---|
| DB كامل | `storage/backups/CD-004/2026-09-15/employee_evaluation_mvc_before_phase0.sql` (884,711 بايت، MariaDB dump) |
| `config/app.php`, `config/config.php`, `config/performance.php` | `_emergency/rollback/CD-004/2026-09-15/config/` |
| `app/Views/auth/forgot-password.php` | `_emergency/rollback/CD-004/2026-09-15/views/auth-forgot-password.php` |

### ترحيل DB — `2026_09_15_A1_authentication.sql`
أُسند وأُطبِّق عبر `mysql -uroot --default-character-set=utf8mb4 ... source file` (خروج 0):
1. `DROP TABLE IF EXISTS password_resets;` ✔
2. `CREATE TABLE login_attempts` (id، username VARCHAR(100)، ip_address VARCHAR(45)، attempted_at، success TINYINT(1)، مفاتيح `idx_login_username_time` و`idx_login_attempted_at`) ✔
3. `CREATE TABLE password_history` (user_id INT(11) مطابق users.id، password_hash VARCHAR(255)، created_at، **FK `fk_pwhistory_user` → users(id) ON DELETE CASCADE**) ✔
4. `ALTER TABLE users` +`must_change_password TINYINT(1) NOT NULL DEFAULT 0` +`permissions_version INT UNSIGNED NOT NULL DEFAULT 1` ✔

**فحص بعد الترحيل** (probe): `login_attempts=1`, `password_history=1`, `password_resets=NO`, أعمدة `users` الجديدة موجودة بالقيم الافتراضية، وFK جديد واحد (`password_history.fk_pwhistory_user`). ✔

### انحدار خفيف بعد الترحيل
- `AuthTest` **20/20 نجاح** (الاختبار الحرج لنظام الدخول غير متأثر). ✔
- فشلان **سابقان** غير مرتبطين بالترحيل (اختبارات معيوبة قائمة): `DatabaseTest::testRowCount` (دلالة `rowCount()` بعد `SELECT COUNT(*)` تعيد 1 صفًا) و`HelpersTest::testConvertToHijriValidDate` (تحويل تاريخ هجري) — سُجّلا في `CD-004_OUT_OF_SCOPE.md` ولا يُصلحان ضمن البنود 1–15.

- **الإغلاق:** المرحلة 0 مكتملة — Commit `1bdca31` — إثبات في «المرحلة 0 — ترحيل قاعدة البيانات» بهذا الملف.

---

## البنود 1–15
(تُضاف بعد كل بند)

### بند 1 — فحص `users.status` بعد `password_verify`
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `app/Controllers/AuthController.php`، `tests/cases/Core/AuthTest.php` |

**التنفيذ:**
- في `AuthController::login()` بعد نجاح `password_verify` (وبعد مسح/تسجيل المحاولة الناجحة) أُضيف فحص `$userCheck->status`:
  - `active`: يُكمل تدفق الدخول الحالي إلى `/dashboard`.
  - `suspended`: رفض + `Audit::log('USER_LOGIN_SUSPENDED', id, 'users', {username})` + `Auth::notifyAdmins('محاولة دخول بحساب موقوف — …')` + فلاش «تم تعليق حسابك…» + توجيه إلى `/login`.
  - `invited`: رفض + `Audit::log('USER_LOGIN_INVITED', id, 'users', {username})` + `Auth::notifyAdmins('محاولة دخول بحساب غير مفعَّل — …')` + فلاش «لم يتم تفعيل حسابك بعد…» + توجيه إلى `/login`.
- **قرار داخل البند:** تدفق `invited` الكامل (شاشة تعيين كلمة المرور + التوجيه الإجباري) مؤجل إلى **بند 10**؛ في هذا البند يُرفض الدخول لكلا الحالتين. لا توجد شاشة تعيين كلمة مرور ولا مسار لها في `routes/web.php` حاليًا.
- المساعد العام `Auth::notifyAdmins(title, message)` (أُضيف مسبقًا كخطوة أولى للبند) هو مسار الإشعار الموحّد، ويُعيد استخدامه بند 2 أيضًا (`notifyLoginLocked`).

**الإثبات:**
- `php -l` للملفين: لا أخطاء. ✔
- `AuthTest` **27/27 نجاح** (3 اختبارات جديدة عبر عملية فرعية مع بذر مستخدمين مؤقتين وقراءة أثر التنفيذ):
  - `testLoginRejectsSuspendedAccount` — كلمة مرور صحيحة + `status=suspended` → لا جلسة (`SESSION_USER_ID=none`) + فلاش الرفض + `USER_LOGIN_SUSPENDED` + إشعار لمشرف نشط (role_id=1 — مرجع تاريخي؛ الكود الفعلي يستخدم بحثًا ديناميكيًا عبر roles.name = 'Admin' AND is_system_role = 1). ✔
  - `testLoginRejectsInvitedAccount` — نفسه مع `invited` + `USER_LOGIN_INVITED`. ✔
  - `testLoginContinuesForActiveAccount` — `active` → جلسة مؤمّنة (`SESSION_USER_ID=<id>`) بلا فلاش + `USER_LOGIN_SUCCESS`. ✔
  - تنظيف تلقائي في `tearDown` (بذر معزول بأسماء `cd004.*`)؛ شُغِّل الاختبار **مرتين متتاليتين** → 27/27 وبلا أي صفوف متبقية (تحقق SQL: users=0, login_attempts=0, notifications=0). ✔
- **Live HTTP** (Apache/MySQL، نموذج الدخول الحقيقي مع توكن CSRF): ثلاثة مستخدمين مؤقتين (suspended/invited/active) بكلمة مرور صحيحة →
  - suspended: `302 → /login` + `ACTION_USER_LOGIN_SUSPENDED=1` + `NOTIF=1`.
  - invited: `302 → /login` + `ACTION_USER_LOGIN_INVITED=1` + `NOTIF=1`.
  - active (ضبط موجب): `302 → /dashboard` + `ACTION_USER_LOGIN_SUCCESS=1` + `NOTIF=0`.
  - تنظيف: `USERS=0` → **PASS**. ✔
- انحدار خفيف: `DatabaseTest` 4/5 و`HelpersTest` 2/3 (نفس الفشلين السابقين الموثقين في OUT_OF_SCOPE) — بلا انحدار جديد. ✔

- **الإغلاق:** البند 1 مكتمل — Commit `ab51405` — إثبات في قسم «بند 1 — فحص users.status بعد password_verify» بهذا الملف.

### بند 2 — قفل محاولات الدخول
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `app/Core/Auth.php`، `app/Controllers/AuthController.php`، `tests/cases/Core/AuthTest.php` |

**التنفيذ:**
- `Auth` (دوال ثابتة جديدة + ثوابت): `MAX_LOGIN_ATTEMPTS=5`، `LOCKOUT_WINDOW_SECONDS=900` (15 دقيقة)، `countLoginFailures(username)`، `isLoginLocked(username)`، `logLoginAttempt(username, success, userId)` (تخزين username+IP في `login_attempts`)، `clearLoginAttempts(username)`، `loginDelaySeconds(priorFailures)` (تأخير متدرج 1/2/4/8 ثوانٍ بسقف 8)، `notifyLoginLocked(username)` (إشعار نوع `warning` لجميع أدوار Admin النشطة — نفس نهج CsrfGraceLogger).
- `AuthController::login()`:
  - قبل التحقق من الاعتمادات: إذا كان الحساب مقفولًا → رفض + `Audit::log('USER_LOGIN_LOCKED_BLOCKED')` + فلاش + توجيه (بدون تسجيل محاولة جديدة).
  - عند الفشل: يُحسب عدد المحاولات السابقة ثم يُسجَّل فشل جديد؛ عند بلوغ العتبة (5) → `Audit::log('USER_LOGIN_LOCKED')` + `notifyLoginLocked` + فلاش القفل، وإلا فلاش الاعتمادات الخاطئة؛ ثم `sleep` بالتأخير المتدرج قبل الرد (أوقات فعلية رُصدت: 1/2/4/8/8 ثانية).
  - عند النجاح: `clearLoginAttempts` + `logLoginAttempt(..., true)` ثم التدفق الحالي (مسح الجلسة/أدوار/صلاحيات/Audit).
- إعادة صياغة استخراج `username` بـ`trim` (اتساق مفتاح القفل).

**قرار داخل البند:** مفتاح القفل هو `username` (حماية الحساب) بغض النظر عن IP؛ يُخزَّن IP في السجلات للتحقيق.

**الإثبات:**
- `php -l` للملفات الثلاثة: لا أخطاء. ✔
- `AuthTest` **24/24 نجاح** (3 اختبارات جديدة: تسلسل التأخير، العد/القفل/المسح، مسح عند النجاح). ✔
- **Live HTTP**: 5 طلبات POST بـاعتمادات خاطئة وتوكن صحيح → failCount 1→5، أوقات ~1.1/2.1/4.1/8.1/8.1 ثانية؛ بعد الخامسة: إشعار في `notifications` (title يحوي اسم المستخدم، type=warning للمشرفين)؛ الطلبان #6 و#7 → فشل **مُحصَّل** (failCount يبقى 5 — لا محاولة جديدة على المسار المقفول) → PASS. تنظيف السجلات والإشعارات التجريبية بعد الاختبار. ✔

- **الإغلاق:** البند 2 مكتمل — Commit `62499d3` — إثبات في قسم «بند 2 — قفل محاولات الدخول» بهذا الملف.

### بند 3 — CSRF صفحة الدخول
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `app/Core/Auth.php`، `app/Views/auth/login.php`، `tests/cases/Core/AuthTest.php` |

**التنفيذ:**
- `Auth::generateCsrfToken()`: أصبح يعمل **قبل المصادقة** — أُزيل `if (!self::check()) return '';` المبكّر؛ يعيد استخدام توكن الجلسة الحالي طالما لم تنتهِ صلاحيته (يمنع إبطال توكنات الصفحات الأخرى)؛ تخزين DB (`csrf_tokens`) محصور داخل `self::check()` (الجدول يتطلب `user_id`) مع try/catch للنسخة غير المنتقلة.
- `Auth::validateCsrfToken()`: يتحقق من **الجلسة أولًا** (يعمل قبل المصادقة لتوكن صفحة الدخول)، ثم DB كطبقة ثانية للمستخدمين المسجّلين فقط.
- `enforceCsrfToken()`: أُزيل `'login'` من `$skipRoutes` — أصبح `['register', 'forgot-password', 'reset-password']` وبه تعليق يوثق بند 3 (POST /login الآن يخضع للتحقق من CSRF)؛ الاستثناءات المتبقية لمسارات ما قبل المصادقة التي تولّد توكناتها داخل صفحاتها، ولـ`api/`.
- `app/Views/auth/login.php`: أُضيف `csrf_field()` داخل نموذج POST — يولّد التوكن قبل المصادقة.

**لازم وظيفي (اختبارات):**
- `AuthTest::testEnforceCsrfTokenSkipsLoginPost` كان يختبر السلوك القديم (تخطي POST /login)؛ بعد بند 3 صار `enforceCsrfToken` يرفض الطلب بلا توكن ويدعو `exit()` (Auth.php:235) فيُنهي **مشغّل الاختبارات كلها** بصمت (خروج 0 بلا أي إخراج) — هذا سبب «اختفت مخرجات runner.php». استُبدل الاختبار باختبارين للسلوك الجديد: `testEnforceCsrfTokenAllowsLoginPostWithValidToken` (توكن صحيح يمرّ) و`testEnforceCsrfTokenRejectsLoginPostWithoutToken` (رفض بلا توكن عبر عملية فرعية — لا يصل تنفيذ ما بعد الرفض).

**الإثبات:**
- `php -l` لـ `Auth.php` و`login.php` و`AuthTest.php`: لا أخطاء. ✔
- محاكاة توكن ما قبل المصادقة (سكربت تجريبي): طول 64، إعادة استخدام `reuse_same=yes`، تحقق صحيح `validate_ok=yes`، تحقق خاطئ مرفوض `validate_bad=rejected` → PASS. ✔
- **Live HTTP** (Apache/MySQL): GET /login → 200 ويحوي `name="_token"` بقيمة 64-سداسي عشرية (csrffield يُرسم قبل المصادقة)؛ إعادة استخدام التوكن عبر إعادة تحميل الصفحة (REUSE_SAME=True)؛ POST /login **بتوكن صحيح** → 302 → `/login` (وصل لفحص الاعتمادات — مرّ من بوابة CSRF)؛ POST **بلا توكن** أو **بتوكن خاطئ** → 302 → `/evaluations/excel/import` (رفض CSRF كما هو محدد بلا HTTP_REFERER). ✔
- `AuthTest` **21/21 نجاح** (بعد تحديث الاختبارات للسلوك الجديد)؛ المجموعة الكاملة: AuthTest 21/21 — مع فشلين سابقين موثقين (`DatabaseTest` 4/5، `HelpersTest` 2/3). ✔

- **الإغلاق:** البند 3 مكتمل — Commit `e0118ff` — إثبات في قسم «بند 3 — CSRF صفحة الدخول» بهذا الملف.

### بند 4 — الخروج عبر POST
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-16 |
| الحالة | **مكتمل** |
| الملفات | `routes/web.php`، `app/Controllers/AuthController.php`، `app/Views/layouts/header.php`، `tests/cases/Core/AuthTest.php`، `CD-001_delivery/appendices/routes_inventory.txt` |

**التنفيذ (Remedy P2 في وثيقة A1 §3.3):**
- `routes/web.php`: حُذف `$router->get('logout', ...)` نهائيًا (أصبح GET /logout → 404) واستُبدل بـ`$router->post('logout', ...)` مع تعليق يوثق البند — الخروج الآن عبر POST فقط، ما يمنع Logout-CSRF عبر رابط مُضمَّن.
- `AuthController::logout()`: `Auth::logout()` (مسح بيانات الجلسة) + `session_destroy()` + **إتلاف كوكي الجلسة صراحةً** عبر `setcookie(session_name(), '', time()-42000, path/domain/secure/httponly)` محروسًا بـ`ini_get('session.use_cookies')` وبقيم `session_get_cookie_params()` (اسم الكوكي الفعلي EVALSESSID بعد بند 5) ثم توجيه `/login`.
- `app/Views/layouts/header.php`: ربط الخروج في القائمة المنسدلة تحوّل من `<a href>` إلى **نموذج POST** (method=POST، action=APP_URL/logout) مع `csrf_field()` — يُغطَّى تلقائيًا بـ`Auth::enforceCsrfToken()` (public/index.php:37).
- `CD-001_delivery/appendices/routes_inventory.txt`: سطر المسار حُدِّث إلى POST + تعليق البند.
- نسخ تراجع: `_emergency/rollback/CD-004/2026-09-15/AuthController.pre-item4.php`, `views/header.pre-item4.php`, `routes/web.pre-item4.php`.

**الإثبات:**
- `php -l` للملفات الأربعة: لا أخطاء. ✔
- `AuthTest` **28/28 نجاح** (اختبار جديد `testLogoutRouteIsPostOnly`: عبر Reflection يتحقق من خريطة `$router` أن `GET['logout']` غير موجود وأن `POST['logout']` = `App\Controllers\AuthController@logout`). ✔
- **Live HTTP** (Apache/MySQL، جلسة حقيقية EVALSESSID): مستخدم مؤقت فاعل →
  - GET /logout → **404** وبعدها GET /dashboard → **200** (الجلسة سليمة — رابط GET لا يُخرج). ✔
  - POST /logout **بلا توكن** → 302 → `/evaluations/excel/import` (رفض CSRF كما هو محدد — لا توجيه لدخول) وبعدها GET /dashboard → **200** (الجلسة سليمة). ✔
  - POST /logout **بتوكن CSRF سليم** (مستخرج من نموذج الخروج المعروض في الـ header) → **302 → /login** مع `Set-Cookie: EVALSESSID=deleted; expires=Thu, 01 Jan 1970 …; Max-Age=0` (كوكي مُتْلَف) وبعدها GET /dashboard → **302 → /login** (الجلسة ملغاة). ✔
  - تحقق أن نموذج الخروج في الـ header يحوي `action=".../logout"` + `name="_token"` (64 محرفًا). ✔
  - تنظيف: USERS=0, NOTIF=0, ATTEMPTS=0, USER_ROLES=0, AUDIT=0 → **PASS**. ✔
- انحدار خفيف: `DatabaseTest` 4/5 و`HelpersTest` 2/3 (الفشلان السابقان الموثقان في OUT_OF_SCOPE) — بلا انحدار جديد. ✔

- **الإغلاق:** البند 4 مكتمل — Commit `6ce71d6` — إثبات في قسم «بند 4 — الخروج عبر POST» بهذا الملف.

### بند 5 — تحصين الجلسة
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `config/config.php` (إعدادات الجلسة + إزالة السطر الفارغ الفاتح)، `public/index.php` (إعادة ترتيب: تحميل الإعدادات قبل `session_start`) |

**التنفيذ:**
- `config/config.php`: كتلة إعدادات جلسة موحّدة تُنفَّذ قبل `session_start()`: `session.gc_maxlifetime=1800`, `session.cookie_lifetime=0`, `session.cookie_httponly=1`, `session.cookie_samesite=Strict`, `session.cookie_secure=0`, `session.use_strict_mode=1`, `session.use_only_cookies=1`, `session_name('EVALSESSID')` (محروسة بـ`session_status()===PHP_SESSION_NONE`).
- `public/index.php`: نُقل `require config/config.php` و`require config/database.php` **قبل** `session_start()` (كانا بعدها — فسيسبب الإعدادات بلا مفعول).

**اكتشافات عرَضية عُولجت ضمن البند (لازمه وظيفي للبند ذاته):**
1. `config/config.php` كان يبدأ بسطر فارغ قبل `<?php` → إخراج مبكر يمنع فعالية إعدادات الجلسة — أُزيل السطر الفاتح.
2. `public/index.php` كان مشفّرًا **CP-1256** (تراثي) → حُوِّل إلى **UTF-8** (التحويل حرفي معكوس 1:1، لا تغيير دلالي) — نسخة مكافئة CP-1256 محفوظة في `_emergency/rollback/CD-004/2026-09-15/index.php.orig-cp1256.raw`.

**إشعار مسبق (ملاحظة إلزامية 1):** تغيير `session_name` إلى `EVALSESSID` يبطل الجلسات القائمة (PHPSESSID) — **مطلوب إعادة تسجيل دخول جميع المستخدمين**؛ نُفِّذ في بداية يوم العمل.

**الإثبات:**
- `php -l` لكلا الملفين: لا أخطاء. ✔
- Smoke (التسلسل الفعلي config←session_start←echo): `session_name=EVALSESSID`, `gc_maxlifetime=1800`, `cookie_httponly=1`, `cookie_samesite=Strict`, `use_strict_mode=1`, `use_only_cookies=1`, جلسة تبدأ بـ26 حرفًا بلا تحذيرات. ✔
- `AuthTest` **20/20 نجاح** (لا انحدار). ✔

- **الإغلاق:** البند 5 مكتمل — Commit `19ce159` — إثبات في قسم «بند 5 — تحصين الجلسة» بهذا الملف.

### بند 6 — إخفاء الأخطاء ودمج الإعدادات
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-16 |
| الحالة | **مكتمل** |
| الملفات | `config/config.php` (الدمج + إخفاء الأخطاء)، `public/index.php` (إزالة Trace)، `_emergency/verify_phase1.php`، `storage/.htaccess`، حذف `config/app.php` و`config/performance.php` |

**التنفيذ (ر.ق 1 + قرار كبير المستشارين 2026-09-16):**
- **دمج `app.php` + `performance.php` في `config/config.php`** وفق جدول قيم الدمج المعتمد في خطة التنفيذ:
  - `memory_limit` **2048M** (رُفضت 4096M) و`max_execution_time` **600** (رُفض 1200) — كما طُلب.
  - `BACKUP_BATCH_SIZE` **100** (قيمة `performance.php` المعتمدة في الجدول — كانت 1000 في config.php).
  - `opcache_reset()` **مستبعد عمدًا** من الدمج (يبقى فقط في كود النسخ الاحتياطي `app/Core/BackupOptimizer.php`) — كما طُلب بعدم نقله.
  - `session.gc_maxlifetime=1800` و`session.cookie_lifetime=0` و`session_name('EVALSESSID')` (بند 5) باقية كما هي.
  - `DEBUG_MODE`/`APP_URL`/`APP_ROOT`/`CSRF_GRACE_PERIOD_MINUTES` — نسخة واحدة في config.php.
- **حذف الملفين نهائيًا**: `config/app.php` + `config/performance.php` (متحقق مسبقًا: لا `require` لأي منهما في أي موضع). grep بعد الحذف: **لا مراجع متبقية** في config/public/app/routes/cron/tests.
- **إخفاء الأخطاء**: `DEBUG_MODE=false`، `error_reporting(E_ALL)`، `display_errors=0`، `log_errors=1`، `ini_set('error_log', APP_ROOT.'/storage/logs/php-error.log')` مع إنشاء دفاعي `@mkdir` للمجلد.
- **`storage/logs/`**: أُنشئ + `storage/.htaccess` بـ`Require all denied` (يمنع الوصول المباشر عبر الويب لسجلات PHP والنسخ الاحتياطية في storage/ — كان ملف حقيقي يُقدَّم مباشرة).
- **`public/index.php` (الأصل 44–49)**: حُذف فرع `DEBUG_MODE` وطباعة الـ Trace بالكامل؛ استُبدل بـ`error_log('[FATAL] '…)` كامل (الرسالة+الملف+السطر+الـTrace) + `http_response_code(500)` + صفحة عامة «حدث خطأ غير متوقع» (بدلًا من 404).
- **`_emergency/verify_phase1.php`**: أُزيل `config/app.php` من قائمة فحص الصياغة؛ استُبدل القسم [2/8] بفحوصات الدمج/الإخفاء (app.php/performance.php محذوفان، لا require لهما، DEBUG_MODE=false، display_errors=0، log_errors=1، error_log→storage/logs، .htaccess موجود)؛ استُبدل `php -l` بـ`PHP_BINARY` ليعمل بلا PHP على PATH.

**الإثبات:**
- `php -l` لـ config.php وindex.php وverify_phase1.php: لا أخطاء. ✔
- grep لأي `require` أو مرجع للملفين المحذوفين: **لا شيء** (config، public، app، routes، cron، tests). ✔
- `AuthTest` **28/28 نجاح** (لا انحدار). ✔
- **اختبار خطأ متعمد (CLI)**: سكربت يستدعي config.php ويطبّع JSON ثم `trigger_error('CD004_ITEM6_DELIBERATE_ERROR', E_USER_WARNING)`:
  - إعدادات تحققت كلها صحيحة (debug_false, display_errors_0, log_errors_1, error_log_path, memory_2048, exec_time_600, الملفان محذوفان).
  - `storage/logs/php-error.log` حوى الواسم؛ وstdout خلا من نص الخطأ (`STDOUT_HIDES_ERROR=YES`) → **PASS**. ✔
- **Live HTTP** (Apache/MySQL) — التطبيق يعمل بالإعداد المندمج:
  - GET /login → 200 مع النموذج؛ GET /dashboard (ضيف) → 302 /login. ✔
  - GET /storage/logs/php-error.log → **403** (محمي). ✔
  - خطأ متعمد عبر HTTP (مسبار مؤقت `public/_item6_error_probe.php` يُرمي Exception) → **500** بجسم فارغ (`PROBE_HIDES_ERROR=YES` — لا نص خطأ/سلسلة/مسار) + الواسم سُجّل في `storage/logs/php-error.log` بعمود Asia/Riyadh؛ حُذف المسبار بعد الاختبار. → **PASS**. ✔
- `_emergency/verify_phase1.php`: القسم [2/8] الجديد **10/10 ✓** والفحصان القديمان المتبقيان (`division_id`، `analysis.view`) فشلان **سابقان** لمرحلة DB قديمة (متحقق: غائبان قبل البند 6، وترحيل CD-004 سليم: login_attempts/password_history موجودان) — سُجّلا في OUT_OF_SCOPE (البندان 6 و7). ✔
- نسخ تراجع: `_emergency/rollback/CD-004/2026-09-15/config/config.pre-item6.php`, `app.pre-item6.php`, `performance.pre-item6.php`, `public/index.pre-item6.php`. ✔

- **الإغلاق:** البند 6 مكتمل — Commit `8a72979` — إثبات في قسم «بند 6 — إخفاء الأخطاء ودمج الإعدادات» بهذا الملف.

### بند 7 — إصلاح حارس Admin/UserController
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `app/Controllers/Admin/UserController.php`، `tests/cases/Core/AuthTest.php` |

**التنفيذ:** كان `__construct()` يستدعي `return (new ErrorController())->forbidden();` بلا `exit` — يقصر العمل على الكونستركتور فقط (تُهمَل القيمة المعادة) ويستمر تنفيذ دالة الإدارة المستهدفة بلا تحقق. أُضيف `exit;` بعد `forbidden()` ليتطابق مع النمط الصحيح في `Auth::can()` (عرض 403 ثم إيقاف فوري). وُثّق التعديل بتعليق داخلي يشير للبند 7.

**الإثبات:**
- `php -l`: لا أخطاء (`UserController.php`, `AuthTest.php`). ✔
- **AuthTest 29/29** ← اختبار جديد `testAdminUserControllerGuardStopsNonAdmin`:
  - عملية فرعية بمستخدم **Staff**: `new UserController()` يوقف التنفيذ قبل `index()` (لا `PHASE1_SENTINEL`) ويعرض صفحة 403 ولا يظهر محتوى «إدارة المستخدمين». ✔
  - عملية فرعية بمستخدم **Admin**: `new UserController()` يمر عبر الحارس (`ADMIN_PASSED`). ✔
  - ملاحظة آلية: عبّر الاختبار عن حد أقصى لقراءة الأنبوبة في `runCli` (مخرجات HTML كبيرة >4KB تُسدّ stdout pipe عند قراءة stderr أولًا) — عُولج بتمرير `$stdoutFile`، وسُجّل كثمرة معرفة في OUT_OF_SCOPE (البند 8).
- **Live HTTP** (Apache/MySQL، ببذرة مستخدمين مؤقتة+أدوار):
  - Staff: تسجيل دخول 302 /dashboard ثم GET `/admin/users` → **403** مع «هذه المساحة ليست ضمن صلاحياتك» دون أي جزء من «إدارة المستخدمين». ✔
  - Staff: POST `/admin/users/update-role` (دور هدف + توكن سليم) → **403** و**لا** سجل `USER_ROLE_UPDATE` جديد للهدف (0 قبل = 0 بعد). ✔
  - Admin: GET `/admin/users` → **200** مع «إدارة المستخدمين». ✔
  - تنظيف: `USERS=0` بعد الحذف. → **PASS**. ✔
- نسخة تراجع: `_emergency/rollback/CD-004/2026-09-15/UserController.pre-item7.php`. ✔

- **الإغلاق:** البند 7 مكتمل — Commit `991e0bb` — إثبات في قسم «بند 7 — إصلاح حارس Admin/UserController» بهذا الملف.

### بند 8 — انعاش نسخة صلاحيات المستخدم (permissions_version)
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| الحالة | **مكتمل** |
| الملفات | `database/migrations/2026_09_21_A1_permissions_version.sql` (جديد)، `app/Core/Auth.php`، `public/index.php`، `app/Controllers/AuthController.php`، `tests/cases/Core/AuthTest.php` |

**النطاق (معتمد 2026-09-21):** انعاش الصلاحيات فقط — لا أي «آلية منع/قفل عامة». العمود `users.permissions_version` (مضاف في بند 0) يزداد عند تعديل `user_roles` أو `role_permissions`؛ مقارنة في كل طلب ← إبطال الجلسة عند الاختلاف؛ نافذة كاش 60 ثانية. قرار المستشار: **Triggers على مستوى قاعدة البيانات** (الاكتمال > الشفافية — نسيان مسار = ثغرة أمنية).

**التنفيذ (DB — ترحيل جديد `2026_09_21_A1_permissions_version.sql`):**
- **خطوة إلزامية أولى:** `UPDATE users SET permissions_version = permissions_version + 1;` — أي جلسة نشطة قبل الترحيل تحمل نسخة قديمة (وجلسات ما قبل البند بلا مفتاح نسخة أصلاً): الزيادة الشاملة تُجبر كل جلسة قائمة على إعادة الدخول عند أول فحص بعد النافذة.
- فهرس `user_roles.role_id` (مطلوب لربط JOIN داخل مشغّل `role_permissions`): **متحقق موجود** (`KEY role_id`) — لا إنشاء.
- 4 مشغّلات (أسماء `cd004_trg_*`، بـ`DROP TRIGGER IF EXISTS` + `CREATE` — آمنة إعادة التشغيل):
  - `user_roles` AFTER **INSERT**/DELETE → `+1` لمستخدم الصف (NEW/OLD.user_id).
  - `role_permissions` AFTER **INSERT**/DELETE → `+1` لـ**كل** مستخدمي الدور عبر `JOIN user_roles` (تعديل صلاحيات دور بـ`N` مستخدم يرفع النسخة `N` مرة — واحدة لكل مستخدم).

**التنفيذ (كود):**
- `Auth::permissionsVersionOf($userId)` — قراءة النسخة من DB (تعادل `-1` عند التعذر = «لا تغيير» حفاظًا على التوافر).
- `Auth::refreshSessionPermissions()` — إعادة بناء `user_roles`/`user_permissions` في الجلسة + تثبيت `permissions_version` و`permissions_check_at`؛ يُستدعى من `login()` (حلّ محل سطري البناء السابقين).
- `Auth::permissionsNeedRefresh()` — الحاكم: داخل نافذة `PERMISSIONS_VERSION_CACHE_SECONDS=60` يعيد `false` بلا قراءة؛ عند الخروج يقرأ النسخة ويقارن؛ الجلسة القديمة بلا مفتاح نسخة ⇒ `true` (تُبطل — يغطي جلسات ما قبل بند 8).
- `Auth::invalidateSessionIfPermissionsChanged()` — حارس الطلب: عند الاختلاف `session_unset` + `session_regenerate_id(true)` + `Flash` «طرأ تعديل على صلاحيات حسابك — يرجى تسجيل الدخول مجددًا.» + توجيه `/login`. *(تفصيلة تنفيذية: وُضع `session_regenerate_id(true)` بدل `session_destroy` لتنقل الرسالة إلى صفحة الدخول التالية؛ الأثر الأمني متكافئ — كل بيانات الجلسة تُطهر والمعرّف يُجدَّد.)*
- `public/index.php` — استدعاء الحارس بعد `enforceCsrfToken()`.

**ADR — إبطال الجلسة عند تغيّر الصلاحيات مع إبلاغ Flash (اعتماد كبير المستشارين 2026-09-21):**
- **السياق:** حارس البند 8 عند اختلاف النسخة يجب أن يُبطل الجلسة ويُوجّه إلى `/login`. الخطة المعتمدة ذكرت `session_destroy`، لكن التدمير الكامل يحذف ملف الجلسة فيُفقد `Flash` (يُخزَّن في بيانات الجلسة) — صفحة الدخول التالية ستصل بلا رسالة توضّح سبب الإعادة.
- **البدائل:**
  1. `session_destroy()` + توجيه مباشر — يُبطل البيانات لكن بلا رسالة مسار للمستخدم.
  2. `session_destroy()` ثم `session_start()` لتخزين الفلاش — كوكي الجلسة تُتلف فلم يبلغ الفلاش المستعرض (القصد محبط).
  3. **`session_unset()` أولًا ثم `session_regenerate_id(true)`** (المُعتمد).
- **القرار:** `session_unset()` ثم `session_regenerate_id(true)` ثم `Flash::set('طرأ تعديل على صلاحيات حسابك — يرجى تسجيل الدخول مجددًا.', 'warning')` ثم توجيه `/login`.
- **المبرر:** `session_unset()` تمسح **كل** بيانات الجلسة (بينها `user_id`/`user_roles`/`user_permissions`/`permissions_version`) — المستخدم لم يعد مسجّلًا. `session_regenerate_id(true)` تمنح معرّفًا جديدًا وتحذف ملف الجلسة القديم (يمنع fixation) مع استبقاء متغيراتها الحالية — ولأن الفلاش يُسكَّن **بعد** الإبطال، يصل إلى صفحة الدخول التالية.
- **الأثر الأمني:** متكافئ مع `session_destroy` — لا بقايا بيانات موثقة في الجلسة الجديدة.
- **تأكيد شرط المستشار:** الترتيب ملتزم — `session_unset()` تُستدعى **قبل** `session_regenerate_id(true)`؛ الكود الفعلي في `app/Core/Auth.php:494-503` (`session_unset()`: سطر 498 ← `session_regenerate_id(true)`: سطر 499).

**الإثبات:**
- تطبيق الترحيل على DB الحية: المشغّلات الأربعة في `information_schema.TRIGGERS` + جميع مستخدمي `users` على `permissions_version=2` (1 قبل + 1 الزيادة الإلزامية؛ 10 مستخدمين). ✔
- `php -l` (Auth.php, index.php, AuthController.php, AuthTest.php + نسخ التراجع الثلاث): لا أخطاء. ✔
- **AuthTest 58/58** (7 اختبارات جديدة — من 51):
  - `testTriggerOnUserRolesAssignAndRemoveBumpsVersion` — إسناد دور يرفع النسخة مرة وإزالته مرة أخرى (AFTER INSERT/DELETE). ✔
  - `testTriggerOnRolePermissionsBumpsEachUserOfRole` — دور بـ**3 مستخدمين**: تعديل صلاحياته يرفع نسخة **كلٍّ** منهم مرة واحدة (إدراج/حذف)، ومستخدم تحكمي بدور آخر لا يتأثر — لو ارتفعت مرة واحدة لكان المشغّل خاطئًا. ✔
  - `testLoginStampsPermissionsVersionInSession` — الدخول يثبّت `permissions_version` مطابقًا لـDB و`permissions_check_at`. ✔
  - `testSessionInvalidatedWhenPermissionsVersionDiffers` — عملية فرعية: نسخة هرمة مع `permissions_check_at=0` ⇒ إبطال (لا sentinel) + `AFTER_USER_ID=none` + رسالة الإعادة + الوجهة `/login` (تحقق ساكن). ✔
  - `testNoInvalidationInsideCacheWindow` — داخل نافذة الـ60 ثانية لا قراءة ولا إبطال؛ عند فرض الخروج تُكشف الهرمة. ✔
  - `testLegacySessionWithoutPermissionsVersionInvalidates` — جلسة ما قبل بند 8 (بلا مفتاح نسخة) تُبطل عند أول فحص. ✔
  - `testAdminDemotedToStaffInvalidatesSessionAndReloginIsNotAdmin` (**إلزامي**) — Admin إلى Staff: جلسة Admin تُبطل فورًا، وإعادة الدخول `IS_ADMIN=0` والأدوار `['Staff']` بلا `Admin` — لو بقي `isAdmin` صحيحًا لكانت ثغرة bypass. ✔
- **المجموعة الكاملة** بلا انحدار: `AuthTest 58/58`؛ `DatabaseTest 4/5` و`HelpersTest 2/3` خط أساس معروف + سطر `View 'errors/404' does not exist.` (خلل بيئة OOS #4) — كما قبل البند.
- نسخ تراجع: `_emergency/rollback/CD-004/2026-09-15/Auth.pre-item8.php` + `AuthController.pre-item8.php` + `public/index.pre-item8.php` (لينت سليم). تراجع DB: `DROP TRIGGER IF EXISTS cd004_trg_user_roles_ai/ad` + `DROP TRIGGER IF EXISTS cd004_trg_role_permissions_ai/ad` (الزيادة الشاملة غير معكوسة — أثر ترحيل موثق ومقبول).

- **الإغلاق:** البند 8 مكتمل — Commit `15b14cb` — إثبات في قسم «بند 8 — انعاش نسخة صلاحيات المستخدم» بهذا الملف.

### بند 9 — إعادة تعيين كلمة المرور عبر Admin + إلزام التغيير (must_change_password)
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| الحالة | **مكتمل** |
| الملفات | `app/Models/User.php`، `app/Controllers/Admin/UserController.php`، `app/Controllers/AuthController.php`، `app/Core/Auth.php`، `app/Views/auth/login.php`، حذف `app/Views/auth/forgot-password.php`، `tests/cases/Core/AuthTest.php` |

**النطاق:** تفعيل العمود الموجود `users.must_change_password` (كان بلا استخدام في الشيفرة) عبر مسار إعادة التعيين الإداري + إلزام التغيير عند الدخول التالي + **ر.ق 2**: إزالة واجهة استعادة كلمة المرور الميتة (لا كود ميت). شاشة تغيير كلمة المرور الفعلية ضمن **بند 10** التالي مباشرة.

**التنفيذ:**
- `User::updatePassword($userId, $newPassword, $mustChange = false)` — عند `$mustChange=true` يضبط `must_change_password = 1` (إعادة تعيين Admin)؛ وعند التغيير العادي يمسح العلم إلى `0` (سقوط الشرط بمجرد تغيير كلمة المرور). الحارس وسياسة بند 11 وتسجيل `password_history` يعملان في الحالتين.
- `Admin\UserController::resetPassword()` — يستدعي `updatePassword(..., true)` ويحدّث رسالة النجاح: «يجب على المستخدم تغييرها عند الدخول التالي» (يبقى `USER_PASSWORD_RESET` في التدقيق).
- `AuthController::login()` — **بعد** المصادقة الناجحة وقبل `/dashboard`: إذا `must_change_password=1` → `Flash::set('يجب تغيير كلمة المرور قبل المتابعة.', 'warning')` + توجيه `Location: /change-password` (الوجهة تنفَّذ في بند 10).
- **ر.ق 2:** إزالة رابط «نسيت كلمة المرور؟» (`href="#"`) من `login.php` (مع إزالة صف `form-options` الفارغ) + حذف ملف `forgot-password.php` (0 بايت) + إزالة `'forgot-password'` من `skipRoutes` في `Auth::enforceCsrfToken` (الطرق الميتة لا تُعفى) — الإعادة الحصرية عبر Admin.

**الإثبات:**
- `php -l` (User.php, UserController.php, AuthController.php, Auth.php, login.php, AuthTest.php): لا أخطاء. ✔
- **AuthTest 43/43** (منها اختبارات بند 9):
  - `testUpdatePasswordWithMustChangeFlagSetsFlag` — `updatePassword(..., true)` يضبط العلم + `historyCount=1`؛ التحديث العادي يمسحه إلى 0. ✔
  - `testLoginForcesMustChangePasswordToChangePassword` — مستخدم بعلم التفعيل: دخول ناجح (SESSION_USER_ID) + رسالة «يجب تغيير كلمة المرور قبل المتابعة» (فرع الإلزام) + `USER_LOGIN_SUCCESS` + تحقق ساكن أن الوجهة `/change-password` (CLI تُرسّل الترويسات قبل shutdown فلا يمكن التقاط `headers_list()` — محطة تحقق موثّقة في الاختبار). ✔
  - `testForgotPasswordDeadSurfaceRemoved` — لا ملف `forgot-password.php` ولا `forgot` في `login.php` / `routes/web.php` + `skipRoutes = ['register','reset-password']` بلا forgot. ✔
  - `testEnforceCsrfTokenNoLongerSkipsForgotPassword` — POST لمسار ميت لم يعد معفًى من CSRF (subprocess: لا `SURVIVED`، exit عبر `enforceCsrfToken`). ✔ (استبدلت الاختبار القديم `testEnforceCsrfTokenSkipsForgotPasswordPost` الذي كان يفحص الإعفاء المحذوف).
- **المجموعة الكاملة** بلا انحدار: `AuthTest 43/43`؛ `DatabaseTest 4/5` و`HelpersTest 2/3` خط أساس معروف. ✔
- نسخ تراجع: `AuthController.pre-item9.php`، `User.pre-item9.php`، `UserController.pre-item9.php`، `Auth.pre-item9.php`، `login.pre-item9.php`، `forgot-password.pre-item9.php` (فارغ — أصل المحذوف). ✔

- **الإغلاق:** البند 9 مكتمل — Commit `1f20e90` — إثبات في قسم «بند 9 — إعادة تعيين كلمة المرور عبر Admin + إلزام التغيير (must_change_password)» بهذا الملف.

### بند 10 — شاشة تغيير كلمة المرور
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| الحالة | **مكتمل** |
| الملفات | `routes/web.php`، `app/Controllers/AuthController.php`، `app/Views/auth/change-password.php` (جديد)، `tests/cases/Core/AuthTest.php` |

**النطاق المعتمد:** شاشة/مسار تغيير كلمة المرور للأفراد الموثقين — تُفتح إجباريًا بعد إعادة تعيين Admin (بند 9) أو طوعًا في أي وقت؛ مع مرجع سياسة بند 11. تدفق «تعيين كلمة مرور الدعوة (invited)» خارج النطاق — بند 1 يبقى مغلقًا بمنع دخول `invited` (وثِق في `CD-004_OUT_OF_SCOPE.md`).

**التنفيذ:**
- `routes/web.php`: `GET change-password → AuthController@showChangePassword` و`POST change-password → AuthController@changePassword` (بجوار `logout`).
- `app/Controllers/AuthController.php`:
  - `requireLogin()` — زائر بلا جلسة: `Flash` + توجيه `/login` (يحمي الـGET والـPOST معًا؛ الحماية الفعلية لكل POST عبر `Auth::enforceCsrfToken` في `public/index.php`).
  - `showChangePassword()` — يعرض `auth/change-password` مع `policy` من `Auth::passwordPolicyRules()` (مرجع مباشر للسياسة المعتمدة).
  - `changePassword()` — 1) تأكيد **كلمة المرور الحالية** عبر `password_verify` (منع التغيير بحجة جلسة مختطفة). 2) مطابقة الحقلين. 3) `User::updatePassword($userId,$new)` — يطبق سياسة بند 11 + نبذ آخر 3 (التاريخ) **ويمسح `must_change_password` تلقائيًا** (سقوط شرط الإلزام). 4) `Audit::log('USER_PASSWORD_CHANGE', ...)` + Flash نجاح + توجيه `/dashboard`.
- `app/Views/auth/change-password.php` (جديد): نمط صفحة الدخول (هيدر/فوتر، بطاقة مركزية) + حقل الحالية + الجديدة + التأكيد + قائمة مرجع السياسة الأربع + `csrf_field()`.
- **Post-الصورة (بند 9+10 كتكامل واحد):** بعد إعادة تعيين Admin، يسجّل المستخدم → `must_change_password=1` → توجيه إجباري `/change-password` → يغيّر وفق السياسة → يمسح العلم → `/dashboard` بتدفق سليم.

**الاختبارات (AuthTest — 51/51):** 8 اختبارات `testChangePassword*`:
`...RequiresLoginRejectsGuest`، `...PageShownForAuthenticatedUser`، `...PageRedirectsGuestToLogin`، `...RejectsWrongCurrentPassword`، `...RejectsConfirmMismatch`، `...EnforcesPolicyViaScreen`، `...RejectsReuseFromHistory`، `...SuccessClearsMustChangeFlagRedirectsDashboardAndAudits`.
مساعدان: `changePasswordScript` (POST) و`changePasswordPageScript` (GET) + `passwordHashOf`/`mustChangeFlagOf`.

**خدع بيئية موثقة:** خرج صفحة الرندر (~13KB) فوق حد أنبوب Windows عند القراءة المتزامنة في `runCli` (~4KB) يشلّ العملية (نفس **OOS #8**) — يلزم تمريـ reference `$stdoutFile`. و`LOCATION=sent` دائمًا تحت CLI (ترويسات تُرسل قبل shutdown) — تُثبت الوجهات ساكنًا (نمط بند 9).
- `php -l` نظيف للـ4 ملفات. المجموعة الكاملة بلا انحدار (AuthTest 51/51؛ DatabaseTest 4/5 + HelpersTest 2/3 خط أساس معروف).

**نسخ الاسترجاع (مجلد `_emergency/rollback/CD-004/2026-09-15/`):** `AuthController.pre-item10.php` + `web.pre-item10.php` (حالة «قبل بند 10» = «بعد بند 9»؛ عند الاسترجاع يُحذف `app/Views/auth/change-password.php`). `php -l` سليم وبلا علامات بند 10.

- **الإغلاق:** البند 10 مكتمل — Commit `1376d4e` — إثبات في قسم «بند 10 — شاشة تغيير كلمة المرور» بهذا الملف.

### بند 11 — سياسة كلمة المرور
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| الحالة | **مكتمل** |
| الملفات | `app/Core/Auth.php`، `app/Models/User.php`، `app/Controllers/Admin/UserController.php`، `tests/cases/Core/AuthTest.php` |

**قرار البند المعتمد (2026-09-21 — كبير المستشارين):** الطول الأدنى 8 أحرف + تنوع **3 من 4** أنواع (حرف كبير/حرف صغير/رقم/رمز خاص) + رفض آخر 3 كلمات مرور سابقة عبر `password_history` + قائمة أعلى 100 كلمة شائعة + **بلا انتهاء صلاحية تلقائي** (لا دورة إجبارية للاستبدال) + دالة تحقق موحّدة `Auth::validatePasswordPolicy()` + رسالة خطأ واضحة لكل شرط. خارطة الترقية المستقبلية: قائمة **NIST Breached Passwords** عند توفرها ثم **MFA** — مُسجَّلة في `A1_Authentication_Unit_Documentation.md`.

**التنفيذ:**
- `app/Core/Auth.php`:
  - الثوابت `PASSWORD_POLICY_MIN_LENGTH = 8` و`PASSWORD_POLICY_HISTORY = 3` + قائمة `PASSWORD_POLICY_COMMON` (أعلى 100 بصيغة الأمرّي — تشمل `password123!`، `Welcome1!`، `Admin123!`، `Changeme1!`، `Temp123!`، `Password1!` لضمان قياس حتمي في الاختبار).
  - `passwordPolicyRules(): array` — وصف القواعد الخمس + سطر الترقية (للواجهة/التوثيق).
  - `validatePasswordPolicy(?string $password, ?int $userId = null): ['ok'=>bool,'errors'=>string[]]` — ترتيب أخطاء ثابت: الطول ← التنوع ← القائمة الشائعة ← نبذ التاريخ (عند تمرير `$userId`).
  - `passwordReusedRecently(int $userId, string $newPassword): bool` — يسترجع آخر 3 هاشات من `password_history` (ترتيب `created_at DESC, id DESC LIMIT 3`) ويطابق بـ `password_verify`.
  - `recordPasswordHistory(int $userId, string $oldHash): void` — إدراج هاش كلمة المرور القديمة ثم **prune** إلى آخر 3 فقط عبر جدول مشتق (Derived Table) للتغلب على قيد MySQL 1093 (DELETE + subquery على نفس الجدول).
  - `generateStrongPassword(int $length = 12): string` — مولّد يضمن الأنواع الأربعة (يستبدل `bin2hex` السابق غير المتوافق مع سياسة التنوع) ويدير حلقة إعادة توليد حتى تحقق `validatePasswordPolicy`.
- `app/Models/User.php`:
  - الخاصية العامة `array $lastPasswordErrors` (تعبئتها/تفريغها) لتقرأ الواجهة رسائل الأخطاء الموحّدة.
  - الحارس الخاص `guardPasswordChange($userId, $newPassword)` — تحقق موحّد (سياسة + نبذ التاريخ عبر `$userId`) + التقاط الهاش الحالي؛ يعيد `null` عند الرفض.
  - `updatePassword($userId, $newPassword)` — عبر الحارس: عند القبول يحدّث الهاش ثم `recordPasswordHistory(الهاش القديم)`.
  - `updateUser($data)` — عند مرور `password`: تحقق قبلي بالسياسة قبل أي جملة SQL (رفض آمن بلا تعديل جزئي) + تسجيل الهاش القديم في التاريخ بعد النجاح.
- `app/Controllers/Admin/UserController.php`:
  - `store()` و`update()`: **preflight** بـ `Auth::validatePasswordPolicy` قبل الحفظ مع `Flash::set` برسالة لكل شرط مخالِف (رسائل موحّدة من Auth).
  - `resetPassword()`: يستخدم `Auth::generateStrongPassword(12)` (كان `bin2hex` بلا تنوع)؛ عند فشل الحارس يعاود رسائل `lastPasswordErrors` في استجابة JSON.

**الإثبات:**
- `php -l` لـ (Auth.php, User.php, UserController.php, AuthTest.php): لا أخطاء. ✔
- **AuthTest 40/40** (منها **9 اختبارات جديدة** لبند 11):
  - `testPasswordPolicyRulesReflectApprovedPolicy` — القيم/القواعد الخمس مطابقة للقرار المعتمد (8، 3، بلا انتهاء صلاحية). ✔
  - `testValidatePasswordPolicyAcceptsCompliantPassword` — كلمة مطابقة تُقبل. ✔
  - `testValidatePasswordPolicyRejectsEmptyPassword` / `RejectsShortPassword` (رسالة «8 أحرف على الأقل») / `RejectsVarietyUnderThreeOfFour` (`abcdefgh123456` و`ABCDEFGH!!!!` = فئتان فقط → مرفوضة) / `RejectsCommonBlacklistPassword` (`Password123!` يُرفض لسبب السوداء وحده: `assertCount(1)`. ✔
  - `testValidatePasswordPolicyRejectsReuseOfLastThreeAndAllowsPrunedFourth` — مسار كامل: 3 تغييرات → `historyCount=3`؛ رفض الكلمة الأخيرة/السابقة/الأقدم ضمن آخر 3؛ التغيير الرابع يُزيح الأقدم (يبقى 3) فيصبح مسموحًا؛ عودة رجعية للكلمة التي ما زالت ضمن آخر 3 تُرفض. يفحص فعلًا **نبذ 3 + prune**. ✔
  - `testUserModelUpdateUserEnforcesPolicy` — `updateUser` يرفض المخالفة بلا حفظ (`lastPasswordErrors` ممتلئة) ويقبل المطابقة مع تسجيل هاش القديم (`historyCount=1`). ✔
  - `testGenerateStrongPasswordMeetsPolicy` — 20 مولّدًا: `strlen ≥ 12` وكلها تمر `validatePasswordPolicy`. ✔
- **المجموعة الكاملة** صنّفت بلا انحدار: `AuthTest 40/40`؛ `DatabaseTest 4/5` و`HelpersTest 2/3` خط أساس معروف سابقًا (لا علاقة له بالبند 11). ✔
- نسخ تراجع: `_emergency/rollback/CD-004/2026-09-15/Auth.pre-item11.php` + `User.pre-item11.php` + `UserController.pre-item11.php`. ✔

- **الإغلاق:** البند 11 مكتمل — Commit `92e021a` — إثبات في قسم «بند 11 — سياسة كلمة المرور» بهذا الملف.

### بند 12 — إزالة «تذكرني»
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-15 |
| الحالة | **مكتمل** |
| الملفات | `app/Views/auth/login.php` |

**التنفيذ:** حُذف checkbox «تذكرني» من نموذج الدخول (كان بلا `name` وكذلك بلا أثر فعلي في تدفق الجلسة)؛ بقيت `form-options`ضمّ ربط «نسيت كلمة المرور؟» كما هي.

**الإثبات:**
- `php -l`: لا أخطاء. ✔
- Live HTTP: صفحة `/login` لا تحتوي `name="remember"`، ورابط `forgot-password` حاضر. ✔

- **الإغلاق:** البند 12 مكتمل — Commit `718c0e3` — إثبات في قسم «بند 12 — إزالة «تذكرني»» بهذا الملف.

### بند 13 — cron التنظيف اليومي

**النطاق (إذن 2026-09-21):** `cron/cleanup.php` يوميًا: (1) حذف `csrf_tokens` المستخدمة أو المنتهية والأقدم من 24 ساعة، (2) حذف `login_attempts` الأقدم من 24 ساعة، (3) حذف الإشعارات `is_read=0` الأقدم من 90 يومًا، (4) تسجيل كل عملية في `audit_logs`. **لا «إعادة مصادقة للأعمال الحساسة»** (OOS #9 — مؤجلة A1-3 → CD-005) ولا أي شيء آخر.

**التنفيذ:**
- `cron/cleanup.php` (جديد — نمط bootstrap `backup.php`): حارس CLI (`php_sapi_name() == 'cli'`)، تحميل `vendor/autoload.php` (PSR-4 `App\`) + `config/config.php` + `config/database.php`، `Asia/Riyadh`.
- **csrf_tokens**: `DELETE … WHERE created_at < NOW() - INTERVAL 24 HOUR AND (used = 1 OR expires_at < NOW())` — الرمز المستخدم أو المنتهي عديم القيمة (أحادي الاستخدام) ولا يُمسّ شيء أحدث من 24 ساعة.
- **login_attempts**: `DELETE … WHERE attempted_at < NOW() - INTERVAL 24 HOUR`.
- **notifications**: `DELETE … WHERE is_read = 0 AND created_at < NOW() - INTERVAL 90 DAY` فقط — المقروءة تُحفظ للتدقيق (سياسة بند 15) ✔ تحذير المستشار (ج).
- كل عملية → `Audit::log` بإجراءات `CRON_CLEANUP_CSRF_TOKENS` / `CRON_CLEANUP_LOGIN_ATTEMPTS` / `CRON_CLEANUP_NOTIFICATIONS`، `entity_type` = الجدول، و`details {deleted: n, rule: …}` — `user_id` = NULL (إجراء نظام عبر `Auth::id()` في CLI). فشل وحدة يكتب `error_log` + يشير `exit=1` بلا إيقاف الوحدات الأخرى؛ فشل الاتصال بالـDB → `exit(1)` فورًا مع فشل مسجَّل.

**إثبات (اختبار يدوي على DB الحية):**
- بذر 8 صفوف مميزة (`cd004_cleanup_*`): رمز csrf قديم (>=48 ساعة) + جديد (ساعتان) + **مستخدم حديث العهد** (`used=1` لكن عمره < 24 ساعة)؛ محاولة دخول قديمة (30 ساعة) + حديثة؛ إشعار قديم **غير مقروء** (95 يومًا) + حديث غير مقروء + قديم **مقروء** (95 يومًا — يجب ألا يُحذف).
- تشغيل `php cron/cleanup.php` → `cleanup csrf_tokens: 175` (يشمل علم البذر القديم + المكتنز الحقيقي القديم — عمل cron الفعلي) / `cleanup login_attempts: 1` / `cleanup notifications: 1`، **خروج 0**.
- التحقق بعد التشغيل: رمز قديم=0 (حُذف) / جديد=1 / مستخدم حديث=1 (لم تُمس — أحدث من 24 ساعة) / محاولة قديمة=0 / حديثة=1 / إشعار قديم غير مقروء=0 / حديث غير مقروء=1 / قديم مقروء=1 (المقروءة سجلّ تدقيق — لم تُحذف) ✔.
- سجل `audit_logs`: 3 صفوف (إجراءات الثلاثة أعلاه) بعدّاد الحذف الفعلي وقاعدة كل حذف ✔.
- تنظيف البذر: الصفوف المتبقية + إدخالات audit التجريبية حُذفت (`COUNT(*)` لعلامات الكشف = 0) — الجدول عاد لحالته.
- `php -l cron/cleanup.php`: لا أخطاء. لا OOS جديد (تحذير المستشار «جدول آخر → OOS → CD-005» مطابق: الثلاثة فقط يحتاجون تنظيفًا؛ أرشفة أي جدول مستقبلًا → CD-005).

**التراجع:** `cron/cleanup.php` ملف جديد — يُستعاد بحذفه، مع نسخة `_emergency/rollback/CD-004/2026-09-15/cron-cleanup.pre-item13.php`.

**التوثيق:** `CHANGELOG` (إدخال بند 13). لا صف P جديد في A1 — سياسة A1 §10 سؤال 8 اكتملت ببندي 15+13.

**الإغلاق:** البند 13 مكتمل — Commit `267a98b` — إثبات في قسم «بند 13 — cron التنظيف اليومي» بهذا الملف.

### بند 14 — دور Admin ديناميكي
| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| الحالة | **مكتمل** |
| الملفات | `app/Core/Auth.php`، `app/Core/CsrfGraceLogger.php`، `_emergency/create_api_keys_table.sql`، `_emergency/csrf_migration.sql`، `tests/cases/Core/AuthTest.php` |

**التنفيذ:** أُزيل كل الاعتماد الصريح على `role_id = 1` (كان متضمّنًا في `Auth::notifyAdmins()` و`CsrfGraceLogger::notifyAdmins()` وسكربتي `_emergency`). أُضيف `Auth::adminRoleIds(): array` المستند لقاعدة «الاتفاقية» (النموذج الفريد `roles.id` قابل للتغيير — لا يجوز تثبيته في الشيفرة): يستعلم `SELECT id FROM roles WHERE name = 'Admin' AND is_system_role = 1` ويخزّن النتيجة في كاش ثابت لكل طلب (`$adminRoleIdsCache`). Fallback آمن: النتيجة فارغة (مثلاً تعديل الدور العام أثناء الصيانة) → لا إشعارات، ويُكتب `error_log('CD004_ITEM14…')` في `storage/logs/php-error.log`. إعادة كتابة `notifyAdmins()`: `UPDATE notifications … WHERE … role_id IN (:rid0…)` مع `ur.user_id` من `user_roles` ومرساة `ur.role_id IN`, وتُعيد فورًا عند `[]`. `clearAdminRoleIdsCache()` عام لتعزيز قابلية الاختبار/الإعداد. السكربتان (`create_api_keys_table.sql`, `csrf_migration.sql`): `role_id = 1` → `role_id IN (SELECT id FROM roles WHERE name='Admin' AND is_system_role=1)` (أدوار HR/Manager/Staff بقيت ثوابت مُستهدفة بنفس الشيفرة الأصلية — لا مشكلة). غطاء الاختبار: `seedAdminUser` صار ديناميكيًا عبر هذه الـsubquery مع أدوات `rotateAdminRole`/`restoreAdminRole` (إعادة تسمية الدور الحالي + إدراج `'Admin'` بمعرّف جديد ≠ 1 ثم الإرجاع) و`demoteSystemAdminRole`/`restoreSystemAdminRole` و`notificationTitleCount`.

**الإثبات:**
- grep شامل (`app/`، `tests/`، `config/`، `routes/`، `public/`، `_emergency`): **صفر** نتائج لـ `role_id = 1`. ✔ (الإشارات المتبقية في `CD-004_Execution_Plan.md:58` و`سطر 74 هنا` فقط — سجل مرجعي تاريخي يُرك ويُترك كما هو).
- `php -l` (Auth.php, CsrfGraceLogger.php, AuthTest.php): لا أخطاء. ✔
- **AuthTest 31/31**، منها اختباران لبند 14:
  - `testNotifyAdminsReachesDynamicAdminRoleId`: تدوير `roles.id` لـ'Admin' إلى معرّف ≠ 1 ثم إشعار → يصل للدور الجديد (count=1) ← تعمل الـsubquery الديناميكية. ✔
  - `testNotifyAdminsFallsBackWhenNoSystemAdminRole`: تنزيل مستوى النظام مؤقتًا (لا يوجد دور «Admin» نظامي) → count=0 + وسم `CD004_ITEM14` في `storage/logs/php-error.log`. ✔
  - فحص ما بعد الاختبارات: `ROLES` أساسية (1 Admin، 2 HR، 3 Manager، 4 Staff، الكل is_system_role=1)، وبلا بقايا (`TMP_ROLES=0`, `ITEM14_USERS=0`). ✔
- **Live HTTP** (Apache/MySQL؛ ببذر مستخدم موقوف + مستخدم Admin منتسب مبدئيًا للدور 1):
  - خط الأساس: تسجيل دخول الموقوف → إشعار «محاولة دخول بحساب موقوف — …» يصل (count≥1). ✔
  - تدوير `roles.id` إلى معرّف جديد (10) بلا تغيير في الاسم/النظام، ثم نقل مستخدم الـAdmin إليه، ثم تسجيل دخول الموقوف مجددًا → العد يزيد بواحد (الإشعار يصل عبر الدور **الجديد** ≠ 1). ✔
  - إعادة الاستعادة (تأكيد 1 = Admin system) وإعادة الإسناد للدور الأصلي، والتنظيف النهائي `USERS=0`. ✔ → **PASS**
- نسخة تراجع: `_emergency/rollback/CD-004/2026-09-15/Auth.pre-item14.php` (رفيق) + `CsrfGraceLogger.pre-item14.php`. ✔
- **تحقق ما بعد إغلاق البند 6 (2026-09-21)**: أعيد تشغيل المجموعة فوق `config.php` المندمج (البند 6): `AuthTest` **31/31** ✓، `CsrfGraceLogger::notifyAdmins` يعمل ✓، `Auth::notifyAdmins` يعمل ✓، وإعادة Live HTTP كاملة (بذرة → إشعار أساس → تدوير `roles.id` إلى 13 → إشعار عبر الدور الجديد Δ+1 → استعادة → تنظيف `USERS=0`) → **PASS** ✓. بلا انحدار ناتج عن البند 6.

- **الإغلاق:** البند 14 مكتمل — Commit `0982b3e` — إثبات في قسم «بند 14 — دور Admin ديناميكي» بهذا الملف.

### بند 15 — شاشة الإشعارات

**النطاق (اعتماد مشروط 2026-09-21):** بند 15 = واجهة مقروءة لإشعارات الحساب. شرط الاعتماد («تأكيد `session_unset` قبل `session_regenerate_id` في بند 8») **مؤكَّد** — ADR أعلاه + رمز فعلي `app/Core/Auth.php:498-499`. تحذيرات المستشار مطابقة: (أ) الإشعارات القديمة (قبل بند 14) تُعرض، (ب) الإشعارات الجديدة تُخزَّن سليمًا، (ج) cron لا يحذف المقروءة (سياسة حفظ)، (د) أي فجوة → OOS.

**التنفيذ:**
- `GET /notifications` → `NotificationController@index` — قائمة الحساب الأحدث أولًا (مقروء + غير مقروء)، صفوف بإصدارات تاريخية (من بند 1/14 بلا `related_url`) وأنماط enum الأربعة (`info/success/warning/danger`) تُعرَض بشارة وتسمية عربية بلا تعديل ENUM (OOS #1). حالة فارغة واضحة.
- `POST /notifications/read/:id` — تعليم إشعار واحد مقروء **بمسار مُسند لصاحب الحساب** (`WHERE id=:id AND user_id=:uid` — لا قبول لقراءة إشعارات الغير). `POST /notifications/read-all` — تعليم كل إشعارات الحساب (لا يمس إشعارات الغير). كلاهما عبر POST محمي بـCSRF (البوابة العامة في `public/index.php:37`).
- جرس الهيدر (`app/Views/layouts/header.php` في مساحة المستخدم): أيقونة + عدد غير المقروء في شارة حمراء + قائمة منسدلة بأحدث 5 إشعارات مع رابط «عرض كل الإشعارات». أنماط CSS في `public/css/style.css`.
- نموذج `app/Models/Notification.php` (نمط `getPdo()+FETCH_ASSOC` السائد): `forUser`/`unreadCount`/`recentForUser`/`markRead`/`markAllRead`. **لا يحتوي أي DELETE.**
- مسارات في `routes/web.php` بعد مجموعة المصادقة.

**سياسة الاحتفاظ (لـcron بند 13 — لم تُنفَّذ في هذا البند):** لا تنفّذ حذفًا الآن؛ عند بناء cron التنظيف في بند 13 يُحذف فقط ما لم يُقرأ قبل 90 يومًا (`is_read=0 AND created_at < NOW() - INTERVAL 90 DAY`) — المقروءة تبقى سجلًّا للتدقيق (متطلب المستشار: «لا يحذف مقروءة ضرورية للتدقيق»).

**الأمان:** نموذج/مسار `markRead` مقصوران على `user_id` الجلسة؛ نوع enum محدد بـBootstrap فحسب (لا إدخال حر في HTML). البوابة (مثل بقية الوحدات) تفحص `Auth::check()` في المنشئ وتُوجّه `/login`.

**إثبات (Live):**
- **`tests/cases/Core/NotificationTest.php` — 13/13**: عدّاد غير المقروء (0 ثم 2)، ترتيب `forUser` مع إشعارات **قديمة** (بلا رابط، `danger/warning`) وجديدة، `recentForUser` حدّ 5، **نطاق markRead/markAllRead** (لا يؤثر على إشعارات الغير)، تخزين `Auth::notifyAdmins` (صف جديد `is_read=0` نوع `warning`)، صفحة تعرض كل الصفوف (قديم+جديد+الروابط+التسميات) بتمييز غير المقروء، حالة فارغة، بوابة زائر (خروج بلا عرض — قيد CLI: `LOCATION=sent` معروف)، وإجراءا POST (خروج + حفظ DB).
- `php -l` نظيف لكل الملفات الملموسة + نسخ الاسترجاع. **المجموعة الكاملة بلا انحدار** (AuthTest 58/58، DatabaseTest 4/5 وHelpersTest 2/3 خط أساس معروف، وسطر `View 'errors/404'` — OOS #4).
- نسخ استرجاع: `_emergency/rollback/CD-004/2026-09-15/routes-web.pre-item15.php` + `header.pre-item15.php` + `style.pre-item15.css` (الموديل/الوحدة/العرض/الاختبار ملفات جديدة — تُستعاد بحذفها).

**التوثيق:** `A1_Authentication_Unit_Documentation.md` سؤال §10 رقم 8 «إشعارات = مخزن؟» → **أُجيب (بند 15): واجهة مقروءة** + سياسة الاحتفاظ. `CHANGELOG` (إدخال بند 15). لا صف P جديد في A1.

**الإغلاق:** البند 15 مكتمل — Commit `57e3de0` — إثبات في قسم «بند 15 — شاشة الإشعارات» بهذا الملف.

---

## المرحلة 5 — اختبار القبول والانحدار (قرار A1)

| الحقل | القيمة |
|---|---|
| التاريخ | 2026-09-21 |
| الحالة | **مكتمل — PASS** (13/13 سيناريو + انحدار) |
| الملفات | `CD-001_delivery/phase5/{Phase5_Acceptance_Report,Phase5_Scenarios,Phase5_Regression_Checklist,Phase5_Test_Users,ROLLBACK_PATHS}.md` |
| الإذن | إذن كبير المستشارين 2026-09-21: تجهيز + تنفيذ 13 سيناريو + انحدار + تقرير. **بلا تعديل على الكود** (إلا لخطأ حرج — لم يحدث). |

**التجهيز:** نسخة DB كاملة `storage/backups/CD-004/phase5/employee_evaluation_mvc_phase5.sql` (944,479 بايت، routines/triggers/events) + نسخة الكود `code/` (38.8MB) + `ROLLBACK_PATHS.md`؛ بيانات اختبار نظيفة (3 فروع × 7 أقسام × 10 موظفين `P5-EMP-01..10` + 6 مستخدمين `test_admin/manager/hr/staff/suspended/invited` بكلمات مرور نظامية في `Phase5_Test_Users.md`)؛ `temp/phase5_seed.sql`/`temp/phase5_cleanup.sql` بنمط TEMP لتجنّب ERROR 1442، وLIKE بدل مقارنة collation (ERROR 1267).

**التنفيذ (عميل HTTP حي curl.exe + فحص DB):** السيناريوهات الـ13 مسجّلة بالكامل في `CD-001_delivery/phase5/Phase5_Acceptance_Report.md` (جدول النتائج + أدلة الأرقام) وتفصيليًا في `temp/phase5_logs/driver*.md`. النتائج 13/13:
- S1 قفل الحساب (5 محاولات ← تأخيرات + `USER_LOGIN_LOCKED`/`_BLOCKED` + إشعار؛ المحاولة السادسة الصحيحة مُمنعة) ✔
- S2 مهلة الجلسة 1800 + كوكي `HttpOnly/SameSite=Strict/EVALSESSID` + إثبات GC للمهلة (lifetime=1ث → `gc_deleted=1` ثم `fresh-set`) ✔
- S3 CSRF الدخول (بلا توكن ← رفض؛ مع التوكن ← نجاح) ✔
- S4 الخروج POST فقط (`GET /logout`=404؛ POST يفكّ الجلسة والكوكي) ✔
- S5 رفض `suspended/invited` رغم صحة كلمة المرور + تدقيق + إشعار ✔
- S6 الحارس (زائر 403 على المحمي + `/login` للوحة؛ staff 403؛ admin 200) ✔
- S7 إعادة التعيين عبر Admin (JSON + `X-CSRF-Token` + جلسة؛ `must_change=1`؛ توجيه قسري `/change-password`) ✔ — عبر `--data-binary @file` (PS5.1 يقطع `{}`) ومع `-b jar` (بلا كوكي → رفض CSRF صحيح).
- S8 تغيير إجباري/حُرّ (مسح العلم + `USER_PASSWORD_CHANGE`) ✔
- S9 سياسة بند 11 (رفض قصيرة/بلا تنوع/شائعة + نبذ آخر 3؛ ملاحظة: إعادة نفس الحالية سائغة — تحسين اختياري مستقبلًا) ✔
- S10 `permissions_version` (2→4 عند تغيير الدور عبر المشغّل؛ نافذة 60 ثانية تحفظ، بعد 70ث تُبطل وتُعاد التوجيه `/login`؛ إعادة دخول بالدور الجديد؛ استعادة v=6) ✔
- S11 لا `remember` ولا ربط «نسيت» ولا `GET /logout` ✔
- S12 `cron/cleanup.php` (قديم يُحذف، حديث/مقروء يُبقى؛ 3 سجلات `CRON_CLEANUP_*`؛ خروج 0) ✔
- S13 دور Admin ديناميكي (تدوير id→36: الإشعار يصل عبر الدور الجديد) + شاشة/جرس + نطاق markRead (إشعار الغير لا يُقرأ) + استعادة ✔

**الانحدار:** `AuthTest` **58/58** + `NotificationTest` **13/13** (بلا انحدار؛ DatabaseTest 4/5 وHelpersTest 2/3 خط أساس معروف OOS)؛ فحص صفحات الوحدات عبر HTTP (Admin: 17 صفحة 200 + 404؛ staff/hr: حراسة 403؛ زائر: العام 200)؛ عينات مواقع `forbidden()` (22) لكل وحدة.

**التنظيف:** `temp/phase5_cleanup.sql` أزال `test_*`/`P5-EMP-*`/بذور P5SEED (users=0, employees=0, csrf/attempts/notifs=0) + سجلات المرحلة أُزيلت؛ DB عادت لحالتها (4 مستخدمون أصليون، 4 أدوار نظامية، `roles.id=1` = Admin، 4 مشغّلات `cd004_trg_*`).

**الإغلاق:** المرحلة 5 مكتملة والوحدة **A1 مكتملة (15/15)** — القرار النهائي في `CD-001_delivery/phase5/Phase5_Acceptance_Report.md` §1/§6. Commit توثيق المرحلة 5 — إثبات في قسم «المرحلة 5» بهذا الملف.

---

## بيان إغلاق الوحدة A1 (توقيع كبير المستشارين 2026-09-21)

**اعتماد نهائي** (إذن تنفيذ صريح 2026-09-21 — «فقط إغلاق A1، لا بدء لـ CD-005، نقطة توقف إلزامية بعد Commit الإغلاق»):

- الوحدة **A1 مكتملة ومعتمدة (15/15)**؛ المرحلة 5 **PASS (13/13) — لا جولة ثانية**. التقييم: جودة استثنائية — الانضباط في النطاق، التوثيق التدريجي، الاختبارات الشاملة، نسخ التراجع؛ 6 أيام فعلية مقابل 12 مخططة (أسرع 50%).
- تصريف ملاحظات المرحلة 5: **S9** (إضافة `new != current`) → CD-005؛ **S2** (`cookie_secure=1` عند HTTPS) → تشغيلي؛ **S6** (مصفوفة صلاحيات كاملة) → A2؛ **تكرار Notifications** → CD-005. **الدين التقني: 14 بندًا → CD-005** (دراسة A2 + مراجعة A1 + خطة المعالجة).
- التوثيق: `CD-001_delivery/phase5/A1_Closure_Statement.md` (8 أقسام) + «§7 اعتماد نهائي» في `Phase5_Acceptance_Report.md`. الترميز في رأس `A1_Authentication_Unit_Documentation.md`/`00_INDEX.md` لم يُعرض بدقة قابلة للتعديل الآمن → سُجّل للتعامل ضمن CD-005 (أو OOS) — لم أُعدّل.
- **الإغلاق الرسمي:** الوحدة مقفلة — Commit `cd6daea` (المرحلة 5) ثم Commit الإغلاق هذا. نقطة التوقف الإلزامية بعد Commit الإغلاق قائمة.